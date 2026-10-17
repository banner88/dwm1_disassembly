; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $042", ROMX[$4000], BANK[$42]

    db $42 ; Bank number

    ; Cross-bank dispatch table (117 entries)
    ; Called via: ld hl, $42XX / rst $10
    dw LoadB42_40eb                  ; Entry 0
    dw $4108                          ; Entry 1
    dw $4125                          ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw $4142                          ; Entry 4 — [table $4009]; text $0000 "Milayou:Terry! Wait! It's time fo…"
    dw $4244                          ; Entry 5 — text $0001 "Milayou:... zzz."
    dw $4259                          ; Entry 6 — text $0002 "Terry looked at a stuffed animal.…"
    dw $42D0                          ; Entry 7 — text $0003 "Terry looked in front of him. A f…"
    dw $4323                          ; Entry 8 — text $0004 "Terry looked at the bookshelf. :A…"
    dw $43B0                          ; Entry 9 — text $0005 "Terry looked at the bookshelf. :D…"
    dw $4431                          ; Entry 10 — text $0006 "[SOUND 60]Terry looked in the dre…"
    dw $4473                          ; Entry 11 — text $0007 "[SOUND 60]Terry looked in the dre…"
    dw $44BA                          ; Entry 12 — text $0008 "*:Are you Milayou? *:Hm, You don'…"
    dw $4590                          ; Entry 13 — text $0009 "*:Huh? What happened? Where is Mi…"
    dw $45C1                          ; Entry 14 — text $000A "*:You speak monster talk don't yo…"
    dw $476A                          ; Entry 15 — text $000B "Terry looks at the bookshelf. :En…"
    dw $47BF                          ; Entry 16 — text $000C "Terry looked at the bookshelf. To…"
    dw $47FB                          ; Entry 17 — text $000D "Terry looked in front of him. The…"
    dw $483B                          ; Entry 18 — text $000E "Terry looked at a stuffed animal.…"
    dw $48B2                          ; Entry 19 — text $000F "*:Oh, you must be the master. You…"
    dw $49CF                          ; Entry 20 — text $0010 "*:This kingdom is created inside …"
    dw $4A3E                          ; Entry 21 — text $0011 "*:Hey, is he the new master Watab…"
    dw $4A77                          ; Entry 22 — text $0012 "*:Yes indeed, I'm taking him to s…"
    dw $4AAC                          ; Entry 23 — text $0013 "*:Good luck at the Starry Night T…"
    dw $4AE0                          ; Entry 24 — text $0014 "*:Now it's time to go see the Kin…"
    dw $4B06                          ; Entry 25 — text $0015 "*:I'm the minister of this kingdo…"
    dw $4B9C                          ; Entry 26 — text $0016 "*:His Majesty is in trouble. Plea…"
    dw $4BD7                          ; Entry 27 — text $0017 "*:Please listen to his wish."
    dw $4BF7                          ; Entry 28 — text $0018 "*:This is the castle of GreatTree."
    dw $4C22                          ; Entry 29 — text $0019 "*:Hurry! Go see the King!"
    dw $4C3F                          ; Entry 30 — text $001A "*:I see....."
    dw $4C50                          ; Entry 31 — text $001B "[HERO] opened a treasure chest!"
    dw $4C6E                          ; Entry 32 — text $001C "[HERO] picked up an Herb."
    dw $4C85                          ; Entry 33 — text $001D "[HERO] found an Herb. But cannot …"
    dw $4CEA                          ; Entry 34 — text $001E "[HERO] opened a treasure chest!"
    dw $4D08                          ; Entry 35 — text $001F "*:This is the Kingdom of GreatTre…"
    dw $4D34                          ; Entry 36 — text $0020 "*:Welcome! I am the King of this …"
    dw $4D91                          ; Entry 37 — text $0021 "King:Oh [HERO]! Will you comply w…"
    dw $517B                          ; Entry 38 — text $0022 "*:Everybody will be happy if you …"
    dw $51DB                          ; Entry 39 — text $0023 "*:I have a feeling that your vict…"
    dw $522C                          ; Entry 40 — text $0024 "[HERO] looked at the bookshelf. :…"
    dw $5285                          ; Entry 41 — text $0025 ":It's a little kingdom built insi…"
    dw $53F1                          ; Entry 42 — text $0026 "[HERO] returned the book to the b…"
    dw $541E                          ; Entry 43 — text $0027 "[HERO] looked at the bookshelf. T…"
    dw $5474                          ; Entry 44 — text $0028 ":People who understand monster ta…"
    dw $55D7                          ; Entry 45 — text $0029 "*:I wanna be a master. What shoul…"
    dw $5608                          ; Entry 46 — text $002A "King:The monster farm is on the u…"
    dw $5677                          ; Entry 47 — text $002B "*:My kingdom has been losing in t…"
    dw $56FD                          ; Entry 48 — text $002C "*:Let me tell you about the legen…"
    dw $58B2                          ; Entry 49 — text $002D "*:Should I repeat the legend of t…"
    dw $58EC                          ; Entry 50 — text $002E "*:Here it is again. *:The Starry …"
    dw $5A53                          ; Entry 51 — text $002F "*:The tournament is held on the S…"
    dw $5B00                          ; Entry 52 — text $0030 "*:Pulio from the farm is goofy bu…"
    dw $5B3C                          ; Entry 53 — text $0031 "*:Upper floor, the monster farm. …"
    dw $5B99                          ; Entry 54 — text $0032 "*:Watabou brings us capable maste…"
    dw $5C54                          ; Entry 55 — text $0033 "*:I wonder where I can get treats."
    dw $5C7A                          ; Entry 56 — text $0034 "[HERO] read the sign. :Danger, Do…"
    dw $5CC2                          ; Entry 57 — text $0035 "*:No! You'll be hurt if you fall."
    dw $5CE6                          ; Entry 58 — text $0036 "*:If it was not for this hole... …"
    dw $5D55                          ; Entry 59 — text $0037 "[HERO] read the sign. :When the G…"
    dw $5E08                          ; Entry 60 — text $0038 "*:I heard that Pulio let the mons…"
    dw $5E3E                          ; Entry 61 — text $0039 "*:Hey, Mr.Monster Master. I wonde…"
    dw $5ED1                          ; Entry 62 — text $003A "[HERO] looked into the jar."
    dw $5EEB                          ; Entry 63 — text $003B "[HERO] looked into the jar. The j…"
    dw $5F28                          ; Entry 64 — text $003C "*:Hey you! You came here to steal…"
    dw $5F5F                          ; Entry 65 — text $003D "*:C'mon, I'll give you a beating.…"
    dw $6007                          ; Entry 66 — text $003E "*:You came here to get monsters?"
    dw $602C                          ; Entry 67 — text $003F "*:I'm Pulio I take care of this f…"
    dw $6159                          ; Entry 68 — text $0040 "*:I'm Slio. I am the grandson of …"
    dw $61BD                          ; Entry 69 — text $0041 "Slio:You can drop off up to 19 mo…"
    dw $6437                          ; Entry 70 — text $0042 "Slio:Raise the monster to be powe…"
    dw $6466                          ; Entry 71 — text $0043 "Slio:D'ya wanna know about the fa…"
    dw $6492                          ; Entry 72 — text $0044 "*:You are at the monster farm."
    dw $64B4                          ; Entry 73 — text $0045 "King:Oh, this monster is the form…"
    dw $65B6                          ; Entry 74 — text $0046 "Pulio:Your Majesty, please forgiv…"
    dw $65E5                          ; Entry 75 — text $0047 "King:Pulio, did Hale escape as we…"
    dw $6612                          ; Entry 76 — text $0048 "Pulio:Your Majesty please forgive…"
    dw $6651                          ; Entry 77 — text $0049 "King:Arrgh! You! You let my preci…"
    dw $66CC                          ; Entry 78 — text $004A "King:What? [HERO]! You have somet…"
    dw $6791                          ; Entry 79 — text $004B "Pulio:Majesty, Hale escaped throu…"
    dw $67D1                          ; Entry 80 — text $004C "King:I see. Now [HERO], proceed t…"
    dw $68DF                          ; Entry 81 — text $004D "*:His Majesty seems to be very up…"
    dw $6966                          ; Entry 82 — text $004E "*:Give the courageous master [HER…"
    dw $69A4                          ; Entry 83 — text $004F "*:In the Chamber of Travelers' Ga…"
    dw $6ABA                          ; Entry 84 — text $0050 "Pulio:Sorry [HERO], It's my fault…"
    dw $6B5B                          ; Entry 85 — text $0051 "*:These stairs bring you to the C…"
    dw $6BA3                          ; Entry 86 — text $0052 "*:Please bring Hale back as soon …"
    dw $6BD9                          ; Entry 87 — text $0053 "*:When you enter the Travelers' G…"
    dw $6DC6                          ; Entry 88 — text $0054 "*:You will find items scattered a…"
    dw $6E72                          ; Entry 89 — text $0055 "*:Hale was the cherished pet of t…"
    dw $6F1C                          ; Entry 90 — text $0056 "*:Welcome to the Chamber of Trave…"
    dw $6F60                          ; Entry 91 — text $0057 "*:We are at the Chamber of Travel…"
    dw $6FFE                          ; Entry 92 — text $0058 "*:How do you do. I'm Hale. *:I kn…"
    dw $7092                          ; Entry 93 — text $0059 "*:You are strong! I like you, [HE…"
    dw $70BB                          ; Entry 94 — text $005A "King:Oh, [HERO]! Did you bring ba…"
    dw $71FE                          ; Entry 95 — text $005B "Pulio:Thank you [HERO]! Now I can…"
    dw $7236                          ; Entry 96 — text $005C "King:[HERO]. Go to the arena. Kin…"
    dw $7314                          ; Entry 97 — text $005D "Slio:[HERO]! Congratulations on y…"
    dw $736B                          ; Entry 98 — text $005E "*:To get to the arena, go straigh…"
    dw $73FE                          ; Entry 99 — text $005F "*:These stairs go up to the monst…"
    dw $7430                          ; Entry 100 — text $0060 "*:This is the castle of GreatTree…"
    dw $749A                          ; Entry 101 — text $0061 "*:Oh boy! This looks dangerous! O…"
    dw $74CA                          ; Entry 102 — text $0062 "*:This is the village of GreatTre…"
    dw $7527                          ; Entry 103 — text $0063 "*:Fhew! I'm glad that I didn't ge…"
    dw $756F                          ; Entry 104 — text $0064 "*:Oh [HERO], it's you. I am getti…"
    dw $75F1                          ; Entry 105 — text $0065 "*:Once I picked up a TinyMedal, *…"
    dw $7779                          ; Entry 106 — text $0066 "*:Would you like to see the list …"
    dw $77B7                          ; Entry 107 — text $0067 "*:You can enter the locked rooms …"
    dw $78FC                          ; Entry 108 — text $0068 "*:Monsters have personalities too…"
    dw $7A31                          ; Entry 109 — text $0069 "*:Hey Master! D'ya have an egg? […"
    dw $7A53                          ; Entry 110 — text $006A "Splat... Poop hit [HERO]."
    dw $7A6A                          ; Entry 111 — text $006B "Thwack! It was the egg of a SkyDr…"
    dw $7AAF                          ; Entry 112 — text $006C "[HERO] took the egg of a SkyDrago…"
    dw $7B2F                          ; Entry 113 — text $006D "Could not keep the egg because th…"
    dw $7C00                          ; Entry 114 — text $006E "Splash! Poop hit [HERO]."
    dw $7C16                          ; Entry 115 — text $006F "*:Treats! BeefJerky, PorkChop, Ri…"
    dw $7CC6                          ; Entry 116 — text $0070 "*:If you take monsters on a journ…"

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


    db $eb
    jr nc, jr_042_418b

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $3a
    ld a, $46
    ld d, c
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
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
    ccf
    ld b, d
    ld b, c
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
    daa
    ld b, [hl]
    ld b, c
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

