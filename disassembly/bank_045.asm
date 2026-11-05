; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $045", ROMX[$4000], BANK[$45]

    db $45 ; Bank number

    ; Cross-bank dispatch table (128 entries)
    ; Called via: ld hl, $45XX / rst $10
    dw LoadB45_4101                  ; Entry 0
    dw TextRunB45_411e               ; Entry 1
    dw TextShowRefreshB45_413b       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_45_4158               ; Entry 4 — [table $4009]; text $0244 "*:Even though its for research...…"
    dw TextStr_45_41b2               ; Entry 5 — text $0245 "*:A skill such as Vivify can evol…"
    dw TextStr_45_42de               ; Entry 6 — text $0246 "*:Monsters fight differently depe…"
    dw TextStr_45_43be               ; Entry 7 — text $0247 "*:Order the same command again & …"
    dw TextStr_45_443f               ; Entry 8 — text $0248 "*:A good personality makes good t…"
    dw TextStr_45_4475               ; Entry 9 — text $0249 "*:Argh, who woke us up?"
    dw TextStr_45_4490               ; Entry 10 — text $024A "*:Since [HERO] won… *:Customers h…"
    dw TextStr_45_4519               ; Entry 11 — text $024B "[HERO] looked at the candle. Whoa…"
    dw TextStr_45_456f               ; Entry 12 — text $024C "*:I heard there are only Plant mo…"
    dw TextStr_45_4625               ; Entry 13 — text $024D "*:If you've got money you should …"
    dw TextStr_45_46bc               ; Entry 14 — text $024E "*:When you receive an offer to br…"
    dw TextStr_45_47b2               ; Entry 15 — text $024F "*:Hic, yo brother. Wanna have a b…"
    dw TextStr_45_481e               ; Entry 16 — text $0250 "*:I know. *:There will be a youth…"
    dw TextStr_45_4883               ; Entry 17 — text $0251 "*:Zzz... zzzz...."
    dw TextStr_45_4899               ; Entry 18 — text $0252 "*:Zzz... zzzz.... ....*bust!* *:I…"
    dw TextStr_45_48f2               ; Entry 19 — text $0253 "*:...zzz. You came again!"
    dw TextStr_45_490f               ; Entry 20 — text $0254 "*:You're strong!!"
    dw TextStr_45_4924               ; Entry 21 — text $0255 "Watabou:You couldn't carry the pr…"
    dw TextStr_45_4977               ; Entry 22 — text $0256 "*:........"
    dw TextStr_45_4986               ; Entry 23 — text $0257 "*:You, stop right there! *:You sh…"
    dw TextStr_45_49ef               ; Entry 24 — text $0258 "*:Must I repeat myself? *:You sha…"
    dw TextStr_45_4a25               ; Entry 25 — text $0259 "*:You are powerful. *:But defeati…"
    dw TextStr_45_4a7e               ; Entry 26 — text $025A "*:Want to match with my CatFly?"
    dw TextStr_45_4aa0               ; Entry 27 — text $025B "*:You are aiming for D class now?…"
    dw TextStr_45_4b52               ; Entry 28 — text $025C "*:The guardian there doesn't belo…"
    dw TextStr_45_4ba1               ; Entry 29 — text $025D "*:I heard it's a haven for slimes…"
    dw TextStr_45_4c4d               ; Entry 30 — text $025E "*:I'm Mick. It's hard to deal wit…"
    dw TextStr_45_4c83               ; Entry 31 — text $025F "*:The Queen gave me a personal in…"
    dw TextStr_45_4cb6               ; Entry 32 — text $0260 "*:If you become famous, you'll be…"
    dw TextStr_45_4cec               ; Entry 33 — text $0261 "*:Why are you bugging me so much?…"
    dw TextStr_45_4dad               ; Entry 34 — text $0262 "Watabou:This village is an illusi…"
    dw TextStr_45_4e3d               ; Entry 35 — text $0263 "*:Grrrr... Whoosh! Whoooosh!"
    dw TextStr_45_4e5d               ; Entry 36 — text $0264 "*:Guffaw Guffaw..? Cackle cackle.…"
    dw TextStr_45_4e85               ; Entry 37 — text $0265 "*:Grrrr... Whoosh! Whoooosh! *:..…"
    dw TextStr_45_4ebb               ; Entry 38 — text $0266 "*:Grrrr... Cackle cackle!!"
    dw TextStr_45_4ed9               ; Entry 39 — text $0267 "*:[HERO]! [HERO]!! *:Meow. Purrrr…"
    dw TextStr_45_4efc               ; Entry 40 — text $0268 "Watabou:It seems MadCat is attach…"
    dw TextStr_45_4f48               ; Entry 41 — text $0269 "[HERO] read the sign. :Youth goes…"
    dw TextStr_45_4fa2               ; Entry 42 — text $026A "*:Hee hee hee! I didn't think you…"
    dw TextStr_45_5010               ; Entry 43 — text $026B "*:No matter how many times you fi…"
    dw TextStr_45_505f               ; Entry 44 — text $026C "You want to breed with my LizardM…"
    dw TextStr_45_508b               ; Entry 45 — text $026D "*:Breeding with monsters of anoth…"
    dw TextStr_45_5163               ; Entry 46 — text $026E "*:This is the Room of Peace & Bra…"
    dw TextStr_45_51d8               ; Entry 47 — text $026F "*:You're my opponent? Is this a j…"
    dw TextStr_45_523b               ; Entry 48 — text $0270 "*:I wondered who it would be. Its…"
    dw TextStr_45_52d1               ; Entry 49 — text $0271 "*:You again? It'll be the same no…"
    dw TextStr_45_5348               ; Entry 50 — text $0272 "King:Oh [HERO]! Good work on surv…"
    dw TextStr_45_5564               ; Entry 51 — text $0273 "*:The Gate of Anger seems strange…"
    dw TextStr_45_5654               ; Entry 52 — text $0274 "*:The number of monsters is incre…"
    dw TextStr_45_5694               ; Entry 53 — text $0275 "King:[HERO]! Its okay to go to ot…"
    dw TextStr_45_5750               ; Entry 54 — text $0276 "[HERO] looked at the bookshelf. :…"
    dw TextStr_45_57c1               ; Entry 55 — text $0277 "*:I heard you defeated Mick. You'…"
    dw TextStr_45_5839               ; Entry 56 — text $0278 "*:The Room of Strength & Anger is…"
    dw TextStr_45_5878               ; Entry 57 — text $0279 "*:You're at the Chamber of Traver…"
    dw TextStr_45_58de               ; Entry 58 — text $027A "*:BattleRex uses EvilSlash. *:It …"
    dw TextStr_45_595c               ; Entry 59 — text $027B "*:There's a strange stone statue …"
    dw TextStr_45_59a0               ; Entry 60 — text $027C "*:Go to the Room of Strength & An…"
    dw TextStr_45_5a75               ; Entry 61 — text $027D "*:Until you settle the disaster b…"
    dw TextStr_45_5aeb               ; Entry 62 — text $027E "*:I guess staying on the farm mea…"
    dw TextStr_45_5b87               ; Entry 63 — text $027F "*:…I heard it's a kingdom of Devi…"
    dw TextStr_45_5c21               ; Entry 64 — text $0280 "*:MadGopher go mad go far! Funny?"
    dw TextStr_45_5c46               ; Entry 65 — text $0281 "*:You beat Mick? You're one tough…"
    dw TextStr_45_5cfd               ; Entry 66 — text $0282 "*:Yo, dude! You're not allowed to…"
    dw TextStr_45_5d31               ; Entry 67 — text $0283 "*:…I heard it is overrun with Zom…"
    dw TextStr_45_5da0               ; Entry 68 — text $0284 "*:So you defeated Mick. *:But rem…"
    dw TextStr_45_5e77               ; Entry 69 — text $0285 "*:[HERO], as you see, the experim…"
    dw TextStr_45_5f60               ; Entry 70 — text $0286 "*:I failed. Sorry, but you have t…"
    dw TextStr_45_5fe0               ; Entry 71 — text $0287 "*:He paid for it! He shouldn't ha…"
    dw TextStr_45_6070               ; Entry 72 — text $0288 "*:Welcome to the Master School. *…"
    dw TextStr_45_60f3               ; Entry 73 — text $0289 "*:…I heard there are monsters in …"
    dw TextStr_45_6179               ; Entry 74 — text $028A "[SOUND 60][HERO] looked into the …"
    dw TextStr_45_61b0               ; Entry 75 — text $028B "*:How did you beat Mick! I'm glad…"
    dw TextStr_45_62b9               ; Entry 76 — text $028C "*:The names of the monsters avail…"
    dw TextStr_45_63a6               ; Entry 77 — text $028D "*:Hmm. Indeed. The victor, [HERO]…"
    dw TextStr_45_63db               ; Entry 78 — text $028E "*:Congratulations on your victory…"
    dw TextStr_45_6458               ; Entry 79 — text $028F "Mick:I should simply accept my de…"
    dw TextStr_45_64f5               ; Entry 80 — text $0290 "*:Ha ha ha! You beat me!"
    dw TextStr_45_6511               ; Entry 81 — text $0291 "*:Squeaking squeaking."
    dw TextStr_45_652b               ; Entry 82 — text $0292 "*:… …"
    dw TextStr_45_6535               ; Entry 83 — text $0293 "Watabou:You did a good job solvin…"
    dw TextStr_45_65bf               ; Entry 84 — text $0294 "*:Wel...come..."
    dw TextStr_45_65d3               ; Entry 85 — text $0295 "*:Come.....again.."
    dw TextStr_45_65ea               ; Entry 86 — text $0296 "*:… … …"
    dw TextStr_45_65f6               ; Entry 87 — text $0297 "*:… … …"
    dw TextStr_45_6602               ; Entry 88 — text $0298 "Watabou:This place was ruined by …"
    dw TextStr_45_667c               ; Entry 89 — text $0299 "[HERO] pulled the slot machine! T…"
    dw TextStr_45_6722               ; Entry 90 — text $029A "Mick:As proof of my friendship le…"
    dw TextStr_45_678f               ; Entry 91 — text $029B "Mick:I'm going on a journey now. …"
    dw TextStr_45_6803               ; Entry 92 — text $029C "*:[HERO], here is the Room of Str…"
    dw TextStr_45_686f               ; Entry 93 — text $029D "*:Monsters are flooding out from …"
    dw TextStr_45_68ff               ; Entry 94 — text $029E "*:It's my wish that... *:my famil…"
    dw TextStr_45_6977               ; Entry 95 — text $029F "*:That my family in this world pr…"
    dw TextStr_45_6a11               ; Entry 96 — text $02A0 "*:Shoot! Not here either!"
    dw TextStr_45_6a2e               ; Entry 97 — text $02A1 "*:Who are you? You're a monster m…"
    dw TextStr_45_6aa0               ; Entry 98 — text $02A2 "[HERO] looked at the egg. A monst…"
    dw TextStr_45_6ad6               ; Entry 99 — text $02A3 "[HERO] looked at the egg. The egg…"
    dw TextStr_45_6b05               ; Entry 100 — text $02A4 "*:Arrrgh! How dare you crack all …"
    dw TextStr_45_6b6f               ; Entry 101 — text $02A5 "*:It's you again! You'll pay for …"
    dw TextStr_45_6ba7               ; Entry 102 — text $02A6 "*:That sword man looked like you.…"
    dw TextStr_45_6bce               ; Entry 103 — text $02A7 "Watabou:Those eggs were the reaso…"
    dw TextStr_45_6c7d               ; Entry 104 — text $02A8 "*:Soon you will become powerful! …"
    dw TextStr_45_6d72               ; Entry 105 — text $02A9 "King:Oh [HERO]!! Welcome back! Ki…"
    dw TextStr_45_6de1               ; Entry 106 — text $02AA "*:Oh... This kingdom is full of e…"
    dw TextStr_45_6f4c               ; Entry 107 — text $02AB "*:You look especially merry. Are …"
    dw TextStr_45_6fc7               ; Entry 108 — text $02AC "DeadTree King:... King of GreatTr…"
    dw TextStr_45_7054               ; Entry 109 — text $02AD "King:DeadTree! You will see! King…"
    dw TextStr_45_7235               ; Entry 110 — text $02AE "*:This shaking is evidence of the…"
    dw TextStr_45_72ae               ; Entry 111 — text $02AF "*:The shaking of GreatTree has ch…"
    dw TextStr_45_737a               ; Entry 112 — text $02B0 "*:Are you familiar with the Gate …"
    dw TextStr_45_73ad               ; Entry 113 — text $02B1 "*:The victor made countless eggs …"
    dw TextStr_45_7420               ; Entry 114 — text $02B2 "*:Are you familiar with the Gate …"
    dw TextStr_45_7456               ; Entry 115 — text $02B3 "*:I looked back and the stone sta…"
    dw TextStr_45_74db               ; Entry 116 — text $02B4 "*:I see. It's okay then. Sorry to…"
    dw TextStr_45_7510               ; Entry 117 — text $02B5 "*:Sometimes a lie makes people ha…"
    dw TextStr_45_75ae               ; Entry 118 — text $02B6 "King:Oh, [HERO] You beat StoneMan…"
    dw TextStr_45_7623               ; Entry 119 — text $02B7 "King:Well [HERO]. Are you talking…"
    dw TextStr_45_7733               ; Entry 120 — text $02B8 "[HERO] looked at the bookshelf. :…"
    dw TextStr_45_7788               ; Entry 121 — text $02B9 "*:You're at the castle of GreatTr…"
    dw TextStr_45_780b               ; Entry 122 — text $02BA "*:A long time ago, the ancestor o…"
    dw TextStr_45_787b               ; Entry 123 — text $02BB "*:I often see the girl who stood …"
    dw TextStr_45_78f3               ; Entry 124 — text $02BC "*:The Kingdom of DeadTree is almo…"
    dw TextStr_45_795e               ; Entry 125 — text $02BD "*:I want us to win this time! *:T…"
    dw TextStr_45_79f3               ; Entry 126 — text $02BE "*:Right to the Bazaar! There are …"
    dw TextStr_45_7a28               ; Entry 127 — text $02BF "*:D... Do ya know there was a big…"

LoadB45_4101:
    ld a, [$c823]
    cp $7c
    jr c, jr_045_4117

    sub $7c
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1f00
    rst $10
    ret


jr_045_4117:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB45_411e:
    ld a, [$c823]
    cp $7c
    jr c, jr_045_4134

    sub $7c
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1f01
    rst $10
    ret


jr_045_4134:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB45_413b:
    ld a, [$c823]
    cp $7c
    jr c, jr_045_4151

    sub $7c
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $1f02
    rst $10
    ret


jr_045_4151:
    call LoadB45_4101
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $45: $4158-$7a5b) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_45_4158:           ; id $0244
    ; "*:Even though its for research... / It's cruel to give me away...! / *:So cruel!!!"
    db $eb, $9f, $a3, $28, $53, $42, $4b, $62, $51, $45, $4c, $52, $44, $45, $62, $46
    db $51, $50, $ef, $ee, $43, $4c, $4f, $62, $4f, $42, $50, $42, $3e, $4f, $40, $45
    db $5f, $5f, $5f, $fa, $f7, $ef, $ee, $2c, $51, $68, $62, $40, $4f, $52, $42, $49
    db $62, $51, $4c, $ef, $ee, $44, $46, $53, $42, $62, $4a, $42, $62, $3e, $54, $3e
    db $56, $5f, $5f, $5f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $62, $40, $4f
    db $52, $42, $49, $63, $63, $63, $ef, $ee, $f7, $f0
