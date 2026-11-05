; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $04b", ROMX[$4000], BANK[$4b]

    db $4B ; Bank number

    ; Cross-bank dispatch table (68 entries)
    ; Called via: ld hl, $4BXX / rst $10
    dw LoadB4b_4089                  ; Entry 0
    dw TextRunB4B_40a1               ; Entry 1
    dw TextShowRefreshB4B_40b9       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_4b_40d1               ; Entry 4 — [table $4009]; text $07C0 "Watabou:[HERO], so you made it! W…"
    dw TextStr_4b_420e               ; Entry 5 — text $07C1 "Watabou:There are still Travelers…"
    dw TextStr_4b_42c0               ; Entry 6 — text $07C2 "Watabou:You made it! [HERO]!! You…"
    dw TextStr_4b_4328               ; Entry 7 — text $07C3 "Watabou:Oh well, you don't need m…"
    dw TextStr_4b_4365               ; Entry 8 — text $07C4 "Watabou:Hey, you have too many pa…"
FuncB4b_4013:
    dw $43CD                          ; Entry 9 — text $07C5 "Watabou:Good to meet you [HERO]. …"
    dw $44AF                          ; Entry 10 — text $07C6 "*:Watabou's magic spell Chance, i…"
    dw $44EA                          ; Entry 11 — text $07C7 "*:[HERO]! Oh it's [HERO]! Welcome…"
    dw $45C8                          ; Entry 12 — text $07C8 "*:Are you scared?"
    dw $45DE                          ; Entry 13 — text $07C9 "*:Want to listen to the descripti…"
    dw $4617                          ; Entry 14 — text $07CA "*:Giggle... It'll be there after …"
    dw $464A                          ; Entry 15 — text $07CB "*:Oh [HERO]!, Good luck! *kiss*"
    dw $4668                          ; Entry 16 — text $07CC "*:Are you ready to challenge the …"
    dw $46A6                          ; Entry 17 — text $07CD "*:If you survive him, there will …"
    dw $46F0                          ; Entry 18 — text $07CE "King:No, it's not an exaggeration…"
    dw $479B                          ; Entry 19 — text $07CF "*:The Master Monster Tamer will b…"
    dw $4818                          ; Entry 20 — text $07D0 "*:You survived D class! *:I'm sti…"
    dw $48BB                          ; Entry 21 — text $07D1 "*:Ho Ho, Well done! You defeated …"
    dw $49AA                          ; Entry 22 — text $07D2 "*:[HERO], to tell you the truth..…"
    dw $4A49                          ; Entry 23 — text $07D3 "*:Oh [HERO]! You really won! *:Aw…"
    db $8D                            ; Entry 24 low ($4A8D)
DataB4b_4032:
    db $4A                            ; Entry 24 high
    dw $4ABB                          ; Entry 25 — text $07D5 "*:What? Where are you? *:Well wha…"
    dw $4B2F                          ; Entry 26 — text $07D6 "*:Oh no! You tripped over didn't …"
    dw $4B9F                          ; Entry 27 — text $07D7 "*:[HERO]! Congratulations on your…"
    dw $4D0E                          ; Entry 28 — text $07D8 "*:I..I heard that monsters exist …"
    dw $4E00                          ; Entry 29 — text $07D9 "*:Hork looks contently at [HERO]."
    dw $4E24                          ; Entry 30 — text $07DA "*:That's it everyone."
    dw $4E3C                          ; Entry 31 — text $07DB "*:One of my friends from abroad i…"
    dw $4EB3                          ; Entry 32 — text $07DC "*:You! I heard you finally made W…"
    dw $4EF8                          ; Entry 33 — text $07DD "*:A Servant has 4 hands, Skeletor…"
    dw $4F53                          ; Entry 34 — text $07DE "*:The bishop I know told me an in…"
    dw $5039                          ; Entry 35 — text $07DF "*:The guy at the entrance to the …"
    dw $5119                          ; Entry 36 — text $07E0 "*:My slime learned an amazing ski…"
    dw $5191                          ; Entry 37 — text $07E1 "*:Hurray! I understand now! *:I c…"
    dw $5268                          ; Entry 38 — text $07E2 "*:Hey hey hey! Run! Don't walk! *…"
    dw $528D                          ; Entry 39 — text $07E3 "*:Yo, dude, go to the reception. …"
    dw $52D0                          ; Entry 40 — text $07E4 "*:Yo, dude, wanna know about Mast…"
    dw $5315                          ; Entry 41 — text $07E5 "*:He has GoldSlime Divinegon, & R…"
    dw $53B9                          ; Entry 42 — text $07E6 "*:Hurray! I understand now! *:I c…"
    dw $5490                          ; Entry 43 — text $07E7 "*:Darn! You really defeated the M…"
    dw $54E0                          ; Entry 44 — text $07E8 "*:It's a HorrorBK. Take good care…"
    dw $5510                          ; Entry 45 — text $07E9 "*:You, must obey! *:Bring me a Ph…"
    dw $5574                          ; Entry 46 — text $07EA "*:This is Natto. repeat after me,…"
    dw $55A4                          ; Entry 47 — text $07EB "*:Natto? What's that? You're maki…"
    dw $5606                          ; Entry 48 — text $07EC "*:Victory... You've conquered one…"
    dw $569A                          ; Entry 49 — text $07ED "*:You won! But you know there is …"
    dw $579C                          ; Entry 50 — text $07EE "*:Y..you defeated the Master Mons…"
    dw $5835                          ; Entry 51 — text $07EF "*:I also was brought here by Wata…"
    dw $59B7                          ; Entry 52 — text $07F0 "*:Ha Ha Ha! I made a comeback! *:…"
    dw $5B94                          ; Entry 53 — text $07F1 "*:You...! I have nothing to say. …"
    dw $5CAD                          ; Entry 54 — text $07F2 "*:Splash, splash! Congratulations…"
    dw $5D46                          ; Entry 55 — text $07F3 "*:Congratulations on your victory…"
    dw $5E00                          ; Entry 56 — text $07F4 ":[HERO] looks at the bookshelf. :…"
    dw $5E7A                          ; Entry 57 — text $07F5 ":At last, [HERO] will compete in …"
    dw $5F0C                          ; Entry 58 — text $07F6 ":At last, [HERO] got a victory! :…"
    dw $6088                          ; Entry 59 — text $07F7 "*:I heard you won with style. *:T…"
    dw $60EE                          ; Entry 60 — text $07F8 "*:Hey, listen! A different monste…"
    dw $61BA                          ; Entry 61 — text $07F9 "*:Where did those millions of sta…"
    dw $6207                          ; Entry 62 — text $07FA "*:Hi [HERO]! Welcome home! *:How …"
    dw $626B                          ; Entry 63 — text $07FB "*:Congratulations on your victory…"
    dw $62DD                          ; Entry 64 — text $07FC "*:Just kidding! You're still a ki…"
    dw $6308                          ; Entry 65 — text $07FD "*:My hubby loves our girl so much…"
    dw $6352                          ; Entry 66 — text $07FE ":Steps of My Baby Part 4 :I guess…"
    dw $6419                          ; Entry 67 — text $07FF ":Steps of My Baby Part 5 :I came …"

LoadB4b_4089:
    ld a, [$c822]
    cp $01
    jr nz, jr_04b_409a

    ld a, $00
    ld [$c822], a
    ld hl, $3f08
    rst $10
    ret


jr_04b_409a:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB4B_40a1:
    ld a, [$c822]
    cp $01
    jr nz, jr_04b_40b2

    ld a, $00
    ld [$c822], a
    ld hl, $3f09
    rst $10
    ret


jr_04b_40b2:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB4B_40b9:
    ld a, [$c822]
    cp $01
    jr nz, jr_04b_40ca

    ld a, $00
    ld [$c822], a
    ld hl, $3f0a
    rst $10
    ret


jr_04b_40ca:
    call LoadB4b_4089
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $4b: $40d1-$7ffe) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_4b_40d1:           ; id $07C0
    ; "Watabou:[HERO], so you made it! / Watabou:I told you [HERO], I'll / be your pal... / Watabou:But I won't become your / pal so easily... / Wa..."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $f6, $5e, $ef, $ee, $50, $4c, $62
    db $56, $4c, $52, $62, $4a, $3e, $41, $42, $62, $46, $51, $63, $fa, $f7, $ef, $ee
    db $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2c, $62, $51, $4c, $49, $41, $ef, $ee
    db $56, $4c, $52, $62, $f6, $5e, $62, $2c, $66, $49, $fa, $f7, $ef, $ee, $3f, $42
    db $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $5f, $5f, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $25, $52, $51, $62, $2c, $ef
    db $ee, $54, $4c, $4b, $67, $62, $3f, $42, $40, $4c, $4a, $42, $62, $56, $4c, $52
    db $4f, $fa, $f7, $ef, $ee, $4d, $3e, $49, $62, $50, $4c, $62, $42, $3e, $50, $46
    db $49, $56, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $a3, $37, $45, $42, $4f, $42, $ef, $ee, $3e, $4f, $42, $62, $50, $51
    db $46, $49, $49, $fa, $f7, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $62, $2a, $3e, $51, $42, $50, $ef, $ee, $51, $45, $3e, $51, $62, $f6, $62
    db $45, $3e, $50, $4b, $67, $fa, $f7, $ef, $ee, $42, $55, $4d, $49, $4c, $4f, $42
    db $41, $62, $56, $42, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e
    db $3f, $4c, $52, $a3, $25, $42, $3e, $51, $62, $3e, $49, $49, $ef, $ee, $51, $45
    db $42, $62, $50, $51, $4f, $4c, $4b, $44, $42, $50, $51, $fa, $f7, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42, $45, $46, $4b, $41, $ef, $ee
    db $51, $45, $42, $62, $2a, $3e, $51, $42, $50, $5f, $fa, $f7, $ef, $ee, $3a, $3e
    db $51, $3e, $3f, $4c, $52, $a3, $3e, $4b, $41, $62, $2c, $66, $49, $ef, $ee, $3f
    db $42, $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $5f, $f7, $f0
TextStr_4b_420e:           ; id $07C1
    ; "Watabou:There are still / Travelers' Gates that [HERO] hasn't / explored yet. / Watabou:Beat all the strongest / monsters behind the Gates /..."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $37, $45, $42, $4f, $42, $ef, $ee
    db $3e, $4f, $42, $62, $50, $51, $46, $49, $49, $fa, $f7, $ef, $ee, $37, $4f, $3e
    db $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $ef, $ee, $51
    db $45, $3e, $51, $62, $f6, $62, $45, $3e, $50, $4b, $67, $fa, $f7, $ef, $ee, $42
    db $55, $4d, $49, $4c, $4f, $42, $41, $62, $56, $42, $51, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $25, $42, $3e, $51, $62, $3e
    db $49, $49, $ef, $ee, $51, $45, $42, $62, $50, $51, $4f, $4c, $4b, $44, $42, $50
    db $51, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42
    db $45, $46, $4b, $41, $ef, $ee, $51, $45, $42, $62, $2a, $3e, $51, $42, $50, $fa
    db $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3e, $4b, $41, $62, $2c
    db $66, $49, $ef, $ee, $3f, $42, $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $5f
    db $f7, $f0
TextStr_4b_42c0:           ; id $07C2
    ; "Watabou:You made it! [HERO]!! / You beat'em all! / Watabou:As I promised, I'll be / your pal, okay? [YES/NO]"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3c, $4c, $52, $62, $4a, $3e, $41
    db $42, $ef, $ee, $46, $51, $63, $62, $f6, $63, $63, $fa, $f7, $ef, $ee, $3c, $4c
    db $52, $62, $3f, $42, $3e, $51, $6e, $4a, $62, $3e, $49, $49, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $24, $50, $62, $2c, $ef
    db $ee, $4d, $4f, $4c, $4a, $46, $50, $42, $41, $5e, $62, $2c, $66, $49, $62, $3f
    db $42, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $5e, $62, $4c
    db $48, $3e, $56, $64, $ef, $ee, $ff, $f0
TextStr_4b_4328:           ; id $07C3
    ; "Watabou:Oh well, you don't need / me... [HERO], you're strong."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $32, $45, $62, $54, $42, $49, $49
    db $5e, $ef, $ee, $56, $4c, $52, $62, $41, $4c, $4b, $67, $62, $4b, $42, $42, $41
    db $fa, $f7, $ef, $ee, $4a, $42, $5f, $5f, $5f, $62, $f6, $5e, $ef, $ee, $56, $4c
    db $52, $69, $42, $62, $50, $51, $4f, $4c, $4b, $44, $5f, $f7, $f0
TextStr_4b_4365:           ; id $07C4
    ; "Watabou:Hey, you have too many / pals! / Watabou:Sorry but I don't think / I can be your pal."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2b, $42, $56, $5e, $62, $56, $4c
    db $52, $ef, $ee, $45, $3e, $53, $42, $62, $51, $4c, $4c, $62, $4a, $3e, $4b, $56
    db $fa, $f7, $ef, $ee, $4d, $3e, $49, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3a
    db $3e, $51, $3e, $3f, $4c, $52, $a3, $36, $4c, $4f, $4f, $56, $ef, $ee, $3f, $52
    db $51, $62, $2c, $62, $41, $4c, $4b, $67, $62, $51, $45, $46, $4b, $48, $fa, $f7
    db $ef, $ee, $2c, $62, $40, $3e, $4b, $62, $3f, $42, $62, $56, $4c, $52, $4f, $62
    db $4d, $3e, $49, $5f, $ef, $ee, $f7, $f0
TextStr_4b_43cd:           ; id $07C5
    ; "Watabou:Good to meet you [HERO]. / I'll be waiting for ya at the / farm! / Watabou:and thanks for / winning! / Watabou:Warubou of GreatLog s..."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $2a, $4c, $4c, $41, $62, $51, $4c
    db $ef, $ee, $4a, $42, $42, $51, $62, $56, $4c, $52, $62, $f6, $5f, $fa, $f7, $ef
    db $ee, $2c, $66, $49, $62, $3f, $42, $62, $54, $3e, $46, $51, $46, $4b, $44, $ef
    db $ee, $43, $4c, $4f, $62, $56, $3e, $62, $3e, $51, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $43, $3e, $4f, $4a, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51
    db $3e, $3f, $4c, $52, $a3, $3e, $4b, $41, $ef, $ee, $51, $45, $3e, $4b, $48, $50
    db $62, $43, $4c, $4f, $fa, $f7, $ef, $ee, $54, $46, $4b, $4b, $46, $4b, $44, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $3a, $3e
    db $4f, $52, $3f, $4c, $52, $ef, $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $2f
    db $4c, $44, $62, $50, $42, $42, $4a, $42, $41, $fa, $f7, $ef, $ee, $50, $51, $42
    db $3e, $4a, $42, $41, $63, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f
    db $4c, $52, $a3, $37, $45, $3e, $4b, $48, $50, $ef, $ee, $51, $4c, $62, $56, $4c
    db $52, $5e, $62, $4b, $42, $54, $fa, $f7, $ef, $ee, $50, $4d, $46, $4f, $46, $51
    db $50, $62, $54, $42, $4f, $42, $ef, $ee, $3f, $4c, $4f, $4b, $5f, $5f, $5f, $63
    db $f7, $f0
TextStr_4b_44af:           ; id $07C6
    ; "*:Watabou's magic spell / Chance, is very interesting."
    db $eb, $9f, $a3, $3a, $3e, $51, $3e, $3f, $4c, $52, $68, $ef, $ee, $4a, $3e, $44
    db $46, $40, $62, $50, $4d, $42, $49, $49, $fa, $f7, $ef, $ee, $26, $45, $3e, $4b
    db $40, $42, $5e, $62, $46, $50, $62, $53, $42, $4f, $56, $ef, $ee, $46, $4b, $51
    db $42, $4f, $42, $50, $51, $46, $4b, $44, $5f, $f7, $f0