jr_042_418b:
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    jr nc, jr_042_41de

    ld c, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    daa
    ld a, $41
    ld h, d
    ld d, c
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld d, d
    ld d, b
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
    ld [hl], $51
    ld a, $56
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld h, d
    ld c, c
    ld a, $51
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a

jr_042_41de:
    ld b, [hl]
    ld b, d
    ld b, c
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld h, d
    ccf
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
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld c, d
    ld b, d
    ld b, d
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
    ld h, h
    rst $28
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, c
    ld h, e
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
    ld h, d
    ld d, a
    ld d, a
    ld d, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    xor $3e
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $4b
    ld b, [hl]
    ld c, d
    ld a, $49
    ld e, a
    ld a, [$eff7]
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
    ld b, [hl]
    ld d, b
    rst $28
    xor $54
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, e
    ld d, [hl]
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc sp
    ld c, a
    ld c, h
    ld c, l
    ld b, d
    ld c, a
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $24
    ld h, d
    ld b, e
    ld c, c
    ld a, $4a
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld a, $4f
    ld c, b
    ld c, c
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, e
    ld a, $4b
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $46
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    inc h
    ld h, d
    add hl, hl
    ld a, $46
    ld c, a
    ld d, [hl]
    ld h, d
    scf
    ld a, $49
    ld b, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f3
    and e
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld c, h
    ld c, e
    ld h, d
    ld a, $62
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $ef
    xor $49
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    daa
    ld b, [hl]
    ld a, $4f
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_042_4425

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    dec hl
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $49
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld h, d
    dec hl
    ld c, h
    ld c, l
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ccf
    ld c, c
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