TextStr_45_41b2:           ; id $0245
    ; "*:A skill such as Vivify can evolve / into Revive with experience. / *:But to evolve. / *:Level, MP & Intelligence have / to be over a certa..."
    db $ea, $9f, $a3, $24, $62, $50, $48, $46, $49, $49, $62, $50, $52, $40, $45, $62
    db $3e, $50, $ef, $ee, $39, $46, $53, $46, $43, $56, $62, $40, $3e, $4b, $62, $42
    db $53, $4c, $49, $53, $42, $fa, $f7, $ef, $ee, $46, $4b, $51, $4c, $62, $35, $42
    db $53, $46, $53, $42, $62, $54, $46, $51, $45, $62, $ef, $ee, $42, $55, $4d, $42
    db $4f, $46, $42, $4b, $40, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51
    db $62, $51, $4c, $62, $42, $53, $4c, $49, $53, $42, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2f, $42, $53, $42, $49, $5e, $62, $30, $33, $62, $b6, $ef, $ee
    db $2c, $4b, $51, $42, $49, $49, $46, $44, $42, $4b, $40, $42, $62, $45, $3e, $53
    db $42, $fa, $f7, $ef, $ee, $51, $4c, $62, $3f, $42, $62, $4c, $53, $42, $4f, $62
    db $3e, $ef, $ee, $40, $42, $4f, $51, $3e, $46, $4b, $62, $53, $3e, $49, $52, $42
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $29, $4c, $4f, $62, $42, $55, $3e, $4a, $4d
    db $49, $42, $5e, $62, $46, $43, $ef, $ee, $56, $4c, $52, $62, $45, $3e, $53, $42
    db $62, $39, $46, $53, $46, $43, $56, $fa, $f7, $ef, $ee, $46, $51, $62, $54, $46
    db $49, $49, $62, $42, $53, $4c, $49, $53, $42, $62, $51, $4c, $ef, $ee, $35, $42
    db $53, $46, $53, $42, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42
    db $4b, $62, $56, $4c, $52, $4f, $62, $53, $3e, $49, $52, $42, $50, $ef, $ee, $42
    db $55, $40, $42, $42, $41, $62, $2f, $42, $53, $42, $49, $62, $3b, $5e, $fa, $f7
    db $ef, $ee, $30, $33, $62, $3c, $5e, $62, $b6, $ef, $ee, $2c, $4b, $51, $42, $49
    db $49, $46, $44, $42, $4b, $40, $42, $62, $3d, $5f, $f7, $f0
TextStr_45_42de:           ; id $0246
    ; "*:Monsters fight differently / depending on their personalities. / *:They might ignore orders if / the orders don't match their / personalit..."
    db $eb, $9f, $a3, $30, $4c, $4b, $50, $51, $42, $4f, $50, $62, $43, $46, $44, $45
    db $51, $ef, $ee, $41, $46, $43, $43, $42, $4f, $42, $4b, $51, $49, $56, $fa, $f7
    db $ef, $ee, $41, $42, $4d, $42, $4b, $41, $46, $4b, $44, $62, $4c, $4b, $62, $51
    db $45, $42, $46, $4f, $ef, $ee, $4d, $42, $4f, $50, $4c, $4b, $3e, $49, $46, $51
    db $46, $42, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $56, $62, $4a
    db $46, $44, $45, $51, $ef, $ee, $46, $44, $4b, $4c, $4f, $42, $62, $4c, $4f, $41
    db $42, $4f, $50, $62, $46, $43, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4c, $4f
    db $41, $42, $4f, $50, $62, $41, $4c, $4b, $67, $ef, $ee, $4a, $3e, $51, $40, $45
    db $62, $51, $45, $42, $46, $4f, $fa, $f7, $ef, $ee, $4d, $42, $4f, $50, $4c, $4b
    db $3e, $49, $46, $51, $46, $42, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $27, $4c, $62, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $ef, $ee
    db $48, $4b, $4c, $54, $62, $45, $4c, $54, $62, $51, $4c, $62, $40, $45, $3e, $4b
    db $44, $42, $fa, $f7, $ef, $ee, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $68
    db $ef, $ee, $4d, $42, $4f, $50, $4c, $4b, $3e, $49, $46, $51, $56, $64, $ff, $f0
TextStr_45_43be:           ; id $0247
    ; "*:Order the same command again & / again until they listen. / *:When they obey, their personality / will have changed."
    db $eb, $9f, $a3, $32, $4f, $41, $42, $4f, $62, $51, $45, $42, $62, $50, $3e, $4a
    db $42, $ef, $ee, $40, $4c, $4a, $4a, $3e, $4b, $41, $62, $3e, $44, $3e, $46, $4b
    db $62, $b6, $fa, $f7, $ef, $ee, $3e, $44, $3e, $46, $4b, $62, $52, $4b, $51, $46
    db $49, $62, $51, $45, $42, $56, $ef, $ee, $49, $46, $50, $51, $42, $4b, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $56, $62, $4c
    db $3f, $42, $56, $5e, $ef, $ee, $51, $45, $42, $46, $4f, $62, $4d, $42, $4f, $50
    db $4c, $4b, $3e, $49, $46, $51, $56, $fa, $f7, $ef, $ee, $54, $46, $49, $49, $62
    db $45, $3e, $53, $42, $62, $40, $45, $3e, $4b, $44, $42, $41, $5f, $ef, $ee, $f7
    db $f0
TextStr_45_443f:           ; id $0248
    ; "*:A good personality makes / good things happen!"
    db $eb, $9f, $a3, $24, $62, $44, $4c, $4c, $41, $ef, $ee, $4d, $42, $4f, $50, $4c
    db $4b, $3e, $49, $46, $51, $56, $62, $4a, $3e, $48, $42, $50, $fa, $f7, $ef, $ee
    db $44, $4c, $4c, $41, $62, $51, $45, $46, $4b, $44, $50, $ef, $ee, $45, $3e, $4d
    db $4d, $42, $4b, $63, $f7, $f0
TextStr_45_4475:           ; id $0249
    ; "*:Argh, who woke us up?"
    db $ea, $9f, $a3, $24, $4f, $44, $45, $5e, $62, $54, $45, $4c, $62, $54, $4c, $48
    db $42, $ef, $ee, $52, $50, $62, $52, $4d, $64, $f7, $f0
TextStr_45_4490:           ; id $024A
    ; "*:Since [HERO] won… / *:Customers have flooded our store! / *:It's all thanks to [HERO]'s / victory! / *:So, what can I do for you today?"
    db $ea, $9f, $a3, $36, $46, $4b, $40, $42, $62, $f6, $ef, $ee, $54, $4c, $4b, $a4
    db $fa, $f7, $ef, $ee, $9f, $a3, $26, $52, $50, $51, $4c, $4a, $42, $4f, $50, $62
    db $45, $3e, $53, $42, $ef, $ee, $43, $49, $4c, $4c, $41, $42, $41, $62, $4c, $52
    db $4f, $62, $50, $51, $4c, $4f, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51
    db $68, $62, $3e, $49, $49, $62, $51, $45, $3e, $4b, $48, $50, $ef, $ee, $51, $4c
    db $62, $f6, $68, $fa, $f7, $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $5e, $62, $54, $45, $3e, $51, $62
    db $40, $3e, $4b, $62, $2c, $ef, $ee, $41, $4c, $62, $43, $4c, $4f, $62, $56, $4c
    db $52, $62, $51, $4c, $41, $3e, $56, $64, $f0
TextStr_45_4519:           ; id $024B
    ; "[HERO] looked at the candle. / Whoa! It's a MadCandle! / But MadCandle is sleeping..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $40, $3e, $4b, $41, $49, $42, $5f, $fa, $f7, $ef, $ee, $3a, $45, $4c, $3e
    db $63, $62, $2c, $51, $68, $62, $3e, $ef, $ee, $30, $3e, $41, $26, $3e, $4b, $41
    db $49, $42, $63, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $30, $3e, $41, $26, $3e
    db $4b, $41, $49, $42, $ef, $ee, $46, $50, $62, $50, $49, $42, $42, $4d, $46, $4b
    db $44, $5f, $5f, $5f, $f7, $f0
TextStr_45_456f:           ; id $024C
    ; "*:I heard there are only Plant / monsters there... / *:An oracle of a cult is the / guardian of the Gate. / *:I heard about the Gate of / Ma..."
    db $ea, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45, $42, $4f, $42
    db $ef, $ee, $3e, $4f, $42, $62, $4c, $4b, $49, $56, $62, $33, $49, $3e, $4b, $51
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $45, $42
    db $4f, $42, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $62
    db $4c, $4f, $3e, $40, $49, $42, $62, $4c, $43, $62, $3e, $ef, $ee, $40, $52, $49
    db $51, $62, $46, $50, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44, $52, $3e, $4f
    db $41, $46, $3e, $4b, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee, $2a, $3e, $51
    db $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62
    db $3e, $3f, $4c, $52, $51, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $62
    db $4c, $43, $fa, $f7, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $4a, $46, $4b, $41
    db $62, $51, $4c, $4c, $5f, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $45
    db $42, $3e, $4f, $64, $ff, $f0
TextStr_45_4625:           ; id $024D
    ; "*:If you've got money you should / get a Sirloin! / *:Almost all the monsters will / become your pal... / *:if you give'em Sirloin 4 times."
    db $ea, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $6c, $42, $62, $44, $4c, $51, $ef
    db $ee, $4a, $4c, $4b, $42, $56, $62, $56, $4c, $52, $62, $50, $45, $4c, $52, $49
    db $41, $fa, $f7, $ef, $ee, $44, $42, $51, $62, $3e, $62, $36, $46, $4f, $49, $4c
    db $46, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $49, $4a, $4c, $50
    db $51, $62, $3e, $49, $49, $62, $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee, $3f, $42, $40, $4c
    db $4a, $42, $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $5f, $5f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $46, $43, $62, $56, $4c, $52, $62, $44, $46, $53
    db $42, $6e, $4a, $ef, $ee, $36, $46, $4f, $49, $4c, $46, $4b, $62, $04, $62, $51
    db $46, $4a, $42, $50, $5f, $f7, $f0
TextStr_45_46bc:           ; id $024E
    ; "*:When you receive an offer to breed, / take it quickly. / *:People always change their mind. / *:It could be a chance to breed / with rare ..."
    db $ea, $9f, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $62, $4f, $42, $40, $42
    db $46, $53, $42, $ef, $ee, $3e, $4b, $62, $4c, $43, $43, $42, $4f, $62, $51, $4c
    db $62, $3f, $4f, $42, $42, $41, $5e, $fa, $f7, $ef, $ee, $51, $3e, $48, $42, $62
    db $46, $51, $62, $4e, $52, $46, $40, $48, $49, $56, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $33, $42, $4c, $4d, $49, $42, $62, $3e, $49, $54, $3e, $56, $50
    db $ef, $ee, $40, $45, $3e, $4b, $44, $42, $62, $51, $45, $42, $46, $4f, $62, $4a
    db $46, $4b, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $62, $40, $4c, $52
    db $49, $41, $62, $3f, $42, $62, $3e, $ef, $ee, $40, $45, $3e, $4b, $40, $42, $62
    db $51, $4c, $62, $3f, $4f, $42, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45
    db $62, $4f, $3e, $4f, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45
    db $3e, $51, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $4f, $42
    db $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c, $52, $4f, $62, $43
    db $4f, $46, $42, $4b, $41, $50, $5c, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $62, $3e, $4f, $42, $fa, $f7, $ef, $ee, $50, $51, $4f, $4c, $4b, $44, $42
    db $4f, $5f, $ef, $ee, $f7, $f0
TextStr_45_47b2:           ; id $024F
    ; "*:Hic, yo brother. Wanna have a breed / with me? / *:Oops, I meant, wanna breed with / my CatFly?"
    db $ea, $9f, $a3, $2b, $46, $40, $5e, $62, $56, $4c, $62, $3f, $4f, $4c, $51, $45
    db $42, $4f, $5f, $ef, $ee, $3a, $3e, $4b, $4b, $3e, $62, $45, $3e, $53, $42, $62
    db $3e, $62, $3f, $4f, $42, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62
    db $4a, $42, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $4c, $4d, $50, $5e
    db $62, $2c, $62, $4a, $42, $3e, $4b, $51, $5e, $ef, $ee, $54, $3e, $4b, $4b, $3e
    db $62, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $4a
    db $56, $62, $26, $3e, $51, $29, $49, $56, $64, $ef, $ee, $f0
TextStr_45_481e:           ; id $0250
    ; "*:I know. / *:There will be a youth... / *:But it's not you. / *:My name's Laura. Thank you."
    db $eb, $9f, $a3, $2c, $62, $48, $4b, $4c, $54, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $46, $49, $49, $ef, $ee, $3f, $42
    db $62, $3e, $62, $56, $4c, $52, $51, $45, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $25, $52, $51, $62, $46, $51, $68, $62, $4b, $4c, $51, $ef, $ee, $56, $4c
    db $52, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $30, $56, $62, $4b, $3e, $4a, $42, $68
    db $ef, $ee, $2f, $3e, $52, $4f, $3e, $5f, $62, $37, $45, $3e, $4b, $48, $62, $56
    db $4c, $52, $5f, $f7, $f0
TextStr_45_4883:           ; id $0251
    ; "*:Zzz... zzzz...."
    db $ea, $9f, $a3, $3d, $57, $57, $5f, $5f, $5f, $62, $57, $57, $57, $57, $5f, $5f
    db $5f, $5f, $ef, $ee, $f7, $f0
TextStr_45_4899:           ; id $0252
    ; "*:Zzz... zzzz.... ....*bust!* / *:It's been a long time since I've / seen a guest."
    db $ea, $9f, $a3, $3d, $57, $57, $5f, $5f, $5f, $62, $57, $57, $57, $57, $5f, $5f
    db $5f, $5f, $ef, $ee, $5f, $5f, $5f, $5f, $9f, $3f, $52, $50, $51, $63, $9f, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62, $3f, $42, $42, $4b, $62, $3e, $62
    db $49, $4c, $4b, $44, $ef, $ee, $51, $46, $4a, $42, $62, $50, $46, $4b, $40, $42
    db $62, $2c, $6c, $42, $fa, $f7, $ef, $ee, $50, $42, $42, $4b, $62, $3e, $62, $44
    db $52, $42, $50, $51, $5f, $ef, $ee, $f7, $f0
TextStr_45_48f2:           ; id $0253
    ; "*:...zzz. You came again!"
    db $ea, $9f, $a3, $5f, $5f, $5f, $57, $57, $57, $5f, $ef, $ee, $3c, $4c, $52, $62
    db $40, $3e, $4a, $42, $62, $3e, $44, $3e, $46, $4b, $63, $f7, $f0
TextStr_45_490f:           ; id $0254
    ; "*:You're strong!!"
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $50, $51, $4f, $4c, $4b, $44, $63
    db $63, $ef, $ee, $f7, $f0
TextStr_45_4924:           ; id $0255
    ; "Watabou:You couldn't carry the / princess. / Watabou:Oh well! Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3c, $4c, $52, $ef, $ee, $40, $4c
    db $52, $49, $41, $4b, $67, $62, $40, $3e, $4f, $4f, $56, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $4d, $4f, $46, $4b, $40, $42, $50, $50, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $32, $45, $62, $54, $42, $49
    db $49, $63, $ef, $ee, $2f, $42, $51, $68, $62, $44, $4c, $62, $3f, $3e, $40, $48
    db $63, $f7, $f0
TextStr_45_4977:           ; id $0256
    ; "*:........"
    db $ea, $9f, $a3, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_45_4986:           ; id $0257
    ; "*:You, stop right there! / *:You shall not pass. / *:I'm Golem the protector of / this village!"
    db $ea, $9f, $a3, $3c, $4c, $52, $5e, $62, $50, $51, $4c, $4d, $62, $4f, $46, $44
    db $45, $51, $ef, $ee, $51, $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $3c, $4c, $52, $62, $50, $45, $3e, $49, $49, $62, $4b, $4c, $51, $ef, $ee, $4d
    db $3e, $50, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $2a, $4c, $49
    db $42, $4a, $62, $51, $45, $42, $ef, $ee, $4d, $4f, $4c, $51, $42, $40, $51, $4c
    db $4f, $62, $4c, $43, $fa, $f7, $ef, $ee, $51, $45, $46, $50, $62, $53, $46, $49
    db $49, $3e, $44, $42, $63, $ef, $ee, $f7, $f0