TextStr_4b_44ea:           ; id $07C7
    ; "*:[HERO]! Oh it's [HERO]! Welcome! / *:As a matter of fact, there's / somebody who wants to / challenge you. / *:You'll find out who it is i..."
    db $ea, $9f, $a3, $f6, $63, $62, $32, $45, $62, $46, $51, $68, $ef, $ee, $f6, $63
    db $62, $3a, $42, $49, $40, $4c, $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $24
    db $50, $62, $3e, $62, $4a, $3e, $51, $51, $42, $4f, $62, $4c, $43, $ef, $ee, $43
    db $3e, $40, $51, $5e, $62, $51, $45, $42, $4f, $42, $68, $fa, $f7, $ef, $ee, $50
    db $4c, $4a, $42, $3f, $4c, $41, $56, $62, $54, $45, $4c, $ef, $ee, $54, $3e, $4b
    db $51, $50, $62, $51, $4c, $fa, $f7, $ef, $ee, $40, $45, $3e, $49, $49, $42, $4b
    db $44, $42, $62, $56, $4c, $52, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c
    db $4c, $52, $66, $49, $62, $43, $46, $4b, $41, $ef, $ee, $4c, $52, $51, $62, $54
    db $45, $4c, $62, $46, $51, $62, $46, $50, $62, $46, $4b, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $43, $46, $44, $45, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $3a, $45, $3e, $51, $62, $3e, $4f, $42, $62, $56, $4c, $52, $ef, $ee, $44
    db $4c, $46, $4b, $44, $62, $51, $4c, $62, $41, $4c, $64, $62, $27, $4c, $fa, $f7
    db $ef, $ee, $56, $4c, $52, $62, $3e, $40, $40, $42, $4d, $51, $62, $51, $45, $42
    db $ef, $ee, $40, $45, $3e, $49, $49, $42, $4b, $44, $42, $64, $ff, $f0
TextStr_4b_45c8:           ; id $07C8
    ; "*:Are you scared?"
    db $ea, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $50, $40, $3e, $4f, $42
    db $41, $64, $ef, $ee, $f7, $f0
TextStr_4b_45de:           ; id $07C9
    ; "*:Want to listen to the / description of the arena? [YES/NO]"
    db $eb, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $46, $50, $51, $42
    db $4b, $ef, $ee, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $41, $42, $50
    db $40, $4f, $46, $4d, $51, $46, $4c, $4b, $62, $4c, $43, $ef, $ee, $51, $45, $42
    db $62, $3e, $4f, $42, $4b, $3e, $64, $ff, $f0
TextStr_4b_4617:           ; id $07CA
    ; "*:Giggle... It'll be there / after the fight!"
    db $eb, $9f, $a3, $2a, $46, $44, $44, $49, $42, $5f, $5f, $5f, $ef, $ee, $2c, $51
    db $66, $49, $62, $3f, $42, $62, $51, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $3e
    db $43, $51, $42, $4f, $62, $51, $45, $42, $62, $43, $46, $44, $45, $51, $63, $ef
    db $ee, $f7, $f0
TextStr_4b_464a:           ; id $07CB
    ; "*:Oh [HERO]!, Good luck! *kiss*"
    db $eb, $9f, $a3, $32, $45, $62, $f6, $63, $5e, $ef, $ee, $2a, $4c, $4c, $41, $62
    db $49, $52, $40, $48, $63, $62, $9f, $48, $46, $50, $50, $9f, $f7, $f0
TextStr_4b_4668:           ; id $07CC
    ; "*:Are you ready to challenge the / Master Monster Tamer? [YES/NO]"
    db $ea, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $4f, $42, $3e, $41, $56
    db $ef, $ee, $51, $4c, $62, $40, $45, $3e, $49, $49, $42, $4b, $44, $42, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b
    db $50, $51, $42, $4f, $ef, $ee, $37, $3e, $4a, $42, $4f, $64, $ff, $f0
TextStr_4b_46a6:           ; id $07CD
    ; "*:If you survive him, there will / be nothing to fear in this world!"
    db $ea, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $50, $52, $4f, $53, $46, $53
    db $42, $ef, $ee, $45, $46, $4a, $5e, $62, $51, $45, $42, $4f, $42, $62, $54, $46
    db $49, $49, $fa, $f7, $ef, $ee, $3f, $42, $62, $4b, $4c, $51, $45, $46, $4b, $44
    db $62, $51, $4c, $62, $43, $42, $3e, $4f, $ef, $ee, $46, $4b, $62, $51, $45, $46
    db $50, $62, $54, $4c, $4f, $49, $41, $63, $f7, $f0
TextStr_4b_46f0:           ; id $07CE
    ; "King:No, it's not an exaggeration. / I'd do it! / King:...well, that's an / exaggeration. Ha Ha Ha Ha Ha! / King:Well, you're dismissed... /..."
    db $ea, $2e, $46, $4b, $44, $a3, $31, $4c, $5e, $62, $46, $51, $68, $62, $4b, $4c
    db $51, $ef, $ee, $3e, $4b, $62, $42, $55, $3e, $44, $44, $42, $4f, $3e, $51, $46
    db $4c, $4b, $5f, $fa, $f7, $ef, $ee, $2c, $6d, $62, $41, $4c, $62, $46, $51, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $5f, $5f, $5f, $54, $42
    db $49, $49, $5e, $ef, $ee, $51, $45, $3e, $51, $68, $62, $3e, $4b, $fa, $f7, $ef
    db $ee, $42, $55, $3e, $44, $44, $42, $4f, $3e, $51, $46, $4c, $4b, $5f, $ef, $ee
    db $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $63, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $5e, $62, $56, $4c
    db $52, $69, $42, $ef, $ee, $41, $46, $50, $4a, $46, $50, $50, $42, $41, $5f, $5f
    db $5f, $fa, $f7, $ef, $ee, $25, $52, $50, $56, $5e, $62, $25, $52, $50, $56, $5e
    db $ef, $ee, $25, $52, $50, $56, $5f, $5f, $5f, $f7, $f0
TextStr_4b_479b:           ; id $07CF
    ; "*:The Master Monster Tamer will / bring very strong monsters. / *:Hats off if you beat the Master / Monster Tamer!"
    db $eb, $9f, $a3, $37, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef, $ee, $30
    db $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $62, $54, $46, $49
    db $49, $fa, $f7, $ef, $ee, $3f, $4f, $46, $4b, $44, $62, $53, $42, $4f, $56, $62
    db $50, $51, $4f, $4c, $4b, $44, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $3e, $51, $50, $62, $4c, $43, $43, $62
    db $46, $43, $62, $56, $4c, $52, $ef, $ee, $3f, $42, $3e, $51, $62, $51, $45, $42
    db $62, $30, $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $30, $4c, $4b, $50, $51
    db $42, $4f, $62, $37, $3e, $4a, $42, $4f, $63, $ef, $ee, $f7, $f0
TextStr_4b_4818:           ; id $07D0
    ; "*:You survived D class! / *:I'm still in E class... / I have to try harder! / *:By the way [HERO], Let's / match our monsters! / *:I have Ic..."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $50, $52, $4f, $53, $46, $53, $42, $41, $ef
    db $ee, $27, $62, $40, $49, $3e, $50, $50, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $6a, $62, $50, $51, $46, $49, $49, $62, $46, $4b, $62, $28, $ef, $ee, $40, $49
    db $3e, $50, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $2c, $62, $45, $3e, $53, $42
    db $62, $51, $4c, $62, $51, $4f, $56, $ef, $ee, $45, $3e, $4f, $41, $42, $4f, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $25, $56, $62, $51, $45, $42, $62, $54, $3e, $56
    db $ef, $ee, $f6, $5e, $62, $2f, $42, $51, $68, $fa, $f7, $ef, $ee, $4a, $3e, $51
    db $40, $45, $62, $4c, $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $2c, $40
    db $42, $30, $3e, $4b, $5e, $ef, $ee, $49, $42, $51, $68, $62, $4a, $3e, $51, $40
    db $45, $5f, $f0
TextStr_4b_48bb:           ; id $07D1
    ; "*:Ho Ho, Well done! You / defeated the Master Monster / Tamer! / *:Now you have nothing to fear! / *:Why don't you go on a trip / to collect..."
    db $ea, $9f, $a3, $2b, $4c, $62, $2b, $4c, $5e, $62, $3a, $42, $49, $49, $ef, $ee
    db $41, $4c, $4b, $42, $63, $62, $3c, $4c, $52, $fa, $f7, $ef, $ee, $41, $42, $43
    db $42, $3e, $51, $42, $41, $62, $51, $45, $42, $ef, $ee, $30, $3e, $50, $51, $42
    db $4f, $62, $30, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $37, $3e, $4a
    db $42, $4f, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $54, $62, $56
    db $4c, $52, $62, $45, $3e, $53, $42, $ef, $ee, $4b, $4c, $51, $45, $46, $4b, $44
    db $62, $51, $4c, $62, $43, $42, $3e, $4f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $45, $56, $62, $41, $4c, $4b, $67, $62, $56, $4c, $52, $ef, $ee, $44, $4c, $62
    db $4c, $4b, $62, $3e, $62, $51, $4f, $46, $4d, $fa, $f7, $ef, $ee, $51, $4c, $62
    db $40, $4c, $49, $49, $42, $40, $51, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $64, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $30, $3e, $50, $51
    db $42, $4f, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42
    db $4f, $fa, $f7, $ef, $ee, $54, $4c, $52, $49, $41, $62, $48, $4b, $4c, $54, $62
    db $45, $4c, $54, $ef, $ee, $4a, $3e, $4b, $56, $62, $4c, $43, $62, $51, $45, $42
    db $4a, $fa, $f7, $ef, $ee, $42, $55, $46, $50, $51, $5f, $ef, $ee, $f7, $f0
TextStr_4b_49aa:           ; id $07D2
    ; "*:[HERO], to tell you the truth.... / *:The Master Monster Tamer / wants to fight you again... / *:...a rematch. What do you think? / Do you..."
    db $ea, $9f, $a3, $f6, $5e, $62, $51, $4c, $62, $51, $42, $49, $49, $ef, $ee, $56
    db $4c, $52, $62, $51, $45, $42, $62, $51, $4f, $52, $51, $45, $5f, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $30, $3e, $50, $51, $42, $4f
    db $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $fa
    db $f7, $ef, $ee, $54, $3e, $4b, $51, $50, $62, $51, $4c, $62, $43, $46, $44, $45
    db $51, $ef, $ee, $56, $4c, $52, $62, $3e, $44, $3e, $46, $4b, $5f, $5f, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $5f, $5f, $5f, $3e, $62, $4f, $42, $4a, $3e, $51, $40
    db $45, $5f, $ef, $ee, $3a, $45, $3e, $51, $62, $41, $4c, $62, $56, $4c, $52, $62
    db $51, $45, $46, $4b, $48, $64, $fa, $f7, $ef, $ee, $27, $4c, $62, $56, $4c, $52
    db $62, $3e, $40, $40, $42, $4d, $51, $62, $46, $51, $64, $ef, $ee, $ff, $f0
TextStr_4b_4a49:           ; id $07D3
    ; "*:Oh [HERO]! You really won! / *:Awesome! Here's a surprise. *kiss*"
    db $eb, $9f, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52, $62, $4f, $42
    db $3e, $49, $49, $56, $62, $54, $4c, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3, $24
    db $54, $42, $50, $4c, $4a, $42, $63, $62, $62, $2b, $42, $4f, $42, $68, $ef, $ee
    db $3e, $62, $50, $52, $4f, $4d, $4f, $46, $50, $42, $5f, $62, $9f, $48, $46, $50
    db $50, $9f, $f7, $f0
TextStr_4b_4a8d:           ; id $07D4
    ; "*:Oh [HERO]! Here is your surprise. / *kiss*"
    db $eb, $9f, $a3, $32, $45, $62, $f6, $63, $62, $2b, $42, $4f, $42, $ef, $ee, $46
    db $50, $62, $56, $4c, $52, $4f, $62, $50, $52, $4f, $4d, $4f, $46, $50, $42, $5f
    db $fa, $f7, $ef, $ee, $9f, $48, $46, $50, $50, $9f, $ef, $ee, $f7, $f0
TextStr_4b_4abb:           ; id $07D5
    ; "*:What? Where are you? / *:Well whatever.. I'll forgive you / because you beat the Master / Monster Tamer."
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3a, $45, $42, $4f, $42, $ef, $ee
    db $3e, $4f, $42, $62, $56, $4c, $52, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42
    db $49, $49, $62, $54, $45, $3e, $51, $42, $53, $42, $4f, $5f, $5f, $ef, $ee, $2c
    db $66, $49, $62, $43, $4c, $4f, $44, $46, $53, $42, $62, $56, $4c, $52, $fa, $f7
    db $ef, $ee, $3f, $42, $40, $3e, $52, $50, $42, $62, $56, $4c, $52, $62, $3f, $42
    db $3e, $51, $ef, $ee, $51, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $fa, $f7
    db $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $5f
    db $ef, $ee, $f7, $f0
TextStr_4b_4b2f:           ; id $07D6
    ; "*:Oh no! You tripped over / didn't you!? / *:Well... it's okay 'cuz you beat / the Master Monster Tamer!"
    db $eb, $9f, $a3, $32, $45, $62, $4b, $4c, $63, $62, $3c, $4c, $52, $ef, $ee, $51
    db $4f, $46, $4d, $4d, $42, $41, $62, $4c, $53, $42, $4f, $fa, $f7, $ef, $ee, $41
    db $46, $41, $4b, $67, $62, $56, $4c, $52, $63, $64, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $3a, $42, $49, $49, $5f, $5f, $5f, $62, $46, $51, $68, $ef, $ee, $4c
    db $48, $3e, $56, $62, $6f, $52, $57, $62, $56, $4c, $52, $62, $3f, $42, $3e, $51
    db $fa, $f7, $ef, $ee, $51, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef, $ee
    db $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $63, $f7, $f0
TextStr_4b_4b9f:           ; id $07D7
    ; "*:[HERO]! Congratulations / on your victory! / *:I, I am so... *sniff* happy.. / so.. happy Waaa waaaaaa! / *:I, I heard that there're monst..."
    db $ea, $9f, $a3, $f6, $63, $ef, $ee, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49
    db $3e, $51, $46, $4c, $4b, $50, $fa, $f7, $ef, $ee, $4c, $4b, $62, $56, $4c, $52
    db $4f, $62, $53, $46, $40, $51, $4c, $4f, $56, $63, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $5e, $62, $2c, $62, $3e, $4a, $62, $50, $4c, $5f, $5f, $5f, $ef
    db $ee, $9f, $50, $4b, $46, $43, $43, $9f, $62, $45, $3e, $4d, $4d, $56, $5f, $5f
    db $fa, $f7, $ef, $ee, $50, $4c, $5f, $5f, $62, $45, $3e, $4d, $4d, $56, $62, $3a
    db $3e, $3e, $3e, $ef, $ee, $54, $3e, $3e, $3e, $3e, $3e, $3e, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $5e, $62, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45
    db $3e, $51, $ef, $ee, $51, $45, $42, $4f, $42, $69, $42, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $42, $55, $46
    db $50, $51, $62, $46, $4b, $62, $51, $45, $46, $50, $ef, $ee, $54, $4c, $4f, $49
    db $41, $62, $51, $45, $3e, $51, $62, $41, $4c, $62, $4b, $4c, $51, $fa, $f7, $ef
    db $ee, $3f, $42, $49, $4c, $4b, $44, $62, $51, $4c, $62, $3e, $4b, $56, $ef, $ee
    db $43, $3e, $4a, $46, $49, $46, $42, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $56, $69, $42, $62, $53, $42, $4f, $56, $ef, $ee, $50, $51, $4f, $4c
    db $4b, $44, $62, $b6, $62, $42, $53, $42, $4b, $62, $46, $43, $fa, $f7, $ef, $ee
    db $56, $4c, $52, $62, $3f, $42, $3e, $51, $6e, $4a, $5e, $62, $51, $45, $42, $56
    db $ef, $ee, $54, $4c, $4b, $67, $62, $3f, $42, $62, $56, $4c, $52, $4f, $62, $4d
    db $3e, $49, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $51, $45, $42
    db $56, $69, $42, $62, $50, $4c, $ef, $ee, $50, $51, $4f, $4c, $4b, $44, $62, $51
    db $45, $3e, $51, $62, $56, $4c, $52, $6d, $fa, $f7, $ef, $ee, $41, $4c, $62, $3e
    db $4b, $56, $51, $45, $46, $4b, $44, $62, $51, $4c, $ef, $ee, $44, $42, $51, $62
    db $51, $45, $42, $4a, $62, $51, $4c, $62, $47, $4c, $46, $4b, $63, $f7, $f0