jr_042_4425:
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $30
    ldh a, [$e9]
    ld h, b
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$e9]
    ld h, b
    scf
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld l, b
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    jr nc, jr_042_450d

    ld c, c
    ld a, $56
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
    ld c, d
    ld e, [hl]
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
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld l, b
    ld h, d
    ld a, $62
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e

jr_042_450d:
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $37
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
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
    ld h, d
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
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
    ld l, $46
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $4c
    ld b, e
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
    xor $3a
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld d, d
    ld b, l
    ld h, h
    ld h, d
    rst $28
    xor $3a
    ld b, l
    ld a, $51
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, h
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_45fd

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld a, $48
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld a, [$eff7]
    xor $41
    ld c, h
    ld c, e
    ld h, a
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
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $30
    ld b, [hl]
    ld c, c

jr_042_45fd:
    ld a, $56
    ld c, h
    ld d, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld a, $48
    ld b, d
    ld c, e
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    ld h, h
    rst $28
    xor $32
    ld b, l
    ld h, d
    ld c, e
    ld c, h
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld a, [$eff7]
    xor $49
    ld a, $51
    ld b, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld h, h
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld a, [hl-]
    ld a, $4f
    ld d, d
    ccf
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
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
    ld b, d
    ld c, a
    ld b, d
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
    rst $28
    xor $46
    ld d, b
    ld h, h
    ld a, [$eff7]
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
    ld e, [hl]
    rst $28
    xor $43
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld h, d
    jr nc, @+$40

    ld d, [hl]
    ccf
    ld b, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld b, l
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
    inc l
    ld h, d
    ld b, l
    ld c, h
    ld c, l
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
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $4a
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
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    and e
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld c, h
    ld c, e
    ld h, a
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
    ld a, [$eff7]
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $3e
    ccf
    ld c, h
    ld d, d
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld d, b
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
    jr z, jr_042_47da

    ld b, b
    ld d, [hl]
    ld b, b
    ld c, c
    ld c, h
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld a, $ef
    xor $4c
    ld b, e
    ld h, d
    jr nc, jr_042_47ec

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
    jr c, jr_042_47ff

    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld c, e
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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

jr_042_47da:
    ld b, d
    ld c, c
    ld b, e
    ld e, a
    ld a, [$eff7]
    xor $37
    ld c, h
    ld c, h
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, e
    ld b, e
    ld b, [hl]
    ld b, b

jr_042_47ec:
    ld d, d
    ld c, c
    ld d, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, e
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a