TextStr_45_49ef:           ; id $0258
    ; "*:Must I repeat myself? / *:You shall not pass!!"
    db $ea, $9f, $a3, $30, $52, $50, $51, $62, $2c, $62, $4f, $42, $4d, $42, $3e, $51
    db $ef, $ee, $4a, $56, $50, $42, $49, $43, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3c
    db $4c, $52, $62, $50, $45, $3e, $49, $49, $62, $4b, $4c, $51, $ef, $ee, $4d, $3e
    db $50, $50, $63, $63, $f7, $f0
TextStr_45_4a25:           ; id $0259
    ; "*:You are powerful. / *:But defeating me doesn't mean you / can enter the village."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $ef, $ee, $4d, $4c, $54, $42
    db $4f, $43, $52, $49, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $41
    db $42, $43, $42, $3e, $51, $46, $4b, $44, $62, $4a, $42, $ef, $ee, $41, $4c, $42
    db $50, $4b, $67, $62, $4a, $42, $3e, $4b, $62, $56, $4c, $52, $fa, $f7, $ef, $ee
    db $40, $3e, $4b, $62, $42, $4b, $51, $42, $4f, $62, $51, $45, $42, $ef, $ee, $53
    db $46, $49, $49, $3e, $44, $42, $5f, $f7, $f0
TextStr_45_4a7e:           ; id $025A
    ; "*:Want to match with my CatFly?"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4a, $3e, $51, $40, $45
    db $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $26, $3e, $51, $29, $49, $56
    db $64, $f0
TextStr_45_4aa0:           ; id $025B
    ; "*:You are aiming for D class now? / Watch out for Mick! / *:Breed many monsters and / teach them lots of skills... / *:and you'll make power..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $3e, $46, $4a, $46, $4b
    db $44, $ef, $ee, $43, $4c, $4f, $62, $27, $62, $40, $49, $3e, $50, $50, $62, $4b
    db $4c, $54, $64, $fa, $f7, $ef, $ee, $3a, $3e, $51, $40, $45, $62, $4c, $52, $51
    db $62, $43, $4c, $4f, $ef, $ee, $30, $46, $40, $48, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $25, $4f, $42, $42, $41, $62, $4a, $3e, $4b, $56, $ef, $ee, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $51, $42, $3e
    db $40, $45, $62, $51, $45, $42, $4a, $ef, $ee, $49, $4c, $51, $50, $62, $4c, $43
    db $62, $50, $48, $46, $49, $49, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $3e, $4b, $41, $62, $56, $4c, $52, $66, $49, $62, $4a, $3e, $48, $42, $ef, $ee
    db $4d, $4c, $54, $42, $4f, $43, $52, $49, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $ef, $ee, $2a, $4c, $4c, $41, $62, $49, $52, $40, $48, $63
    db $f7, $f0
TextStr_45_4b52:           ; id $025C
    ; "*:The guardian there doesn't / belong to any of the monster / families!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef
    db $ee, $51, $45, $42, $4f, $42, $62, $41, $4c, $42, $50, $4b, $67, $fa, $f7, $ef
    db $ee, $3f, $42, $49, $4c, $4b, $44, $62, $51, $4c, $62, $3e, $4b, $56, $62, $4c
    db $43, $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7
    db $ef, $ee, $43, $3e, $4a, $46, $49, $46, $42, $50, $63, $ef, $ee, $f7, $f0
TextStr_45_4ba1:           ; id $025D
    ; "*:I heard it's a haven for slimes. / *:The guardian there is a monster / feared by even the great evil / lord! / *:Wanna hear about the Gate..."
    db $ea, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $46, $51, $68, $62, $3e
    db $ef, $ee, $45, $3e, $53, $42, $4b, $62, $43, $4c, $4f, $62, $50, $49, $46, $4a
    db $42, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e
    db $4f, $41, $46, $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62
    db $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $43, $42, $3e
    db $4f, $42, $41, $62, $3f, $56, $62, $42, $53, $42, $4b, $ef, $ee, $51, $45, $42
    db $62, $44, $4f, $42, $3e, $51, $62, $42, $53, $46, $49, $fa, $f7, $ef, $ee, $49
    db $4c, $4f, $41, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $4b, $4b
    db $3e, $62, $45, $42, $3e, $4f, $62, $3e, $3f, $4c, $52, $51, $ef, $ee, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $28, $55, $51
    db $46, $4b, $40, $51, $46, $4c, $4b, $64, $ef, $ee, $ff, $f0
TextStr_45_4c4d:           ; id $025E
    ; "*:I'm Mick. It's hard to deal with / all my fans!"
    db $ea, $9f, $a3, $2c, $6a, $62, $30, $46, $40, $48, $5f, $62, $2c, $51, $68, $ef
    db $ee, $45, $3e, $4f, $41, $62, $51, $4c, $62, $41, $42, $3e, $49, $62, $54, $46
    db $51, $45, $fa, $f7, $ef, $ee, $3e, $49, $49, $62, $4a, $56, $62, $43, $3e, $4b
    db $50, $63, $ef, $ee, $f7, $f0
TextStr_45_4c83:           ; id $025F
    ; "*:The Queen gave me a personal / invitation."
    db $ea, $9f, $a3, $37, $45, $42, $62, $34, $52, $42, $42, $4b, $62, $44, $3e, $53
    db $42, $ef, $ee, $4a, $42, $62, $3e, $62, $4d, $42, $4f, $50, $4c, $4b, $3e, $49
    db $fa, $f7, $ef, $ee, $46, $4b, $53, $46, $51, $3e, $51, $46, $4c, $4b, $5f, $ef
    db $ee, $f7, $f0
TextStr_45_4cb6:           ; id $0260
    ; "*:If you become famous, you'll be / invited too!"
    db $ea, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $3f, $42, $40, $4c, $4a, $42
    db $ef, $ee, $43, $3e, $4a, $4c, $52, $50, $5e, $62, $56, $4c, $52, $66, $49, $62
    db $3f, $42, $fa, $f7, $ef, $ee, $46, $4b, $53, $46, $51, $42, $41, $62, $51, $4c
    db $4c, $63, $ef, $ee, $f7, $f0
TextStr_45_4cec:           ; id $0261
    ; "*:Why are you bugging / me so much? / *:I'll let you breed with my / monster to get you off my back. / *:You only have weak monsters. / *:Mi..."
    db $ea, $9f, $a3, $3a, $45, $56, $62, $3e, $4f, $42, $ef, $ee, $56, $4c, $52, $62
    db $3f, $52, $44, $44, $46, $4b, $44, $fa, $f7, $ef, $ee, $4a, $42, $62, $50, $4c
    db $62, $4a, $52, $40, $45, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66
    db $49, $62, $49, $42, $51, $62, $56, $4c, $52, $ef, $ee, $3f, $4f, $42, $42, $41
    db $62, $54, $46, $51, $45, $62, $4a, $56, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $62, $51, $4c, $62, $44, $42, $51, $ef, $ee, $56, $4c, $52, $62
    db $4c, $43, $43, $62, $4a, $56, $62, $3f, $3e, $40, $48, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $3c, $4c, $52, $62, $4c, $4b, $49, $56, $62, $45, $3e, $53, $42, $ef
    db $ee, $54, $42, $3e, $48, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $30, $46, $4b, $42, $62, $46, $50, $ef, $ee, $2f, $46
    db $57, $3e, $4f, $41, $30, $3e, $4b, $5f, $fa, $f7, $ef, $ee, $2b, $42, $4f, $42
    db $62, $46, $50, $62, $4a, $56, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $63
    db $f0
TextStr_45_4dad:           ; id $0262
    ; "Watabou:This village is an / illusion of Golem. / Watabou:That's why you cannot go / in. / Watabou:Let's go back to the / castle!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $37, $45, $46, $50, $ef, $ee, $53
    db $46, $49, $49, $3e, $44, $42, $62, $46, $50, $62, $3e, $4b, $fa, $f7, $ef, $ee
    db $46, $49, $49, $52, $50, $46, $4c, $4b, $62, $4c, $43, $62, $2a, $4c, $49, $42
    db $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3
    db $37, $45, $3e, $51, $68, $ef, $ee, $54, $45, $56, $62, $56, $4c, $52, $62, $40
    db $3e, $4b, $4b, $4c, $51, $62, $44, $4c, $fa, $f7, $ef, $ee, $46, $4b, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2f, $42, $51
    db $68, $ef, $ee, $44, $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $40, $3e, $50, $51, $49, $42, $63, $ef, $ee, $f7, $f0
TextStr_45_4e3d:           ; id $0263
    ; "*:Grrrr... Whoosh! Whoooosh!"
    db $ea, $9f, $a3, $2a, $4f, $4f, $4f, $4f, $5f, $5f, $5f, $ef, $ee, $3a, $45, $4c
    db $4c, $50, $45, $63, $62, $3a, $45, $4c, $4c, $4c, $4c, $50, $45, $63, $f7, $f0
TextStr_45_4e5d:           ; id $0264
    ; "*:Guffaw Guffaw..? Cackle cackle...?"
    db $ea, $9f, $a3, $2a, $52, $43, $43, $3e, $54, $62, $2a, $52, $43, $43, $3e, $54
    db $5f, $5f, $64, $ef, $ee, $26, $3e, $40, $48, $49, $42, $62, $40, $3e, $40, $48
    db $49, $42, $5f, $5f, $5f, $64, $f7, $f0
TextStr_45_4e85:           ; id $0265
    ; "*:Grrrr... Whoosh! Whoooosh! / *:......cackle!!"
    db $ea, $9f, $a3, $2a, $4f, $4f, $4f, $4f, $5f, $5f, $5f, $ef, $ee, $3a, $45, $4c
    db $4c, $50, $45, $63, $62, $3a, $45, $4c, $4c, $4c, $4c, $50, $45, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $5f, $5f, $5f, $5f, $5f, $5f, $40, $3e, $40, $48, $49, $42
    db $63, $63, $ef, $ee, $f7, $f0
TextStr_45_4ebb:           ; id $0266
    ; "*:Grrrr... Cackle cackle!!"
    db $ea, $9f, $a3, $2a, $4f, $4f, $4f, $4f, $5f, $5f, $5f, $ef, $ee, $26, $3e, $40
    db $48, $49, $42, $62, $40, $3e, $40, $48, $49, $42, $63, $63, $f7, $f0
TextStr_45_4ed9:           ; id $0267
    ; "*:[HERO]! [HERO]!! / *:Meow. Purrrr..."
    db $ea, $9f, $a3, $f6, $63, $ef, $ee, $f6, $63, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $30, $42, $4c, $54, $5f, $62, $33, $52, $4f, $4f, $4f, $4f, $5f, $5f, $5f, $ef
    db $ee, $f7, $f0
TextStr_45_4efc:           ; id $0268
    ; "Watabou:It seems MadCat is attached / to [HERO]! / Watabou:Let's go back!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2c, $51, $62, $50, $42, $42, $4a
    db $50, $ef, $ee, $30, $3e, $41, $26, $3e, $51, $62, $46, $50, $62, $3e, $51, $51
    db $3e, $40, $45, $42, $41, $fa, $f7, $ef, $ee, $51, $4c, $62, $f6, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2f, $42, $51, $68
    db $62, $44, $4c, $ef, $ee, $3f, $3e, $40, $48, $63, $f7, $f0
TextStr_45_4f48:           ; id $0269
    ; "[HERO] read the sign. / :Youth goes in haste! But the / longest way is the shortest way!"
    db $f6, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $50, $46, $44, $4b
    db $5f, $fa, $f7, $ef, $ee, $a3, $3c, $4c, $52, $51, $45, $62, $44, $4c, $42, $50
    db $62, $46, $4b, $ef, $ee, $45, $3e, $50, $51, $42, $63, $62, $25, $52, $51, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $49, $4c, $4b, $44, $42, $50, $51, $62, $54
    db $3e, $56, $62, $46, $50, $62, $51, $45, $42, $ef, $ee, $50, $45, $4c, $4f, $51
    db $42, $50, $51, $62, $54, $3e, $56, $63, $f7, $f0
TextStr_45_4fa2:           ; id $026A
    ; "*:Hee hee hee! I didn't think / you could make it this far. / *:Unfortunately, this is / a dead end."
    db $ea, $9f, $a3, $2b, $42, $42, $62, $45, $42, $42, $62, $45, $42, $42, $63, $ef
    db $ee, $2c, $62, $41, $46, $41, $4b, $67, $62, $51, $45, $46, $4b, $48, $fa, $f7
    db $ef, $ee, $56, $4c, $52, $62, $40, $4c, $52, $49, $41, $62, $4a, $3e, $48, $42
    db $ef, $ee, $46, $51, $62, $51, $45, $46, $50, $62, $43, $3e, $4f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $38, $4b, $43, $4c, $4f, $51, $52, $4b, $3e, $51, $42, $49
    db $56, $5e, $ef, $ee, $51, $45, $46, $50, $62, $46, $50, $fa, $f7, $ef, $ee, $3e
    db $62, $41, $42, $3e, $41, $62, $42, $4b, $41, $5f, $ef, $ee, $f7, $f0
TextStr_45_5010:           ; id $026B
    ; "*:No matter how many times you / fight, it won't make any / difference!"
    db $ea, $9f, $a3, $31, $4c, $62, $4a, $3e, $51, $51, $42, $4f, $62, $45, $4c, $54
    db $ef, $ee, $4a, $3e, $4b, $56, $62, $51, $46, $4a, $42, $50, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51, $5e, $62, $46, $51, $62, $54, $4c
    db $4b, $67, $ef, $ee, $4a, $3e, $48, $42, $62, $3e, $4b, $56, $fa, $f7, $ef, $ee
    db $41, $46, $43, $43, $42, $4f, $42, $4b, $40, $42, $63, $ef, $ee, $f7, $f0
TextStr_45_505f:           ; id $026C
    ; "You want to breed with / my LizardMan?"
    db $ea, $3c, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $ef, $ee, $3f, $4f
    db $42, $42, $41, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $4a, $56, $62, $2f
    db $46, $57, $3e, $4f, $41, $30, $3e, $4b, $64, $ef, $ee, $f0
TextStr_45_508b:           ; id $026D
    ; "*:Breeding with monsters of / another master... / *:creates stronger monsters than / matching with your own monsters! / *:Let me know if the..."
    db $ea, $9f, $a3, $25, $4f, $42, $42, $41, $46, $4b, $44, $62, $54, $46, $51, $45
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $4c, $43, $fa, $f7, $ef
    db $ee, $3e, $4b, $4c, $51, $45, $42, $4f, $62, $4a, $3e, $50, $51, $42, $4f, $5f
    db $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $40, $4f, $42, $3e, $51, $42
    db $50, $62, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $62, $51, $45, $3e, $4b, $fa, $f7, $ef, $ee, $4a, $3e, $51
    db $40, $45, $46, $4b, $44, $62, $54, $46, $51, $45, $62, $56, $4c, $52, $4f, $ef
    db $ee, $4c, $54, $4b, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $2f, $42, $51, $62, $4a, $42, $62, $48, $4b, $4c, $54, $62
    db $46, $43, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $4b, $56
    db $51, $45, $46, $4b, $44, $fa, $f7, $ef, $ee, $2c, $62, $40, $3e, $4b, $62, $45
    db $42, $49, $4d, $62, $56, $4c, $52, $ef, $ee, $54, $46, $51, $45, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $62, $45, $3e, $62
    db $45, $3e, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_45_5163:           ; id $026E
    ; "*:This is the Room of Peace & / Bravery. / *:Go right to the Gate of Bravery. / Left to the Gate of Peace."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $62, $35
    db $4c, $4c, $4a, $ef, $ee, $4c, $43, $62, $33, $42, $3e, $40, $42, $62, $b6, $fa
    db $f7, $ef, $ee, $25, $4f, $3e, $53, $42, $4f, $56, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $2a, $4c, $62, $4f, $46, $44, $45, $51, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $25, $4f, $3e, $53
    db $42, $4f, $56, $5f, $fa, $f7, $ef, $ee, $2f, $42, $43, $51, $62, $51, $4c, $62
    db $51, $45, $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $33, $42, $3e
    db $40, $42, $5f, $f7, $f0