TextStr_4b_4d0e:           ; id $07D8
    ; "*:I..I heard that monsters exist in / this world that do not belong to / any families. / *:They're very strong & even if / you beat'em they ..."
    db $ea, $9f, $a3, $2c, $5f, $5f, $2c, $62, $45, $42, $3e, $4f, $41, $62, $51, $45
    db $3e, $51, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $42, $55, $46
    db $50, $51, $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $46, $50, $62, $54, $4c
    db $4f, $49, $41, $62, $51, $45, $3e, $51, $ef, $ee, $41, $4c, $62, $4b, $4c, $51
    db $62, $3f, $42, $49, $4c, $4b, $44, $62, $51, $4c, $fa, $f7, $ef, $ee, $3e, $4b
    db $56, $62, $43, $3e, $4a, $46, $49, $46, $42, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $56, $69, $42, $62, $53, $42, $4f, $56, $ef, $ee
    db $50, $51, $4f, $4c, $4b, $44, $62, $b6, $62, $42, $53, $42, $4b, $62, $46, $43
    db $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $3f, $42, $3e, $51, $6e, $4a, $62, $51
    db $45, $42, $56, $ef, $ee, $54, $4c, $4b, $67, $62, $3f, $42, $62, $56, $4c, $52
    db $4f, $62, $4d, $3e, $49, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62
    db $51, $45, $42, $56, $69, $42, $62, $50, $4c, $ef, $ee, $50, $51, $4f, $4c, $4b
    db $44, $62, $51, $45, $3e, $51, $62, $56, $4c, $52, $6d, $fa, $f7, $ef, $ee, $41
    db $4c, $62, $3e, $4b, $56, $51, $45, $46, $4b, $44, $62, $51, $4c, $ef, $ee, $44
    db $42, $51, $62, $51, $45, $42, $4a, $62, $51, $4c, $62, $47, $4c, $46, $4b, $63
    db $f7, $f0
TextStr_4b_4e00:           ; id $07D9
    ; "*:Hork looks contently at / [HERO]."
    db $9f, $a3, $2b, $4c, $4f, $48, $62, $49, $4c, $4c, $48, $50, $ef, $ee, $40, $4c
    db $4b, $51, $42, $4b, $51, $49, $56, $62, $3e, $51, $fa, $f7, $ef, $ee, $f6, $5f
    db $ef, $ee, $f7, $f0
TextStr_4b_4e24:           ; id $07DA
    ; "*:That's it everyone."
    db $ea, $9f, $a3, $37, $45, $3e, $51, $68, $62, $46, $51, $ef, $ee, $42, $53, $42
    db $4f, $56, $4c, $4b, $42, $5f, $f7, $f0
TextStr_4b_4e3c:           ; id $07DB
    ; "*:One of my friends from / abroad is an old monster master. / *:He used to like this guy who / walked a lot."
    db $ea, $9f, $a3, $32, $4b, $42, $62, $4c, $43, $62, $4a, $56, $ef, $ee, $43, $4f
    db $46, $42, $4b, $41, $50, $62, $43, $4f, $4c, $4a, $fa, $f7, $ef, $ee, $3e, $3f
    db $4f, $4c, $3e, $41, $62, $46, $50, $62, $3e, $4b, $62, $4c, $49, $41, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $62, $4a, $3e, $50, $51, $42, $4f, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $2b, $42, $62, $52, $50, $42, $41, $62, $51, $4c, $62
    db $49, $46, $48, $42, $ef, $ee, $51, $45, $46, $50, $62, $44, $52, $56, $62, $54
    db $45, $4c, $fa, $f7, $ef, $ee, $54, $3e, $49, $48, $42, $41, $62, $3e, $62, $49
    db $4c, $51, $5f, $ef, $ee, $f7, $f0
TextStr_4b_4eb3:           ; id $07DC
    ; "*:You! I heard you finally made / Watabou your pal. / *:Wow!"
    db $ea, $9f, $a3, $3c, $4c, $52, $63, $62, $2c, $62, $45, $42, $3e, $4f, $41, $62
    db $56, $4c, $52, $ef, $ee, $43, $46, $4b, $3e, $49, $49, $56, $62, $4a, $3e, $41
    db $42, $fa, $f7, $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $56, $4c, $52
    db $4f, $ef, $ee, $4d, $3e, $49, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $4c, $54
    db $63, $ef, $ee, $f7, $f0
TextStr_4b_4ef8:           ; id $07DD
    ; "*:A Servant has 4 hands, Skeletor / has 6 hands. / *:I wonder if they're related..."
    db $ea, $9f, $a3, $24, $62, $36, $42, $4f, $53, $3e, $4b, $51, $62, $45, $3e, $50
    db $ef, $ee, $04, $62, $45, $3e, $4b, $41, $50, $5e, $62, $36, $48, $42, $49, $42
    db $51, $4c, $4f, $fa, $f7, $ef, $ee, $45, $3e, $50, $62, $06, $62, $45, $3e, $4b
    db $41, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b
    db $41, $42, $4f, $62, $46, $43, $ef, $ee, $51, $45, $42, $56, $69, $42, $62, $4f
    db $42, $49, $3e, $51, $42, $41, $5f, $5f, $5f, $f7, $f0
TextStr_4b_4f53:           ; id $07DE
    ; "*:The bishop I know told me an / intense song! / *:Gi-Gi, GigaSlash of MadKnight / *:Mu-Mu, MultiCut of SkyDragon / 'n MadCondor / *:HellBla..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $3f, $46, $50, $45, $4c, $4d, $62, $2c, $ef
    db $ee, $48, $4b, $4c, $54, $62, $51, $4c, $49, $41, $62, $4a, $42, $62, $3e, $4b
    db $fa, $f7, $ef, $ee, $46, $4b, $51, $42, $4b, $50, $42, $62, $50, $4c, $4b, $44
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $46, $9c, $2a, $46, $5e, $62
    db $2a, $46, $44, $3e, $36, $49, $3e, $50, $45, $ef, $ee, $4c, $43, $62, $30, $3e
    db $41, $2e, $4b, $46, $44, $45, $51, $fa, $f7, $ef, $ee, $9f, $a3, $30, $52, $9c
    db $30, $52, $5e, $62, $30, $52, $49, $51, $46, $26, $52, $51, $ef, $ee, $4c, $43
    db $62, $36, $48, $56, $27, $4f, $3e, $44, $4c, $4b, $fa, $f7, $ef, $ee, $70, $62
    db $30, $3e, $41, $26, $4c, $4b, $41, $4c, $4f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2b, $42, $49, $49, $25, $49, $3e, $50, $51, $62, $4c, $43, $ef, $ee, $30
    db $42, $51, $3e, $49, $2e, $46, $4b, $44, $fa, $f7, $ef, $ee, $70, $62, $3d, $3e
    db $4d, $25, $46, $4f, $41, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $46, $44
    db $25, $3e, $4b, $44, $62, $4c, $43, $ef, $ee, $2a, $4c, $49, $41, $2a, $4c, $49
    db $42, $4a, $fa, $f7, $ef, $ee, $70, $62, $27, $46, $53, $46, $4b, $42, $44, $4c
    db $4b, $63, $ef, $ee, $f7, $f0
TextStr_4b_5039:           ; id $07DF
    ; "*:The guy at the entrance to the / restaurant...He's my rival. / *:He has unbelievable / battle skills! / *:I can't wait until I get the / u..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $44, $52, $56, $62, $3e, $51, $62, $51, $45
    db $42, $ef, $ee, $42, $4b, $51, $4f, $3e, $4b, $40, $42, $62, $51, $4c, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $4f, $42, $50, $51, $3e, $52, $4f, $3e, $4b, $51
    db $5f, $5f, $5f, $2b, $42, $68, $ef, $ee, $4a, $56, $62, $4f, $46, $53, $3e, $49
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $62, $45, $3e, $50, $ef, $ee, $52
    db $4b, $3f, $42, $49, $46, $42, $53, $3e, $3f, $49, $42, $fa, $f7, $ef, $ee, $3f
    db $3e, $51, $51, $49, $42, $62, $50, $48, $46, $49, $49, $50, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $54, $3e, $46, $51
    db $ef, $ee, $52, $4b, $51, $46, $49, $62, $2c, $62, $44, $42, $51, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $52, $49, $51, $46, $4a, $3e, $51, $42, $62, $4a, $4c
    db $4b, $50, $51, $42, $4f, $ef, $ee, $50, $48, $46, $49, $49, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $29, $4c, $4f, $62, $50, $51, $3e, $4f, $51, $42, $4f, $50, $5e
    db $ef, $ee, $2c, $6a, $62, $44, $4c, $4b, $4b, $3e, $62, $4f, $3e, $46, $50, $42
    db $fa, $f7, $ef, $ee, $3d, $3e, $4d, $25, $46, $4f, $41, $5f, $ef, $ee, $f7, $f0
TextStr_4b_5119:           ; id $07E0
    ; "*:My slime learned an amazing skill! / *:What kind of skill? / Me..me..meg.. / *:No, it's too great to say it!"
    db $ea, $9f, $a3, $30, $56, $62, $50, $49, $46, $4a, $42, $62, $49, $42, $3e, $4f
    db $4b, $42, $41, $ef, $ee, $3e, $4b, $62, $3e, $4a, $3e, $57, $46, $4b, $44, $62
    db $50, $48, $46, $49, $49, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e, $51
    db $62, $48, $46, $4b, $41, $62, $4c, $43, $ef, $ee, $50, $48, $46, $49, $49, $64
    db $fa, $f7, $ef, $ee, $30, $42, $5f, $5f, $4a, $42, $5f, $5f, $4a, $42, $44, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $5e, $62, $46, $51, $68
    db $62, $51, $4c, $4c, $ef, $ee, $44, $4f, $42, $3e, $51, $62, $51, $4c, $62, $50
    db $3e, $56, $62, $46, $51, $63, $f7, $f0
TextStr_4b_5191:           ; id $07E1
    ; "*:Hurray! I understand now! / *:I can be a better tamer by / understanding the monster's pain! / *:I'm into journeys more than / collecting ..."
    db $ea, $9f, $a3, $2b, $52, $4f, $4f, $3e, $56, $63, $ef, $ee, $2c, $62, $52, $4b
    db $41, $42, $4f, $50, $51, $3e, $4b, $41, $62, $4b, $4c, $54, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $62, $3f, $42, $62, $3e, $ef, $ee, $3f
    db $42, $51, $51, $42, $4f, $62, $51, $3e, $4a, $42, $4f, $62, $3f, $56, $fa, $f7
    db $ef, $ee, $52, $4b, $41, $42, $4f, $50, $51, $3e, $4b, $41, $46, $4b, $44, $62
    db $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $68, $62, $4d, $3e
    db $46, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $46, $4b, $51, $4c
    db $ef, $ee, $47, $4c, $52, $4f, $4b, $42, $56, $50, $62, $4a, $4c, $4f, $42, $62
    db $51, $45, $3e, $4b, $fa, $f7, $ef, $ee, $40, $4c, $49, $49, $42, $40, $51, $46
    db $4b, $44, $62, $46, $51, $42, $4a, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $24, $4b, $41, $62, $50, $4c, $4a, $42, $45, $4c, $54, $5e, $ef, $ee, $2c
    db $62, $4a, $42, $51, $62, $51, $45, $3e, $51, $62, $4a, $3e, $50, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $3e, $49, $49, $62, $51, $45, $42, $62, $51, $46, $4a, $42
    db $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_4b_5268:           ; id $07E2
    ; "*:Hey hey hey! Run! Don't walk! / *:Yo, dude, go to the reception. / *:The challenger's waiting."
    db $ea, $9f, $a3, $2b, $42, $56, $62, $45, $42, $56, $62, $45, $42, $56, $63, $ef
    db $ee, $35, $52, $4b, $63, $62, $62, $27, $4c, $4b, $67, $62, $54, $3e, $49, $48
    db $63, $fa, $f7, $ef, $ee
TextStr_4b_528d:           ; id $07E3
    ; "*:Yo, dude, go to the reception. / *:The challenger's waiting."
    db $ea, $9f, $a3, $3c, $4c, $5e, $62, $41, $52, $41, $42, $5e, $62, $44, $4c, $62
    db $51, $4c, $ef, $ee, $51, $45, $42, $62, $4f, $42, $40, $42, $4d, $51, $46, $4c
    db $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $40, $45, $3e, $49
    db $49, $42, $4b, $44, $42, $4f, $68, $ef, $ee, $54, $3e, $46, $51, $46, $4b, $44
    db $5f, $f7, $f0
TextStr_4b_52d0:           ; id $07E4
    ; "*:Yo, dude, wanna know about Master / Monsters Tamer's monsters? [YES/NO]"
    db $ea, $9f, $a3, $3c, $4c, $5e, $62, $41, $52, $41, $42, $5e, $62, $54, $3e, $4b
    db $4b, $3e, $ef, $ee, $48, $4b, $4c, $54, $62, $3e, $3f, $4c, $52, $51, $62, $30
    db $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f
    db $50, $62, $37, $3e, $4a, $42, $4f, $68, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $64, $ff, $f0
TextStr_4b_5315:           ; id $07E5
    ; "*:He has GoldSlime Divinegon, & / Rosevine! / *:Master Monster Tamer's monsters / are perfect! / *:I don't believe anybody can beat / that o..."
    db $ea, $9f, $a3, $2b, $42, $62, $45, $3e, $50, $62, $2a, $4c, $49, $41, $36, $49
    db $46, $4a, $42, $ef, $ee, $27, $46, $53, $46, $4b, $42, $44, $4c, $4b, $5e, $62
    db $b6, $fa, $f7, $ef, $ee, $35, $4c, $50, $42, $53, $46, $4b, $42, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b
    db $50, $51, $42, $4f, $ef, $ee, $37, $3e, $4a, $42, $4f, $68, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62, $4d, $42, $4f
    db $43, $42, $40, $51, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $41
    db $4c, $4b, $67, $62, $3f, $42, $49, $46, $42, $53, $42, $ef, $ee, $3e, $4b, $56
    db $3f, $4c, $41, $56, $62, $40, $3e, $4b, $62, $3f, $42, $3e, $51, $fa, $f7, $ef
    db $ee, $51, $45, $3e, $51, $62, $4c, $49, $41, $9c, $51, $46, $4a, $42, $4f, $5f
    db $ef, $ee, $f7, $f0
TextStr_4b_53b9:           ; id $07E6
    ; "*:Hurray! I understand now! / *:I can be a better tamer by / understanding the monster's pain! / *:I'm into journeys more than / collecting ..."
    db $ea, $9f, $a3, $2b, $52, $4f, $4f, $3e, $56, $63, $ef, $ee, $2c, $62, $52, $4b
    db $41, $42, $4f, $50, $51, $3e, $4b, $41, $62, $4b, $4c, $54, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $62, $3f, $42, $62, $3e, $ef, $ee, $3f
    db $42, $51, $51, $42, $4f, $62, $51, $3e, $4a, $42, $4f, $62, $3f, $56, $fa, $f7
    db $ef, $ee, $52, $4b, $41, $42, $4f, $50, $51, $3e, $4b, $41, $46, $4b, $44, $62
    db $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $68, $62, $4d, $3e
    db $46, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $46, $4b, $51, $4c
    db $ef, $ee, $47, $4c, $52, $4f, $4b, $42, $56, $50, $62, $4a, $4c, $4f, $42, $62
    db $51, $45, $3e, $4b, $fa, $f7, $ef, $ee, $40, $4c, $49, $49, $42, $40, $51, $46
    db $4b, $44, $62, $46, $51, $42, $4a, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $24, $4b, $41, $62, $50, $4c, $4a, $42, $45, $4c, $54, $5e, $ef, $ee, $2c
    db $62, $4a, $42, $51, $62, $51, $45, $3e, $51, $62, $4a, $3e, $50, $51, $42, $4f
    db $fa, $f7, $ef, $ee, $3e, $49, $49, $62, $51, $45, $42, $62, $51, $46, $4a, $42
    db $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_4b_5490:           ; id $07E7
    ; "*:Darn! You really defeated the / Master Monster Tamer! / *:You're good!"
    db $ea, $9f, $a3, $27, $3e, $4f, $4b, $63, $62, $3c, $4c, $52, $62, $4f, $42, $3e
    db $49, $49, $56, $ef, $ee, $41, $42, $43, $42, $3e, $51, $42, $41, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b, $50
    db $51, $42, $4f, $ef, $ee, $37, $3e, $4a, $42, $4f, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $3c, $4c, $52, $69, $42, $62, $44, $4c, $4c, $41, $63, $ef, $ee, $f7, $f0
TextStr_4b_54e0:           ; id $07E8
    ; "*:It's a HorrorBK. Take good care / of it."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $62, $2b, $4c, $4f, $4f, $4c, $4f, $25
    db $2e, $5f, $ef, $ee, $37, $3e, $48, $42, $62, $44, $4c, $4c, $41, $62, $40, $3e
    db $4f, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $46, $51, $5f, $ef, $ee, $f7, $f0
TextStr_4b_5510:           ; id $07E9
    ; "*:You, must obey! / *:Bring me a Phoenix! / *:The Phoenix, the child of dribbling / bear!"
    db $eb, $9f, $a3, $3c, $4c, $52, $5e, $62, $4a, $52, $50, $51, $ef, $ee, $4c, $3f
    db $42, $56, $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4f, $46, $4b, $44, $62, $4a
    db $42, $ef, $ee, $3e, $62, $33, $45, $4c, $42, $4b, $46, $55, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $33, $45, $4c, $42, $4b, $46, $55, $5e, $62
    db $51, $45, $42, $ef, $ee, $40, $45, $46, $49, $41, $62, $4c, $43, $62, $41, $4f
    db $46, $3f, $3f, $49, $46, $4b, $44, $fa, $f7, $ef, $ee, $3f, $42, $3e, $4f, $63
    db $ef, $ee, $f7, $f0