jr_042_47ff:
    ld d, [hl]
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
    rst $28
    xor $43
    ld c, a
    ld c, h
    ld c, e
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, b
    rst $28
    xor $4a
    ld b, [hl]
    ld b, c
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$37]
    ld b, d
    ld c, a
    ld c, a
    ld d, [hl]
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
    xor $3e
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $4b
    ld b, [hl]
    ld c, d
    ld a, $49
    ld e, a
    ld a, [$eff7]
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
    ld b, [hl]
    ld d, b
    rst $28
    xor $54
    ld c, a
    ld b, [hl]
    ld d, c
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, e
    ld d, [hl]
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc sp
    ld c, a
    ld c, h
    ld c, l
    ld b, d
    ld c, a
    ld d, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
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
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ccf
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
    ld e, a
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, l
    ld a, $41
    rst $28
    xor $3e
    ld h, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld c, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
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
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
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
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
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
    ld e, a
    rst $28
    xor $3a
    ld b, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
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
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld a, $56
    rst $28
    xor $4c
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
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
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld d, c
    ld d, c
    ld c, h
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, l
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
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, d
    ld d, h
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
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
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld b, d
    ld b, d
    ld b, c
    ld e, [hl]
    ld h, d
    inc l
    ld l, d
    rst $28
    xor $51
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
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
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $544c
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
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
    ld a, [$eff7]
    xor $24
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_4b90

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $50
    rst $28
    xor $3e
    ld h, d
    ld b, e
    ld a, $53
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $50
    ld c, b
    ld h, d
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $45
    ld b, [hl]

jr_042_4b90:
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_4be3

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $46
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
    ld a, [$eff7]
    xor $33
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld d, e
    ld b, [hl]
    ld b, c
    ld b, d
    rst $28
    xor $52
    ld d, b
    ld h, d
    ld a, $46
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]

jr_042_4be3:
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $45
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld e, a
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
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld d, d
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, e
    ld h, d
    ld a, [hl+]
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $51
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
    ld h, e
    ld a, [$f0f7]
    or $62
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $3e
    ld c, e
    ld h, d
    dec hl
    ld b, d
    ld c, a
    ccf
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld b, e
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    rst $28
    xor $3e
    ld c, e
    ld h, d
    dec hl
    ld b, d
    ld c, a
    ccf
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
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
    xor $f6
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec hl
    ld b, d
    ld c, a
    ccf
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
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
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ld a, $ef
    xor $51
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
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
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
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
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
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld a, $4a
    rst $28
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
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $48
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
    and e
    inc l
    ld b, c
    ld b, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld b, e
    ld d, [hl]
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld e, [hl]
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, c
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
    xor $3a
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
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
    jr nc, jr_042_4e21

    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    add hl, hl
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
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
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
    rst $28
    xor $4c
    ld b, e

jr_042_4e21:
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
    ld a, $51
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld a, $56
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $4f
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $48
    ld b, [hl]
    ld b, c
    ld c, e
    ld a, $4d
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    daa
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
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
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $40
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld c, a
    ld b, d
    ld c, [hl]
    ld d, d
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
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    dec hl
    ld c, d
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    ld e, a
    dec hl
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $4b
    ld a, [$eff7]
    xor $42
    ld a, $50
    ld b, [hl]
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld b, l
    ld a, $4b
    rst $28
    xor $50
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $45
    ld b, d
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
    and e
    ld a, [hl-]
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
    cpl
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $46
    ld d, b
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
    ld h, d
    ld c, h
    ld b, e
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
    xor $3e
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
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
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
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
    ld a, [$eff7]
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
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, h
    ld b, d
    rst $28
    xor $3f
    ld c, h
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    jr nc, @+$44

    ld a, $4b
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld e, [hl]
    rst $28
    xor $50
    ld b, d
    ld a, $4f
    ld b, b
    ld b, l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
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
    ld b, e
    ld c, h
    ld c, a
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
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, l
    ld a, $49
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
    ld h, d
    ld d, b
    ld c, h
    ld c, d
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, b
    ld b, d
    ld c, a
    ld d, e
    ld b, d
    rst $28
    xor $3e
    ld d, b
    ld h, d
    ld a, $62
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
    and e
    scf
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
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $52
    ld c, l
    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $50
    ld c, b
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr z, jr_042_51d3

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
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
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
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
    ld d, c
    rst $28
    xor $37
    ld c, h
    ld d, d
    ld c, a
    ld c, e