TextStr_45_51d8:           ; id $026F
    ; "*:You're my opponent? / Is this a joke? / *:You have no chance with / monsters like that!"
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $4a, $56, $ef, $ee, $4c, $4d, $4d
    db $4c, $4b, $42, $4b, $51, $64, $fa, $f7, $ef, $ee, $2c, $50, $62, $51, $45, $46
    db $50, $62, $3e, $62, $47, $4c, $48, $42, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $3c, $4c, $52, $62, $45, $3e, $53, $42, $62, $4b, $4c, $ef, $ee, $40, $45
    db $3e, $4b, $40, $42, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $62, $49, $46, $48, $42, $ef, $ee, $51, $45, $3e, $51
    db $63, $f7, $f0
TextStr_45_523b:           ; id $0270
    ; "*:I wondered who it would be. / Its' you! / *:It seems the breeding with my / monster worked out for you! / *:Show me what you're made of!"
    db $ea, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $42, $41, $ef, $ee, $54
    db $45, $4c, $62, $46, $51, $62, $54, $4c, $52, $49, $41, $62, $3f, $42, $5f, $fa
    db $f7, $ef, $ee, $2c, $51, $50, $5c, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $51, $62, $50, $42, $42, $4a, $50, $62, $51, $45, $42
    db $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $54, $46, $51, $45, $62
    db $4a, $56, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $4c
    db $4f, $48, $42, $41, $ef, $ee, $4c, $52, $51, $62, $43, $4c, $4f, $62, $56, $4c
    db $52, $63, $fa, $f7, $ef, $ee, $9f, $a3, $36, $45, $4c, $54, $62, $4a, $42, $62
    db $54, $45, $3e, $51, $ef, $ee, $56, $4c, $52, $69, $42, $62, $4a, $3e, $41, $42
    db $62, $4c, $43, $63, $f7, $f0
TextStr_45_52d1:           ; id $0271
    ; "*:You again? It'll be the same / no matter how many times you try! / *:I'm strong. You're weak. / End of story!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $44, $3e, $46, $4b, $64, $ef, $ee, $2c
    db $51, $66, $49, $62, $3f, $42, $62, $51, $45, $42, $62, $50, $3e, $4a, $42, $fa
    db $f7, $ef, $ee, $4b, $4c, $62, $4a, $3e, $51, $51, $42, $4f, $62, $45, $4c, $54
    db $62, $4a, $3e, $4b, $56, $ef, $ee, $51, $46, $4a, $42, $50, $62, $56, $4c, $52
    db $62, $51, $4f, $56, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $50, $51
    db $4f, $4c, $4b, $44, $5f, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $54, $42, $3e
    db $48, $5f, $fa, $f7, $ef, $ee, $28, $4b, $41, $62, $4c, $43, $62, $50, $51, $4c
    db $4f, $56, $63, $ef, $ee, $f7, $f0
TextStr_45_5348:           ; id $0272
    ; "King:Oh [HERO]! Good work on / surviving D class! / King:I permit you to compete in C / class and above! / King:...I take it back. In fact, ..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $2a, $4c, $4c
    db $41, $62, $54, $4c, $4f, $48, $62, $4c, $4b, $fa, $f7, $ef, $ee, $50, $52, $4f
    db $53, $46, $53, $46, $4b, $44, $62, $27, $62, $40, $49, $3e, $50, $50, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $4d, $42, $4f, $4a
    db $46, $51, $62, $56, $4c, $52, $ef, $ee, $51, $4c, $62, $40, $4c, $4a, $4d, $42
    db $51, $42, $62, $46, $4b, $62, $26, $fa, $f7, $ef, $ee, $40, $49, $3e, $50, $50
    db $62, $3e, $4b, $41, $62, $3e, $3f, $4c, $53, $42, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $2e, $46, $4b, $44, $a3, $5f, $5f, $5f, $2c, $62, $51, $3e, $48, $42, $62
    db $46, $51, $ef, $ee, $3f, $3e, $40, $48, $5f, $62, $2c, $4b, $62, $43, $3e, $40
    db $51, $5e, $fa, $f7, $ef, $ee, $f6, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $37, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49
    db $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $fa, $f7, $ef, $ee, $46, $4b
    db $62, $51, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee, $36, $51
    db $4f, $42, $4b, $44, $51, $45, $62, $b6, $62, $24, $4b, $44, $42, $4f, $fa, $f7
    db $ef, $ee, $50, $42, $42, $4a, $62, $50, $51, $4f, $3e, $4b, $44, $42, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $24, $4b, $62, $42, $4b, $4c
    db $4f, $4a, $4c, $52, $50, $ef, $ee, $4b, $52, $4a, $3f, $42, $4f, $62, $4c, $43
    db $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $3e, $4f, $42
    db $62, $3e, $4d, $4d, $42, $3e, $4f, $46, $4b, $44, $62, $4c, $52, $51, $ef, $ee
    db $4c, $43, $62, $4b, $4c, $54, $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $24, $50, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $5e
    db $ef, $ee, $2c, $62, $40, $3e, $4b, $4b, $4c, $51, $62, $46, $44, $4b, $4c, $4f
    db $42, $fa, $f7, $ef, $ee, $51, $45, $46, $50, $62, $4d, $4f, $4c, $3f, $49, $42
    db $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2a, $4c, $62
    db $51, $4c, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $62
    db $36, $51, $4f, $42, $4b, $44, $51, $45, $fa, $f7, $ef, $ee, $b6, $62, $24, $4b
    db $44, $42, $4f, $ef, $ee, $46, $4a, $4a, $42, $41, $46, $3e, $51, $42, $49, $56
    db $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $35, $42, $50, $4c, $49, $53
    db $42, $62, $51, $45, $42, $ef, $ee, $4d, $4f, $4c, $3f, $49, $42, $4a, $63, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $66, $49, $62, $49, $42, $3e, $53
    db $42, $62, $46, $51, $ef, $ee, $51, $4c, $62, $56, $4c, $52, $5e, $62, $f6, $63
    db $fa, $f7, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $42, $55, $40, $52, $50, $42
    db $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $25, $52, $50, $56, $63, $62, $25, $52
    db $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $f7, $f0
TextStr_45_5564:           ; id $0273
    ; "*:The Gate of Anger seems / strange! / *:It seems an enormous number / of monsters are appearing! / *:Please get to the bottom of / this imm..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee
    db $24, $4b, $44, $42, $4f, $62, $50, $42, $42, $4a, $50, $fa, $f7, $ef, $ee, $50
    db $51, $4f, $3e, $4b, $44, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $51, $62, $50, $42, $42, $4a, $50, $62, $3e, $4b, $ef, $ee, $42, $4b, $4c, $4f
    db $4a, $4c, $52, $50, $62, $4b, $52, $4a, $3f, $42, $4f, $fa, $f7, $ef, $ee, $4c
    db $43, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $4f, $42, $ef, $ee
    db $3e, $4d, $4d, $42, $3e, $4f, $46, $4b, $44, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $33, $49, $42, $3e, $50, $42, $62, $44, $42, $51, $62, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $3f, $4c, $51, $51, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $51, $45, $46, $50, $62, $46, $4a, $4a, $42, $41, $46, $3e, $51, $42, $49, $56
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2a, $3e, $51
    db $42, $62, $4c, $43, $ef, $ee, $24, $4b, $44, $42, $4f, $62, $46, $50, $62, $49
    db $4c, $40, $3e, $51, $42, $41, $fa, $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42
    db $62, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $ef, $ee, $37, $4f, $3e
    db $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $5f, $f7, $f0
TextStr_45_5654:           ; id $0274
    ; "*:The number of monsters is / increasing. What's going on!?"
    db $eb, $9f, $a3, $37, $45, $42, $62, $4b, $52, $4a, $3f, $42, $4f, $62, $4c, $43
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $46, $50, $fa, $f7, $ef
    db $ee, $46, $4b, $40, $4f, $42, $3e, $50, $46, $4b, $44, $5f, $62, $3a, $45, $3e
    db $51, $68, $ef, $ee, $44, $4c, $46, $4b, $44, $62, $4c, $4b, $63, $64, $f7, $f0
TextStr_45_5694:           ; id $0275
    ; "King:[HERO]! Its okay to go to / other Travelers' Gates, but first, / King:go fix the problem with / the Gate of Anger quickly!! / King:You'..."
    db $ea, $2e, $46, $4b, $44, $a3, $f6, $63, $ef, $ee, $2c, $51, $50, $62, $4c, $48
    db $3e, $56, $62, $51, $4c, $62, $44, $4c, $62, $51, $4c, $fa, $f7, $ef, $ee, $4c
    db $51, $45, $42, $4f, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $ef
    db $ee, $2a, $3e, $51, $42, $50, $5e, $62, $3f, $52, $51, $62, $43, $46, $4f, $50
    db $51, $5e, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $44, $4c, $62, $43, $46
    db $55, $62, $51, $45, $42, $ef, $ee, $4d, $4f, $4c, $3f, $49, $42, $4a, $62, $54
    db $46, $51, $45, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $62
    db $4c, $43, $62, $24, $4b, $44, $42, $4f, $ef, $ee, $4e, $52, $46, $40, $48, $49
    db $56, $63, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c, $52, $69
    db $42, $ef, $ee, $42, $55, $40, $52, $50, $42, $41, $5f, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62, $25, $52, $50, $56, $63, $ef
    db $ee, $25, $52, $50, $56, $63, $5f, $5f, $5f, $62, $f7, $f0
TextStr_45_5750:           ; id $0276
    ; "[HERO] looked at the bookshelf. / :Seeking the one I saw in / a vision... ... ... ... ... / a touching story!"
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $36, $42, $42, $48, $46, $4b, $44, $62, $51, $45, $42, $ef, $ee, $4c, $4b, $42
    db $62, $2c, $62, $50, $3e, $54, $62, $46, $4b, $fa, $f7, $ef, $ee, $3e, $62, $53
    db $46, $50, $46, $4c, $4b, $5f, $5f, $5f, $ef, $ee, $5f, $5f, $5f, $62, $5f, $5f
    db $5f, $62, $5f, $5f, $5f, $62, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $3e, $62, $51
    db $4c, $52, $40, $45, $46, $4b, $44, $ef, $ee, $50, $51, $4c, $4f, $56, $63, $f7
    db $f0
TextStr_45_57c1:           ; id $0277
    ; "*:I heard you defeated Mick. / You're getting an ego aren't you? / *:You can't brag about beating / such a wimp!"
    db $eb, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $56, $4c, $52, $ef, $ee
    db $41, $42, $43, $42, $3e, $51, $42, $41, $62, $30, $46, $40, $48, $5f, $fa, $f7
    db $ef, $ee, $3c, $4c, $52, $69, $42, $62, $44, $42, $51, $51, $46, $4b, $44, $62
    db $3e, $4b, $ef, $ee, $42, $44, $4c, $62, $3e, $4f, $42, $4b, $67, $62, $56, $4c
    db $52, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $67
    db $62, $3f, $4f, $3e, $44, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $3f, $42, $3e
    db $51, $46, $4b, $44, $fa, $f7, $ef, $ee, $50, $52, $40, $45, $62, $3e, $62, $54
    db $46, $4a, $4d, $63, $ef, $ee, $f7, $f0
TextStr_45_5839:           ; id $0278
    ; "*:The Room of Strength & Anger / is in the middle. Hurry!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee
    db $36, $51, $4f, $42, $4b, $44, $51, $45, $62, $b6, $62, $24, $4b, $44, $42, $4f
    db $fa, $f7, $ef, $ee, $46, $50, $62, $46, $4b, $62, $51, $45, $42, $62, $4a, $46
    db $41, $41, $49, $42, $5f, $ef, $ee, $2b, $52, $4f, $4f, $56, $63, $f7, $f0
TextStr_45_5878:           ; id $0279
    ; "*:You're at the Chamber of / Traverlers' Gates! / *:The Room of Strength & Anger / is next!"
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $51, $62, $51, $45, $42, $ef
    db $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee, $37
    db $4f, $3e, $53, $42, $4f, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c
    db $4a, $62, $4c, $43, $ef, $ee, $36, $51, $4f, $42, $4b, $44, $51, $45, $62, $b6
    db $62, $24, $4b, $44, $42, $4f, $fa, $f7, $ef, $ee, $46, $50, $62, $4b, $42, $55
    db $51, $63, $ef, $ee, $f7, $f0
TextStr_45_58de:           ; id $027A
    ; "*:BattleRex uses EvilSlash. / *:It also uses MetalCut! / *:It often goes into a rage. I / wonder if it's enraged now?"
    db $eb, $9f, $a3, $25, $3e, $51, $51, $49, $42, $35, $42, $55, $62, $52, $50, $42
    db $50, $ef, $ee, $28, $53, $46, $49, $36, $49, $3e, $50, $45, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $51, $62, $3e, $49, $50, $4c, $62, $52, $50, $42, $50, $ef
    db $ee, $30, $42, $51, $3e, $49, $26, $52, $51, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $51, $62, $4c, $43, $51, $42, $4b, $62, $44, $4c, $42, $50, $ef, $ee, $46
    db $4b, $51, $4c, $62, $3e, $62, $4f, $3e, $44, $42, $5f, $62, $2c, $fa, $f7, $ef
    db $ee, $54, $4c, $4b, $41, $42, $4f, $62, $46, $43, $62, $46, $51, $68, $ef, $ee
    db $42, $4b, $4f, $3e, $44, $42, $41, $62, $4b, $4c, $54, $64, $f7, $f0
TextStr_45_595c:           ; id $027B
    ; "*:There's a strange stone / statue behind the Gate of Strength!"
    db $eb, $9f, $a3, $37, $45, $42, $4f, $42, $68, $62, $3e, $ef, $ee, $50, $51, $4f
    db $3e, $4b, $44, $42, $62, $50, $51, $4c, $4b, $42, $fa, $f7, $ef, $ee, $50, $51
    db $3e, $51, $52, $42, $62, $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $ef
    db $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $36, $51, $4f, $42, $4b, $44, $51
    db $45, $63, $f7, $f0
TextStr_45_59a0:           ; id $027C
    ; "*:Go to the Room of Strength & / Anger in the Chamber of / Travelers' Gates! / *:'Till then, you can't fight in the / arena! The King comman..."
    db $ea, $9f, $a3, $2a, $4c, $62, $51, $4c, $62, $51, $45, $42, $62, $35, $4c, $4c
    db $4a, $ef, $ee, $4c, $43, $62, $36, $51, $4f, $42, $4b, $44, $51, $45, $62, $b6
    db $fa, $f7, $ef, $ee, $24, $4b, $44, $42, $4f, $62, $46, $4b, $62, $51, $45, $42
    db $ef, $ee, $26, $45, $3e, $4a, $3f, $42, $4f, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $71, $46, $49, $49, $62, $51, $45
    db $42, $4b, $5e, $62, $56, $4c, $52, $ef, $ee, $40, $3e, $4b, $67, $62, $43, $46
    db $44, $45, $51, $62, $46, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $3e, $4f
    db $42, $4b, $3e, $63, $62, $37, $45, $42, $62, $2e, $46, $4b, $44, $ef, $ee, $40
    db $4c, $4a, $4a, $3e, $4b, $41, $42, $41, $62, $56, $4c, $52, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $4c, $52, $4f, $ef, $ee
    db $4c, $4b, $49, $56, $62, $45, $4c, $4d, $42, $63, $62, $27, $4c, $4b, $67, $fa
    db $f7, $ef, $ee, $41, $46, $50, $3e, $4d, $4d, $4c, $46, $4b, $51, $62, $52, $50
    db $5f, $ef, $ee, $f7, $f0
TextStr_45_5a75:           ; id $027D
    ; "*:Until you settle the disaster / behind the Gate of Anger, / *:I won't allow you to compete / at the arena!"
    db $eb, $9f, $a3, $38, $4b, $51, $46, $49, $62, $56, $4c, $52, $62, $50, $42, $51
    db $51, $49, $42, $ef, $ee, $51, $45, $42, $62, $41, $46, $50, $3e, $50, $51, $42
    db $4f, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $ef
    db $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $24, $4b, $44, $42, $4f, $5e, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b, $67, $62, $3e, $49, $49, $4c
    db $54, $ef, $ee, $56, $4c, $52, $62, $51, $4c, $62, $40, $4c, $4a, $4d, $42, $51
    db $42, $fa, $f7, $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $3e, $4f, $42, $4b
    db $3e, $63, $ef, $ee, $f7, $f0