TextStr_4b_5574:           ; id $07EA
    ; "*:This is Natto. repeat after / me, c'mon."
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $31, $3e, $51, $51, $4c
    db $5f, $ef, $ee, $4f, $42, $4d, $42, $3e, $51, $62, $3e, $43, $51, $42, $4f, $fa
    db $f7, $ef, $ee, $4a, $42, $5e, $62, $40, $6a, $4c, $4b, $5f, $ef, $ee, $f7, $f0
TextStr_4b_55a4:           ; id $07EB
    ; "*:Natto? What's that? You're / making it up! / *:Why don't you simply call it / soybeans?"
    db $ea, $9f, $a3, $31, $3e, $51, $51, $4c, $64, $62, $3a, $45, $3e, $51, $68, $ef
    db $ee, $51, $45, $3e, $51, $64, $62, $3c, $4c, $52, $69, $42, $fa, $f7, $ef, $ee
    db $4a, $3e, $48, $46, $4b, $44, $62, $46, $51, $62, $52, $4d, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $45, $56, $62, $41, $4c, $4b, $67, $62, $56, $4c
    db $52, $ef, $ee, $50, $46, $4a, $4d, $49, $56, $62, $40, $3e, $49, $49, $62, $46
    db $51, $fa, $f7, $ef, $ee, $50, $4c, $56, $3f, $42, $3e, $4b, $50, $64, $ef, $ee
    db $f7, $f0
TextStr_4b_5606:           ; id $07EC
    ; "*:Victory... You've conquered / one of the best. / *:I have to say congratulations... / *:But remember, there's always / someone better!"
    db $ea, $9f, $a3, $39, $46, $40, $51, $4c, $4f, $56, $5f, $5f, $5f, $ef, $ee, $3c
    db $4c, $52, $6c, $42, $62, $40, $4c, $4b, $4e, $52, $42, $4f, $42, $41, $fa, $f7
    db $ef, $ee, $4c, $4b, $42, $62, $4c, $43, $62, $51, $45, $42, $62, $3f, $42, $50
    db $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $3e, $53, $42
    db $62, $51, $4c, $62, $50, $3e, $56, $ef, $ee, $40, $4c, $4b, $44, $4f, $3e, $51
    db $52, $49, $3e, $51, $46, $4c, $4b, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $25, $52, $51, $62, $4f, $42, $4a, $42, $4a, $3f, $42, $4f, $5e, $ef, $ee
    db $51, $45, $42, $4f, $42, $68, $62, $3e, $49, $54, $3e, $56, $50, $fa, $f7, $ef
    db $ee, $50, $4c, $4a, $42, $4c, $4b, $42, $62, $3f, $42, $51, $51, $42, $4f, $63
    db $ef, $ee, $f7, $f0
TextStr_4b_569a:           ; id $07ED
    ; "*:You won! But you know there is / always someone better. / *:The power of the Master Monster / Tamer is not a joke. / *:Rosevine which the ..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $54, $4c, $4b, $63, $62, $62, $25, $52, $51
    db $ef, $ee, $56, $4c, $52, $62, $48, $4b, $4c, $54, $62, $51, $45, $42, $4f, $42
    db $62, $46, $50, $fa, $f7, $ef, $ee, $3e, $49, $54, $3e, $56, $50, $62, $50, $4c
    db $4a, $42, $4c, $4b, $42, $ef, $ee, $3f, $42, $51, $51, $42, $4f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4d, $4c, $54, $42, $4f, $62, $4c, $43
    db $62, $51, $45, $42, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $30, $4c, $4b
    db $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $37, $3e, $4a, $42, $4f, $62, $46, $50
    db $62, $4b, $4c, $51, $62, $3e, $ef, $ee, $47, $4c, $48, $42, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $35, $4c, $50, $42, $53, $46, $4b, $42, $62, $54, $45, $46, $40
    db $45, $ef, $ee, $51, $45, $42, $62, $4c, $49, $41, $9c, $51, $46, $4a, $42, $4f
    db $fa, $f7, $ef, $ee, $45, $3e, $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $5f, $5f, $5f, $4f, $42, $4e, $52, $46, $4f, $42, $50, $62, $3e, $ef
    db $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $46, $51, $45, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $4d, $4c, $54, $42, $4f, $62, $4c, $43, $62, $3e, $4b
    db $62, $42, $53, $46, $49, $ef, $ee, $49, $4c, $4f, $41, $62, $43, $4c, $4f, $fa
    db $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $5f, $5f, $5f, $ef, $ee
    db $f7, $f0
TextStr_4b_579c:           ; id $07EE
    ; "*:Y..you defeated the Master / Monster Tamer? / *:What a master! I can't believe it! / *:I can't say there is always / someone better anymor..."
    db $ea, $9f, $a3, $3c, $5f, $5f, $56, $4c, $52, $62, $41, $42, $43, $42, $3e, $51
    db $42, $41, $ef, $ee, $51, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $fa, $f7
    db $ef, $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $64
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e, $51, $62, $3e, $62, $4a
    db $3e, $50, $51, $42, $4f, $63, $62, $2c, $ef, $ee, $40, $3e, $4b, $67, $62, $3f
    db $42, $49, $46, $42, $53, $42, $62, $46, $51, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $62, $40, $3e, $4b, $67, $62, $50, $3e, $56, $ef, $ee, $51, $45, $42, $4f
    db $42, $62, $46, $50, $62, $3e, $49, $54, $3e, $56, $50, $fa, $f7, $ef, $ee, $50
    db $4c, $4a, $42, $4c, $4b, $42, $62, $3f, $42, $51, $51, $42, $4f, $ef, $ee, $3e
    db $4b, $56, $4a, $4c, $4f, $42, $5f, $f7, $f0
TextStr_4b_5835:           ; id $07EF
    ; "*:I also was brought here by / Watabou a long time ago. / *:I became a master & won a / victory in the tournament. / *:Spirits born on the S..."
    db $ea, $9f, $a3, $2c, $62, $3e, $49, $50, $4c, $62, $54, $3e, $50, $ef, $ee, $3f
    db $4f, $4c, $52, $44, $45, $51, $62, $45, $42, $4f, $42, $62, $3f, $56, $fa, $f7
    db $ef, $ee, $3a, $3e, $51, $3e, $3f, $4c, $52, $62, $3e, $62, $49, $4c, $4b, $44
    db $ef, $ee, $51, $46, $4a, $42, $62, $3e, $44, $4c, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $62, $3f, $42, $40, $3e, $4a, $42, $62, $3e, $ef, $ee, $4a, $3e, $50
    db $51, $42, $4f, $62, $b6, $62, $54, $4c, $4b, $62, $3e, $fa, $f7, $ef, $ee, $53
    db $46, $40, $51, $4c, $4f, $56, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $51
    db $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $36, $4d, $46, $4f, $46, $51, $50, $62, $3f, $4c, $4f, $4b, $62, $4c, $4b, $ef
    db $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45
    db $51, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $4a, $52, $50, $51, $62, $3f, $42
    db $62, $44, $4f, $4c, $54, $46, $4b, $44, $ef, $ee, $4b, $42, $54, $62, $50, $3e
    db $4d, $49, $46, $4b, $44, $50, $fa, $f7, $ef, $ee, $4c, $43, $62, $2a, $4f, $42
    db $3e, $51, $37, $4f, $42, $42, $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f
    db $42, $62, $3f, $56, $62, $4b, $4c, $54, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $28
    db $53, $42, $4b, $51, $52, $3e, $49, $49, $56, $62, $51, $45, $42, $ef, $ee, $50
    db $3e, $4d, $49, $46, $4b, $44, $50, $62, $54, $46, $49, $49, $62, $44, $4f, $4c
    db $54, $fa, $f7, $ef, $ee, $b6, $62, $3f, $42, $40, $4c, $4a, $42, $62, $3e, $62
    db $3f, $46, $44, $ef, $ee, $51, $4f, $42, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $24, $62, $3f, $46, $44, $62, $51, $4f, $42, $42, $62, $47, $52, $50, $51, $ef
    db $ee, $49, $46, $48, $42, $62, $51, $45, $46, $50, $62, $48, $46, $4b, $44, $41
    db $4c, $4a, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $f6, $5e
    db $ef, $ee, $54, $45, $3e, $51, $62, $54, $4c, $52, $49, $41, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $49, $46, $48, $42, $62, $51, $4c, $41, $3e, $56, $64, $ef
    db $ee, $f0
TextStr_4b_59b7:           ; id $07F0
    ; "*:Ha Ha Ha! I made a comeback! / *:You're still a novice. / Grow and become powerful! / *:I too was brought here by / Watabou a long time ag..."
    db $ea, $9f, $a3, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $63, $62, $2c, $62, $4a
    db $3e, $41, $42, $ef, $ee, $3e, $62, $40, $4c, $4a, $42, $3f, $3e, $40, $48, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $50, $51, $46, $49
    db $49, $ef, $ee, $3e, $62, $4b, $4c, $53, $46, $40, $42, $5f, $fa, $f7, $ef, $ee
    db $2a, $4f, $4c, $54, $62, $3e, $4b, $41, $62, $3f, $42, $40, $4c, $4a, $42, $ef
    db $ee, $4d, $4c, $54, $42, $4f, $43, $52, $49, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $62, $51, $4c, $4c, $62, $54, $3e, $50, $ef, $ee, $3f, $4f, $4c, $52, $44
    db $45, $51, $62, $45, $42, $4f, $42, $62, $3f, $56, $fa, $f7, $ef, $ee, $3a, $3e
    db $51, $3e, $3f, $4c, $52, $62, $3e, $62, $49, $4c, $4b, $44, $ef, $ee, $51, $46
    db $4a, $42, $62, $3e, $44, $4c, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3f
    db $42, $40, $3e, $4a, $42, $62, $3e, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62
    db $b6, $62, $54, $4c, $4b, $62, $3e, $fa, $f7, $ef, $ee, $53, $46, $40, $51, $4c
    db $4f, $56, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $51, $4c, $52, $4f, $4b
    db $3e, $4a, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4d, $46, $4f
    db $46, $51, $50, $62, $3f, $4c, $4f, $4b, $62, $4c, $4b, $ef, $ee, $51, $45, $42
    db $62, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $5f, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $4a, $52, $50, $51, $62, $3f, $42, $62, $44, $4f, $4c
    db $54, $46, $4b, $44, $ef, $ee, $4b, $42, $54, $62, $50, $3e, $4d, $49, $46, $4b
    db $44, $50, $62, $4c, $43, $fa, $f7, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f
    db $42, $42, $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f, $42, $62, $3f, $56
    db $62, $4b, $4c, $54, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $28, $53, $42, $4b, $51
    db $52, $3e, $49, $49, $56, $62, $51, $45, $42, $ef, $ee, $50, $3e, $4d, $49, $46
    db $4b, $44, $62, $54, $46, $49, $49, $62, $44, $4f, $4c, $54, $fa, $f7, $ef, $ee
    db $b6, $62, $3f, $42, $40, $4c, $4a, $42, $62, $3e, $62, $3f, $46, $44, $ef, $ee
    db $51, $4f, $42, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $3f, $46, $44
    db $62, $51, $4f, $42, $42, $62, $47, $52, $50, $51, $ef, $ee, $49, $46, $48, $42
    db $62, $51, $45, $46, $50, $62, $48, $46, $4b, $44, $41, $4c, $4a, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $f6, $5e, $ef, $ee, $54, $45, $3e
    db $51, $62, $54, $4c, $52, $49, $41, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $49
    db $46, $48, $42, $62, $51, $4c, $41, $3e, $56, $64, $ef, $ee, $f0
TextStr_4b_5b94:           ; id $07F1
    ; "*:You...! I have nothing to say. / *:You & your monsters grew up / to be great. / *:Only thing left for you is to tame / all the monsters.. ..."
    db $ea, $9f, $a3, $3c, $4c, $52, $5f, $5f, $5f, $63, $62, $2c, $62, $45, $3e, $53
    db $42, $ef, $ee, $4b, $4c, $51, $45, $46, $4b, $44, $62, $51, $4c, $62, $50, $3e
    db $56, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $b6, $62, $56, $4c
    db $52, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $44, $4f, $42
    db $54, $62, $52, $4d, $fa, $f7, $ef, $ee, $51, $4c, $62, $3f, $42, $62, $44, $4f
    db $42, $3e, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $4b, $49, $56
    db $62, $51, $45, $46, $4b, $44, $62, $49, $42, $43, $51, $ef, $ee, $43, $4c, $4f
    db $62, $56, $4c, $52, $62, $46, $50, $62, $51, $4c, $62, $51, $3e, $4a, $42, $fa
    db $f7, $ef, $ee, $3e, $49, $49, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51
    db $62, $46, $51, $62, $46, $50, $4b, $67, $ef, $ee, $42, $3e, $50, $56, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $62
    db $02, $01, $05, $ef, $ee, $48, $46, $4b, $41, $50, $62, $4c, $43, $62, $51, $45
    db $42, $4a, $5f, $fa, $f7, $ef, $ee, $2c, $62, $40, $4c, $52, $49, $41, $4b, $67
    db $62, $41, $4c, $62, $46, $51, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $42, $49, $49, $62, $f6, $5e, $ef, $ee, $54, $45, $3e, $51, $62, $54, $4c
    db $52, $49, $41, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $49, $46, $48, $42, $62
    db $51, $4c, $41, $3e, $56, $64, $ef, $ee, $f0
TextStr_4b_5cad:           ; id $07F2
    ; "*:Splash, splash! Congratulations. / Lemme tell ya a useful thing. / *:There're monsters you / cannot get without breeding. / Splash, splash..."
    db $eb, $9f, $a3, $36, $4d, $49, $3e, $50, $45, $5e, $62, $50, $4d, $49, $3e, $50
    db $45, $63, $ef, $ee, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46
    db $4c, $4b, $50, $5f, $fa, $f7, $ef, $ee, $2f, $42, $4a, $4a, $42, $62, $51, $42
    db $49, $49, $62, $56, $3e, $62, $3e, $ef, $ee, $52, $50, $42, $43, $52, $49, $62
    db $51, $45, $46, $4b, $44, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f
    db $42, $69, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $56, $4c
    db $52, $fa, $f7, $ef, $ee, $40, $3e, $4b, $4b, $4c, $51, $62, $44, $42, $51, $62
    db $54, $46, $51, $45, $4c, $52, $51, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b
    db $44, $5f, $fa, $f7, $ef, $ee, $36, $4d, $49, $3e, $50, $45, $5e, $62, $50, $4d
    db $49, $3e, $50, $45, $63, $ef, $ee, $f7, $f0
TextStr_4b_5d46:           ; id $07F3
    ; "*:Congratulations on your victory! / Let me give you a tip. / *:When you breed monsters with a / high number next to the +, the / combinatio..."
    db $eb, $9f, $a3, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c
    db $4b, $50, $ef, $ee, $4c, $4b, $62, $56, $4c, $52, $4f, $62, $53, $46, $40, $51
    db $4c, $4f, $56, $63, $fa, $f7, $ef, $ee, $2f, $42, $51, $62, $4a, $42, $62, $44
    db $46, $53, $42, $62, $56, $4c, $52, $62, $3e, $ef, $ee, $51, $46, $4d, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $62, $3f, $4f
    db $42, $42, $41, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46
    db $51, $45, $62, $3e, $fa, $f7, $ef, $ee, $45, $46, $44, $45, $62, $4b, $52, $4a
    db $3f, $42, $4f, $62, $4b, $42, $55, $51, $ef, $ee, $51, $4c, $62, $51, $45, $42
    db $62, $a2, $5e, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $40, $4c, $4a, $3f, $46
    db $4b, $3e, $51, $46, $4c, $4b, $ef, $ee, $40, $3e, $4b, $62, $4d, $4f, $4c, $41
    db $52, $40, $42, $62, $3e, $fa, $f7, $ef, $ee, $4f, $3e, $4f, $42, $62, $4a, $4c
    db $4b, $50, $51, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_4b_5e00:           ; id $07F4
    ; ":[HERO] looks at the bookshelf. / :Saying of the day... / :There are a total of 215 monsters! / Want to read the rest? [YES/NO]"
    db $a3, $f6, $62, $49, $4c, $4c, $48, $50, $62, $3e, $51, $ef, $ee, $51, $45, $42
    db $62, $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $fa, $f7, $ef, $ee, $a3
    db $36, $3e, $56, $46, $4b, $44, $62, $4c, $43, $62, $51, $45, $42, $ef, $ee, $41
    db $3e, $56, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $4f, $42, $62
    db $3e, $4f, $42, $62, $3e, $62, $51, $4c, $51, $3e, $49, $ef, $ee, $4c, $43, $62
    db $02, $01, $05, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $fa, $f7, $ef
    db $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $51, $45
    db $42, $ef, $ee, $4f, $42, $50, $51, $64, $ff, $f0