jr_042_51d3:
    ld a, $4a
    ld b, d
    ld c, e
    ld d, c
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $ef
    xor $43
    ld b, d
    ld b, d
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
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
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
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
    scf
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
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
    ld e, a
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
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld h, h
    rst $38
    ldh a, [$a3]
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
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
    ccf
    ld d, d
    ld b, [hl]
    ld c, c
    ld d, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    ld [hl-], a
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    ld h, d
    ccf
    ld d, d
    ld b, [hl]
    ld c, c
    ld d, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc h
    ld c, c
    ld c, c
    ld h, d
    ld d, c
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
    ld d, b
    rst $28
    xor $45
    ld a, $53
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
    ld a, [$eff7]
    xor $40
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    dec h
    ld b, d
    ld d, [hl]
    ld c, h
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
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
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
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $a3
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
    xor $4b
    ld b, d
    ld a, $4f
    ld d, b
    ld e, [hl]
    ld h, d
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld a, [hl+]
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
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $28
    xor $f7
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
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
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld b, l
    ld b, d
    ld c, c
    ld b, e
    ld e, a
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
    xor $37
    ld b, l
    ld b, d
    ld h, d
    jr nc, @+$40

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
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
    ld e, a
    ld e, a
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
    xor $3f
    ld c, h
    ld c, h
    ld c, b
    ld h, h
    rst $38
    ldh a, [$a3]
    inc sp
    ld b, d
    ld c, h
    ld c, l
    ld c, c
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $51
    ld a, $49
    ld c, b
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $3f
    ld c, c
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $43
    ld b, d
    ld d, h
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $40
    ld a, $4b
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
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, c
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, d
    ld c, l
    ld c, h
    ld c, a
    ld d, c
    ld a, $4b
    ld d, c
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    rst $28
    xor $3f
    ld d, d
    ld d, c
    ld h, d
    ld a, $49
    ld d, b
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $49
    ld b, [hl]
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
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $a3
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
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
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $a3
    ld a, $4b
    ld b, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $3e
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
    ccf
    ld d, [hl]
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
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
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
    ccf
    ld b, d
    ld h, d
    ld a, $ef
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $3a
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
    ld h, d
    ld b, c
    ld c, h
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    scf
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
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $52
    ld c, l
    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
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
    ld a, [hl+]
    ld c, h
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $50
    ld c, b
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld d, c
    ld c, h
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
    ld d, b
    ld c, h
    ld c, d
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
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_042_56d2

    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    rst $28
    xor $45
    ld a, $50
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld c, c
    ld c, h
    ld d, b
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
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
    ld h, d
    ld d, h
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d

jr_042_56d2:
    ld b, l
    ld c, h
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $3a
    ld b, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, e
    ld h, d
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
    ld c, c
    ld b, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld a, [$eff7]
    xor $4c
    ld b, e
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
    add hl, hl
    ld c, a
    ld a, $44
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $49
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
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
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
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
    xor $f3
    sbc a
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
    ld e, [hl]
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
    ld d, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl], $45
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld b, d
    ld a, $51
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
    ld d, c
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld [hl-], a
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, [hl]
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld d, c
    ld d, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld b, d
    ld c, e
    ld d, c
    rst $28
    xor $4d
    ld c, h
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld d, b
    ld a, $46
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $49
    ld b, [hl]
    ld b, e
    ld b, d
    ld e, a
    ld a, [$eff7]
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
    ld a, $62
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
    ld b, l
    ld b, d
    ld c, c
    ld b, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
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
    scf
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
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld c, e
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
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld c, l
    ld c, a
    ld b, d
    ld d, b
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
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
    add hl, hl
    ld b, [hl]
    ld b, h
    ld b, l
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
    xor $44
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
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
    xor $4a
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
    inc sp
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, e
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld b, h
    ld d, d
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr c, jr_042_5b8e

    ld c, l
    ld b, d
    ld c, a
    ld h, d
    ld b, e
    ld c, c
    ld c, h
    ld c, h
    ld c, a
    ld e, [hl]
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
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    rst $28
    xor $4c
    ld b, e
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
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld h, d
    ld d, c
    ld b, l

jr_042_5b8e:
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    rst $28
    xor $52
    ld d, b
    ld h, d
    ld b, b
    ld a, $4d
    ld a, $3f
    ld c, c
    ld b, d
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
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld h, d
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
    xor $54
    ld b, [hl]
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
    xor $51
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    rst $28
    xor $48
    ld b, [hl]
    ld b, c
    ld c, e
    ld a, $4d
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
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
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
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
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld a, $4b
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
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
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    inc l
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld e, a
    rst $30
    ldh a, [$f6]
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    daa
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    daa
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $4f
    ld d, d
    ld d, b
    ld b, l
    ld e, a
    ld h, d
    ld a, [hl+]
    ld c, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $634c
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $45
    ld d, d
    ld c, a
    ld d, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld a, $49
    ld c, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld d, c
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
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    xor $2f
    ld b, [hl]
    ld c, l
    ld d, b
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld b, b
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    rst $28
    xor $56
    ld b, d
    ld d, c
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld d, d
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
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
    xor $50
    ld b, [hl]
    ld b, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $a3
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
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
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
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
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $42
    ld d, e
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld b, d
    ld a, $51
    scf
    ld c, a
    ld b, d
    ld b, d
    ld l, b
    rst $28
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld d, c
    ld b, l
    ld e, a
    ld a, [$eff7]
    xor $a3
    scf
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    rst $28
    xor $51
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld d, b
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
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
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld c, c
    ld b, d
    ld d, c
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
    ld d, b
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    jr nc, jr_042_5e97

    ld e, a
    jr nc, jr_042_5e97

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
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $40
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld d, d
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld a, $51
    ld b, b
    ld b, l

jr_042_5e97:
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, a
    ld a, $4f
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $40
    ld a, $51
    ld b, b
    ld b, l
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
    ld a, [$f0f7]
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
    ld b, h
    ld a, $4f
    ccf
    ld a, $44
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4a
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $50
    ld d, c
    ld b, d
    ld a, $49
    ld h, d
    ld c, d
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
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld h, $6a
    ld c, h
    ld c, e
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld a, $62
    ccf
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, e
    ld h, d
    ld d, b
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, e
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
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
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
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $50
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld e, a
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
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld a, $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
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
    ld e, a
    rst $28
    xor $fa
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
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $44
    ld b, d
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
    ld h, h
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    rst $28
    xor $2c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
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
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    scf
    ld a, $48
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
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    rst $28
    xor $3e
    ld b, b
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc l
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
    rst $28
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
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld h, d
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ccf
    ld e, a
    rst $28
    xor $2c
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $53
    ld c, h
    ld c, a
    ld b, [hl]
    ld d, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld h, $45
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    rst $28
    xor $96
    inc sp
    inc l
    ld h, $2e
    ld h, d
    jr c, jr_042_6170

    sub a
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
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
    ld e, a
    rst $28
    xor $f0
    db $eb
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld [hl], $49
    ld b, [hl]
    ld c, h
    ld e, a
    ld h, d
    inc l
    ld h, d
    rst $28
    xor $3e
    ld c, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d