TextStr_45_5aeb:           ; id $027E
    ; "*:I guess staying on the farm means / no special skills are learned... / *:[HERO]! I heard you survived D / class! / *:I guess I have to try..."
    db $ea, $9f, $a3, $2c, $62, $44, $52, $42, $50, $50, $62, $50, $51, $3e, $56, $46
    db $4b, $44, $ef, $ee, $4c, $4b, $62, $51, $45, $42, $62, $43, $3e, $4f, $4a, $62
    db $4a, $42, $3e, $4b, $50, $fa, $f7, $ef, $ee, $4b, $4c, $62, $50, $4d, $42, $40
    db $46, $3e, $49, $62, $50, $48, $46, $49, $49, $50, $ef, $ee, $3e, $4f, $42, $62
    db $49, $42, $3e, $4f, $4b, $42, $41, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $f6, $63, $62, $2c, $62, $45, $42, $3e, $4f, $41, $ef, $ee, $56, $4c, $52, $62
    db $50, $52, $4f, $53, $46, $53, $42, $41, $62, $27, $fa, $f7, $ef, $ee, $40, $49
    db $3e, $50, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $44, $52
    db $42, $50, $50, $62, $2c, $62, $45, $3e, $53, $42, $ef, $ee, $51, $4c, $62, $51
    db $4f, $56, $62, $45, $3e, $4f, $41, $42, $4f, $63, $f7, $f0
TextStr_45_5b87:           ; id $027F
    ; "*:…I heard it's a kingdom of Devils / out there. / *:And the guardian used to be a / human! / *:Want to hear about the Gate / of Sleeping? [..."
    db $ea, $9f, $a3, $a4, $2c, $62, $45, $42, $3e, $4f, $41, $62, $46, $51, $68, $62
    db $3e, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $62, $4c, $43, $62, $27, $42
    db $53, $46, $49, $50, $fa, $f7, $ef, $ee, $4c, $52, $51, $62, $51, $45, $42, $4f
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $41, $62, $51, $45
    db $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $52, $50, $42, $41
    db $62, $51, $4c, $62, $3f, $42, $62, $3e, $fa, $f7, $ef, $ee, $45, $52, $4a, $3e
    db $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $4b, $51, $62, $51
    db $4c, $62, $45, $42, $3e, $4f, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $36, $49, $42
    db $42, $4d, $46, $4b, $44, $64, $ef, $ee, $ff, $f0
TextStr_45_5c21:           ; id $0280
    ; "*:MadGopher go mad go far! Funny?"
    db $ea, $9f, $a3, $30, $3e, $41, $2a, $4c, $4d, $45, $42, $4f, $62, $44, $4c, $62
    db $4a, $3e, $41, $ef, $ee, $44, $4c, $62, $43, $3e, $4f, $63, $62, $29, $52, $4b
    db $4b, $56, $64, $f7, $f0
TextStr_45_5c46:           ; id $0281
    ; "*:You beat Mick? You're one tough / cookie aren't you? / *:But if you get an ego you'll / suffer the same fate as Mick. / *:Why don't you vi..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3f, $42, $3e, $51, $62, $30, $46, $40, $48
    db $64, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $4c, $4b, $42, $62, $51, $4c, $52
    db $44, $45, $fa, $f7, $ef, $ee, $40, $4c, $4c, $48, $46, $42, $62, $3e, $4f, $42
    db $4b, $67, $62, $56, $4c, $52, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25
    db $52, $51, $62, $46, $43, $62, $56, $4c, $52, $62, $44, $42, $51, $ef, $ee, $3e
    db $4b, $62, $42, $44, $4c, $62, $56, $4c, $52, $66, $49, $fa, $f7, $ef, $ee, $50
    db $52, $43, $43, $42, $4f, $62, $51, $45, $42, $62, $50, $3e, $4a, $42, $ef, $ee
    db $43, $3e, $51, $42, $62, $3e, $50, $62, $30, $46, $40, $48, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $3a, $45, $56, $62, $41, $4c, $4b, $67, $62, $56, $4c, $52, $ef
    db $ee, $53, $46, $50, $46, $51, $62, $45, $46, $4a, $62, $51, $4c, $62, $50, $42
    db $42, $fa, $f7, $ef, $ee, $45, $4c, $54, $62, $45, $42, $68, $62, $41, $4c, $46
    db $4b, $44, $64, $ef, $ee, $f7, $f0
TextStr_45_5cfd:           ; id $0282
    ; "*:Yo, dude! You're not allowed to / fight huh?"
    db $ea, $9f, $a3, $3c, $4c, $5e, $62, $41, $52, $41, $42, $63, $62, $3c, $4c, $52
    db $69, $42, $ef, $ee, $4b, $4c, $51, $62, $3e, $49, $49, $4c, $54, $42, $41, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51, $62, $45, $52, $45, $64
    db $ef, $ee, $f7, $f0
TextStr_45_5d31:           ; id $0283
    ; "*:…I heard it is overrun with / Zombies there! / *:The guardian there has been / sleeping for ages."
    db $ea, $9f, $a3, $a4, $2c, $62, $45, $42, $3e, $4f, $41, $62, $46, $51, $62, $46
    db $50, $ef, $ee, $4c, $53, $42, $4f, $4f, $52, $4b, $62, $54, $46, $51, $45, $fa
    db $f7, $ef, $ee, $3d, $4c, $4a, $3f, $46, $42, $50, $62, $51, $45, $42, $4f, $42
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e
    db $4f, $41, $46, $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $45, $3e, $50
    db $62, $3f, $42, $42, $4b, $fa, $f7, $ef, $ee, $50, $49, $42, $42, $4d, $46, $4b
    db $44, $62, $43, $4c, $4f, $62, $3e, $44, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_45_5da0:           ; id $0284
    ; "*:So you defeated Mick. / *:But remember. There's always / somebody better than you. / *:You won't be able to win with / monsters you catch...."
    db $ea, $9f, $a3, $36, $4c, $62, $56, $4c, $52, $62, $41, $42, $43, $42, $3e, $51
    db $42, $41, $ef, $ee, $30, $46, $40, $48, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25
    db $52, $51, $62, $4f, $42, $4a, $42, $4a, $3f, $42, $4f, $5f, $ef, $ee, $37, $45
    db $42, $4f, $42, $68, $62, $3e, $49, $54, $3e, $56, $50, $fa, $f7, $ef, $ee, $50
    db $4c, $4a, $42, $3f, $4c, $41, $56, $62, $3f, $42, $51, $51, $42, $4f, $ef, $ee
    db $51, $45, $3e, $4b, $62, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c
    db $4c, $52, $62, $54, $4c, $4b, $67, $62, $3f, $42, $ef, $ee, $3e, $3f, $49, $42
    db $62, $51, $4c, $62, $54, $46, $4b, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $56, $4c, $52, $ef, $ee, $40, $3e
    db $51, $40, $45, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $66, $49, $62
    db $45, $3e, $53, $42, $62, $51, $4c, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $4c, $fa, $f7, $ef, $ee, $44, $42
    db $51, $62, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $5f, $f7, $f0
TextStr_45_5e77:           ; id $0285
    ; "*:[HERO], as you see, the / experiment failed miserably!! / *:The big kettle was blown into / bits. / *:Sorry, but I need to ask you / to gi..."
    db $ea, $9f, $a3, $f6, $5e, $62, $3e, $50, $62, $56, $4c, $52, $ef, $ee, $50, $42
    db $42, $5e, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $42, $55, $4d, $42, $4f, $46
    db $4a, $42, $4b, $51, $62, $43, $3e, $46, $49, $42, $41, $ef, $ee, $4a, $46, $50
    db $42, $4f, $3e, $3f, $49, $56, $63, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45
    db $42, $62, $3f, $46, $44, $62, $48, $42, $51, $51, $49, $42, $ef, $ee, $54, $3e
    db $50, $62, $3f, $49, $4c, $54, $4b, $62, $46, $4b, $51, $4c, $fa, $f7, $ef, $ee
    db $3f, $46, $51, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $4f
    db $4f, $56, $5e, $62, $3f, $52, $51, $62, $2c, $ef, $ee, $4b, $42, $42, $41, $62
    db $51, $4c, $62, $3e, $50, $48, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $51, $4c
    db $62, $44, $46, $53, $42, $62, $52, $4d, $ef, $ee, $4a, $56, $62, $3e, $50, $50
    db $46, $50, $51, $3e, $4b, $51, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $4b, $50
    db $51, $42, $3e, $41, $5e, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42
    db $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $fa, $f7, $ef, $ee, $41, $4c
    db $54, $4b, $62, $51, $45, $42, $4f, $42, $62, $46, $50, $ef, $ee, $4b, $4c, $54
    db $62, $56, $4c, $52, $4f, $50, $63, $f7, $f0
TextStr_45_5f60:           ; id $0286
    ; "*:I failed. Sorry, but you / have to give up my assistant. / *:Instead, the Travelers' Gate / down there is now yours!"
    db $ea, $9f, $a3, $2c, $62, $43, $3e, $46, $49, $42, $41, $5f, $ef, $ee, $36, $4c
    db $4f, $4f, $56, $5e, $62, $3f, $52, $51, $62, $56, $4c, $52, $fa, $f7, $ef, $ee
    db $45, $3e, $53, $42, $62, $51, $4c, $62, $44, $46, $53, $42, $62, $52, $4d, $ef
    db $ee, $4a, $56, $62, $3e, $50, $50, $46, $50, $51, $3e, $4b, $51, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $4b, $50, $51, $42, $3e, $41, $5e, $62, $51, $45, $42
    db $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51
    db $42, $fa, $f7, $ef, $ee, $41, $4c, $54, $4b, $62, $51, $45, $42, $4f, $42, $62
    db $46, $50, $ef, $ee, $4b, $4c, $54, $62, $56, $4c, $52, $4f, $50, $63, $f7, $f0
TextStr_45_5fe0:           ; id $0287
    ; "*:He paid for it! He shouldn't have / offered me as a gift for a favor! / *:Well, maybe I put in too much / gunpowder... Hee hee hee..."
    db $eb, $9f, $a3, $2b, $42, $62, $4d, $3e, $46, $41, $62, $43, $4c, $4f, $62, $46
    db $51, $63, $ef, $ee, $2b, $42, $62, $50, $45, $4c, $52, $49, $41, $4b, $67, $62
    db $45, $3e, $53, $42, $fa, $f7, $ef, $ee, $4c, $43, $43, $42, $4f, $42, $41, $62
    db $4a, $42, $62, $3e, $50, $62, $3e, $ef, $ee, $44, $46, $43, $51, $62, $43, $4c
    db $4f, $62, $3e, $62, $43, $3e, $53, $4c, $4f, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $42, $49, $49, $5e, $62, $4a, $3e, $56, $3f, $42, $62, $2c, $ef, $ee, $4d
    db $52, $51, $62, $46, $4b, $62, $51, $4c, $4c, $62, $4a, $52, $40, $45, $fa, $f7
    db $ef, $ee, $44, $52, $4b, $4d, $4c, $54, $41, $42, $4f, $5f, $5f, $5f, $ef, $ee
    db $2b, $42, $42, $62, $45, $42, $42, $62, $45, $42, $42, $5f, $5f, $5f, $f7, $f0
TextStr_45_6070:           ; id $0288
    ; "*:Welcome to the Master School. / *:Today's lecture is about how to / change the gender of a monster. / *:Want to listen? [YES/NO]"
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $36, $40, $45, $4c, $4c, $49
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c, $41, $3e, $56, $68, $62, $49, $42
    db $40, $51, $52, $4f, $42, $ef, $ee, $46, $50, $62, $3e, $3f, $4c, $52, $51, $62
    db $45, $4c, $54, $62, $51, $4c, $fa, $f7, $ef, $ee, $40, $45, $3e, $4b, $44, $42
    db $62, $51, $45, $42, $62, $44, $42, $4b, $41, $42, $4f, $ef, $ee, $4c, $43, $62
    db $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $46, $50, $51, $42, $4b, $64, $ef
    db $ee, $ff, $f0
TextStr_45_60f3:           ; id $0289
    ; "*:…I heard there are monsters in / the Bird family crowded in there. / *:A great evil lord seems to / be the guardian there."
    db $ea, $9f, $a3, $a4, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45, $42, $4f
    db $42, $ef, $ee, $3e, $4f, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62
    db $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $25, $46, $4f, $41, $62, $43
    db $3e, $4a, $46, $49, $56, $ef, $ee, $40, $4f, $4c, $54, $41, $42, $41, $62, $46
    db $4b, $62, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62
    db $44, $4f, $42, $3e, $51, $62, $42, $53, $46, $49, $ef, $ee, $49, $4c, $4f, $41
    db $62, $50, $42, $42, $4a, $50, $62, $51, $4c, $fa, $f7, $ef, $ee, $3f, $42, $62
    db $51, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $51, $45
    db $42, $4f, $42, $5f, $f7, $f0
TextStr_45_6179:           ; id $028A
    ; "[SOUND 60][HERO] looked into the dresser. / But nothing's there."
    db $e9, $60, $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef
    db $ee, $51, $45, $42, $62, $41, $4f, $42, $50, $50, $42, $4f, $5f, $fa, $f7, $ef
    db $ee, $25, $52, $51, $62, $4b, $4c, $51, $45, $46, $4b, $44, $68, $ef, $ee, $51
    db $45, $42, $4f, $42, $5f, $f7, $f0
TextStr_45_61b0:           ; id $028B
    ; "*:How did you beat Mick! I'm glad / you breed with my monster! / *:You know what? Some spells work / on some monsters and others don't. / *:..."
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $41, $46, $41, $62, $56, $4c, $52, $62, $3f
    db $42, $3e, $51, $ef, $ee, $30, $46, $40, $48, $63, $62, $2c, $6a, $62, $44, $49
    db $3e, $41, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3f, $4f, $42, $42, $41, $62
    db $54, $46, $51, $45, $ef, $ee, $4a, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $48, $4b, $4c, $54, $62
    db $54, $45, $3e, $51, $64, $ef, $ee, $36, $4c, $4a, $42, $62, $50, $4d, $42, $49
    db $49, $50, $62, $54, $4c, $4f, $48, $fa, $f7, $ef, $ee, $4c, $4b, $62, $50, $4c
    db $4a, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef, $ee, $3e, $4b, $41
    db $62, $4c, $51, $45, $42, $4f, $50, $62, $41, $4c, $4b, $67, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $29, $4c, $4f, $62, $42, $55, $3e, $4a, $4d, $49, $42, $5e, $ef
    db $ee, $3d, $4c, $4a, $3f, $46, $42, $50, $62, $3e, $4f, $42, $fa, $f7, $ef, $ee
    db $54, $42, $3e, $48, $62, $3e, $44, $3e, $46, $4b, $50, $51, $ef, $ee, $43, $46
    db $4f, $42, $62, $50, $4d, $42, $49, $49, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $33, $49, $3e, $4b, $51, $50, $62, $3e, $4f, $42, $ef, $ee, $50, $51, $4f, $4c
    db $4b, $44, $62, $3e, $44, $3e, $46, $4b, $50, $51, $fa, $f7, $ef, $ee, $4d, $4c
    db $46, $50, $4c, $4b, $50, $62, $3e, $4b, $41, $ef, $ee, $4d, $3e, $4f, $3e, $49
    db $56, $50, $46, $50, $5f, $5f, $5f, $f7, $f0