TextStr_4b_5e7a:           ; id $07F5
    ; ":At last, [HERO] will compete in / the tournament! / :He is something. He looks like me / in my younger days, too! / Want to read the rest? ..."
    db $a3, $24, $51, $62, $49, $3e, $50, $51, $5e, $62, $f6, $ef, $ee, $54, $46, $49
    db $49, $62, $40, $4c, $4a, $4d, $42, $51, $42, $62, $46, $4b, $fa, $f7, $ef, $ee
    db $51, $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $a3, $2b, $42, $62, $46, $50, $62, $50, $4c, $4a, $42
    db $51, $45, $46, $4b, $44, $5f, $ef, $ee, $2b, $42, $62, $49, $4c, $4c, $48, $50
    db $62, $49, $46, $48, $42, $62, $4a, $42, $fa, $f7, $ef, $ee, $46, $4b, $62, $4a
    db $56, $62, $56, $4c, $52, $4b, $44, $42, $4f, $ef, $ee, $41, $3e, $56, $50, $5e
    db $62, $51, $4c, $4c, $63, $fa, $f7, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c
    db $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $4f, $42, $50, $51, $64
    db $ff, $f0
TextStr_4b_5f0c:           ; id $07F6
    ; ":At last, [HERO] got a victory! / :I remember those days. I used to be / a master, too. / :I won a victory in the Starry / Night tournament...."
    db $a3, $24, $51, $62, $49, $3e, $50, $51, $5e, $62, $f6, $ef, $ee, $44, $4c, $51
    db $62, $3e, $62, $53, $46, $40, $51, $4c, $4f, $56, $63, $fa, $f7, $ef, $ee, $a3
    db $2c, $62, $4f, $42, $4a, $42, $4a, $3f, $42, $4f, $62, $51, $45, $4c, $50, $42
    db $ef, $ee, $41, $3e, $56, $50, $5f, $62, $2c, $62, $52, $50, $42, $41, $62, $51
    db $4c, $62, $3f, $42, $fa, $f7, $ef, $ee, $3e, $62, $4a, $3e, $50, $51, $42, $4f
    db $5e, $62, $51, $4c, $4c, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $2c, $62, $54
    db $4c, $4b, $62, $3e, $62, $53, $46, $40, $51, $4c, $4f, $56, $ef, $ee, $46, $4b
    db $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $fa, $f7, $ef, $ee, $31
    db $46, $44, $45, $51, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $a3, $2c, $62, $54, $42, $4b, $51, $62, $51, $4c
    db $62, $51, $45, $42, $ef, $ee, $50, $45, $4f, $46, $4b, $42, $62, $51, $4c, $62
    db $50, $42, $42, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $3f, $46, $4f, $51, $45
    db $62, $4c, $43, $62, $3e, $62, $50, $4d, $46, $4f, $46, $51, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $a3, $24, $62, $36, $4d, $46, $4f, $46, $51, $62, $4c, $43, $ef
    db $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $62, $3f, $4c, $4f, $4b, $62
    db $4c, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56
    db $62, $31, $46, $44, $45, $51, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $43, $49
    db $42, $54, $62, $3e, $54, $3e, $56, $ef, $ee, $51, $4c, $62, $50, $51, $3e, $4f
    db $51, $62, $3e, $fa, $f7, $ef, $ee, $4b, $42, $54, $62, $2a, $4f, $42, $3e, $51
    db $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $2c, $51, $62, $54
    db $46, $49, $49, $62, $44, $4f, $4c, $54, $62, $51, $4c, $ef, $ee, $3f, $42, $62
    db $3e, $62, $3f, $46, $44, $62, $3f, $46, $44, $62, $51, $4f, $42, $42, $fa, $f7
    db $ef, $ee, $47, $52, $50, $51, $62, $49, $46, $48, $42, $62, $51, $45, $46, $50
    db $ef, $ee, $48, $46, $4b, $44, $41, $4c, $4a, $63, $f7, $f0
TextStr_4b_6088:           ; id $07F7
    ; "*:I heard you won with style. / *:The Master Monster Tamer is / so happy as if he won himself."
    db $eb, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41, $62, $56, $4c, $52, $62, $54
    db $4c, $4b, $ef, $ee, $54, $46, $51, $45, $62, $50, $51, $56, $49, $42, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef
    db $ee, $30, $4c, $4b, $50, $51, $42, $4f, $62, $37, $3e, $4a, $42, $4f, $62, $46
    db $50, $fa, $f7, $ef, $ee, $50, $4c, $62, $45, $3e, $4d, $4d, $56, $62, $3e, $50
    db $62, $46, $43, $62, $45, $42, $ef, $ee, $54, $4c, $4b, $62, $45, $46, $4a, $50
    db $42, $49, $43, $5f, $f7, $f0
TextStr_4b_60ee:           ; id $07F8
    ; "*:Hey, listen! A different / monster was born! / *:A different monster was born / from the same combination! / *:Maybe your victory created ..."
    db $ea, $9f, $a3, $2b, $42, $56, $5e, $62, $49, $46, $50, $51, $42, $4b, $63, $ef
    db $ee, $24, $62, $41, $46, $43, $43, $42, $4f, $42, $4b, $51, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $3e, $50, $62, $3f, $4c, $4f, $4b
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $41, $46, $43, $43, $42
    db $4f, $42, $4b, $51, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $3e
    db $50, $62, $3f, $4c, $4f, $4b, $fa, $f7, $ef, $ee, $43, $4f, $4c, $4a, $62, $51
    db $45, $42, $62, $50, $3e, $4a, $42, $ef, $ee, $40, $4c, $4a, $3f, $46, $4b, $3e
    db $51, $46, $4c, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $56, $3f, $42
    db $62, $56, $4c, $52, $4f, $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56, $62, $40
    db $4f, $42, $3e, $51, $42, $41, $fa, $f7, $ef, $ee, $3e, $62, $4a, $46, $4f, $3e
    db $40, $49, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $4f, $62, $54
    db $3e, $50, $62, $46, $51, $62, $41, $52, $42, $ef, $ee, $51, $4c, $62, $4a, $56
    db $62, $44, $4c, $4c, $41, $62, $3e, $40, $51, $64, $f7, $f0
TextStr_4b_61ba:           ; id $07F9
    ; "*:Where did those millions of stars / that fell on the Starry Night go?"
    db $ea, $9f, $a3, $3a, $45, $42, $4f, $42, $62, $41, $46, $41, $62, $51, $45, $4c
    db $50, $42, $ef, $ee, $4a, $46, $49, $49, $46, $4c, $4b, $50, $62, $4c, $43, $62
    db $50, $51, $3e, $4f, $50, $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $43, $42
    db $49, $49, $62, $4c, $4b, $62, $51, $45, $42, $ef, $ee, $36, $51, $3e, $4f, $4f
    db $56, $62, $31, $46, $44, $45, $51, $62, $44, $4c, $64, $f7, $f0
TextStr_4b_6207:           ; id $07FA
    ; "*:Hi [HERO]! Welcome home! / *:How have you been? / I missed you. / *:How may I help you today?"
    db $eb, $9f, $a3, $2b, $46, $62, $f6, $63, $ef, $ee, $3a, $42, $49, $40, $4c, $4a
    db $42, $62, $45, $4c, $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c, $54
    db $62, $45, $3e, $53, $42, $62, $56, $4c, $52, $ef, $ee, $3f, $42, $42, $4b, $64
    db $fa, $f7, $ef, $ee, $2c, $62, $4a, $46, $50, $50, $42, $41, $62, $56, $4c, $52
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c, $54, $62, $4a, $3e, $56
    db $62, $2c, $62, $45, $42, $49, $4d, $ef, $ee, $56, $4c, $52, $62, $51, $4c, $41
    db $3e, $56, $64, $f0
TextStr_4b_626b:           ; id $07FB
    ; "*:Congratulations on your victory. / I knew you could do it! / *:Hey, how about marrying my / daughter? [YES/NO]"
    db $ea, $9f, $a3, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c
    db $4b, $50, $ef, $ee, $4c, $4b, $62, $56, $4c, $52, $4f, $62, $53, $46, $40, $51
    db $4c, $4f, $56, $5f, $fa, $f7, $ef, $ee, $2c, $62, $48, $4b, $42, $54, $62, $56
    db $4c, $52, $62, $40, $4c, $52, $49, $41, $ef, $ee, $41, $4c, $62, $46, $51, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $56, $5e, $62, $45, $4c, $54, $62, $3e
    db $3f, $4c, $52, $51, $ef, $ee, $4a, $3e, $4f, $4f, $56, $46, $4b, $44, $62, $4a
    db $56, $fa, $f7, $ef, $ee, $41, $3e, $52, $44, $45, $51, $42, $4f, $64, $ef, $ee
    db $ff, $f0
TextStr_4b_62dd:           ; id $07FC
    ; "*:Just kidding! You're still a / kid!"
    db $ea, $9f, $a3, $2d, $52, $50, $51, $62, $48, $46, $41, $41, $46, $4b, $44, $63
    db $ef, $ee, $3c, $4c, $52, $69, $42, $62, $50, $51, $46, $49, $49, $62, $3e, $fa
    db $f7, $ef, $ee, $48, $46, $41, $63, $ef, $ee, $f7, $f0
TextStr_4b_6308:           ; id $07FD
    ; "*:My hubby loves our girl so much.. / *:..he keeps a journal of her."
    db $eb, $9f, $a3, $30, $56, $62, $45, $52, $3f, $3f, $56, $62, $49, $4c, $53, $42
    db $50, $ef, $ee, $4c, $52, $4f, $62, $44, $46, $4f, $49, $62, $50, $4c, $62, $4a
    db $52, $40, $45, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $5f, $5f, $45, $42, $62
    db $48, $42, $42, $4d, $50, $62, $3e, $ef, $ee, $47, $4c, $52, $4f, $4b, $3e, $49
    db $62, $4c, $43, $62, $45, $42, $4f, $5f, $f7, $f0
TextStr_4b_6352:           ; id $07FE
    ; ":Steps of My Baby Part 4 / :I guess I've forgotten an / important thing. / :I forgot to name my baby! / :She was so cute that I completely /..."
    db $a3, $36, $51, $42, $4d, $50, $62, $4c, $43, $62, $30, $56, $62, $25, $3e, $3f
    db $56, $ef, $ee, $62, $33, $3e, $4f, $51, $62, $04, $fa, $f7, $ef, $ee, $a3, $2c
    db $62, $44, $52, $42, $50, $50, $62, $2c, $6c, $42, $ef, $ee, $43, $4c, $4f, $44
    db $4c, $51, $51, $42, $4b, $62, $3e, $4b, $fa, $f7, $ef, $ee, $46, $4a, $4d, $4c
    db $4f, $51, $3e, $4b, $51, $62, $51, $45, $46, $4b, $44, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $a3, $2c, $62, $43, $4c, $4f, $44, $4c, $51, $62, $51, $4c, $62, $4b
    db $3e, $4a, $42, $ef, $ee, $4a, $56, $62, $3f, $3e, $3f, $56, $63, $fa, $f7, $ef
    db $ee, $a3, $36, $45, $42, $62, $54, $3e, $50, $62, $50, $4c, $62, $40, $52, $51
    db $42, $ef, $ee, $51, $45, $3e, $51, $62, $2c, $62, $40, $4c, $4a, $4d, $49, $42
    db $51, $42, $49, $56, $fa, $f7, $ef, $ee, $43, $4c, $4f, $44, $4c, $51, $62, $3e
    db $3f, $4c, $52, $51, $62, $46, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e
    db $4b, $51, $62, $51, $4c, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee
    db $4f, $42, $50, $51, $64, $ff, $f0