jr_042_6170:
    ld b, h
    ld c, a
    ld a, $4b
    ld b, c
    ld d, b
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld a, [hl+]
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $62
    ld [hl], $49
    ld b, [hl]
    ccf
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
    daa
    ld l, e
    ld a, $62
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
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
    ld [hl], $49
    ld b, [hl]
    ld c, h
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
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld d, b
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
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
    xor $40
    ld a, $4b
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
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
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
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
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec h
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
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $44
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    rst $28
    xor $46
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld a, [$eff7]
    xor $54
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
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4f
    ld b, d
    ld a, $40
    ld b, l
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
    ld e, [hl]
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $49
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, l
    ld d, d
    ld d, c
    rst $28
    xor $3e
    ld c, c
    ld c, c
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $ef
    xor $41
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $41
    ld c, a
    ld c, h
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld bc, $6209
    ld c, d
    ld c, h
    ld c, a
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
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$eff7]
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc h
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $4f
    ld b, d
    ld a, $40
    ld b, l
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
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld a, $4f
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
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
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $51
    ld a, $48
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
    ld a, [$eff7]
    xor $54
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
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, a
    rst $30
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld a, $46
    ld d, b
    ld b, d
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    daa
    ld l, e
    ld a, $62
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $ef
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $51
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
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $4a
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
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld c, d
    ld b, d
    ld c, a
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld l, b
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
    or $63
    ld h, d
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    rst $28
    xor $41
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $41
    ld c, h
    ld c, l
    ld d, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    dec hl
    ld d, d
    ld b, l
    ld h, h
    ld h, d
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $37
    ld b, l
    ld a, $51
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, e
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
    dec hl
    ld b, d
    ld h, d
    ld c, d
    ld d, d
    ld d, b
    ld d, c
    ld l, h
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
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
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
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
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, e
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, e
    rst $28
    xor $25
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $30
    ld a, $47
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld e, [hl]
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    jr nc, jr_042_665e

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    rst $28
    xor $4d
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld c, h
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc h
    ld c, a
    ld c, a
    ld b, h
    ld b, l
    ld h, e
    ld h, d

jr_042_665e:
    inc a
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld d, [hl]
    ld a, [$eff7]
    xor $4d
    ld c, a
    ld b, d
    ld b, b
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    rst $28
    xor $42
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
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
    xor $37
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld b, l
    ld b, [hl]
    ld c, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld d, d
    ld c, e
    ld b, h
    ld b, d
    ld c, h
    ld c, e
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $3c
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
    ld h, h
    ld h, e
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
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $40
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $43
    ld c, a
    ld b, d
    ld b, d
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, h
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
    ld d, b
    ld a, $56
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
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld h, h
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    jr c, jr_042_67ac

    ld c, d
    ld c, d
    ld e, a
    ld e, a
    ld e, a
    ld [hl], $4c
    ld d, d
    ld c, e
    ld b, c
    ld d, b
    rst $28
    xor $46
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4a
    ld a, $56
    ld h, d
    ld d, c
    ld c, a
    ld d, [hl]
    ld h, d
    or $5f
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    jr nc, jr_042_67d8

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    ld e, [hl]
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d

jr_042_67ac:
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
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
    ld e, a
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    inc l

jr_042_67d8:
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld e, a
    ld h, d
    ld sp, $544c
    rst $28
    xor $f6
    ld e, [hl]
    ld h, d
    ld c, l
    ld c, a
    ld c, h
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    rst $28
    xor $2a
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, [hl]
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, l
    ld a, $4f
    ld b, c
    ld c, h
    ld c, e
    rst $28
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld e, a
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
    ld d, c
    ld c, a
    ld b, d
    ld a, $50
    ld d, d
    ld c, a
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld e, a
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc h
    ld d, b
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
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
    ld a, $4f
    ld b, d
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld e, a
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
    dec hl
    ld b, [hl]
    ld d, b
    ld h, d
    jr nc, jr_042_6926

    ld b, a
    ld b, d
    ld d, b
    ld d, c
    ld d, [hl]
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $53
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, d
    ld c, l
    ld d, b
    ld b, d
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
    ld c, l
    ld c, a
    ld c, h
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l

jr_042_6926:
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    or $5e
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, a
    ld a, $44
    ld b, d
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $f6
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
    rst $28
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
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld h, $45
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    rst $28
    xor $4c
    ld b, e
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld b, d
    ld d, l
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld c, a
    ld a, $49
    ld d, b
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
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld d, b
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
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
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld b, c
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
    xor $49
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $50
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
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
    ld c, c
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    or $5e
    rst $28
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $52
    ld c, c
    ld d, c
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
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld e, [hl]
    rst $28
    xor $49
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
    ld a, $62
    ld a, $fa
    rst $30
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
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
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $52
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld [hl-], a
    jr c, jr_042_6b7a

    ld sp, $2f24
    rst $28
    xor $52
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl-], a
    inc sp
    scf
    ld sp, $f75f
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    rst $28
    xor $3f
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c