TextStr_45_62b9:           ; id $028C
    ; "*:The names of the monsters available / only through breeding are: / *:HerbMan, WhiteKing, / RainHawk, Rosevine, / *:KingLeo, Armorpion, / C..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $4b, $3e, $4a, $42, $50, $62, $4c, $43, $62
    db $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $53
    db $3e, $46, $49, $3e, $3f, $49, $42, $fa, $f7, $ef, $ee, $4c, $4b, $49, $56, $62
    db $51, $45, $4f, $4c, $52, $44, $45, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b
    db $44, $62, $3e, $4f, $42, $a3, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $4f, $3f
    db $30, $3e, $4b, $5e, $ef, $ee, $3a, $45, $46, $51, $42, $2e, $46, $4b, $44, $5e
    db $fa, $f7, $ef, $ee, $35, $3e, $46, $4b, $2b, $3e, $54, $48, $5e, $ef, $ee, $35
    db $4c, $50, $42, $53, $46, $4b, $42, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $2e, $46
    db $4b, $44, $2f, $42, $4c, $5e, $ef, $ee, $24, $4f, $4a, $4c, $4f, $4d, $46, $4c
    db $4b, $5e, $fa, $f7, $ef, $ee, $26, $4c, $3e, $51, $4c, $49, $5e, $ef, $ee, $2a
    db $4c, $49, $41, $36, $49, $46, $4a, $42, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c
    db $49, $41, $2a, $4c, $49, $42, $4a, $62, $3e, $4b, $41, $ef, $ee, $27, $46, $53
    db $46, $4b, $42, $44, $4c, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c, $54
    db $62, $4a, $3e, $4b, $56, $62, $4c, $43, $62, $51, $45, $42, $4a, $ef, $ee, $40
    db $3e, $4b, $62, $56, $4c, $52, $62, $44, $42, $51, $64, $f7, $f0
TextStr_45_63a6:           ; id $028D
    ; "*:Hmm. Indeed. The victor, [HERO] / won't need them."
    db $ea, $9f, $a3, $2b, $4a, $4a, $5f, $62, $2c, $4b, $41, $42, $42, $41, $5f, $ef
    db $ee, $37, $45, $42, $62, $53, $46, $40, $51, $4c, $4f, $5e, $62, $f6, $fa, $f7
    db $ef, $ee, $54, $4c, $4b, $67, $62, $4b, $42, $42, $41, $62, $51, $45, $42, $4a
    db $5f, $ef, $ee, $f7, $f0
TextStr_45_63db:           ; id $028E
    ; "*:Congratulations on your victory! / Our admirable [HERO]! / *:I took notes on how to inherit / the skills. Want to see? [YES/NO]"
    db $eb, $9f, $a3, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c
    db $4b, $50, $ef, $ee, $4c, $4b, $62, $56, $4c, $52, $4f, $62, $53, $46, $40, $51
    db $4c, $4f, $56, $63, $fa, $f7, $ef, $ee, $32, $52, $4f, $62, $3e, $41, $4a, $46
    db $4f, $3e, $3f, $49, $42, $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $62, $51, $4c, $4c, $48, $62, $4b, $4c, $51, $42, $50, $62, $4c, $4b, $ef, $ee
    db $45, $4c, $54, $62, $51, $4c, $62, $46, $4b, $45, $42, $4f, $46, $51, $fa, $f7
    db $ef, $ee, $51, $45, $42, $62, $50, $48, $46, $49, $49, $50, $5f, $62, $3a, $3e
    db $4b, $51, $ef, $ee, $51, $4c, $62, $50, $42, $42, $64, $ff, $f0
TextStr_45_6458:           ; id $028F
    ; "Mick:I should simply accept my / defeat... / Mick:As a token of our friendship, / let's breed our monsters. / Mick:You can breed with my Dea..."
    db $ea, $30, $46, $40, $48, $a3, $2c, $62, $50, $45, $4c, $52, $49, $41, $ef, $ee
    db $50, $46, $4a, $4d, $49, $56, $62, $3e, $40, $40, $42, $4d, $51, $62, $4a, $56
    db $fa, $f7, $ef, $ee, $41, $42, $43, $42, $3e, $51, $5f, $5f, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $30, $46, $40, $48, $a3, $24, $50, $62, $3e, $62, $51, $4c, $48
    db $42, $4b, $ef, $ee, $4c, $43, $62, $4c, $52, $4f, $62, $43, $4f, $46, $42, $4b
    db $41, $50, $45, $46, $4d, $5e, $fa, $f7, $ef, $ee, $49, $42, $51, $68, $62, $3f
    db $4f, $42, $42, $41, $62, $4c, $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5f, $fa, $f7, $ef, $ee, $30, $46, $40, $48, $a3, $3c, $4c, $52, $62
    db $40, $3e, $4b, $62, $3f, $4f, $42, $42, $41, $ef, $ee, $54, $46, $51, $45, $62
    db $4a, $56, $62, $27, $42, $3e, $41, $31, $46, $51, $42, $63, $f0
TextStr_45_64f5:           ; id $0290
    ; "*:Ha ha ha! You beat me!"
    db $ea, $9f, $a3, $2b, $3e, $62, $45, $3e, $62, $45, $3e, $63, $ef, $ee, $3c, $4c
    db $52, $62, $3f, $42, $3e, $51, $62, $4a, $42, $63, $f7, $f0
TextStr_45_6511:           ; id $0291
    ; "*:Squeaking squeaking."
    db $ea, $9f, $a3, $36, $4e, $52, $42, $3e, $48, $46, $4b, $44, $ef, $ee, $50, $4e
    db $52, $42, $3e, $48, $46, $4b, $44, $5f, $f7, $f0
TextStr_45_652b:           ; id $0292
    ; "*:… …"
    db $ea, $9f, $a3, $a4, $62, $a4, $ef, $ee, $f7, $f0
TextStr_45_6535:           ; id $0293
    ; "Watabou:You did a good job solving / the Forest Maze. / Watabou: Sometimes taking / the longest path is the shortest / path."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3c, $4c, $52, $62, $41, $46, $41
    db $ef, $ee, $3e, $62, $44, $4c, $4c, $41, $62, $47, $4c, $3f, $62, $50, $4c, $49
    db $53, $46, $4b, $44, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $29, $4c, $4f, $42
    db $50, $51, $62, $30, $3e, $57, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e
    db $51, $3e, $3f, $4c, $52, $a3, $ef, $ee, $36, $4c, $4a, $42, $51, $46, $4a, $42
    db $50, $62, $51, $3e, $48, $46, $4b, $44, $fa, $f7, $ef, $ee, $51, $45, $42, $62
    db $49, $4c, $4b, $44, $42, $50, $51, $62, $4d, $3e, $51, $45, $ef, $ee, $46, $50
    db $62, $51, $45, $42, $62, $50, $45, $4c, $4f, $51, $42, $50, $51, $fa, $f7, $ef
    db $ee, $4d, $3e, $51, $45, $5f, $ef, $ee, $f7, $f0
TextStr_45_65bf:           ; id $0294
    ; "*:Wel...come..."
    db $ea, $9f, $a3, $3a, $42, $49, $5f, $5f, $5f, $40, $4c, $4a, $42, $5f, $5f, $5f
    db $ef, $ee, $f7, $f0
TextStr_45_65d3:           ; id $0295
    ; "*:Come.....again.."
    db $ea, $9f, $a3, $26, $4c, $4a, $42, $5f, $5f, $5f, $5f, $5f, $3e, $44, $3e, $46
    db $4b, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_45_65ea:           ; id $0296
    ; "*:… … …"
    db $ea, $9f, $a3, $a4, $62, $a4, $62, $a4, $ef, $ee, $f7, $f0
TextStr_45_65f6:           ; id $0297
    ; "*:… … …"
    db $ea, $9f, $a3, $a4, $62, $a4, $62, $a4, $ef, $ee, $f7, $f0
TextStr_45_6602:           ; id $0298
    ; "Watabou:This place was ruined / by monsters a long time ago... / Watabou:so long ago... / Watabou:Well, let's go."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $37, $45, $46, $50, $ef, $ee, $4d
    db $49, $3e, $40, $42, $62, $54, $3e, $50, $62, $4f, $52, $46, $4b, $42, $41, $fa
    db $f7, $ef, $ee, $3f, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e
    db $62, $49, $4c, $4b, $44, $ef, $ee, $51, $46, $4a, $42, $62, $3e, $44, $4c, $5f
    db $5f, $5f, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $50, $4c
    db $ef, $ee, $49, $4c, $4b, $44, $62, $3e, $44, $4c, $5f, $5f, $5f, $fa, $f7, $ef
    db $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3a, $42, $49, $49, $5e, $ef, $ee
    db $49, $42, $51, $68, $62, $44, $4c, $5f, $f7, $f0
TextStr_45_667c:           ; id $0299
    ; "[HERO] pulled the slot machine! / The symbols are spinning around. / Ka-ching Ka-ching Ka-ching! / 3 Slime icons in a row. / Jingle! / [HERO..."
    db $f6, $62, $4d, $52, $49, $49, $42, $41, $62, $51, $45, $42, $ef, $ee, $50, $49
    db $4c, $51, $62, $4a, $3e, $40, $45, $46, $4b, $42, $63, $fa, $f7, $ef, $ee, $37
    db $45, $42, $62, $50, $56, $4a, $3f, $4c, $49, $50, $62, $3e, $4f, $42, $ef, $ee
    db $50, $4d, $46, $4b, $4b, $46, $4b, $44, $62, $3e, $4f, $4c, $52, $4b, $41, $5f
    db $fa, $f7, $ef, $ee, $2e, $3e, $9c, $40, $45, $46, $4b, $44, $62, $2e, $3e, $9c
    db $40, $45, $46, $4b, $44, $ef, $ee, $2e, $3e, $9c, $40, $45, $46, $4b, $44, $63
    db $fa, $f7, $ef, $ee, $03, $62, $36, $49, $46, $4a, $42, $62, $46, $40, $4c, $4b
    db $50, $ef, $ee, $46, $4b, $62, $3e, $62, $4f, $4c, $54, $5f, $fa, $f7, $ef, $ee
    db $2d, $46, $4b, $44, $49, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $f6, $62, $44
    db $4c, $51, $62, $05, $00, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $2a
    db $4c, $49, $41, $63, $f7, $f0
TextStr_45_6722:           ; id $029A
    ; "Mick:As proof of my friendship / let's breed our monsters. / Mick:Will you match with my / DeadNite?"
    db $ea, $30, $46, $40, $48, $a3, $24, $50, $62, $4d, $4f, $4c, $4c, $43, $ef, $ee
    db $4c, $43, $62, $4a, $56, $62, $43, $4f, $46, $42, $4b, $41, $50, $45, $46, $4d
    db $fa, $f7, $ef, $ee, $49, $42, $51, $68, $62, $3f, $4f, $42, $42, $41, $62, $4c
    db $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef
    db $ee, $30, $46, $40, $48, $a3, $3a, $46, $49, $49, $62, $56, $4c, $52, $ef, $ee
    db $4a, $3e, $51, $40, $45, $62, $54, $46, $51, $45, $62, $4a, $56, $fa, $f7, $ef
    db $ee, $27, $42, $3e, $41, $31, $46, $51, $42, $64, $ef, $ee, $f0
TextStr_45_678f:           ; id $029B
    ; "Mick:I'm going on a journey now. / Mick:[HERO], best of luck! / I hope you'll be able to enter / the Tournament!"
    db $ea, $30, $46, $40, $48, $a3, $2c, $6a, $62, $44, $4c, $46, $4b, $44, $ef, $ee
    db $4c, $4b, $62, $3e, $62, $47, $4c, $52, $4f, $4b, $42, $56, $62, $4b, $4c, $54
    db $5f, $fa, $f7, $ef, $ee, $30, $46, $40, $48, $a3, $f6, $5e, $ef, $ee, $3f, $42
    db $50, $51, $62, $4c, $43, $62, $49, $52, $40, $48, $63, $fa, $f7, $ef, $ee, $2c
    db $62, $45, $4c, $4d, $42, $62, $56, $4c, $52, $66, $49, $62, $3f, $42, $ef, $ee
    db $3e, $3f, $49, $42, $62, $51, $4c, $62, $42, $4b, $51, $42, $4f, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63
    db $ef, $ee, $f7, $f0
TextStr_45_6803:           ; id $029C
    ; "*:[HERO], here is the Room of / Strength & Anger. / *:The Gate of Anger on the / right seems strange!!"
    db $ea, $9f, $a3, $f6, $5e, $62, $45, $42, $4f, $42, $62, $46, $50, $ef, $ee, $51
    db $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $fa, $f7, $ef, $ee, $36, $51
    db $4f, $42, $4b, $44, $51, $45, $62, $b6, $62, $24, $4b, $44, $42, $4f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2a, $3e, $51, $42, $62
    db $4c, $43, $ef, $ee, $24, $4b, $44, $42, $4f, $62, $4c, $4b, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $4f, $46, $44, $45, $51, $62, $50, $42, $42, $4a, $50, $ef
    db $ee, $50, $51, $4f, $3e, $4b, $44, $42, $63, $63, $f7, $f0
TextStr_45_686f:           ; id $029D
    ; "*:Monsters are flooding out from / the Gate of Anger! / *:We have to do something or our / world will be in trouble! / *:[HERO]! Help us!"
    db $ea, $9f, $a3, $30, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $4f, $42, $ef
    db $ee, $43, $49, $4c, $4c, $41, $46, $4b, $44, $62, $4c, $52, $51, $62, $43, $4f
    db $4c, $4a, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $62, $4c
    db $43, $ef, $ee, $24, $4b, $44, $42, $4f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $42, $62, $45, $3e, $53, $42, $62, $51, $4c, $62, $41, $4c, $ef, $ee, $50, $4c
    db $4a, $42, $51, $45, $46, $4b, $44, $62, $4c, $4f, $62, $4c, $52, $4f, $fa, $f7
    db $ef, $ee, $54, $4c, $4f, $49, $41, $62, $54, $46, $49, $49, $62, $3f, $42, $62
    db $46, $4b, $ef, $ee, $51, $4f, $4c, $52, $3f, $49, $42, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $f6, $63, $ef, $ee, $2b, $42, $49, $4d, $62, $52, $50, $63, $f7, $f0
TextStr_45_68ff:           ; id $029E
    ; "*:It's my wish that... / *:my family in this world / prospers. Who are you? / *:Leave before you feel my wrath!"
    db $ea, $9f, $a3, $2c, $51, $68, $62, $4a, $56, $62, $54, $46, $50, $45, $ef, $ee
    db $51, $45, $3e, $51, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $4a, $56, $62
    db $43, $3e, $4a, $46, $49, $56, $62, $46, $4b, $ef, $ee, $51, $45, $46, $50, $62
    db $54, $4c, $4f, $49, $41, $fa, $f7, $ef, $ee, $4d, $4f, $4c, $50, $4d, $42, $4f
    db $50, $5f, $ef, $ee, $3a, $45, $4c, $62, $3e, $4f, $42, $62, $56, $4c, $52, $64
    db $fa, $f7, $ef, $ee, $9f, $a3, $2f, $42, $3e, $53, $42, $62, $3f, $42, $43, $4c
    db $4f, $42, $ef, $ee, $56, $4c, $52, $62, $43, $42, $42, $49, $62, $4a, $56, $62
    db $54, $4f, $3e, $51, $45, $63, $f7, $f0
TextStr_45_6977:           ; id $029F
    ; "*:That my family in this world / prospers... / *:That's my wish. You! What are you / doing with my eggs! / *:Get out before you feel my wrat..."
    db $ea, $9f, $a3, $37, $45, $3e, $51, $62, $4a, $56, $62, $43, $3e, $4a, $46, $49
    db $56, $ef, $ee, $46, $4b, $62, $51, $45, $46, $50, $62, $54, $4c, $4f, $49, $41
    db $fa, $f7, $ef, $ee, $4d, $4f, $4c, $50, $4d, $42, $4f, $50, $5f, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $3e, $51, $68, $62, $4a, $56, $62
    db $54, $46, $50, $45, $5f, $ef, $ee, $3c, $4c, $52, $63, $62, $3a, $45, $3e, $51
    db $62, $3e, $4f, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $41, $4c, $46, $4b
    db $44, $62, $54, $46, $51, $45, $62, $4a, $56, $ef, $ee, $42, $44, $44, $50, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $2a, $42, $51, $62, $4c, $52, $51, $62, $3f, $42
    db $43, $4c, $4f, $42, $ef, $ee, $56, $4c, $52, $62, $43, $42, $42, $49, $62, $4a
    db $56, $62, $54, $4f, $3e, $51, $45, $63, $f7, $f0