TextStr_4b_6419:           ; id $07FF
    ; ":Steps of My Baby Part 5 / :I came up with my baby's name. / :Santi. It's Santi."
    db $a3, $36, $51, $42, $4d, $50, $62, $4c, $43, $62, $30, $56, $62, $25, $3e, $3f
    db $56, $ef, $ee, $33, $3e, $4f, $51, $62, $05, $fa, $f7, $ef, $ee, $a3, $2c, $62
    db $40, $3e, $4a, $42, $62, $52, $4d, $62, $54, $46, $51, $45, $62, $4a, $56, $ef
    db $ee, $3f, $3e, $3f, $56, $68, $62, $4b, $3e, $4a, $42, $5f, $fa, $f7, $ef, $ee
    db $a3, $36, $3e, $4b, $51, $46, $5f, $62, $2c, $51, $68, $ef, $ee, $36, $3e, $4b
    db $51, $46, $5f, $f7, $f0, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $7f, $00, $40, $00, $5f, $00
    db $5f, $1f, $40, $00, $7f, $00, $00, $00, $00, $00, $fe, $00, $02, $04, $fa, $04
    db $fa, $fc, $02, $00, $fe, $00, $00, $78, $00, $40, $b6, $40, $32, $44, $b2, $44
    db $b2, $c4, $32, $40, $b6, $40, $00, $1e, $00, $10, $6d, $10, $4c, $10, $4d, $10
    db $4d, $11, $4c, $10, $6d, $10, $00, $00, $00, $00, $7f, $00, $40, $00, $5f, $00
    db $5f, $1f, $40, $00, $7f, $00, $00, $00, $00, $00, $fe, $00, $02, $04, $fa, $04
    db $fa, $fc, $02, $00, $fe, $00, $00, $78, $00, $40, $b6, $40, $32, $44, $b2, $44
    db $b2, $c4, $32, $40, $b6, $40, $00, $1e, $00, $10, $6d, $10, $4c, $10, $4d, $10
    db $4d, $11, $4c, $10, $6d, $10, $00, $00, $00, $00, $7f, $00, $40, $00, $5f, $00
    db $5f, $1f, $40, $00, $7f, $00, $00, $00, $00, $00, $fe, $00, $02, $04, $fa, $04
    db $fa, $fc, $02, $00, $fe, $00, $00, $78, $00, $40, $b6, $40, $32, $44, $b2, $44
    db $b2, $c4, $32, $40, $b6, $40, $00, $1e, $00, $10, $6d, $10, $4c, $10, $4d, $10
    db $4d, $11, $4c, $10, $6d, $10, $00, $00, $00, $00, $7f, $00, $40, $00, $5f, $00
    db $5f, $1f, $40, $00, $7f, $00, $00, $00, $00, $00, $fe, $00, $02, $04, $fa, $04
    db $fa, $fc, $02, $00, $fe, $00, $00, $78, $00, $40, $b6, $40, $32, $44, $b2, $44
    db $b2, $c4, $32, $40, $b6, $40, $00, $1e, $00, $10, $6d, $10, $4c, $10, $4d, $10
    db $4d, $11, $4c, $10, $6d, $10, $00, $38, $c7, $0e, $f1, $07, $f8, $0e, $f1, $18
    db $e7, $c1, $3e, $e0, $1f, $83, $7c, $a4, $5b, $8e, $71, $0e, $f1, $1b, $e4, $11
    db $ee, $41, $be, $60, $9f, $e0, $1f, $1c, $e3, $70, $8f, $e0, $1f, $70, $8f, $18
    db $e7, $83, $7c, $07, $f8, $c1, $3e, $07, $f8, $06, $f9, $82, $7d, $88, $77, $d8
    db $27, $70, $8f, $71, $8e, $25, $da, $e0, $1f, $0e, $f1, $83, $7c, $c1, $3e, $83
    db $7c, $06, $f9, $70, $8f, $38, $c7, $1c, $e3, $36, $c9, $22, $dd, $82, $7d, $c0
    db $3f, $c1, $3e, $49, $b6, $1d, $e2, $07, $f8, $70, $8f, $c1, $3e, $83, $7c, $c1
    db $3e, $60, $9f, $0e, $f1, $1c, $e3, $b8, $47, $92, $6d, $83, $7c, $03, $fc, $41
    db $be, $44, $bb, $6c, $93, $38, $c7, $83, $7c, $e0, $1f, $70, $8f, $e0, $1f, $81
    db $7e, $1c, $e3, $0e, $f1, $38, $c7, $11, $ee, $41, $be, $60, $9f, $e0, $1f, $a4
    db $5b, $8e, $71, $0e, $f1, $1b, $e4, $c1, $3e, $07, $f8, $0e, $f1, $07, $f8, $81
    db $7e, $38, $c7, $70, $8f, $1c, $e3, $d8, $27, $70, $8f, $71, $8e, $25, $da, $07
    db $f8, $06, $f9, $82, $7d, $88, $77, $38, $c7, $1c, $e3, $38, $c7, $60, $9f, $07
    db $f8, $83, $7c, $0e, $f1, $e0, $1f, $30, $cf, $70, $8f, $52, $ad, $47, $b8, $07
    db $f8, $8d, $72, $88, $77, $a0, $5f, $1c, $e3, $38, $c7, $1c, $e3, $06, $f9, $e0
    db $1f, $c1, $3e, $70, $8f, $07, $f8, $05, $fa, $11, $ee, $b1, $4e, $e0, $1f, $e2
    db $1d, $4a, $b5, $0e, $f1, $0c, $f3, $ff, $10, $ef, $38, $d7, $ec, $23, $d7, $c0
    db $3b, $00, $df, $00, $27, $20, $d8, $a4, $5b, $8e, $71, $0e, $f1, $1b, $e4, $11
    db $ee, $41, $be, $60, $9f, $e0, $1f, $1c, $e3, $70, $8f, $e0, $1f, $70, $8f, $18
    db $e7, $83, $7c, $07, $f8, $c1, $3e, $07, $f8, $06, $f9, $82, $7d, $88, $77, $d8
    db $27, $70, $8f, $71, $8e, $25, $da, $ff, $04, $fb, $0e, $f5, $3b, $c8, $f5, $30
    db $ce, $00, $7f, $00, $9c, $80, $63, $1c, $e3, $36, $c9, $22, $dd, $82, $7d, $c0
    db $3f, $c1, $3e, $49, $b6, $1d, $e2, $07, $f8, $70, $8f, $c1, $3e, $83, $7c, $c1
    db $3e, $60, $9f, $0e, $f1, $1c, $e3, $b8, $47, $92, $6d, $83, $7c, $03, $fc, $41
    db $be, $44, $bb, $6c, $93, $38, $c7, $ff, $01, $fe, $83, $7d, $ce, $32, $7d, $0c
    db $b3, $00, $fd, $00, $72, $02, $8d, $11, $ee, $41, $be, $60, $9f, $e0, $1f, $a4
    db $5b, $8e, $71, $0e, $f1, $1b, $e4, $c1, $3e, $07, $f8, $0e, $f1, $07, $f8, $81
    db $7e, $38, $c7, $70, $8f, $1c, $e3, $d8, $27, $70, $8f, $71, $8e, $25, $da, $07
    db $f8, $06, $f9, $82, $7d, $88, $77, $ff, $40, $bf, $e0, $5f, $b3, $8c, $5f, $03
    db $ec, $00, $f7, $00, $c9, $08, $36, $30, $cf, $70, $8f, $52, $ad, $47, $b8, $07
    db $f8, $8d, $72, $88, $77, $a0, $5f, $1c, $e3, $38, $c7, $1c, $e3, $06, $f9, $e0
    db $1f, $c1, $3e, $70, $8f, $07, $f8, $05, $fa, $11, $ee, $b1, $4e, $e0, $1f, $e2
    db $1d, $4a, $b5, $0e, $f1, $0c, $f3, $03, $db, $8f, $af, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $20, $7a, $87, $b7, $cf, $df, $ef, $ef, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $06, $f8, $1d, $e0, $3b, $c0, $f6, $01, $2c
    db $c2, $69, $84, $69, $84, $b5, $43, $c0, $3f, $6a, $15, $ba, $05, $ba, $05, $5c
    db $83, $2a, $45, $2e, $41, $1c, $c3, $20, $7a, $85, $b5, $cf, $df, $ef, $ef, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $20, $b6, $81, $b1, $8d, $ad, $8f, $af, $8f
    db $af, $27, $77, $8f, $bf, $8f, $af, $03, $fc, $16, $e8, $0e, $f0, $fd, $00, $1a
    db $e1, $34, $c2, $55, $a0, $b9, $43, $60, $1f, $ba, $05, $da, $05, $5e, $81, $2c
    db $c3, $16, $e1, $16, $61, $2e, $c1, $20, $b6, $81, $b1, $8d, $ad, $8f, $af, $8f
    db $af, $27, $77, $8f, $bf, $8f, $af, $20, $7a, $87, $b7, $cf, $df, $ef, $ef, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $06, $f8, $1d, $e0, $3b, $c0, $f6, $01, $2c
    db $c2, $69, $84, $69, $84, $b5, $43, $c0, $3f, $6a, $15, $ba, $05, $ba, $05, $5c
    db $83, $2a, $45, $2e, $41, $1c, $c3, $20, $7a, $87, $b7, $cf, $df, $ef, $ef, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $03, $db, $8f, $af, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $2b, $d0, $59, $a0, $56, $a0, $75, $82, $a8
    db $47, $50, $8e, $51, $8c, $69, $87, $c0, $3f, $e8, $17, $f0, $0f, $7f, $00, $b8
    db $07, $5c, $83, $5a, $05, $3d, $82, $ff, $10, $ef, $38, $d7, $ec, $23, $d7, $c0
    db $3b, $00, $df, $00, $27, $20, $d8, $1c, $e3, $70, $8f, $e0, $1f, $70, $8f, $18
    db $e7, $83, $7c, $07, $f8, $c1, $3e, $06, $f8, $1d, $e0, $3b, $c0, $f6, $01, $2c
    db $c2, $69, $84, $69, $84, $b5, $43, $c0, $3f, $6a, $15, $ba, $05, $ba, $05, $5c
    db $83, $2a, $45, $2e, $41, $1c, $c3, $ff, $04, $fb, $0e, $f5, $3b, $c8, $f5, $30
    db $ce, $00, $7f, $00, $9c, $80, $63, $07, $f8, $70, $8f, $c1, $3e, $83, $7c, $c1
    db $3e, $60, $9f, $0e, $f1, $1c, $e3, $03, $fc, $16, $e8, $0e, $f0, $fd, $00, $1a
    db $e1, $34, $c2, $55, $a0, $b9, $43, $60, $1f, $ba, $05, $da, $05, $5e, $81, $2c
    db $c3, $16, $e1, $16, $61, $2e, $c1, $ff, $01, $fe, $83, $7d, $ce, $32, $7d, $0c
    db $b3, $00, $fd, $00, $72, $02, $8d, $c1, $3e, $07, $f8, $0e, $f1, $07, $f8, $81
    db $7e, $38, $c7, $70, $8f, $1c, $e3, $06, $f8, $1d, $e0, $3b, $c0, $f6, $01, $2c
    db $c2, $69, $84, $69, $84, $b5, $43, $c0, $3f, $6a, $15, $ba, $05, $ba, $05, $5c
    db $83, $2a, $45, $2e, $41, $1c, $c3, $ff, $40, $bf, $e0, $5f, $b3, $8c, $5f, $03
    db $ec, $00, $f7, $00, $c9, $08, $36, $1c, $e3, $38, $c7, $1c, $e3, $06, $f9, $e0
    db $1f, $c1, $3e, $70, $8f, $07, $f8, $2b, $d0, $59, $a0, $56, $a0, $75, $82, $a8
    db $47, $50, $8e, $51, $8c, $69, $87, $c0, $3f, $e8, $17, $f0, $0f, $7f, $00, $b8
    db $07, $5c, $83, $5a, $05, $3d, $82, $87, $87, $78, $78, $00, $00, $30, $30, $f7
    db $70, $9f, $60, $18, $60, $60, $60, $60, $60, $00, $00, $00, $87, $00, $fd, $00
    db $bd, $00, $b5, $00, $36, $00, $00, $ff, $ff, $e1, $e1, $10, $10, $30, $30, $7e
    db $60, $9f, $60, $81, $60, $60, $60, $60, $60, $00, $00, $00, $1e, $00, $fd, $00
    db $b5, $00, $b5, $00, $37, $00, $00, $e1, $e1, $1e, $1e, $20, $20, $70, $70, $91
    db $70, $9f, $60, $7e, $60, $60, $60, $00, $00, $00, $00, $00, $e1, $00, $bf, $00
    db $bd, $00, $b5, $00, $54, $00, $00, $ff, $ff, $87, $87, $30, $30, $70, $70, $18
    db $60, $9f, $60, $e7, $60, $60, $60, $00, $00, $00, $00, $00, $78, $00, $bf, $00
    db $b5, $00, $b5, $00, $55, $00, $00, $78, $78, $87, $87, $30, $30, $70, $70, $18
    db $60, $9f, $60, $e7, $60, $60, $60, $00, $00, $00, $00, $00, $78, $00, $bf, $00
    db $b5, $00, $b5, $00, $55, $00, $00, $ff, $ff, $1e, $1e, $20, $20, $70, $70, $91
    db $70, $9f, $60, $7e, $60, $60, $60, $00, $00, $00, $00, $00, $e1, $00, $bf, $00
    db $bd, $00, $b5, $00, $54, $00, $00, $1e, $1e, $e1, $e1, $10, $10, $30, $30, $7e
    db $60, $9f, $60, $81, $60, $60, $60, $60, $60, $00, $00, $00, $1e, $00, $fd, $00
    db $b5, $00, $b5, $00, $37, $00, $00, $ff, $ff, $78, $78, $00, $00, $30, $30, $f7
    db $70, $9f, $60, $18, $60, $60, $60, $60, $60, $00, $00, $00, $87, $00, $fd, $00
    db $bd, $00, $b5, $00, $36, $00, $00, $ff, $10, $ef, $38, $d7, $ec, $23, $d7, $c0
    db $3b, $00, $df, $00, $27, $20, $d8, $00, $bd, $00, $de, $00, $5e, $00, $bd, $00
    db $f5, $00, $7a, $00, $5e, $00, $bd, $1c, $e3, $70, $8f, $e0, $1f, $70, $8f, $18
    db $e7, $83, $7c, $07, $f8, $c1, $3e, $00, $45, $00, $90, $00, $44, $00, $11, $00
    db $15, $00, $41, $00, $44, $00, $11, $ff, $04, $fb, $0e, $f5, $3b, $c8, $f5, $30
    db $ce, $00, $7f, $00, $9c, $80, $63, $00, $7a, $00, $bd, $00, $af, $00, $de, $00
    db $7a, $00, $bd, $00, $bc, $00, $7a, $07, $f8, $70, $8f, $c1, $3e, $83, $7c, $c1
    db $3e, $60, $9f, $0e, $f1, $1c, $e3, $00, $8a, $00, $20, $00, $22, $00, $88, $00
    db $8a, $00, $20, $00, $89, $00, $23, $ff, $01, $fe, $83, $7d, $ce, $32, $7d, $0c
    db $b3, $00, $fd, $00, $72, $02, $8d, $00, $f5, $00, $7a, $00, $5e, $00, $bd, $00
    db $bd, $00, $de, $00, $5e, $00, $bd, $c1, $3e, $07, $f8, $0e, $f1, $07, $f8, $81
    db $7e, $38, $c7, $70, $8f, $1c, $e3, $00, $15, $00, $41, $00, $44, $00, $11, $00
    db $45, $00, $90, $00, $44, $00, $11, $ff, $40, $bf, $e0, $5f, $b3, $8c, $5f, $03
    db $ec, $00, $f7, $00, $c9, $08, $36, $00, $7a, $00, $bd, $00, $bc, $00, $7a, $00
    db $7a, $00, $bd, $00, $af, $00, $de, $1c, $e3, $38, $c7, $1c, $e3, $06, $f9, $e0
    db $1f, $c1, $3e, $70, $8f, $07, $f8, $00, $8a, $00, $20, $00, $89, $00, $23, $00
    db $8a, $00, $20, $00, $22, $00, $88, $ff, $00, $bf, $40, $1f, $e0, $07, $f8, $03
    db $fc, $0c, $f3, $30, $cf, $00, $ff, $ff, $00, $ff, $00, $ff, $00, $bc, $43, $10
    db $ef, $08, $f7, $04, $fb, $00, $ff, $a4, $fd, $a6, $e6, $93, $f3, $d0, $71, $cc
    db $7d, $e3, $3f, $f8, $1f, $ff, $07, $25, $bf, $65, $67, $c9, $cf, $8b, $0e, $b3
    db $3e, $c7, $fc, $1f, $f8, $ff, $e0, $ff, $00, $ff, $00, $ff, $00, $7b, $84, $31
    db $ce, $c0, $3f, $00, $ff, $00, $ff, $ff, $00, $fb, $04, $f1, $0e, $c0, $3f, $00
    db $ff, $80, $7f, $43, $bc, $00, $ff, $a4, $e5, $a6, $e6, $93, $ff, $d4, $78, $cc
    db $7c, $e3, $3f, $f8, $1f, $ff, $07, $25, $a7, $65, $67, $d9, $ef, $0b, $3e, $33
    db $3e, $c7, $fc, $1f, $f8, $ff, $e0, $ff, $00, $ff, $00, $ff, $00, $bc, $43, $10
    db $ef, $08, $f7, $04, $fb, $00, $ff, $ff, $00, $bf, $40, $1f, $e0, $07, $f8, $03
    db $fc, $0c, $f3, $30, $cf, $00, $ff, $a4, $fd, $a6, $e6, $93, $f3, $d0, $71, $cc
    db $7d, $e3, $3f, $f8, $1f, $ff, $07, $25, $bf, $65, $67, $c9, $cf, $8b, $0e, $b3
    db $3e, $c7, $fc, $1f, $f8, $ff, $e0, $ff, $00, $fb, $04, $f1, $0e, $c0, $3f, $00
    db $ff, $80, $7f, $43, $bc, $00, $ff, $ff, $00, $ff, $00, $ff, $00, $7b, $84, $31
    db $ce, $c0, $3f, $00, $ff, $00, $ff, $a4, $e5, $a6, $e6, $93, $ff, $d4, $78, $cc
    db $7c, $e3, $3f, $f8, $1f, $ff, $07, $25, $a7, $65, $67, $d9, $ef, $0b, $3e, $33
    db $3e, $c7, $fc, $1f, $f8, $ff, $e0, $fe, $fe, $fc, $fd, $f9, $fa, $f3, $f4, $f3
    db $f4, $f9, $fa, $fc, $fd, $fe, $fe, $7f, $7f, $3f, $bf, $9f, $5f, $cf, $2f, $cf
    db $2f, $9f, $5f, $3f, $bf, $7f, $7f, $a4, $fd, $a6, $e6, $93, $f3, $d0, $f1, $cc
    db $fd, $e3, $ff, $f8, $ff, $ff, $ff, $25, $bf, $65, $67, $c9, $cf, $8b, $0f, $b3
    db $3f, $c7, $ff, $1f, $ff, $ff, $ff, $e7, $e7, $c3, $db, $99, $a5, $3c, $42, $3c
    db $42, $99, $a5, $c3, $db, $e7, $e7, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $a4, $e5, $a6, $e6, $93, $ff, $d4, $f8, $cc
    db $fc, $e3, $ff, $f8, $ff, $ff, $ff, $25, $a7, $65, $67, $d9, $ef, $0b, $3f, $33
    db $3f, $c7, $ff, $1f, $ff, $ff, $ff, $7f, $7f, $3f, $bf, $9f, $5f, $cf, $2f, $cf
    db $2f, $9f, $5f, $3f, $bf, $7f, $7f, $fe, $fe, $fc, $fd, $f9, $fa, $f3, $f4, $f3
    db $f4, $f9, $fa, $fc, $fd, $fe, $fe, $a4, $fd, $a6, $e6, $93, $f3, $d0, $f1, $cc
    db $fd, $e3, $ff, $f8, $ff, $ff, $ff, $25, $bf, $65, $67, $c9, $cf, $8b, $0f, $b3
    db $3f, $c7, $ff, $1f, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff
    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $e7, $e7, $c3, $db, $99, $a5, $3c, $42, $3c
    db $42, $99, $a5, $c3, $db, $e7, $e7, $a4, $e5, $a6, $e6, $93, $ff, $d4, $f8, $cc
    db $fc, $e3, $ff, $f8, $ff, $ff, $ff, $25, $a7, $65, $67, $d9, $ef, $0b, $3f, $33
    db $3f, $c7, $ff, $1f, $ff, $ff, $ff, $fe, $ff, $fe, $ff, $fe, $ff, $e0, $e0, $83
    db $8c, $77, $78, $f3, $fc, $fb, $fc, $7f, $7f, $7f, $7f, $7f, $7f, $07, $07, $c1
    db $31, $ee, $1e, $cf, $3f, $df, $3f, $7f, $7f, $3f, $bf, $9f, $df, $9f, $df, $9f
    db $df, $9f, $df, $cf, $ef, $ef, $ff, $fc, $fc, $f8, $fb, $f3, $f7, $e7, $ef, $e7
    db $ef, $e7, $ef, $cf, $df, $9f, $bf, $fe, $ff, $fe, $ff, $fe, $ff, $e0, $e0, $83
    db $8c, $77, $78, $f3, $fc, $fb, $fc, $7f, $7f, $7f, $7f, $7f, $7f, $07, $07, $c1
    db $31, $ee, $1e, $cf, $3f, $df, $3f, $3f, $3f, $1f, $df, $cf, $ef, $e7, $f7, $e7
    db $f7, $e7, $f7, $f3, $fb, $f9, $fd, $fc, $fc, $f0, $f3, $e3, $ef, $cf, $df, $9f
    db $bf, $7f, $3f, $bf, $5f, $ff, $af, $fe, $ff, $fe, $ff, $fe, $ff, $e0, $e0, $83
    db $83, $77, $77, $f7, $f7, $fb, $fb, $7f, $7f, $7f, $7f, $7f, $7f, $07, $07, $c1
    db $c1, $ee, $ee, $ef, $ef, $df, $df, $3f, $3f, $0f, $cf, $c7, $f7, $f3, $fb, $f9
    db $fd, $fe, $fc, $fd, $fa, $ff, $f5, $fc, $fc, $f8, $fb, $f3, $f7, $e7, $ef, $e7
    db $ef, $e7, $ef, $cf, $df, $9f, $bf, $fe, $ff, $fe, $ff, $fe, $ff, $e0, $e0, $83
    db $8c, $77, $78, $f3, $fc, $fb, $fc, $7f, $7f, $7f, $7f, $7f, $7f, $07, $07, $c1
    db $31, $ee, $1e, $cf, $3f, $df, $3f, $3f, $3f, $1f, $df, $cf, $ef, $e7, $f7, $e7
    db $f7, $e7, $f7, $f3, $fb, $f9, $fd, $fe, $fe, $fc, $fd, $f9, $fb, $f9, $fb, $f9
    db $fb, $f9, $fb, $f3, $f7, $f7, $ff, $c1, $e3, $b8, $f8, $72, $7a, $ee, $fc, $dd
    db $fd, $db, $db, $dd, $dd, $ff, $ff, $b3, $b7, $3d, $3d, $4e, $5e, $77, $3f, $bb
    db $bf, $db, $df, $bb, $bf, $ff, $ff, $de, $df, $de, $df, $de, $df, $5e, $df, $6c
    db $ee, $a8, $ac, $cb, $cf, $f0, $f4, $fb, $fb, $fb, $ff, $fb, $ff, $7a, $fa, $36
    db $76, $15, $1f, $d3, $d3, $3f, $3f, $c1, $e3, $b8, $f8, $b2, $ba, $ae, $bc, $ed
    db $ed, $eb, $eb, $ed, $ed, $ff, $ff, $b3, $b7, $3d, $3d, $4d, $5d, $75, $3d, $b7
    db $bf, $d7, $df, $b7, $bf, $ff, $ff, $f6, $f7, $ee, $ef, $ee, $ef, $ae, $ef, $ac
    db $ee, $a8, $ac, $c3, $c7, $f0, $f4, $ef, $ef, $f7, $ff, $f7, $ff, $75, $f5, $35
    db $75, $15, $1f, $d3, $d3, $3f, $3f, $f1, $f3, $e8, $f8, $da, $fa, $d6, $dc, $cd
    db $dd, $eb, $eb, $f5, $f5, $ff, $ff, $af, $af, $37, $3f, $5b, $5f, $6b, $3b, $b3
    db $bb, $d7, $df, $af, $bf, $ff, $ff, $fe, $ff, $f8, $f9, $e6, $f7, $d6, $f7, $d4
    db $d6, $d0, $d4, $e3, $e7, $f0, $f4, $ff, $ff, $9f, $bf, $e7, $f7, $6b, $eb, $2b
    db $6b, $1b, $1f, $d7, $d7, $3f, $3f, $c1, $e3, $b8, $f8, $b2, $ba, $ae, $bc, $ed
    db $ed, $eb, $eb, $ed, $ed, $ff, $ff, $b3, $b7, $3d, $3d, $4d, $5d, $75, $3d, $b7
    db $bf, $d7, $df, $b7, $bf, $ff, $ff, $f6, $f7, $ee, $ef, $ee, $ef, $ae, $ef, $ac
    db $ee, $a8, $ac, $c3, $c7, $f0, $f4, $ef, $ef, $f7, $ff, $f7, $ff, $75, $f5, $35
    db $75, $15, $1f, $d3, $d3, $3f, $3f, $ff, $ef, $ff, $d7, $ef, $3b, $d7, $f4, $3b
    db $fb, $df, $df, $27, $27, $d8, $f8, $5b, $5b, $71, $71, $f1, $f1, $e4, $e4, $ee
    db $ee, $be, $be, $9f, $9f, $1f, $1f, $e3, $e3, $8f, $8f, $1f, $1f, $8f, $8f, $e7
    db $e7, $7c, $7c, $f8, $f8, $3e, $3e, $f8, $f8, $f9, $f9, $7d, $7d, $77, $77, $27
    db $27, $8f, $8f, $8e, $8e, $da, $da, $ff, $fb, $ff, $f5, $fb, $ce, $f5, $3d, $ce
    db $fe, $7f, $7f, $9c, $9c, $63, $e3, $e3, $e3, $c9, $c9, $dd, $dd, $7d, $7d, $3f
    db $3f, $3e, $3e, $b6, $b6, $e2, $e2, $f8, $f8, $8f, $8f, $3e, $3e, $7c, $7c, $3e
    db $3e, $9f, $9f, $f1, $f1, $e3, $e3, $47, $47, $6d, $6d, $7c, $7c, $fc, $fc, $be
    db $be, $bb, $bb, $93, $93, $c7, $c7, $ff, $fe, $ff, $7d, $fe, $b3, $7d, $4f, $b3
    db $bf, $fd, $fd, $72, $72, $8d, $8f, $ee, $ee, $be, $be, $9f, $9f, $1f, $1f, $5b
    db $5b, $71, $71, $f1, $f1, $e4, $e4, $3e, $3e, $f8, $f8, $f1, $f1, $f8, $f8, $7e
    db $7e, $c7, $c7, $8f, $8f, $e3, $e3, $27, $27, $8f, $8f, $8e, $8e, $da, $da, $f8
    db $f8, $f9, $f9, $7d, $7d, $77, $77, $ff, $bf, $ff, $5f, $bf, $ec, $5f, $d3, $ec
    db $ef, $f7, $f7, $c9, $c9, $36, $3e, $cf, $cf, $8f, $8f, $ad, $ad, $b8, $b8, $f8
    db $f8, $72, $72, $77, $77, $5f, $5f, $e3, $e3, $c7, $c7, $e3, $e3, $f9, $f9, $1f
    db $1f, $3e, $3e, $8f, $8f, $f8, $f8, $fa, $fa, $ee, $ee, $4e, $4e, $1f, $1f, $1d
    db $1d, $b5, $b5, $f1, $f1, $f3, $f3, $ff, $ff, $ff, $44, $66, $55, $66, $55, $66
    db $55, $66, $55, $44, $44, $ff, $ff, $ff, $ff, $44, $ff, $cc, $ee, $cc, $ee, $cc
    db $ee, $cc, $ee, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $22, $33, $aa, $33, $aa, $33
    db $aa, $33, $aa, $22, $22, $ff, $ff, $ff, $ff, $22, $ff, $66, $77, $66, $77, $66
    db $77, $66, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $88, $cc, $aa, $cc, $aa, $cc
    db $aa, $cc, $aa, $88, $88, $ff, $ff, $ff, $ff, $88, $ff, $99, $dd, $99, $dd, $99
    db $dd, $99, $dd, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $11, $99, $55, $99, $55, $99
    db $55, $99, $55, $11, $11, $ff, $ff, $ff, $ff, $11, $ff, $33, $bb, $33, $bb, $33
    db $bb, $33, $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $11, $99, $55, $99, $55, $99
    db $55, $99, $55, $11, $11, $ff, $ff, $ff, $ff, $11, $ff, $33, $bb, $33, $bb, $33
    db $bb, $33, $bb, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $88, $cc, $aa, $cc, $aa, $cc
    db $aa, $cc, $aa, $88, $88, $ff, $ff, $ff, $ff, $88, $ff, $99, $dd, $99, $dd, $99
    db $dd, $99, $dd, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $22, $33, $aa, $33, $aa, $33
    db $aa, $33, $aa, $22, $22, $ff, $ff, $ff, $ff, $22, $ff, $66, $77, $66, $77, $66
    db $77, $66, $77, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $44, $66, $55, $66, $55, $66
    db $55, $66, $55, $44, $44, $ff, $ff, $ff, $ff, $44, $ff, $cc, $ee, $cc, $ee, $cc
    db $ee, $cc, $ee, $ff, $ff, $ff, $ff, $ff, $ff, $c3, $3c, $c3, $3c, $f0, $f0, $e1
    db $ff, $3c, $00, $78, $00, $f0, $00, $f0, $00, $78, $00, $3c, $00, $1e, $00, $ff
    db $00, $c3, $3c, $c3, $3c, $ff, $ff, $ff, $ff, $c3, $3c, $c3, $3c, $0f, $0f, $87
    db $ff, $3c, $00, $1e, $00, $0f, $00, $0f, $00, $1e, $00, $3c, $00, $78, $00, $ff
    db $00, $c3, $3c, $c3, $3c, $ff, $ff, $ff, $ff, $0f, $f0, $0f, $f0, $c3, $c3, $87
    db $ff, $f0, $00, $e1, $00, $c3, $00, $c3, $00, $e1, $00, $f0, $00, $78, $00, $ff
    db $00, $0f, $f0, $0f, $f0, $ff, $ff, $ff, $ff, $f0, $0f, $f0, $0f, $c3, $c3, $e1
    db $ff, $0f, $00, $87, $00, $c3, $00, $c3, $00, $87, $00, $0f, $00, $1e, $00, $ff
    db $00, $f0, $0f, $f0, $0f, $ff, $ff, $ff, $ff, $3c, $c3, $3c, $c3, $0f, $0f, $1e
    db $ff, $c3, $00, $87, $00, $0f, $00, $0f, $00, $87, $00, $c3, $00, $e1, $00, $ff
    db $00, $3c, $c3, $3c, $c3, $ff, $ff, $ff, $ff, $3c, $c3, $3c, $c3, $f0, $f0, $78
    db $ff, $c3, $00, $e1, $00, $f0, $00, $f0, $00, $e1, $00, $c3, $00, $87, $00, $ff
    db $00, $3c, $c3, $3c, $c3, $ff, $ff, $ff, $ff, $f0, $0f, $f0, $0f, $3c, $3c, $78
    db $ff, $0f, $00, $1e, $00, $3c, $00, $3c, $00, $1e, $00, $0f, $00, $87, $00, $ff
    db $00, $f0, $0f, $f0, $0f, $ff, $ff, $ff, $ff, $0f, $f0, $0f, $f0, $3c, $3c, $1e
    db $ff, $f0, $00, $78, $00, $3c, $00, $3c, $00, $78, $00, $f0, $00, $e1, $00, $ff
    db $00, $0f, $f0, $0f, $f0, $ff, $ff, $c7, $ff, $ef, $38, $ff, $10, $7d, $a2, $9a
    db $45, $30, $8f, $28, $97, $10, $af, $00, $9f, $00, $8f, $00, $97, $00, $8a, $00
    db $45, $10, $10, $28, $38, $c7, $ff, $e3, $ff, $f7, $1c, $ff, $08, $be, $45, $59
    db $a2, $0c, $f1, $14, $e9, $08, $f5, $00, $f9, $00, $f1, $00, $e9, $00, $51, $00
    db $a2, $08, $08, $14, $1c, $e3, $ff, $1f, $ff, $bf, $e0, $ff, $40, $f5, $8a, $6a
    db $15, $c0, $3e, $a0, $5e, $40, $be, $00, $7e, $00, $3e, $00, $5e, $00, $2a, $00
    db $15, $40, $40, $a0, $e0, $1f, $ff, $f8, $ff, $fd, $07, $ff, $02, $af, $51, $56
    db $a8, $03, $7c, $05, $7a, $02, $7d, $00, $7e, $00, $7c, $00, $7a, $00, $54, $00
    db $a8, $02, $02, $05, $07, $f8, $ff, $7c, $ff, $fe, $83, $ff, $01, $d7, $2a, $a9
    db $54, $03, $f8, $82, $79, $01, $fa, $00, $f9, $00, $f8, $00, $79, $00, $a8, $00
    db $54, $01, $01, $82, $83, $7c, $ff, $3e, $ff, $7f, $c1, $ff, $80, $eb, $54, $95
    db $2a, $c0, $1f, $41, $9e, $80, $5f, $00, $9f, $00, $1f, $00, $9e, $00, $15, $00
    db $2a, $80, $80, $41, $c1, $3e, $ff, $f1, $ff, $fb, $0e, $ff, $04, $5f, $a8, $a6
    db $51, $0c, $e3, $0a, $e5, $04, $eb, $00, $e7, $00, $e3, $00, $e5, $00, $a2, $00
    db $51, $04, $04, $0a, $0e, $f1, $ff, $8f, $ff, $df, $70, $ff, $20, $fa, $15, $65
    db $8a, $30, $c7, $50, $a7, $20, $d7, $00, $e7, $00, $c7, $00, $a7, $00, $45, $00
    db $8a, $20, $20, $50, $70, $8f, $ff, $02, $fd, $03, $fc, $01, $fc, $00, $ff, $05
    db $fa, $24, $da, $25, $da, $13, $c8, $80, $7f, $10, $ef, $20, $4f, $40, $1f, $00
    db $bf, $24, $5b, $24, $db, $08, $33, $21, $ce, $12, $cd, $11, $ec, $48, $a5, $25
    db $da, $04, $e3, $82, $79, $81, $78, $08, $b3, $90, $67, $60, $97, $00, $2f, $04
    db $9b, $04, $7b, $08, $93, $98, $47, $02, $fd, $03, $fc, $01, $fc, $00, $ff, $05
    db $fa, $24, $da, $25, $da, $13, $c8, $80, $7f, $10, $ef, $20, $4f, $40, $1f, $00
    db $bf, $24, $5b, $24, $db, $08, $33, $21, $ce, $12, $cd, $11, $ec, $48, $a5, $25
    db $da, $04, $e3, $82, $79, $81, $78, $08, $b3, $90, $67, $60, $97, $00, $2f, $04
    db $9b, $04, $7b, $08, $93, $98, $47, $02, $fd, $03, $fc, $01, $fc, $00, $ff, $05
    db $fa, $24, $da, $25, $da, $13, $c8, $80, $7f, $10, $ef, $20, $4f, $40, $1f, $00
    db $bf, $24, $5b, $24, $db, $08, $33, $21, $ce, $12, $cd, $11, $ec, $48, $a5, $25
    db $da, $04, $e3, $82, $79, $81, $78, $08, $b3, $90, $67, $60, $97, $00, $2f, $04
    db $9b, $04, $7b, $08, $93, $98, $47, $02, $fd, $03, $fc, $01, $fc, $00, $ff, $05
    db $fa, $24, $da, $25, $da, $13, $c8, $80, $7f, $10, $ef, $20, $4f, $40, $1f, $00
    db $bf, $24, $5b, $24, $db, $08, $33, $21, $ce, $12, $cd, $11, $ec, $48, $a5, $25
    db $da, $04, $e3, $82, $79, $81, $78, $08, $b3, $90, $67, $60, $97, $00, $2f, $04
    db $9b, $04, $7b, $08, $93, $98, $47, $ff, $01, $ff, $01, $ff, $01, $ff, $02, $ff
    db $02, $ff, $02, $ff, $1c, $ff, $e0, $ff, $80, $ff, $80, $ff, $80, $7f, $c0, $7f
    db $c0, $7f, $c0, $3f, $b8, $7f, $07, $e0, $fe, $fd, $1c, $ff, $02, $ff, $02, $ff
    db $02, $ff, $01, $ff, $01, $ff, $01, $07, $7f, $3f, $f8, $7f, $c0, $7f, $c0, $7f
    db $c0, $ff, $80, $ff, $80, $ff, $80, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff
    db $00, $ff, $ff, $ff, $60, $f8, $1f, $ff, $20, $ff, $60, $ff, $60, $ff, $a0, $ff
    db $a0, $bf, $60, $bf, $60, $3f, $a0, $fc, $06, $fe, $04, $fe, $05, $ff, $05, $ff
    db $05, $ff, $06, $ff, $06, $ff, $04, $7f, $18, $07, $3e, $ff, $ff, $ff, $00, $ff
    db $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $30, $ff, $28, $ff
    db $16, $fd, $0b, $fa, $0d, $fd, $06, $ff, $00, $ff, $00, $ff, $0c, $ff, $14, $ff
    db $68, $ff, $90, $df, $30, $bf, $60, $ff, $04, $fe, $09, $fd, $0b, $ff, $16, $ff
    db $28, $ff, $30, $ff, $00, $ff, $00, $3f, $a0, $1f, $50, $9f, $b0, $ef, $78, $f7
    db $1c, $ff, $0c, $ff, $00, $ff, $00, $ff, $04, $ff, $06, $ff, $06, $ff, $05, $ff
    db $05, $fe, $05, $fe, $05, $fe, $05, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff
    db $00, $ff, $ff, $ff, $06, $1f, $78, $fe, $19, $f8, $64, $ff, $ff, $ff, $00, $ff
    db $00, $ff, $00, $ff, $00, $ff, $00, $3f, $20, $3f, $a0, $bf, $20, $bf, $e0, $bf
    db $e0, $ff, $60, $ff, $60, $ff, $20, $01, $ff, $01, $ff, $01, $ff, $03, $fe, $03
    db $fe, $03, $fe, $1f, $fc, $ff, $e0, $80, $ff, $80, $ff, $80, $ff, $40, $ff, $40
    db $ff, $40, $ff, $38, $bf, $7f, $07, $e0, $fe, $1d, $fc, $03, $fe, $03, $fe, $03
    db $fe, $01, $ff, $01, $ff, $01, $ff, $07, $7f, $38, $ff, $40, $ff, $40, $ff, $40
    db $ff, $80, $ff, $80, $ff, $80, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
    db $ff, $ff, $ff, $7f, $e0, $18, $ff, $20, $ff, $60, $ff, $60, $ff, $e0, $bf, $e0
    db $bf, $a0, $7f, $a0, $7f, $20, $bf, $04, $fe, $06, $fc, $06, $fd, $07, $fd, $07
    db $fd, $06, $ff, $06, $ff, $04, $ff, $78, $1f, $06, $3f, $ff, $ff, $00, $ff, $00
    db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $30, $ff, $38, $ef, $1e
    db $f7, $0d, $fb, $0a, $fd, $05, $fe, $00, $ff, $00, $ff, $0c, $ff, $1c, $f7, $78
    db $ef, $f0, $9f, $d0, $3f, $a0, $7f, $07, $fc, $0e, $f9, $0d, $fb, $1e, $f7, $38
    db $ef, $30, $ff, $00, $ff, $00, $ff, $20, $bf, $10, $5f, $90, $bf, $68, $ff, $14
    db $ff, $0c, $ff, $00, $ff, $00, $ff, $04, $ff, $06, $ff, $06, $ff, $07, $fd, $07
    db $fd, $06, $fd, $06, $fd, $06, $fd, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
    db $ff, $ff, $ff, $fe, $07, $18, $7f, $1e, $f9, $78, $e4, $ff, $ff, $00, $ff, $00
    db $ff, $00, $ff, $00, $ff, $00, $ff, $20, $3f, $20, $bf, $a0, $3f, $a0, $ff, $a0
    db $ff, $60, $ff, $60, $ff, $20, $ff, $ff, $10, $ef, $38, $d7, $ec, $23, $d7, $c0
    db $3b, $00, $df, $00, $27, $20, $d8, $1c, $e3, $70, $8f, $e0, $1f, $70, $8f, $18
    db $e7, $83, $7c, $07, $f8, $c1, $3e, $00, $ef, $00, $e7, $00, $e3, $00, $e9, $00
    db $c9, $00, $d1, $00, $a3, $00, $8b, $00, $a3, $00, $83, $00, $d1, $00, $c9, $00
    db $e9, $00, $e3, $08, $ff, $08, $ff, $ff, $04, $fb, $0e, $f5, $3b, $c8, $f5, $30
    db $ce, $00, $7f, $00, $9c, $80, $63, $07, $f8, $70, $8f, $c1, $3e, $83, $7c, $c1
    db $3e, $60, $9f, $0e, $f1, $1c, $e3, $00, $f7, $00, $e7, $00, $c7, $00, $a3, $00
    db $a3, $00, $a7, $00, $a7, $00, $8b, $00, $d1, $00, $c1, $00, $d1, $00, $c9, $00
    db $e9, $00, $e3, $08, $ff, $08, $ff, $ff, $01, $fe, $83, $7d, $ce, $32, $7d, $0c
    db $b3, $00, $fd, $00, $72, $02, $8d, $c1, $3e, $07, $f8, $0e, $f1, $07, $f8, $81
    db $7e, $38, $c7, $70, $8f, $1c, $e3, $00, $df, $00, $cf, $00, $8f, $00, $a7, $00
    db $a7, $00, $a3, $00, $d1, $00, $e1, $00, $d1, $00, $c1, $00, $d1, $00, $d3, $00
    db $cb, $00, $e3, $08, $ff, $08, $ff, $ff, $40, $bf, $e0, $5f, $b3, $8c, $5f, $03
    db $ec, $00, $f7, $00, $c9, $08, $36, $1c, $e3, $38, $c7, $1c, $e3, $06, $f9, $e0
    db $1f, $c1, $3e, $70, $8f, $07, $f8, $00, $bf, $00, $9f, $00, $87, $00, $d1, $00
    db $e9, $00, $e9, $00, $e9, $00, $c1, $00, $d3, $00, $c3, $00, $d3, $00, $d3, $00
    db $cb, $00, $e3, $08, $ff, $08, $ff, $ff, $88, $ff, $55, $ff, $22, $ff, $5f, $f0
    db $90, $f0, $57, $f0, $37, $f0, $57, $ff, $88, $ff, $55, $ff, $22, $ff, $f9, $0f
    db $0a, $0f, $ec, $0f, $ea, $0f, $e9, $f0, $97, $f0, $57, $f0, $37, $f0, $50, $ff
    db $9f, $ff, $44, $ff, $2a, $ff, $51, $0f, $ea, $0f, $ec, $0f, $ea, $0f, $09, $ff
    db $fa, $ff, $44, $ff, $aa, $ff, $11, $ff, $44, $ff, $aa, $ff, $51, $ff, $9f, $f5
    db $55, $f8, $38, $f0, $53, $f8, $9b, $ff, $44, $ff, $aa, $ff, $11, $ff, $fa, $5f
    db $59, $0f, $0a, $1f, $dc, $0f, $ca, $f0, $53, $f8, $3b, $f0, $50, $fa, $9a, $ff
    db $5f, $ff, $88, $ff, $55, $ff, $a2, $1f, $d9, $0f, $ca, $1f, $1c, $af, $aa, $ff
    db $f9, $ff, $8a, $ff, $55, $ff, $22, $ff, $22, $ff, $55, $ff, $88, $ff, $5f, $ff
    db $3f, $fa, $5a, $fc, $9c, $f8, $59, $ff, $22, $ff, $55, $ff, $8a, $ff, $fc, $ff
    db $fa, $bf, $b9, $1f, $1a, $3f, $bc, $fc, $3d, $f8, $58, $fd, $9d, $ff, $5f, $ff
    db $3f, $ff, $51, $ff, $aa, $ff, $44, $1f, $9a, $3f, $39, $5f, $5a, $ff, $fc, $ff
    db $fa, $ff, $11, $ff, $aa, $ff, $44, $ff, $11, $ff, $aa, $ff, $44, $ff, $3f, $f5
    db $55, $f8, $98, $f0, $53, $f8, $3b, $ff, $11, $ff, $aa, $ff, $45, $ff, $fa, $5f
    db $5c, $0f, $0a, $1f, $d9, $0f, $ca, $f0, $53, $f8, $9b, $f0, $50, $fa, $3a, $ff
    db $5f, $ff, $a2, $ff, $55, $ff, $88, $1f, $dc, $0f, $ca, $1f, $19, $af, $aa, $ff
    db $fc, $ff, $22, $ff, $55, $ff, $8a, $26, $d8, $5d, $a0, $7b, $80, $76, $81, $ec
    db $02, $69, $84, $69, $84, $b4, $42, $d4, $2b, $6a, $15, $bd, $02, $ba, $05, $5d
    db $82, $2a, $45, $2e, $41, $1d, $c2, $40, $80, $cc, $13, $40, $80, $80, $70, $46
    db $b1, $06, $f1, $03, $f8, $00, $fc, $03, $00, $02, $c9, $02, $01, $03, $0c, $02
    db $cd, $00, $8f, $00, $9f, $00, $3f, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
    db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
    db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $c0, $0c, $d3, $00, $c0, $00, $f0, $06
    db $f1, $06, $f1, $03, $f8, $00, $fc, $00, $03, $00, $cb, $00, $03, $00, $0f, $00
    db $cf, $00, $8f, $00, $9f, $00, $3f, $1b, $e4, $2e, $d0, $5e, $a0, $3d, $c0, $5a
    db $a1, $34, $c2, $55, $a0, $38, $c2, $6a, $15, $b7, $08, $da, $05, $5d, $82, $2d
    db $42, $16, $21, $17, $20, $2e, $41, $c0, $00, $cc, $13, $40, $80, $a0, $50, $06
    db $f1, $06, $f1, $03, $f8, $00, $fc, $03, $00, $02, $c9, $03, $00, $03, $0c, $02
    db $cd, $00, $8f, $00, $9f, $00, $3f, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
    db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00, $ff, $00
    db $ff, $00, $ff, $00, $ff, $00, $ff, $00, $c0, $0c, $d3, $00, $c0, $00, $f0, $06
    db $f1, $06, $f1, $03, $f8, $00, $fc, $00, $03, $00, $cb, $00, $03, $00, $0f, $00
    db $cf, $00, $8f, $00, $9f, $00, $3f, $ff, $10, $ef, $38, $d7, $ec, $23, $d7, $c0
    db $3b, $00, $df, $00, $27, $20, $d8, $a4, $5b, $8e, $71, $0e, $f1, $1b, $e4, $11
    db $ee, $41, $be, $60, $9f, $e0, $1f, $1c, $e3, $70, $8f, $e0, $1f, $70, $8f, $18
    db $e7, $83, $7c, $07, $f8, $c1, $3e, $00, $7e, $00, $3f, $00, $3f, $00, $7e, $00
    db $7e, $00, $fc, $00, $fc, $00, $7e, $ff, $04, $fb, $0e, $f5, $3b, $c8, $f5, $30
    db $ce, $00, $7f, $00, $9c, $80, $63, $1c, $e3, $36, $c9, $22, $dd, $82, $7d, $c0
    db $3f, $c1, $3e, $49, $b6, $1d, $e2, $07, $f8, $70, $8f, $c1, $3e, $83, $7c, $c1
    db $3e, $60, $9f, $0e, $f1, $1c, $e3, $00, $3f, $00, $7e, $00, $7e, $00, $fc, $00
    db $fc, $00, $7e, $00, $7e, $00, $3f, $ff, $01, $fe, $83, $7d, $ce, $32, $7d, $0c
    db $b3, $00, $fd, $00, $72, $02, $8d, $11, $ee, $41, $be, $60, $9f, $e0, $1f, $a4
    db $5b, $8e, $71, $0e, $f1, $1b, $e4, $c1, $3e, $07, $f8, $0e, $f1, $07, $f8, $81
    db $7e, $38, $c7, $70, $8f, $1c, $e3, $00, $7e, $00, $fc, $00, $fc, $00, $7e, $00
    db $7e, $00, $3f, $00, $3f, $00, $7e, $ff, $40, $bf, $e0, $5f, $b3, $8c, $5f, $03
    db $ec, $00, $f7, $00, $c9, $08, $36, $30, $cf, $70, $8f, $52, $ad, $47, $b8, $07
    db $f8, $8d, $72, $88, $77, $a0, $5f, $1c, $e3, $38, $c7, $1c, $e3, $06, $f9, $e0
    db $1f, $c1, $3e, $70, $8f, $07, $f8, $00, $fc, $00, $7e, $00, $7e, $00, $3f, $00
    db $3f, $00, $7e, $00, $7e, $00, $fc, $88, $77, $00, $ff, $22, $dd, $10, $ef, $20
    db $cf, $40, $8f, $40, $9e, $40, $88, $88, $77, $00, $ff, $22, $dd, $08, $f7, $04
    db $f3, $02, $f1, $02, $79, $02, $11, $20, $c0, $60, $80, $a0, $10, $92, $22, $97
    db $17, $97, $17, $be, $3e, $b8, $38, $04, $03, $06, $01, $05, $08, $49, $44, $e9
    db $e8, $e9, $e8, $7d, $7c, $1d, $1c, $84, $7b, $0e, $f5, $2f, $d6, $0f, $f7, $0f
    db $f7, $3f, $cf, $7d, $ad, $78, $a8, $28, $d7, $70, $af, $f2, $6d, $f0, $ef, $f0
    db $ef, $fc, $f3, $be, $b5, $1e, $15, $70, $b0, $60, $a0, $60, $a0, $20, $c0, $20
    db $c0, $10, $e0, $10, $e0, $10, $e0, $0e, $0d, $06, $05, $06, $05, $04, $03, $04
    db $03, $08, $07, $08, $07, $08, $07, $88, $77, $00, $ff, $22, $dd, $10, $ef, $20
    db $cf, $40, $8f, $40, $9e, $40, $88, $88, $77, $00, $ff, $22, $dd, $08, $f7, $04
    db $f3, $02, $f1, $02, $79, $02, $11, $20, $c0, $60, $80, $a0, $10, $92, $22, $97
    db $17, $97, $17, $be, $3e, $b8, $38, $04, $03, $06, $01, $05, $08, $49, $44, $e9
    db $e8, $e9, $e8, $7d, $7c, $1d, $1c, $84, $7b, $0e, $f5, $2f, $d6, $0f, $f7, $0f
    db $f7, $3f, $cf, $7d, $ad, $78, $a8, $28, $d7, $70, $af, $f2, $6d, $f0, $ef, $f0
    db $ef, $fc, $f3, $be, $b5, $1e, $15, $70, $b0, $60, $a0, $60, $a0, $20, $c0, $20
    db $c0, $10, $e0, $10, $e0, $10, $e0, $0e, $0d, $06, $05, $06, $05, $04, $03, $04
    db $03, $08, $07, $08, $07, $08, $07, $ff, $10, $ef, $38, $d7, $ec, $23, $d7, $c0
    db $3b, $00, $df, $00, $27, $20, $d8, $06, $f9, $1d, $e2, $3b, $c4, $f7, $08, $2e
    db $d1, $6d, $92, $6d, $92, $b6, $48, $c0, $3f, $6a, $95, $ba, $45, $ba, $45, $dc
    db $23, $6a, $95, $6e, $91, $dc, $23, $00, $ff, $40, $ba, $a0, $5f, $40, $bf, $00
    db $ff, $08, $57, $14, $eb, $08, $f7, $ff, $04, $fb, $0e, $f5, $3b, $c8, $f5, $30
    db $ce, $00, $7f, $00, $9c, $80, $63, $03, $fc, $16, $e9, $0e, $f1, $fd, $02, $1b
    db $e4, $36, $c9, $55, $aa, $ba, $44, $60, $9f, $ba, $45, $da, $25, $de, $21, $ec
    db $13, $f6, $09, $76, $89, $ee, $11, $00, $ff, $00, $fa, $08, $f7, $14, $eb, $09
    db $f6, $82, $5d, $01, $ee, $00, $ff, $ff, $01, $fe, $83, $7d, $ce, $32, $7d, $0c
    db $b3, $00, $fd, $00, $72, $02, $8d, $06, $f9, $1d, $e2, $3b, $c4, $f7, $08, $2e
    db $d1, $6d, $92, $6d, $92, $b6, $48, $c0, $3f, $6a, $95, $ba, $45, $ba, $45, $dc
    db $23, $6a, $95, $6e, $91, $dc, $23, $00, $ff, $02, $f8, $05, $fa, $02, $fd, $00
    db $ff, $40, $1f, $a0, $4f, $40, $bf, $ff, $40, $bf, $e0, $5f, $b3, $8c, $5f, $03
    db $ec, $00, $f7, $00, $c9, $08, $36, $03, $fc, $16, $e9, $0e, $f1, $fd, $02, $1b
    db $e4, $36, $c9, $55, $aa, $ba, $44, $60, $9f, $ba, $45, $da, $25, $de, $21, $ec
    db $13, $f6, $09, $76, $89, $ee, $11, $00, $ff, $00, $fa, $80, $7f, $41, $be, $90
    db $6f, $28, $57, $10, $cf
; --- END re-sectioned text run (bank $4b) ---
    nop
    rst $38