jr_042_6b7a:
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $26
    ld b, l
    ld a, $4a
    ccf
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld b, e
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
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $2b
    ld a, $49
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld a, $50
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    scf
    ld c, a
    ld a, $53
    ld b, d
    ld c, c
    ld b, d
    ld c, a
    ld d, b
    ld e, h
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld d, b
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $50
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $4b
    ld h, d
    ld a, $49
    ld b, [hl]
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
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
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $4a
    ld a, $44
    ld b, [hl]
    ld b, b
    ld a, $49
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld d, h
    ld a, $4f
    ld c, l
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld b, d
    ld d, l
    ld d, c
    ld a, [$eff7]
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
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
    xor $3e
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $49
    ld a, $50
    ld d, c
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld d, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld b, c
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
    ld a, [$eff7]
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
    ld d, b
    ld b, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $4d
    ld h, d
    ld c, h
    ld b, e
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
    ld l, h
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld c, l
    ld c, a
    ld b, d
    ld d, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $36
    jr z, jr_042_6dac

    jr z, jr_042_6da5

    scf
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld d, c
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld d, b
    rst $28
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]

jr_042_6da5:
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3e

jr_042_6dac:
    ld c, a
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4a
    ld d, [hl]
    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
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
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, b
    ld b, b
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr c, @+$52

    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld d, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $3e
    ld b, c
    ld d, e
    ld b, d
    ld c, e
    ld d, c
    ld d, d
    ld c, a
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
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $40
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld [bc], a
    nop
    ld a, [$eff7]
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld a, $49
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld c, l
    ld b, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld l, $46
    ld c, e
    ld b, h
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
    ld b, c
    ld b, [hl]
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    rst $28
    xor $3e
    ld d, h
    ld a, $56
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld d, e
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4f
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $4c
    ld c, l
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
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
    ld e, [hl]
    rst $28
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
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld a, $4f
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
    xor $37
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
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
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec hl
    ld a, $49
    ld b, d
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld l, c
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4c
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    or $63
    rst $30
    ldh a, [$eb]
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
    ld h, d
    ld b, c
    ld c, h
    ld e, a
    rst $28
    xor $2c
    ld l, d
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $45
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $25
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
    xor $43
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, h
    ld c, h
    ld h, d
    ccf
    ld a, $40
    ld c, b
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
    ld a, $4f
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
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, [hl]
    ld a, [$eff7]
    xor $f6
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
    ld e, [hl]
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
    ccf
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    ld h, e
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    dec hl
    ld a, $49
    ld b, d
    rst $28
    xor $50
    ld a, $46
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $3f
    ld a, $40
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, h
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
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld a, $46
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $4f
    ld a, $51
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld b, a
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld e, a
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld b, d
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
    dec hl
    ld c, d
    ld c, d
    and h
    ld h, d
    inc a
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    xor $3a
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc l
    ld l, d
    ld h, d
    ld c, l
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld b, d
    ld c, a
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld a, [$eff7]
    xor $44
    ld c, h
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    inc sp
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
    ld h, e
    ld h, d
    ld sp, $544c
    ld h, d
    inc l
    ld a, [$eff7]
    xor $40
    ld a, $4b
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
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    ld l, $46
    ld c, e
    ld b, h
    and e
    or $5f
    rst $28
    xor $2a
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5f
    ld a, [$eff7]
    xor $2e
    ld b, [hl]
    ld c, e
    ld b, h
    and e
    inc a
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, a
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    rst $28
    xor $3e
    ld c, a
    ld b, d
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
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5f
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
    ld b, b
    ld a, $4b
    rst $28
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
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $41
    ld b, d
    ld b, e
    ld b, d
    ld a, $51
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
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
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld e, a
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
    ld [hl], $49
    ld b, [hl]
    ld c, h
    and e
    or $63
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
    ld a, [$eff7]
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl+]
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $62
    ld [hl], $49
    ld b, [hl]
    ccf
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
    ld c, l
    ld c, a
    ld c, h
    ld d, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld c, e
    ld a, $5e
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld a, $46
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $4c
    ld d, d
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
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
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
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
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld d, b
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $52
    ld c, l
    ld h, d
    ld d, c
    ld c, h
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
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $28
    xor $f7
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
    xor $fa
    rst $30
    rst $28
    xor $f3
    sbc a
    and e
    add hl, hl
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
    ld b, d
    rst $28
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
    ld e, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld a, [$eff7]
    xor $41
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ccf
    ld c, h
    ld d, [hl]
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld d, b
    ld h, d
    ld b, c
    ld a, $4b
    ld b, h
    ld b, d
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $32
    ld b, l
    ld e, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld h, e
    rst $28
    xor $f7
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
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $53
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, $44
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
    xor $fa
    rst $30
    rst $28
    xor $f3
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
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    add hl, hl
    ld b, l
    ld b, d
    ld d, h
    ld h, e
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld b, h
    ld c, c
    ld a, $41
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld a, [$eff7]
    xor $45
    ld d, d
    ld c, a
    ld d, c
    ld h, e
    ld h, d
    inc l
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
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld a, $4f
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    or $5e
    rst $28
    xor $46
    ld d, c
    ld l, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld a, $4a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, c
    ld b, c
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
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $50
    ld d, c
    ld a, $46
    ld c, a
    ld d, b
    ld h, d
    ld b, l
    ld d, d
    ld c, a
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc a
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
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $64
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    inc l
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $3e
    ld h, d
    scf
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_042_7650

    ld b, c
    ld a, $49
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $50
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
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