TextStr_45_6a11:           ; id $02A0
    ; "*:Shoot! Not here either!"
    db $ea, $9f, $a3, $36, $45, $4c, $4c, $51, $63, $62, $31, $4c, $51, $ef, $ee, $45
    db $42, $4f, $42, $62, $42, $46, $51, $45, $42, $4f, $63, $f7, $f0
TextStr_45_6a2e:           ; id $02A1
    ; "*:Who are you? You're a monster / master aren't you! / *:Ha! Coward! You can't even use / your own sword!"
    db $ea, $9f, $a3, $3a, $45, $4c, $62, $3e, $4f, $42, $62, $56, $4c, $52, $64, $ef
    db $ee, $3c, $4c, $52, $69, $42, $62, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $3e, $4f, $42, $4b, $67
    db $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $3e, $63
    db $62, $26, $4c, $54, $3e, $4f, $41, $63, $ef, $ee, $3c, $4c, $52, $62, $40, $3e
    db $4b, $67, $62, $42, $53, $42, $4b, $62, $52, $50, $42, $fa, $f7, $ef, $ee, $56
    db $4c, $52, $4f, $62, $4c, $54, $4b, $62, $50, $54, $4c, $4f, $41, $63, $ef, $ee
    db $f7, $f0
TextStr_45_6aa0:           ; id $02A2
    ; "[HERO] looked at the egg. / A monster hatched from it!"
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $42, $44, $44, $5f, $fa, $f7, $ef, $ee, $24, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $ef, $ee, $45, $3e, $51, $40, $45, $42, $41, $62, $43, $4f, $4c, $4a
    db $62, $46, $51, $63, $f7, $f0
TextStr_45_6ad6:           ; id $02A3
    ; "[HERO] looked at the egg. / The egg is cracked."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $42, $44, $44, $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $62, $42, $44, $44
    db $62, $46, $50, $ef, $ee, $40, $4f, $3e, $40, $48, $42, $41, $5f, $f7, $f0
TextStr_45_6b05:           ; id $02A4
    ; "*:Arrrgh! How dare you crack all my / eggs! / *:There's no excuse for what / your kind has done!"
    db $ea, $9f, $a3, $24, $4f, $4f, $4f, $44, $45, $63, $62, $2b, $4c, $54, $62, $41
    db $3e, $4f, $42, $ef, $ee, $56, $4c, $52, $62, $40, $4f, $3e, $40, $48, $62, $3e
    db $49, $49, $62, $4a, $56, $fa, $f7, $ef, $ee, $42, $44, $44, $50, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f, $42, $68, $62, $4b, $4c, $ef
    db $ee, $42, $55, $40, $52, $50, $42, $62, $43, $4c, $4f, $62, $54, $45, $3e, $51
    db $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $48, $46, $4b, $41, $62, $45, $3e
    db $50, $ef, $ee, $41, $4c, $4b, $42, $63, $f7, $f0
TextStr_45_6b6f:           ; id $02A5
    ; "*:It's you again! You'll pay for / what you've done!"
    db $ea, $9f, $a3, $2c, $51, $68, $62, $56, $4c, $52, $62, $3e, $44, $3e, $46, $4b
    db $63, $ef, $ee, $3c, $4c, $52, $66, $49, $62, $4d, $3e, $56, $62, $43, $4c, $4f
    db $fa, $f7, $ef, $ee, $54, $45, $3e, $51, $62, $56, $4c, $52, $6c, $42, $62, $41
    db $4c, $4b, $42, $63, $ef, $ee, $f7, $f0
TextStr_45_6ba7:           ; id $02A6
    ; "*:That sword man looked like you..."
    db $ea, $9f, $a3, $37, $45, $3e, $51, $62, $50, $54, $4c, $4f, $41, $62, $4a, $3e
    db $4b, $ef, $ee, $49, $4c, $4c, $48, $42, $41, $62, $49, $46, $48, $42, $62, $56
    db $4c, $52, $5f, $5f, $5f, $f7, $f0
TextStr_45_6bce:           ; id $02A7
    ; "Watabou:Those eggs were the / reason there were so many monsters! / Watabou:You've completed the / king's quest! / Watabou:Come on! Let's go..."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $37, $45, $4c, $50, $42, $ef, $ee
    db $42, $44, $44, $50, $62, $54, $42, $4f, $42, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $4f, $42, $3e, $50, $4c, $4b, $62, $51, $45, $42, $4f, $42, $62, $54, $42
    db $4f, $42, $ef, $ee, $50, $4c, $62, $4a, $3e, $4b, $56, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $63, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52
    db $a3, $3c, $4c, $52, $6c, $42, $ef, $ee, $40, $4c, $4a, $4d, $49, $42, $51, $42
    db $41, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $48, $46, $4b, $44, $68, $62, $4e
    db $52, $42, $50, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $a3, $26, $4c, $4a, $42, $62, $4c, $4b, $63, $ef, $ee, $2f, $42, $51
    db $68, $62, $44, $4c, $62, $3f, $3e, $40, $48, $62, $51, $4c, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $40, $3e, $50, $51, $49, $42, $63, $ef, $ee, $f7, $f0
TextStr_45_6c7d:           ; id $02A8
    ; "*:Soon you will become powerful! / *:During my journey, I kept / bumping into bishops. / *:Maybe it's because I always / travel everywhere t..."
    db $eb, $9f, $a3, $36, $4c, $4c, $4b, $62, $56, $4c, $52, $62, $54, $46, $49, $49
    db $ef, $ee, $3f, $42, $40, $4c, $4a, $42, $62, $4d, $4c, $54, $42, $4f, $43, $52
    db $49, $63, $fa, $f7, $ef, $ee, $9f, $a3, $27, $52, $4f, $46, $4b, $44, $62, $4a
    db $56, $ef, $ee, $47, $4c, $52, $4f, $4b, $42, $56, $5e, $62, $2c, $62, $48, $42
    db $4d, $51, $fa, $f7, $ef, $ee, $3f, $52, $4a, $4d, $46, $4b, $44, $62, $46, $4b
    db $51, $4c, $ef, $ee, $3f, $46, $50, $45, $4c, $4d, $50, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $30, $3e, $56, $3f, $42, $62, $46, $51, $68, $ef, $ee, $3f, $42, $40
    db $3e, $52, $50, $42, $62, $2c, $62, $3e, $49, $54, $3e, $56, $50, $fa, $f7, $ef
    db $ee, $51, $4f, $3e, $53, $42, $49, $ef, $ee, $42, $53, $42, $4f, $56, $54, $45
    db $42, $4f, $42, $62, $51, $4c, $62, $51, $4f, $56, $fa, $f7, $ef, $ee, $51, $4c
    db $62, $43, $46, $4b, $41, $62, $3e, $49, $49, $62, $51, $45, $42, $ef, $ee, $46
    db $51, $42, $4a, $50, $62, $2c, $62, $40, $3e, $4b, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $3a, $42, $49, $49, $5e, $62, $41, $4c, $42, $50, $62, $51, $45, $46, $50
    db $ef, $ee, $46, $4b, $43, $4c, $4f, $4a, $3e, $51, $46, $4c, $4b, $62, $45, $42
    db $49, $4d, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3e, $51, $62, $3e, $49, $49
    db $64, $ef, $ee, $f7, $f0
TextStr_45_6d72:           ; id $02A9
    ; "King:Oh [HERO]!! Welcome back! / King:I heard you've completed / your mission. Good job! / King:!!....Hmm!"
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $63, $ef, $ee, $3a, $42
    db $49, $40, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $63, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $ef, $ee, $56, $4c, $52
    db $6c, $42, $62, $40, $4c, $4a, $4d, $49, $42, $51, $42, $41, $fa, $f7, $ef, $ee
    db $56, $4c, $52, $4f, $62, $4a, $46, $50, $50, $46, $4c, $4b, $5f, $ef, $ee, $2a
    db $4c, $4c, $41, $62, $47, $4c, $3f, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $63, $63, $5f, $5f, $5f, $5f, $2b, $4a, $4a, $63, $ef, $ee, $f7, $f0
TextStr_45_6de1:           ; id $02AA
    ; "*:Oh... This kingdom is full / of energy. / *:Everybody is excited because / Starry Night is drawing near... / *:...It's enviable. My kingdo..."
    db $ea, $9f, $a3, $32, $45, $5f, $5f, $5f, $62, $37, $45, $46, $50, $ef, $ee, $48
    db $46, $4b, $44, $41, $4c, $4a, $62, $46, $50, $62, $43, $52, $49, $49, $fa, $f7
    db $ef, $ee, $4c, $43, $62, $42, $4b, $42, $4f, $44, $56, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $28, $53, $42, $4f, $56, $3f, $4c, $41, $56, $62, $46, $50
    db $ef, $ee, $42, $55, $40, $46, $51, $42, $41, $62, $3f, $42, $40, $3e, $52, $50
    db $42, $fa, $f7, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $62, $46, $50, $ef, $ee, $41, $4f, $3e, $54, $46, $4b, $44, $62, $4b, $42
    db $3e, $4f, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $5f, $5f, $5f, $2c, $51
    db $68, $62, $42, $4b, $53, $46, $3e, $3f, $49, $42, $5f, $ef, $ee, $30, $56, $62
    db $48, $46, $4b, $44, $41, $4c, $4a, $62, $46, $50, $fa, $f7, $ef, $ee, $54, $46
    db $51, $45, $42, $4f, $42, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25
    db $52, $51, $5e, $62, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $ef, $ee
    db $3f, $42, $3e, $52, $51, $56, $62, $4f, $42, $3e, $49, $46, $57, $42, $41, $fa
    db $f7, $ef, $ee, $4c, $4b, $49, $56, $62, $3e, $43, $51, $42, $4f, $62, $51, $45
    db $42, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $62, $54, $46, $51, $45, $42
    db $4f, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $2c, $62
    db $51, $3e, $48, $42, $62, $3e, $ef, $ee, $50, $42, $40, $4c, $4b, $41, $62, $49
    db $4c, $4c, $48, $5e, $62, $51, $45, $46, $50, $fa, $f7, $ef, $ee, $48, $46, $4b
    db $44, $41, $4c, $4a, $62, $50, $42, $42, $4a, $50, $ef, $ee, $53, $42, $4f, $56
    db $62, $4a, $42, $4f, $4f, $56, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $3f
    db $4c, $41, $56, $62, $45, $3e, $50, $62, $51, $45, $42, $46, $4f, $ef, $ee, $43
    db $42, $42, $51, $62, $4c, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44, $4f
    db $4c, $52, $4b, $41, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_45_6f4c:           ; id $02AB
    ; "*:You look especially merry. / Are you a street performer? / *:I'm the King of DeadTree. Go cheer / everybody up!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $49, $4c, $4c, $48, $ef, $ee, $42, $50, $4d
    db $42, $40, $46, $3e, $49, $49, $56, $62, $4a, $42, $4f, $4f, $56, $5f, $fa, $f7
    db $ef, $ee, $24, $4f, $42, $62, $56, $4c, $52, $62, $3e, $62, $50, $51, $4f, $42
    db $42, $51, $ef, $ee, $4d, $42, $4f, $43, $4c, $4f, $4a, $42, $4f, $64, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $6a, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $62
    db $4c, $43, $ef, $ee, $27, $42, $3e, $41, $37, $4f, $42, $42, $5f, $62, $2a, $4c
    db $62, $40, $45, $42, $42, $4f, $fa, $f7, $ef, $ee, $42, $53, $42, $4f, $56, $3f
    db $4c, $41, $56, $62, $52, $4d, $63, $ef, $ee, $f7, $f0
TextStr_45_6fc7:           ; id $02AC
    ; "DeadTree King:... King of GreatTree, / have you found a master? / DeadTree King:Or, maybe you won't / have one this time? Ha Ha Ha.."
    db $ea, $27, $42, $3e, $41, $37, $4f, $42, $42, $62, $2e, $46, $4b, $44, $a3, $5f
    db $5f, $5f, $ef, $ee, $2e, $46, $4b, $44, $62, $4c, $43, $62, $2a, $4f, $42, $3e
    db $51, $37, $4f, $42, $42, $5e, $fa, $f7, $ef, $ee, $45, $3e, $53, $42, $62, $56
    db $4c, $52, $62, $43, $4c, $52, $4b, $41, $ef, $ee, $3e, $62, $4a, $3e, $50, $51
    db $42, $4f, $64, $fa, $f7, $ef, $ee, $27, $42, $3e, $41, $37, $4f, $42, $42, $62
    db $2e, $46, $4b, $44, $a3, $32, $4f, $5e, $ef, $ee, $4a, $3e, $56, $3f, $42, $62
    db $56, $4c, $52, $62, $54, $4c, $4b, $67, $fa, $f7, $ef, $ee, $45, $3e, $53, $42
    db $62, $4c, $4b, $42, $62, $51, $45, $46, $50, $ef, $ee, $51, $46, $4a, $42, $64
    db $62, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $5f, $5f, $f7, $f0
TextStr_45_7054:           ; id $02AD
    ; "King:DeadTree! You will see! / King:...[HERO], Don't mind the / interruption... / King:Nonetheless, Welcome back! / King:I heard you got rid..."
    db $ea, $2e, $46, $4b, $44, $a3, $27, $42, $3e, $41, $37, $4f, $42, $42, $63, $ef
    db $ee, $3c, $4c, $52, $62, $54, $46, $49, $49, $62, $50, $42, $42, $63, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $5f, $5f, $5f, $f6, $5e, $ef, $ee, $27, $4c
    db $4b, $67, $62, $4a, $46, $4b, $41, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $46
    db $4b, $51, $42, $4f, $4f, $52, $4d, $51, $46, $4c, $4b, $5f, $5f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $31, $4c, $4b, $42, $51, $45, $42
    db $49, $42, $50, $50, $5e, $ef, $ee, $3a, $42, $49, $40, $4c, $4a, $42, $62, $3f
    db $3e, $40, $48, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $45
    db $42, $3e, $4f, $41, $62, $56, $4c, $52, $ef, $ee, $44, $4c, $51, $62, $4f, $46
    db $41, $62, $4c, $43, $62, $3e, $4b, $fa, $f7, $ef, $ee, $42, $4b, $4c, $4f, $4a
    db $4c, $52, $50, $62, $3e, $4a, $4c, $52, $4b, $51, $ef, $ee, $4c, $43, $62, $42
    db $44, $44, $50, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $37, $45, $3e
    db $51, $68, $62, $4a, $56, $ef, $ee, $f6, $5f, $62, $3c, $4c, $52, $69, $42, $fa
    db $f7, $ef, $ee, $51, $45, $42, $62, $3f, $42, $50, $51, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $2a, $4c, $62, $4c, $4b, $63, $ef, $ee, $f6
    db $5f, $62, $37, $4f, $56, $fa, $f7, $ef, $ee, $43, $46, $44, $45, $51, $46, $4b
    db $44, $62, $46, $4b, $62, $26, $ef, $ee, $40, $49, $3e, $50, $50, $62, $3e, $4b
    db $41, $62, $3f, $42, $56, $4c, $4b, $41, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b
    db $44, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $ef, $ee, $50, $52, $4f, $53
    db $46, $53, $42, $62, $36, $62, $40, $49, $3e, $50, $50, $fa, $f7, $ef, $ee, $56
    db $4c, $52, $66, $49, $62, $3f, $42, $62, $51, $45, $42, $62, $4f, $42, $4d, $ef
    db $ee, $4c, $43, $62, $4a, $56, $62, $48, $46, $4b, $44, $41, $4c, $4a, $63, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $3e, $4a, $62, $40, $4c, $52
    db $4b, $51, $46, $4b, $44, $ef, $ee, $4c, $4b, $62, $56, $4c, $52, $5e, $62, $f6
    db $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $45, $3e, $53, $42
    db $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $51, $4c, $62, $51
    db $3e, $48, $42, $fa, $f7, $ef, $ee, $40, $3e, $4f, $42, $62, $4c, $43, $5f, $62
    db $3c, $4c, $52, $69, $42, $ef, $ee, $41, $46, $50, $4a, $46, $50, $50, $42, $41
    db $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62
    db $25, $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $5f, $5f, $5f, $f7
    db $f0
TextStr_45_7235:           ; id $02AE
    ; "*:This shaking is evidence of the / growth of GreatTree. / *:You will notice changes to / GreatTree's landscape."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $50, $45, $3e, $48, $46, $4b, $44, $62
    db $46, $50, $ef, $ee, $42, $53, $46, $41, $42, $4b, $40, $42, $62, $4c, $43, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $44, $4f, $4c, $54, $51, $45, $62, $4c, $43
    db $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $3c, $4c, $52, $62, $54, $46, $49, $49, $62, $4b, $4c, $51, $46, $40
    db $42, $ef, $ee, $40, $45, $3e, $4b, $44, $42, $50, $62, $51, $4c, $fa, $f7, $ef
    db $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $68, $ef, $ee, $49, $3e, $4b
    db $41, $50, $40, $3e, $4d, $42, $5f, $f7, $f0
TextStr_45_72ae:           ; id $02AF
    ; "*:The shaking of GreatTree has / changed the landscape. / *:There must be new places you / can go now! / *:Remember! Sometimes, it's / impor..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $50, $45, $3e, $48, $46, $4b, $44, $62, $4c
    db $43, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $45, $3e, $50
    db $fa, $f7, $ef, $ee, $40, $45, $3e, $4b, $44, $42, $41, $62, $51, $45, $42, $ef
    db $ee, $49, $3e, $4b, $41, $50, $40, $3e, $4d, $42, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $37, $45, $42, $4f, $42, $62, $4a, $52, $50, $51, $62, $3f, $42, $ef, $ee
    db $4b, $42, $54, $62, $4d, $49, $3e, $40, $42, $50, $62, $56, $4c, $52, $fa, $f7
    db $ef, $ee, $40, $3e, $4b, $62, $44, $4c, $62, $4b, $4c, $54, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $35, $42, $4a, $42, $4a, $3f, $42, $4f, $63, $ef, $ee
    db $36, $4c, $4a, $42, $51, $46, $4a, $42, $50, $5e, $62, $46, $51, $68, $fa, $f7
    db $ef, $ee, $46, $4a, $4d, $4c, $4f, $51, $3e, $4b, $51, $62, $51, $4c, $62, $51
    db $3e, $49, $48, $ef, $ee, $51, $4c, $62, $4d, $42, $4c, $4d, $49, $42, $62, $49
    db $46, $53, $46, $4b, $44, $fa, $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62
    db $48, $46, $4b, $44, $41, $4c, $4a, $5f, $ef, $ee, $f7, $f0
TextStr_45_737a:           ; id $02B0
    ; "*:Are you familiar with the / Gate of Anger? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62, $24, $4b, $44, $42, $4f, $64, $ef
    db $ee, $ff, $f0
TextStr_45_73ad:           ; id $02B1
    ; "*:The victor made countless eggs / vanish instantly. / *:How do you like it? This is the / legend of [HERO]!"
    db $eb, $9f, $a3, $37, $45, $42, $62, $53, $46, $40, $51, $4c, $4f, $62, $4a, $3e
    db $41, $42, $ef, $ee, $40, $4c, $52, $4b, $51, $49, $42, $50, $50, $62, $42, $44
    db $44, $50, $fa, $f7, $ef, $ee, $53, $3e, $4b, $46, $50, $45, $62, $46, $4b, $50
    db $51, $3e, $4b, $51, $49, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b
    db $4c, $54, $62, $41, $4c, $62, $56, $4c, $52, $62, $49, $46, $48, $42, $ef, $ee
    db $46, $51, $64, $62, $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $49, $42, $44, $42, $4b, $41, $62, $4c, $43, $62, $f6, $63, $ef
    db $ee, $f7, $f0
TextStr_45_7420:           ; id $02B2
    ; "*:Are you familiar with the Gate of / Strength? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $36, $51, $4f, $42, $4b, $44, $51
    db $45, $64, $ef, $ee, $ff, $f0
TextStr_45_7456:           ; id $02B3
    ; "*:I looked back and the stone / statue was not at the same place! / *:It's the story about a man who / survived his journey."
    db $eb, $9f, $a3, $2c, $62, $49, $4c, $4c, $48, $42, $41, $62, $3f, $3e, $40, $48
    db $ef, $ee, $3e, $4b, $41, $62, $51, $45, $42, $62, $50, $51, $4c, $4b, $42, $fa
    db $f7, $ef, $ee, $50, $51, $3e, $51, $52, $42, $62, $54, $3e, $50, $62, $4b, $4c
    db $51, $62, $3e, $51, $ef, $ee, $51, $45, $42, $62, $50, $3e, $4a, $42, $62, $4d
    db $49, $3e, $40, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62, $51
    db $45, $42, $62, $50, $51, $4c, $4f, $56, $ef, $ee, $3e, $3f, $4c, $52, $51, $62
    db $3e, $62, $4a, $3e, $4b, $62, $54, $45, $4c, $fa, $f7, $ef, $ee, $50, $52, $4f
    db $53, $46, $53, $42, $41, $62, $45, $46, $50, $ef, $ee, $47, $4c, $52, $4f, $4b
    db $42, $56, $5f, $f7, $f0
TextStr_45_74db:           ; id $02B4
    ; "*:I see. It's okay then. Sorry to / bother you."
    db $ea, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $62, $2c, $51, $68, $62, $4c, $48
    db $3e, $56, $ef, $ee, $51, $45, $42, $4b, $5f, $62, $36, $4c, $4f, $4f, $56, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $3f, $4c, $51, $45, $42, $4f, $62, $56, $4c, $52
    db $5f, $ef, $ee, $f7, $f0
TextStr_45_7510:           ; id $02B5
    ; "*:Sometimes a lie makes people / happy but... / *:eventually makes them unhappy... / *:It's the mumbling of a man / who was deceived by a mo..."
    db $eb, $9f, $a3, $36, $4c, $4a, $42, $51, $46, $4a, $42, $50, $62, $3e, $62, $49
    db $46, $42, $ef, $ee, $4a, $3e, $48, $42, $50, $62, $4d, $42, $4c, $4d, $49, $42
    db $fa, $f7, $ef, $ee, $45, $3e, $4d, $4d, $56, $62, $3f, $52, $51, $5f, $5f, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $42, $53, $42, $4b, $51, $52, $3e, $49
    db $49, $56, $62, $4a, $3e, $48, $42, $50, $ef, $ee, $51, $45, $42, $4a, $62, $52
    db $4b, $45, $3e, $4d, $4d, $56, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $51, $68, $62, $51, $45, $42, $ef, $ee, $4a, $52, $4a, $3f, $49, $46, $4b, $44
    db $62, $4c, $43, $62, $3e, $62, $4a, $3e, $4b, $fa, $f7, $ef, $ee, $54, $45, $4c
    db $62, $54, $3e, $50, $62, $41, $42, $40, $42, $46, $53, $42, $41, $ef, $ee, $3f
    db $56, $62, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $f7, $f0
TextStr_45_75ae:           ; id $02B6
    ; "King:Oh, [HERO] You beat / StoneMan! / King:I heard StoneMan snuck up / behind you! / King:He's a sneaky one!"
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $5e, $62, $f6, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $fa, $f7, $ef, $ee, $36, $51, $4c, $4b, $42, $30, $3e
    db $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $45
    db $42, $3e, $4f, $41, $ef, $ee, $36, $51, $4c, $4b, $42, $30, $3e, $4b, $62, $50
    db $4b, $52, $40, $48, $62, $52, $4d, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b
    db $41, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $a3, $2b, $42, $68, $62, $3e, $62, $50, $4b, $42, $3e, $48, $56, $ef, $ee, $4c
    db $4b, $42, $63, $f7, $f0
TextStr_45_7623:           ; id $02B7
    ; "King:Well [HERO]. Are you talking to / the people of my kingdom? / King:I heard there is a man called / the Medal Man in the village. / King..."
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $f6, $5f, $ef, $ee, $24
    db $4f, $42, $62, $56, $4c, $52, $62, $51, $3e, $49, $48, $46, $4b, $44, $62, $51
    db $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4d, $42, $4c, $4d, $49, $42, $62
    db $4c, $43, $62, $4a, $56, $62, $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $64
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $62, $45, $42, $3e, $4f, $41
    db $62, $51, $45, $42, $4f, $42, $ef, $ee, $46, $50, $62, $3e, $62, $4a, $3e, $4b
    db $62, $40, $3e, $49, $49, $42, $41, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $30
    db $42, $41, $3e, $49, $62, $30, $3e, $4b, $62, $46, $4b, $ef, $ee, $51, $45, $42
    db $62, $53, $46, $49, $49, $3e, $44, $42, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b
    db $44, $a3, $2b, $42, $62, $49, $46, $48, $42, $50, $ef, $ee, $37, $46, $4b, $56
    db $30, $42, $41, $3e, $49, $50, $5f, $62, $3a, $45, $56, $fa, $f7, $ef, $ee, $41
    db $4c, $4b, $67, $62, $56, $4c, $52, $62, $3f, $4f, $46, $4b, $44, $ef, $ee, $51
    db $45, $42, $4a, $62, $51, $4c, $62, $45, $46, $4a, $5f, $fa, $f7, $ef, $ee, $2e
    db $46, $4b, $44, $a3, $2c, $62, $3e, $4a, $62, $3f, $52, $50, $56, $5f, $ef, $ee
    db $3c, $4c, $52, $69, $42, $62, $41, $46, $50, $4a, $46, $50, $50, $42, $41, $63
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56, $63, $62, $25
    db $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $5f, $5f, $5f, $f7, $f0
TextStr_45_7733:           ; id $02B8
    ; "[HERO] looked at the bookshelf. / :Make Your Money Grow. / :Do not make fake money."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $30, $3e, $48, $42, $62, $3c, $4c, $52, $4f, $62, $30, $4c, $4b, $42, $56, $ef
    db $ee, $2a, $4f, $4c, $54, $5f, $fa, $f7, $ef, $ee, $a3, $27, $4c, $62, $4b, $4c
    db $51, $62, $4a, $3e, $48, $42, $ef, $ee, $43, $3e, $48, $42, $62, $4a, $4c, $4b
    db $42, $56, $5f, $f7, $f0
TextStr_45_7788:           ; id $02B9
    ; "*:You're at the castle of / GreatTree. / *:There have been changes in the / village and the Bazaar due to the / quake."
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $40, $3e, $50, $51, $49, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f
    db $42, $3e, $51, $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $4f, $42, $62, $45, $3e, $53, $42, $62, $3f, $42, $42, $4b, $ef
    db $ee, $40, $45, $3e, $4b, $44, $42, $50, $62, $46, $4b, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $53, $46, $49, $49, $3e, $44, $42, $62, $3e, $4b, $41, $62, $51
    db $45, $42, $ef, $ee, $25, $3e, $57, $3e, $3e, $4f, $62, $41, $52, $42, $62, $51
    db $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4e, $52, $3e, $48, $42, $5f, $ef
    db $ee, $f7, $f0
TextStr_45_780b:           ; id $02BA
    ; "*:A long time ago, the ancestor of / Watabou asked us... / *:to hold the tournaments. / I wonder why?"
    db $eb, $9f, $a3, $24, $62, $49, $4c, $4b, $44, $62, $51, $46, $4a, $42, $62, $3e
    db $44, $4c, $5e, $ef, $ee, $51, $45, $42, $62, $3e, $4b, $40, $42, $50, $51, $4c
    db $4f, $62, $4c, $43, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62
    db $3e, $50, $48, $42, $41, $ef, $ee, $52, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $51, $4c, $62, $45, $4c, $49, $41, $62, $51, $45, $42, $ef, $ee, $51
    db $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $50, $5f, $fa, $f7, $ef, $ee, $2c
    db $62, $54, $4c, $4b, $41, $42, $4f, $62, $54, $45, $56, $64, $ef, $ee, $f7, $f0
TextStr_45_787b:           ; id $02BB
    ; "*:I often see the girl who stood in / the way down there. / *:She's always at the arena during / your battles."
    db $ea, $9f, $a3, $2c, $62, $4c, $43, $51, $42, $4b, $62, $50, $42, $42, $62, $51
    db $45, $42, $ef, $ee, $44, $46, $4f, $49, $62, $54, $45, $4c, $62, $50, $51, $4c
    db $4c, $41, $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $54, $3e, $56
    db $62, $41, $4c, $54, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $36, $45, $42, $68, $62, $3e, $49, $54, $3e, $56, $50, $62, $3e
    db $51, $ef, $ee, $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $62, $41, $52, $4f
    db $46, $4b, $44, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $3f, $3e, $51, $51
    db $49, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_45_78f3:           ; id $02BC
    ; "*:The Kingdom of DeadTree is almost / dead. / *:I wonder if GreatTree will / eventually die too."
    db $eb, $9f, $a3, $37, $45, $42, $62, $2e, $46, $4b, $44, $41, $4c, $4a, $62, $4c
    db $43, $ef, $ee, $27, $42, $3e, $41, $37, $4f, $42, $42, $62, $46, $50, $62, $3e
    db $49, $4a, $4c, $50, $51, $fa, $f7, $ef, $ee, $41, $42, $3e, $41, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $46
    db $43, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $54, $46, $49
    db $49, $fa, $f7, $ef, $ee, $42, $53, $42, $4b, $51, $52, $3e, $49, $49, $56, $62
    db $41, $46, $42, $ef, $ee, $51, $4c, $4c, $5f, $f7, $f0
TextStr_45_795e:           ; id $02BD
    ; "*:I want us to win this time! / *:The Stars will listen to your / wish on the Starry Night. / *:The victory makes your wish / come true."
    db $eb, $9f, $a3, $2c, $62, $54, $3e, $4b, $51, $62, $52, $50, $62, $51, $4c, $62
    db $54, $46, $4b, $ef, $ee, $51, $45, $46, $50, $62, $51, $46, $4a, $42, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $36, $51, $3e, $4f, $50, $62, $54
    db $46, $49, $49, $ef, $ee, $49, $46, $50, $51, $42, $4b, $62, $51, $4c, $62, $56
    db $4c, $52, $4f, $fa, $f7, $ef, $ee, $54, $46, $50, $45, $62, $4c, $4b, $62, $51
    db $45, $42, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $53, $46, $40, $51, $4c
    db $4f, $56, $ef, $ee, $4a, $3e, $48, $42, $50, $62, $56, $4c, $52, $4f, $62, $54
    db $46, $50, $45, $fa, $f7, $ef, $ee, $40, $4c, $4a, $42, $62, $51, $4f, $52, $42
    db $5f, $ef, $ee, $f7, $f0
TextStr_45_79f3:           ; id $02BE
    ; "*:Right to the Bazaar! There are / new stores!"
    db $eb, $9f, $a3, $35, $46, $44, $45, $51, $62, $51, $4c, $62, $51, $45, $42, $ef
    db $ee, $25, $3e, $57, $3e, $3e, $4f, $63, $62, $37, $45, $42, $4f, $42, $62, $3e
    db $4f, $42, $fa, $f7, $ef, $ee, $4b, $42, $54, $62, $50, $51, $4c, $4f, $42, $50
    db $63, $ef, $ee, $f7, $f0
TextStr_45_7a28:           ; id $02BF
    ; "*:D... Do ya know there was a big / quake? [YES/NO]"
    db $eb, $9f, $a3, $27, $5f, $5f, $5f, $62, $27, $4c, $62, $56, $3e, $62, $48, $4b
    db $4c, $54, $ef, $ee, $51, $45, $42, $4f, $42, $62, $54, $3e, $50, $62, $3e, $62
    db $3f, $46, $44, $fa, $f7, $ef, $ee, $4e, $52, $3e, $48, $42, $64, $62, $ef, $ee
    db $ff, $f0, $00
; --- END re-sectioned text run (bank $45) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