jr_042_7650:
    ld h, d
    ld a, [hl+]
    ld a, $51
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    cpl
    ld b, d
    ld d, c
    ld h, d
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
    ld a, [$eff7]
    xor $52
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
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
    ld a, [$eff7]
    xor $50
    ld c, h
    ld c, d
    ld b, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $43
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld c, d
    ld a, $49
    ld c, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
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
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
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
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld d, b
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld d, [hl]
    ld c, h
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
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
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
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
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
    ld b, b
    ld a, $4b
    ld h, d
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld d, b
    ld a, [$eff7]
    xor $4c
    ld c, e
    ld c, c
    ld d, [hl]
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
    xor $4a
    ld a, $51
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld c, e
    ld a, $5f
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
    ld d, c
    ld b, l
    ld a, $51
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
    ld d, b
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
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
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld a, $50
    ld d, c
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
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
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld e, [hl]
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld c, d
    ld a, $51
    ld b, b
    ld b, l
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
    ld c, a
    ld a, $46
    ld c, e
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
    ld c, h
    ld c, a
    ld h, d
    ld a, $41
    ld b, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $4b
    ld b, d
    ld d, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_042_794d

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
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

jr_042_791b:
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    daa
    ld b, d
    ld c, l
    ld b, d
    ld c, e
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $33
    cpl
    inc h
    ld sp, $5262
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $3f
    ld a, $51
    ld d, c
    ld c, c

jr_042_794d:
    ld b, d
    ld d, b
    ld e, [hl]
    ld d, c
    ld b, l
    ld b, d
    ld b, [hl]
    ld c, a
    rst $28
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
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    sub [hl]
    ld h, $2b
    inc h
    dec [hl]
    ld a, [hl+]
    jr z, jr_042_791b

    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld a, $53
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
    sub [hl]
    jr nc, jr_042_79ec

    dec sp
    jr z, jr_042_79ea

    sub a
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld b, e
    ld d, d

jr_042_79ea:
    ld c, c
    ld e, a

jr_042_79ec:
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    rst $28
    xor $96
    ld h, $24
    jr c, jr_042_7a3a

    inc l
    ld [hl-], a
    jr c, jr_042_7a3d

    sub a
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $40
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    rst $28
    xor $40
    ld c, h
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld c, a
    ld a, $51
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    jr nc, jr_042_7a78

jr_042_7a3a:
    ld d, b
    ld d, c
    ld b, d

jr_042_7a3d:
    ld c, a
    ld h, e
    ld h, d
    daa
    ld l, e
    ld a, $ef
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, h
    rst $38
    ldh a, [$36]
    ld c, l
    ld c, c
    ld a, $51
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $33
    ld c, h
    ld c, h
    ld c, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld h, d
    or $5f
    rst $30
    ldh a, [$37]
    ld b, l
    ld d, h
    ld a, $40
    ld c, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $f3

jr_042_7a78:
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3e
    ld h, d
    ld [hl], $48
    ld d, [hl]
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $45
    ld b, [hl]
    ld d, c
    ld h, d
    or $68
    rst $28
    xor $45
    ld b, d
    ld a, $41
    ld h, e
    ld h, e
    rst $30
    ldh a, [$f6]
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $36
    ld c, b
    ld d, [hl]
    daa
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $25
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
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
    ld b, b
    ld a, $4f
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld a, $4f
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [rNR52]
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, b
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $42
    ld b, h
    ld b, h
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
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    rst $28
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
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    rst $28
    xor $3e
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    rst $28
    xor $40
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $40
    ld a, $4f
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    rst $28
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld b, e
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
    xor $33
    ld c, h
    ld c, h
    ld c, l
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld h, d
    or $5f
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, e
    rst $28
    xor $25
    ld b, d
    ld b, d
    ld b, e
    dec l
    ld b, d
    ld c, a
    ld c, b
    ld d, [hl]
    ld e, [hl]
    ld a, [$eff7]
    xor $33
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ld e, [hl]
    rst $28
    xor $35
    ld b, [hl]
    ccf
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld b, d
    ld b, d
    ld b, e
    dec l
    ld b, d
    ld c, a
    ld c, b
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld d, c
    ld a, $50
    ld d, c
    ld d, [hl]
    ld h, e
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
    ccf
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $51
    ld b, l
    ld a, $4b
    ld h, d
    inc sp
    ld c, h
    ld c, a
    ld c, b
    ld h, $45
    ld c, h
    ld c, l
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld [hl], $46
    ld c, a
    ld c, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld b, d
    ld d, b
    ld d, c
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld l, b
    ld h, d
    ld a, $50
    ld h, d
    ld d, [hl]
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $3e
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld h, e
    rst $30
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
    ld d, c
    ld a, $48
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
    ld c, h
    ld c, e
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
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
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
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld a, [$eff7]
    xor $3e
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld e, [hl]
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld c, h
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
    dec h
    ld d, d
    ld d, c
    ld e, [hl]
    ld b, [hl]
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld e, [hl]
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, h
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
    rst $28
    xor $4f
    ld b, d
    ld b, d
    ld b, d
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
