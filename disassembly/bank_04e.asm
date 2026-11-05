; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $04e", ROMX[$4000], BANK[$4e]

    db $4E ; Bank number

    ; Cross-bank dispatch table (92 entries)
    ; Called via: ld hl, $4EXX / rst $10
    dw LoadB4e_40b9                  ; Entry 0
    dw TextRunB4E_40e7               ; Entry 1
    dw TextShowRefreshB4E_4115       ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw TextStr_4e_4143               ; Entry 4 — [table $4009]; text $0868 "*:To show my appreciation, I'll o…"
    dw TextStr_4e_41c3               ; Entry 5 — text $0869 "*:Hi. Welcome to the library. *:Y…"
    dw TextStr_4e_428e               ; Entry 6 — text $086A "*:W, Well, it's no use asking me.…"
    dw TextStr_4e_42cf               ; Entry 7 — text $086B "*:To win, train your monsters beh…"
    dw TextStr_4e_43ce               ; Entry 8 — text $086C "*:We gather here at the arena, se…"
    dw TextStr_4e_44b6               ; Entry 9 — text $086D "*:All monsters are born from eggs."
    dw TextStr_4e_44dc               ; Entry 10 — text $086E "*:Eggs will be eggs forever if le…"
    dw TextStr_4e_4586               ; Entry 11 — text $086F ":If you choose CHARGE you can tra…"
    dw TextStr_4e_4721               ; Entry 12 — text $0870 "[HERO] returned the old lady's no…"
    dw TextStr_4e_4755               ; Entry 13 — text $0871 "*:Hmmm. It's unfortunate."
    dw TextStr_4e_4771               ; Entry 14 — text $0872 "*:Hmmm. You survived G class. Wel…"
    dw TextStr_4e_4865               ; Entry 15 — text $0873 "*:Hmm. You survived F class. Cong…"
    dw TextStr_4e_4957               ; Entry 16 — text $0874 "*:There will be Spookys, ArmyAnts…"
    dw TextStr_4e_4a71               ; Entry 17 — text $0875 "*:Humpf, okay."
    dw TextStr_4e_4a84               ; Entry 18 — text $0876 "*:Would you like to hear about th…"
    dw TextStr_4e_4ac1               ; Entry 19 — text $0877 "*:There were MiniDraks, BigRoosts…"
    dw TextStr_4e_4c5f               ; Entry 20 — text $0878 "*:Want to know about the monsters…"
    dw TextStr_4e_4ca5               ; Entry 21 — text $0879 "*:There were Goopis, PillowRats, …"
    dw TextStr_4e_4dfe               ; Entry 22 — text $087A "*:There are characteristics for m…"
    dw TextStr_4e_4ef1               ; Entry 23 — text $087B "*:Dragons with Metaly parents *:a…"
    dw TextStr_4e_5035               ; Entry 24 — text $087C "*:Would you like to hear about th…"
    dw TextStr_4e_506f               ; Entry 25 — text $087D "*:There were BigRoosts, SpotSlime…"
    dw TextStr_4e_519e               ; Entry 26 — text $087E "*:Want to know about the monsters…"
    dw TextStr_4e_51e3               ; Entry 27 — text $087F "*:There are Demonites, BeanMen, 1…"
    dw TextStr_4e_5319               ; Entry 28 — text $0880 "*:You survived E class, You did b…"
    dw TextStr_4e_5357               ; Entry 29 — text $0881 "*:IceMan has a relative!! *:It is…"
    dw TextStr_4e_53e2               ; Entry 30 — text $0882 "*:When you choose COMMAND, very w…"
    dw TextStr_4e_54d9               ; Entry 31 — text $0883 "*:Would you like to learn about t…"
    dw TextStr_4e_5514               ; Entry 32 — text $0884 "*:There were GiantWorms, Poisongo…"
    dw TextStr_4e_5696               ; Entry 33 — text $0885 "*:Want to know about the monsters…"
    dw TextStr_4e_56dc               ; Entry 34 — text $0886 "*:There are MudDolls, TreeSlimes,…"
    dw TextStr_4e_582a               ; Entry 35 — text $0887 "*:When the family of the pedigree…"
    dw TextStr_4e_5973               ; Entry 36 — text $0888 "*:There are foreign masters whose…"
    dw TextStr_4e_5a0c               ; Entry 37 — text $0889 "[HERO] reads the blackboard. *:Th…"
    dw TextStr_4e_5b17               ; Entry 38 — text $088A "*:Namely, dragons with Metaly par…"
    dw TextStr_4e_5bc4               ; Entry 39 — text $088B "*:A mnemonic for useful skills an…"
    dw TextStr_4e_5c86               ; Entry 40 — text $088C "*:Would you like to learn about t…"
    dw TextStr_4e_5cbf               ; Entry 41 — text $088D "*:There were Snailys, Saccers, Gu…"
    dw TextStr_4e_5e49               ; Entry 42 — text $088E "*:Want to know about the monsters…"
    dw TextStr_4e_5e8d               ; Entry 43 — text $088F "*:There are Facers, Tonguellas, F…"
    dw TextStr_4e_5fb3               ; Entry 44 — text $0890 "*:Would you like to hear about th…"
    dw TextStr_4e_5ff1               ; Entry 45 — text $0891 "*:There are Onionos, Gophecadas, …"
    dw TextStr_4e_60f2               ; Entry 46 — text $0892 "*:Want to know about the monsters…"
    dw TextStr_4e_613a               ; Entry 47 — text $0893 "*:There are SpikyBoys, KingCobras…"
    dw TextStr_4e_62b5               ; Entry 48 — text $0894 "*:The Hork downstairs wants to le…"
    dw TextStr_4e_6352               ; Entry 49 — text $0895 "*:Monsters can inherit all the sk…"
    dw TextStr_4e_6493               ; Entry 50 — text $0896 "*:Its parents only learned Heal, …"
    dw TextStr_4e_6607               ; Entry 51 — text $0897 "*:I took notes on how to change t…"
    dw TextStr_4e_6662               ; Entry 52 — text $0898 "[HERO] opened the notebook. :When…"
    dw TextStr_4e_67ba               ; Entry 53 — text $0899 "*:I took notes on how to catch mo…"
    dw TextStr_4e_67fd               ; Entry 54 — text $089A "*:Foreign masters have lots of ki…"
    dw TextStr_4e_6889               ; Entry 55 — text $089B "*:Gate of Labyrinth. Want to lear…"
    dw TextStr_4e_68be               ; Entry 56 — text $089C "*:There are RockSlimes, Chamelgon…"
    dw TextStr_4e_69f4               ; Entry 57 — text $089D "*:Want to know about the monsters…"
    dw TextStr_4e_6a3a               ; Entry 58 — text $089E "*:There are WeedBugs, HammerMen, …"
    dw TextStr_4e_6b4b               ; Entry 59 — text $089F "*:You want to learn about the Gat…"
    dw TextStr_4e_6b85               ; Entry 60 — text $08A0 "*:I don't want to tell you this. …"
    dw TextStr_4e_6ca5               ; Entry 61 — text $08A1 "*:I don't want to be reminded of …"
    dw TextStr_4e_6ce4               ; Entry 62 — text $08A2 "*:What? You want to know about th…"
    dw TextStr_4e_6d23               ; Entry 63 — text $08A3 "*:I see... I don't remember much.…"
    dw TextStr_4e_6e62               ; Entry 64 — text $08A4 "*:Tut, you remind me of bad memor…"
    dw TextStr_4e_6e90               ; Entry 65 — text $08A5 "*:I,I thought you went to the Gat…"
    dw TextStr_4e_6f15               ; Entry 66 — text $08A6 "*:Oh, you haven't visited the Gat…"
    dw TextStr_4e_6fcd               ; Entry 67 — text $08A7 "*:You, must obey me. *:I want to …"
    dw TextStr_4e_7033               ; Entry 68 — text $08A8 "*:Oh, It is KingLeo! How majestic…"
    dw TextStr_4e_708c               ; Entry 69 — text $08A9 "*:It's a SmartBk Use it wisely!"
    dw TextStr_4e_70ae               ; Entry 70 — text $08AA "*:You, must obey me! *:Bring me a…"
    dw TextStr_4e_711a               ; Entry 71 — text $08AB "*:Oh, It is RainHawk! What beauti…"
    dw TextStr_4e_717b               ; Entry 72 — text $08AC "*:It's a BeNiceBK. Use it wisely."
    dw TextStr_4e_719f               ; Entry 73 — text $08AD "*:You must obey me! *:I want to s…"
    dw TextStr_4e_7209               ; Entry 74 — text $08AE "*:Oh! it is Armorpion! What a sca…"
    dw TextStr_4e_7270               ; Entry 75 — text $08AF "*:It is QuestBK. Use it wisely."
    dw TextStr_4e_7293               ; Entry 76 — text $08B0 "*:You must obey me. *:I want to s…"
    dw TextStr_4e_72f3               ; Entry 77 — text $08B1 "*:It's a Rosevine! How snaky it i…"
    dw TextStr_4e_734c               ; Entry 78 — text $08B2 "It's a LifeAcorn. Use it wisely."
    dw TextStr_4e_736f               ; Entry 79 — text $08B3 "*:You must obey me. *:I want to s…"
    dw TextStr_4e_73d8               ; Entry 80 — text $08B4 "*:It's GoldGolem! I could be blin…"
    dw TextStr_4e_7445               ; Entry 81 — text $08B5 "*:It's a TinyMedal. Use it wisely."
    dw TextStr_4e_746f               ; Entry 82 — text $08B6 "*:You must obey me. *:I want to s…"
    dw TextStr_4e_74dc               ; Entry 83 — text $08B7 "*:It's Divinegon! How noble! *:We…"
    dw TextStr_4e_752e               ; Entry 84 — text $08B8 "*:It's a TinyMedal. Use it wisely."
    dw TextStr_4e_7559               ; Entry 85 — text $08B9 "*:[HERO], my hearts content. *:Th…"
    dw TextStr_4e_75ea               ; Entry 86 — text $08BA "*:Her Majesty, the Queen of Great…"
    dw TextStr_4e_76b1               ; Entry 87 — text $08BB "*:Her Majesty desires a KingSlime…"
    dw TextStr_4e_770a               ; Entry 88 — text $08BC "*:Her Majesty desires a Florajay.…"
    dw TextStr_4e_7764               ; Entry 89 — text $08BD "*:Her Majesty desires a CurseLamp…"
    dw TextStr_4e_77c8               ; Entry 90 — text $08BE "*:I'm Mick. Those clingy fans are…"
    dw TextStr_4e_79a8               ; Entry 91 — text $08BF "*:Her Majesty desires WildApe. *:…"

LoadB4e_40b9:
    ld a, [$c822]
    cp $01
    jr nz, jr_04e_40ca

    ld a, $01
    ld [$c822], a
    ld hl, $4f00
    rst $10
    ret


jr_04e_40ca:
    ld a, [$c823]
    cp $58
    jr c, jr_04e_40e0

    sub $58
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4f00
    rst $10
    ret


jr_04e_40e0:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB4E_40e7:
    ld a, [$c822]
    cp $01
    jr nz, jr_04e_40f8

    ld a, $01
    ld [$c822], a
    ld hl, $4f01
    rst $10
    ret


jr_04e_40f8:
    ld a, [$c823]
    cp $58
    jr c, jr_04e_410e

    sub $58
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4f01
    rst $10
    ret


jr_04e_410e:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB4E_4115:
    ld a, [$c822]
    cp $01
    jr nz, jr_04e_4126

    ld a, $01
    ld [$c822], a
    ld hl, $4f02
    rst $10
    ret


jr_04e_4126:
    ld a, [$c823]
    cp $58
    jr c, jr_04e_413c

    sub $58
    ld [$c823], a
    ld a, $00
    ld [$c822], a
    ld hl, $4f02
    rst $10
    ret


jr_04e_413c:
    call LoadB4e_40b9
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $4e: $4143-$7a0d) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_4e_4143:           ; id $0868
    ; "*:To show my appreciation, I'll / open the Travelers' Gates. / *:It'll be ready as soon as I find / it. Come back later!"
    db $eb, $9f, $a3, $37, $4c, $62, $50, $45, $4c, $54, $62, $4a, $56, $ef, $ee, $3e
    db $4d, $4d, $4f, $42, $40, $46, $3e, $51, $46, $4c, $4b, $5e, $62, $2c, $66, $49
    db $fa, $f7, $ef, $ee, $4c, $4d, $42, $4b, $62, $51, $45, $42, $ef, $ee, $37, $4f
    db $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $51, $66, $49, $62, $3f, $42, $62, $4f, $42, $3e
    db $41, $56, $ef, $ee, $3e, $50, $62, $50, $4c, $4c, $4b, $62, $3e, $50, $62, $2c
    db $62, $43, $46, $4b, $41, $fa, $f7, $ef, $ee, $46, $51, $5f, $62, $26, $4c, $4a
    db $42, $62, $3f, $3e, $40, $48, $ef, $ee, $49, $3e, $51, $42, $4f, $63, $f7, $f0
TextStr_4e_41c3:           ; id $0869
    ; "*:Hi. Welcome to the library. / *:You're a monster master aren't you? / Doing well with taming monsters? / *:The proof of a powerful monster..."
    db $eb, $9f, $a3, $2b, $46, $5f, $62, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51
    db $4c, $ef, $ee, $51, $45, $42, $62, $49, $46, $3f, $4f, $3e, $4f, $56, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $3e, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $3e, $4f, $42
    db $4b, $67, $62, $56, $4c, $52, $64, $fa, $f7, $ef, $ee, $27, $4c, $46, $4b, $44
    db $62, $54, $42, $49, $49, $62, $54, $46, $51, $45, $ef, $ee, $51, $3e, $4a, $46
    db $4b, $44, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $64, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $4d, $4f, $4c, $4c, $43, $62, $4c, $43, $62, $3e
    db $ef, $ee, $4d, $4c, $54, $42, $4f, $43, $52, $49, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $fa, $f7, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $46, $50, $5e
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $45, $3e, $53, $46, $4b, $44, $62, $49
    db $4c, $51, $50, $62, $4c, $43, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62
    db $43, $4f, $46, $42, $4b, $41, $50, $63, $fa, $f7, $f0
TextStr_4e_428e:           ; id $086A
    ; "*:W, Well, it's no use asking me. / *:Ask the people inside."
    db $ea, $9f, $a3, $3a, $5e, $62, $3a, $42, $49, $49, $5e, $62, $46, $51, $68, $62
    db $4b, $4c, $ef, $ee, $52, $50, $42, $62, $3e, $50, $48, $46, $4b, $44, $62, $4a
    db $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $50, $48, $62, $51, $45, $42, $62
    db $4d, $42, $4c, $4d, $49, $42, $ef, $ee, $46, $4b, $50, $46, $41, $42, $5f, $f7
    db $f0
TextStr_4e_42cf:           ; id $086B
    ; "*:To win, train your monsters / behind the Travelers' Gates, / *:or make stronger monsters your / pals. / *:The only Travelers' Gate / you c..."
    db $ea, $9f, $a3, $37, $4c, $62, $54, $46, $4b, $5e, $62, $51, $4f, $3e, $46, $4b
    db $ef, $ee, $56, $4c, $52, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa
    db $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $ef, $ee, $37
    db $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $50, $5e
    db $fa, $f7, $ef, $ee, $9f, $a3, $4c, $4f, $62, $4a, $3e, $48, $42, $62, $50, $51
    db $4f, $4c, $4b, $44, $42, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $4d, $3e, $49, $50, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4c, $4b, $49, $56, $ef, $ee
    db $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $fa
    db $f7, $ef, $ee, $56, $4c, $52, $62, $40, $3e, $4b, $62, $44, $4c, $62, $46, $4b
    db $62, $4b, $4c, $54, $ef, $ee, $46, $50, $62, $51, $45, $42, $62, $2a, $3e, $51
    db $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $25, $42, $44, $46, $4b, $4b, $46, $4b
    db $44, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62, $3f
    db $3e, $40, $48, $62, $51, $45, $42, $4f, $42, $ef, $ee, $4a, $3e, $4b, $56, $62
    db $51, $46, $4a, $42, $50, $62, $51, $4c, $fa, $f7, $ef, $ee, $51, $4f, $3e, $46
    db $4b, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee, $f7, $f0
TextStr_4e_43ce:           ; id $086C
    ; "*:We gather here at the arena, / seeking victory. / *:Ha, you can't win even in G / class. / *:You have weak monsters with you! / That's all..."
    db $ea, $9f, $a3, $3a, $42, $62, $44, $3e, $51, $45, $42, $4f, $62, $45, $42, $4f
    db $42, $ef, $ee, $3e, $51, $62, $51, $45, $42, $62, $3e, $4f, $42, $4b, $3e, $5e
    db $fa, $f7, $ef, $ee, $50, $42, $42, $48, $46, $4b, $44, $62, $53, $46, $40, $51
    db $4c, $4f, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $3e, $5e, $62
    db $56, $4c, $52, $62, $40, $3e, $4b, $67, $ef, $ee, $54, $46, $4b, $62, $42, $53
    db $42, $4b, $62, $46, $4b, $62, $2a, $fa, $f7, $ef, $ee, $40, $49, $3e, $50, $50
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $45, $3e, $53
    db $42, $62, $54, $42, $3e, $48, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $62, $54, $46, $51, $45, $62, $56, $4c, $52, $63, $fa, $f7, $ef, $ee, $37, $45
    db $3e, $51, $68, $62, $3e, $49, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $39, $46, $50, $46, $51, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42
    db $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $fa, $f7, $ef, $ee, $4f, $42
    db $4d, $42, $3e, $51, $42, $41, $49, $56, $62, $51, $4c, $ef, $ee, $51, $4f, $3e
    db $46, $4b, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $63, $ef, $ee, $f7, $f0
TextStr_4e_44b6:           ; id $086D
    ; "*:All monsters are born from eggs."
    db $ea, $9f, $a3, $24, $49, $49, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62
    db $3e, $4f, $42, $ef, $ee, $3f, $4c, $4f, $4b, $62, $43, $4f, $4c, $4a, $62, $42
    db $44, $44, $50, $5f, $f7, $f0
TextStr_4e_44dc:           ; id $086E
    ; "*:Eggs will be eggs forever if / left alone. / *:There's a place to hatch eggs in / this kingdom. / *:Until you find this place, leave / the..."
    db $ea, $9f, $a3, $28, $44, $44, $50, $62, $54, $46, $49, $49, $62, $3f, $42, $ef
    db $ee, $42, $44, $44, $50, $62, $43, $4c, $4f, $42, $53, $42, $4f, $62, $46, $43
    db $fa, $f7, $ef, $ee, $49, $42, $43, $51, $62, $3e, $49, $4c, $4b, $42, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f, $42, $68, $62, $3e, $62
    db $4d, $49, $3e, $40, $42, $ef, $ee, $51, $4c, $62, $45, $3e, $51, $40, $45, $62
    db $42, $44, $44, $50, $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $46, $50, $62
    db $48, $46, $4b, $44, $41, $4c, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $38, $4b, $51, $46, $49, $62, $56, $4c, $52, $62, $43, $46, $4b, $41, $ef, $ee
    db $51, $45, $46, $50, $62, $4d, $49, $3e, $40, $42, $5e, $62, $49, $42, $3e, $53
    db $42, $fa, $f7, $ef, $ee, $51, $45, $42, $4a, $62, $3e, $51, $62, $51, $45, $42
    db $62, $43, $3e, $4f, $4a, $5f, $ef, $ee, $f7, $f0
TextStr_4e_4586:           ; id $086F
    ; ":If you choose CHARGE you can / train the monsters to be brave. / :Brave monsters have a better / chance to make clean hits. / :If you choos..."
    db $a3, $2c, $43, $62, $56, $4c, $52, $62, $40, $45, $4c, $4c, $50, $42, $ef, $ee
    db $26, $2b, $24, $35, $2a, $28, $62, $56, $4c, $52, $62, $40, $3e, $4b, $fa, $f7
    db $ef, $ee, $51, $4f, $3e, $46, $4b, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $ef, $ee, $51, $4c, $62, $3f, $42, $62, $3f, $4f, $3e, $53
    db $42, $5f, $fa, $f7, $ef, $ee, $a3, $25, $4f, $3e, $53, $42, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $62, $3f, $42
    db $51, $51, $42, $4f, $fa, $f7, $ef, $ee, $40, $45, $3e, $4b, $40, $42, $62, $51
    db $4c, $62, $4a, $3e, $48, $42, $ef, $ee, $40, $49, $42, $3e, $4b, $62, $45, $46
    db $51, $50, $5f, $fa, $f7, $ef, $ee, $a3, $2c, $43, $62, $56, $4c, $52, $62, $40
    db $45, $4c, $4c, $50, $42, $ef, $ee, $30, $2c, $3b, $28, $27, $5e, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46
    db $49, $49, $ef, $ee, $3f, $42, $40, $4c, $4a, $42, $62, $54, $46, $50, $42, $4f
    db $5f, $fa, $f7, $ef, $ee, $a3, $3a, $46, $50, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $ef, $ee, $42, $3e, $50, $46, $49, $56, $62, $41, $42, $40, $46
    db $41, $42, $fa, $f7, $ef, $ee, $54, $45, $46, $40, $45, $62, $50, $52, $4d, $4d
    db $4c, $4f, $51, $ef, $ee, $50, $48, $46, $49, $49, $62, $46, $50, $62, $3f, $42
    db $50, $51, $fa, $f7, $ef, $ee, $51, $4c, $62, $52, $50, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $62, $40, $45, $4c
    db $4c, $50, $42, $ef, $ee, $26, $24, $38, $37, $2c, $32, $38, $36, $5e, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef, $ee
    db $25, $42, $40, $4c, $4a, $42, $62, $40, $3e, $52, $51, $46, $4c, $52, $50, $5f
    db $fa, $f7, $ef, $ee, $a3, $26, $3e, $52, $51, $46, $4c, $52, $50, $62, $4a, $4c
    db $4b, $50, $51, $42, $4f, $50, $ef, $ee, $41, $4c, $4b, $67, $62, $52, $50, $42
    db $62, $30, $33, $62, $3f, $52, $51, $fa, $f7, $ef, $ee, $50, $4c, $4a, $42, $51
    db $46, $4a, $42, $50, $62, $45, $42, $3e, $49, $ef, $ee, $51, $45, $42, $46, $4f
    db $62, $41, $3e, $4a, $3e, $44, $42, $50, $5f, $f7, $f0
TextStr_4e_4721:           ; id $0870
    ; "[HERO] returned the old lady's / notebook to the jar."
    db $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $62, $51, $45, $42, $ef, $ee
    db $4c, $49, $41, $62, $49, $3e, $41, $56, $68, $fa, $f7, $ef, $ee, $4b, $4c, $51
    db $42, $3f, $4c, $4c, $48, $62, $51, $4c, $62, $51, $45, $42, $ef, $ee, $47, $3e
    db $4f, $5f, $f7, $f0
TextStr_4e_4755:           ; id $0871
    ; "*:Hmmm. It's unfortunate."
    db $ea, $9f, $a3, $2b, $4a, $4a, $4a, $5f, $62, $2c, $51, $68, $ef, $ee, $52, $4b
    db $43, $4c, $4f, $51, $52, $4b, $3e, $51, $42, $5f, $f7, $f0
TextStr_4e_4771:           ; id $0872
    ; "*:Hmmm. You survived G class. / Well, I guess I'll congratulate you. / *:But G class is a piece of cake. / *:The real battles start now. / R..."
    db $ea, $9f, $a3, $2b, $4a, $4a, $4a, $5f, $62, $3c, $4c, $52, $ef, $ee, $50, $52
    db $4f, $53, $46, $53, $42, $41, $62, $2a, $62, $40, $49, $3e, $50, $50, $5f, $fa
    db $f7, $ef, $ee, $3a, $42, $49, $49, $5e, $62, $2c, $62, $44, $52, $42, $50, $50
    db $62, $2c, $66, $49, $ef, $ee, $40, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e
    db $51, $42, $62, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51
    db $62, $2a, $62, $40, $49, $3e, $50, $50, $62, $46, $50, $ef, $ee, $3e, $62, $4d
    db $46, $42, $40, $42, $62, $4c, $43, $62, $40, $3e, $48, $42, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $4f, $42, $3e, $49, $62, $3f, $3e, $51, $51
    db $49, $42, $50, $ef, $ee, $50, $51, $3e, $4f, $51, $62, $4b, $4c, $54, $5f, $fa
    db $f7, $ef, $ee, $35, $42, $4a, $42, $4a, $3f, $42, $4f, $62, $51, $45, $3e, $51
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $62, $51, $4c, $62, $51
    db $45, $42, $62, $35, $4c, $4c, $4a, $ef, $ee, $4c, $43, $62, $39, $46, $49, $49
    db $3e, $44, $42, $4f, $62, $b6, $62, $fa, $f7, $ef, $ee, $37, $3e, $49, $46, $50
    db $4a, $3e, $4b, $62, $3e, $4b, $41, $ef, $ee, $46, $4a, $4d, $4f, $4c, $53, $42
    db $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $50, $48, $46, $49, $49, $50, $5f
    db $ef, $ee, $f7, $f0
TextStr_4e_4865:           ; id $0873
    ; "*:Hmm. You survived F class. / Congratulations. / *:Train in the Room of Memories & / Bewilder. / *:Have you tried breeding monsters / in th..."
    db $ea, $9f, $a3, $2b, $4a, $4a, $5f, $62, $3c, $4c, $52, $ef, $ee, $50, $52, $4f
    db $53, $46, $53, $42, $41, $62, $29, $62, $40, $49, $3e, $50, $50, $5f, $fa, $f7
    db $ef, $ee, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c, $4b
    db $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4f, $3e, $46, $4b, $62
    db $46, $4b, $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $62
    db $30, $42, $4a, $4c, $4f, $46, $42, $50, $62, $b6, $fa, $f7, $ef, $ee, $25, $42
    db $54, $46, $49, $41, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b
    db $3e, $53, $42, $62, $56, $4c, $52, $62, $51, $4f, $46, $42, $41, $ef, $ee, $3f
    db $4f, $42, $42, $41, $46, $4b, $44, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $fa, $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $36, $45, $4f, $46, $4b
    db $42, $62, $4c, $43, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44
    db $45, $51, $64, $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $50, $51, $42, $4f, $62
    db $3f, $4f, $42, $42, $41, $46, $4b, $44, $5e, $ef, $ee, $3e, $4b, $41, $62, $56
    db $4c, $52, $66, $49, $62, $4a, $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $51, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $5f, $ef, $ee
    db $f7, $f0
TextStr_4e_4957:           ; id $0874
    ; "*:There will be Spookys, ArmyAnts, / Anteaters, and Goopis there! / *:ArmyAnts will make you sleep / while they attack! / *:The guardian the..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $46, $49, $49, $62, $3f, $42
    db $ef, $ee, $36, $4d, $4c, $4c, $48, $56, $50, $5e, $62, $24, $4f, $4a, $56, $24
    db $4b, $51, $50, $5e, $fa, $f7, $ef, $ee, $24, $4b, $51, $42, $3e, $51, $42, $4f
    db $50, $5e, $62, $3e, $4b, $41, $ef, $ee, $2a, $4c, $4c, $4d, $46, $50, $62, $51
    db $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4f, $4a, $56, $24
    db $4b, $51, $50, $62, $54, $46, $49, $49, $ef, $ee, $4a, $3e, $48, $42, $62, $56
    db $4c, $52, $62, $50, $49, $42, $42, $4d, $fa, $f7, $ef, $ee, $54, $45, $46, $49
    db $42, $62, $51, $45, $42, $56, $62, $3e, $51, $51, $3e, $40, $48, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46
    db $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $62, $2a
    db $4c, $49, $42, $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62
    db $46, $51, $62, $40, $45, $3e, $4f, $44, $42, $50, $ef, $ee, $46, $51, $50, $62
    db $4d, $4c, $54, $42, $4f, $5e, $62, $54, $3e, $51, $40, $45, $fa, $f7, $ef, $ee
    db $43, $4c, $4f, $62, $46, $51, $50, $62, $4b, $42, $55, $51, $62, $51, $52, $4f
    db $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2a, $4c
    db $49, $42, $4a, $62, $46, $50, $ef, $ee, $53, $52, $49, $4b, $42, $4f, $3e, $3f
    db $49, $42, $62, $51, $4c, $fa, $f7, $ef, $ee, $50, $49, $42, $42, $4d, $62, $50
    db $4d, $42, $49, $49, $50, $5f, $ef, $ee, $f7, $f0
TextStr_4e_4a71:           ; id $0875
    ; "*:Humpf, okay."
    db $ea, $9f, $a3, $2b, $52, $4a, $4d, $43, $5e, $62, $4c, $48, $3e, $56, $5f, $ef
    db $ee, $f7, $f0
TextStr_4e_4a84:           ; id $0876
    ; "*:Would you like to hear about the / Gate of Bewilder? [YES/NO]"
    db $ea, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $51, $4c, $62, $45, $42, $3e, $4f, $62, $3e, $3f, $4c, $52, $51
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62
    db $25, $42, $54, $46, $49, $41, $42, $4f, $64, $ef, $ee, $ff, $f0
TextStr_4e_4ac1:           ; id $0877
    ; "*:There were MiniDraks, / BigRoosts, EvilSeeds, / *:Demonites, SpotSlimes and / Horks living there. / *:When all of your monsters are / para..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $42, $4f, $42, $ef, $ee, $30
    db $46, $4b, $46, $27, $4f, $3e, $48, $50, $5e, $fa, $f7, $ef, $ee, $25, $46, $44
    db $35, $4c, $4c, $50, $51, $50, $5e, $ef, $ee, $28, $53, $46, $49, $36, $42, $42
    db $41, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $27, $42, $4a, $4c, $4b, $46, $51
    db $42, $50, $5e, $ef, $ee, $36, $4d, $4c, $51, $36, $49, $46, $4a, $42, $50, $62
    db $3e, $4b, $41, $fa, $f7, $ef, $ee, $2b, $4c, $4f, $48, $50, $62, $49, $46, $53
    db $46, $4b, $44, $ef, $ee, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $3a, $45, $42, $4b, $62, $3e, $49, $49, $62, $4c, $43, $62, $56, $4c, $52
    db $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3e, $4f, $42, $fa
    db $f7, $ef, $ee, $4d, $3e, $4f, $3e, $49, $56, $57, $42, $41, $62, $56, $4c, $52
    db $69, $42, $ef, $ee, $43, $46, $4b, $46, $50, $45, $42, $41, $5f, $fa, $f7, $ef
    db $ee, $27, $4c, $4b, $67, $62, $43, $4c, $4f, $44, $42, $51, $ef, $ee, $50, $4c
    db $4a, $42, $62, $30, $4c, $4c, $4b, $2b, $42, $4f, $3f, $50, $63, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef
    db $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $29, $3e, $40, $42, $37, $4f, $42, $42, $5f, $62, $2c, $51, $62, $54, $46
    db $49, $49, $ef, $ee, $40, $3e, $50, $51, $62, $3e, $62, $40, $52, $4f, $50, $42
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $24, $62, $40, $52, $4f, $50, $42, $62, $46
    db $50, $62, $3e, $ef, $ee, $4f, $42, $3e, $49, $62, $51, $45, $4f, $42, $3e, $51
    db $5f, $62, $38, $50, $42, $fa, $f7, $ef, $ee, $2f, $3e, $52, $4f, $42, $49, $50
    db $62, $51, $4c, $62, $40, $52, $4f, $42, $ef, $ee, $40, $52, $4f, $50, $42, $50
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $62, $46, $4b, $ef, $ee, $51, $45, $42, $62, $4d, $49, $3e, $4b
    db $51, $62, $43, $3e, $4a, $46, $49, $56, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62
    db $53, $52, $49, $4b, $42, $4f, $3e, $3f, $49, $42, $62, $51, $4c, $ef, $ee, $43
    db $46, $4f, $42, $62, $3e, $51, $51, $3e, $40, $48, $50, $63, $f7, $f0
TextStr_4e_4c5f:           ; id $0878
    ; "*:Want to know about the monsters / behind the Gate of Memories? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $30, $42, $4a, $4c, $4f
    db $46, $42, $50, $64, $ff, $f0
TextStr_4e_4ca5:           ; id $0879
    ; "*:There were Goopis, / PillowRats, DragonKids, / Catapilas... / *:Pickys, and FairyDraks / living there. / *:Sometimes, SpotSlimes show / up..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $42, $4f, $42, $ef, $ee, $2a
    db $4c, $4c, $4d, $46, $50, $5e, $fa, $f7, $ef, $ee, $33, $46, $49, $49, $4c, $54
    db $35, $3e, $51, $50, $5e, $ef, $ee, $27, $4f, $3e, $44, $4c, $4b, $2e, $46, $41
    db $50, $5e, $fa, $f7, $ef, $ee, $26, $3e, $51, $3e, $4d, $46, $49, $3e, $50, $5f
    db $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $33, $46, $40, $48, $56, $50
    db $5e, $62, $3e, $4b, $41, $ef, $ee, $29, $3e, $46, $4f, $56, $27, $4f, $3e, $48
    db $50, $fa, $f7, $ef, $ee, $49, $46, $53, $46, $4b, $44, $62, $51, $45, $42, $4f
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $4a, $42, $51, $46
    db $4a, $42, $50, $5e, $ef, $ee, $36, $4d, $4c, $51, $36, $49, $46, $4a, $42, $50
    db $62, $50, $45, $4c, $54, $fa, $f7, $ef, $ee, $52, $4d, $5f, $62, $25, $42, $62
    db $40, $3e, $4f, $42, $43, $52, $49, $5f, $ef, $ee, $37, $45, $42, $56, $62, $40
    db $3e, $4b, $62, $40, $3e, $49, $49, $fa, $f7, $ef, $ee, $4c, $51, $45, $42, $4f
    db $50, $62, $43, $4c, $4f, $62, $45, $42, $49, $4d, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef
    db $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $30, $3e, $41, $26, $3e, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $51, $62, $40, $3e, $4b, $62, $40, $3e, $50, $51, $62, $3e, $ef, $ee, $36
    db $4e, $52, $3e, $49, $49, $2b, $46, $51, $62, $43, $3e, $50, $51, $42, $4f, $fa
    db $f7, $ef, $ee, $51, $45, $3e, $4b, $62, $3e, $4b, $56, $3f, $4c, $41, $56, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $69, $42
    db $62, $50, $49, $4c, $54, $5e, $ef, $ee, $56, $4c, $52, $66, $49, $62, $3f, $42
    db $62, $51, $4c, $3e, $50, $51, $63, $f7, $f0
TextStr_4e_4dfe:           ; id $087A
    ; "*:There are characteristics / for monsters, / *:such as resistance to / fire or ice. / *:For example, Metaly is / resistant to everything! /..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $40, $45
    db $3e, $4f, $3e, $40, $51, $42, $4f, $46, $50, $51, $46, $40, $50, $fa, $f7, $ef
    db $ee, $43, $4c, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $50, $52, $40, $45, $62, $3e, $50, $ef, $ee, $4f
    db $42, $50, $46, $50, $51, $3e, $4b, $40, $42, $62, $51, $4c, $fa, $f7, $ef, $ee
    db $43, $46, $4f, $42, $62, $4c, $4f, $62, $46, $40, $42, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $29, $4c, $4f, $62, $42, $55, $3e, $4a, $4d, $49, $42, $5e
    db $ef, $ee, $30, $42, $51, $3e, $49, $56, $62, $46, $50, $fa, $f7, $ef, $ee, $4f
    db $42, $50, $46, $50, $51, $3e, $4b, $51, $62, $51, $4c, $ef, $ee, $42, $53, $42
    db $4f, $56, $51, $45, $46, $4b, $44, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45
    db $42, $50, $42, $ef, $ee, $40, $45, $3e, $4f, $3e, $40, $51, $42, $4f, $46, $50
    db $51, $46, $40, $50, $fa, $f7, $ef, $ee, $40, $3e, $4b, $62, $3f, $42, $62, $46
    db $4b, $45, $42, $4f, $46, $51, $42, $41, $ef, $ee, $3f, $56, $62, $51, $45, $42
    db $46, $4f, $62, $48, $46, $41, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e
    db $4b, $51, $62, $51, $4c, $62, $45, $42, $3e, $4f, $ef, $ee, $4a, $4c, $4f, $42
    db $64, $ff, $f0
TextStr_4e_4ef1:           ; id $087B
    ; "*:Dragons with Metaly / parents / *:are more resistant to a / variety of things. / *:The more the + for breeding, the / greater the tendency..."
    db $ea, $9f, $a3, $27, $4f, $3e, $44, $4c, $4b, $50, $ef, $ee, $54, $46, $51, $45
    db $62, $30, $42, $51, $3e, $49, $56, $fa, $f7, $ef, $ee, $4d, $3e, $4f, $42, $4b
    db $51, $50, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4f, $42, $62, $4a, $4c
    db $4f, $42, $ef, $ee, $4f, $42, $50, $46, $50, $51, $3e, $4b, $51, $62, $51, $4c
    db $62, $3e, $fa, $f7, $ef, $ee, $53, $3e, $4f, $46, $42, $51, $56, $62, $4c, $43
    db $62, $51, $45, $46, $4b, $44, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $4a, $4c, $4f, $42, $62, $51, $45, $42, $62, $a2, $ef, $ee
    db $43, $4c, $4f, $62, $3f, $4f, $42, $42, $41, $46, $4b, $44, $5e, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $44, $4f, $42, $3e, $51, $42, $4f, $62, $51, $45, $42
    db $ef, $ee, $51, $42, $4b, $41, $42, $4b, $40, $56, $62, $43, $4c, $4f, $62, $51
    db $45, $3e, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4f, $42, $42, $41, $62
    db $54, $46, $51, $45, $62, $3e, $4b, $ef, $ee, $52, $4b, $41, $42, $4f, $50, $51
    db $3e, $4b, $41, $46, $4b, $44, $62, $4c, $43, $fa, $f7, $ef, $ee, $51, $45, $42
    db $50, $42, $62, $ef, $ee, $40, $45, $3e, $4f, $3e, $40, $51, $42, $4f, $46, $50
    db $51, $46, $40, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $51, $4f, $4c, $4b
    db $44, $42, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46
    db $49, $49, $62, $3f, $42, $fa, $f7, $ef, $ee, $3f, $4c, $4f, $4b, $62, $46, $43
    db $62, $51, $45, $42, $56, $ef, $ee, $40, $4c, $4a, $4d, $42, $4b, $50, $3e, $51
    db $42, $62, $43, $4c, $4f, $fa, $f7, $ef, $ee, $42, $3e, $40, $45, $62, $4c, $51
    db $45, $42, $4f, $68, $62, $54, $42, $3e, $48, $ef, $ee, $4d, $4c, $46, $4b, $51
    db $50, $5f, $f7, $f0
TextStr_4e_5035:           ; id $087C
    ; "*:Would you like to hear about the / Gate of Peace? [YES/NO]"
    db $ea, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $51, $4c, $62, $45, $42, $3e, $4f, $62, $3e, $3f, $4c, $52, $51
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62
    db $33, $42, $3e, $40, $42, $64, $ef, $ee, $ff, $f0
TextStr_4e_506f:           ; id $087D
    ; "*:There were BigRoosts, / SpotSlimes, CoilBirds, / *:DragonKids, Crestpents, / BoneSlaves, Almirajs, / *:Horks and BullBirds / living there...."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $42, $4f, $42, $ef, $ee, $25
    db $46, $44, $35, $4c, $4c, $50, $51, $50, $5e, $fa, $f7, $ef, $ee, $36, $4d, $4c
    db $51, $36, $49, $46, $4a, $42, $50, $5e, $ef, $ee, $26, $4c, $46, $49, $25, $46
    db $4f, $41, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $27, $4f, $3e, $44, $4c, $4b
    db $2e, $46, $41, $50, $5e, $ef, $ee, $26, $4f, $42, $50, $51, $4d, $42, $4b, $51
    db $50, $5e, $fa, $f7, $ef, $ee, $25, $4c, $4b, $42, $36, $49, $3e, $53, $42, $50
    db $5e, $ef, $ee, $24, $49, $4a, $46, $4f, $3e, $47, $50, $5e, $fa, $f7, $ef, $ee
    db $9f, $a3, $2b, $4c, $4f, $48, $50, $62, $3e, $4b, $41, $ef, $ee, $25, $52, $49
    db $49, $25, $46, $4f, $41, $50, $fa, $f7, $ef, $ee, $49, $46, $53, $46, $4b, $44
    db $62, $51, $45, $42, $4f, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $62, $26, $4f, $42, $50, $51, $4d, $42, $4b, $51, $50, $ef, $ee, $45
    db $3e, $53, $42, $62, $33, $4c, $46, $50, $4c, $4b, $2b, $46, $51, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b
    db $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $29, $3e, $4b, $44, $36, $49, $46, $4a, $42, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $46, $51, $62, $40, $45, $3e, $4f
    db $44, $42, $50, $ef, $ee, $46, $51, $68, $62, $4d, $4c, $54, $42, $4f, $5e, $62
    db $54, $3e, $51, $40, $45, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $4f, $42
    db $4a, $3e, $46, $4b, $46, $4b, $44, $62, $2b, $33, $63, $ef, $ee, $f7, $f0
TextStr_4e_519e:           ; id $087E
    ; "*:Want to know about the monsters / behind the Gate of Bravery? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $25, $4f, $3e, $53, $42
    db $4f, $56, $64, $ff, $f0
TextStr_4e_51e3:           ; id $087F
    ; "*:There are Demonites, / BeanMen, 1EyeClowns, / FloraMen, / *:SabreMen, GiantWorms, and / BullBirds living there! / *:The FloraMan can use F..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $27, $42
    db $4a, $4c, $4b, $46, $51, $42, $50, $5e, $fa, $f7, $ef, $ee, $25, $42, $3e, $4b
    db $30, $42, $4b, $5e, $ef, $ee, $01, $28, $56, $42, $26, $49, $4c, $54, $4b, $50
    db $5e, $fa, $f7, $ef, $ee, $29, $49, $4c, $4f, $3e, $30, $42, $4b, $5e, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $36, $3e, $3f, $4f, $42, $30, $42, $4b, $5e, $ef
    db $ee, $2a, $46, $3e, $4b, $51, $3a, $4c, $4f, $4a, $50, $5e, $62, $3e, $4b, $41
    db $fa, $f7, $ef, $ee, $25, $52, $49, $49, $25, $46, $4f, $41, $50, $62, $49, $46
    db $53, $46, $4b, $44, $ef, $ee, $51, $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $29, $49, $4c, $4f, $3e, $30, $3e, $4b, $62, $40
    db $3e, $4b, $ef, $ee, $52, $50, $42, $62, $29, $46, $4f, $42, $3f, $3e, $4b, $42
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41
    db $46, $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $25, $46, $44, $28, $56, $42, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $51, $62, $54, $46, $49, $49, $62, $52, $50, $42, $ef
    db $ee, $2c, $40, $42, $24, $46, $4f, $62, $b6, $fa, $f7, $ef, $ee, $36, $4b, $4c
    db $54, $36, $51, $4c, $4f, $4a, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25
    db $42, $3e, $50, $51, $50, $62, $3e, $4f, $42, $ef, $ee, $53, $52, $49, $4b, $42
    db $4f, $3e, $3f, $49, $42, $62, $51, $4c, $fa, $f7, $ef, $ee, $50, $4d, $42, $49
    db $49, $50, $62, $3e, $4b, $41, $62, $3e, $46, $4f, $ef, $ee, $3e, $51, $51, $3e
    db $40, $48, $50, $63, $f7, $f0
TextStr_4e_5319:           ; id $0880
    ; "*:You survived E class, You did / better than I thought."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $50, $52, $4f, $53, $46, $53, $42, $41, $ef
    db $ee, $28, $62, $40, $49, $3e, $50, $50, $5e, $62, $3c, $4c, $52, $62, $41, $46
    db $41, $fa, $f7, $ef, $ee, $3f, $42, $51, $51, $42, $4f, $62, $51, $45, $3e, $4b
    db $62, $2c, $ef, $ee, $51, $45, $4c, $52, $44, $45, $51, $5f, $f7, $f0
TextStr_4e_5357:           ; id $0881
    ; "*:IceMan has a relative!! / *:It is called LavaMan. But it's / not behind the Travelers' Gate! / *:Foreign masters might have one!"
    db $ea, $9f, $a3, $2c, $40, $42, $30, $3e, $4b, $62, $45, $3e, $50, $62, $3e, $ef
    db $ee, $4f, $42, $49, $3e, $51, $46, $53, $42, $63, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $51, $62, $46, $50, $62, $40, $3e, $49, $49, $42, $41, $ef, $ee, $2f
    db $3e, $53, $3e, $30, $3e, $4b, $5f, $62, $25, $52, $51, $62, $46, $51, $68, $fa
    db $f7, $ef, $ee, $4b, $4c, $51, $62, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e
    db $51, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $29, $4c, $4f, $42, $46, $44, $4b
    db $62, $4a, $3e, $50, $51, $42, $4f, $50, $ef, $ee, $4a, $46, $44, $45, $51, $62
    db $45, $3e, $53, $42, $62, $4c, $4b, $42, $63, $f7, $f0
TextStr_4e_53e2:           ; id $0882
    ; "*:When you choose COMMAND, very / wild monsters, / *:often won't obey your command. / *:In that case, take the monsters / around with you to..."
    db $ea, $9f, $a3, $3a, $45, $42, $4b, $62, $56, $4c, $52, $62, $40, $45, $4c, $4c
    db $50, $42, $ef, $ee, $26, $32, $30, $30, $24, $31, $27, $5e, $62, $53, $42, $4f
    db $56, $fa, $f7, $ef, $ee, $54, $46, $49, $41, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $4c, $43, $51, $42, $4b
    db $62, $54, $4c, $4b, $67, $62, $4c, $3f, $42, $56, $ef, $ee, $56, $4c, $52, $4f
    db $62, $40, $4c, $4a, $4a, $3e, $4b, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $4b, $62, $51, $45, $3e, $51, $62, $40, $3e, $50, $42, $5e, $ef, $ee, $51, $3e
    db $48, $42, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa
    db $f7, $ef, $ee, $3e, $4f, $4c, $52, $4b, $41, $62, $54, $46, $51, $45, $62, $56
    db $4c, $52, $ef, $ee, $51, $4c, $62, $49, $4c, $54, $42, $4f, $62, $51, $45, $42
    db $46, $4f, $fa, $f7, $ef, $ee, $54, $46, $49, $41, $4b, $42, $50, $50, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $56
    db $69, $42, $ef, $ee, $49, $42, $43, $51, $62, $4c, $4b, $62, $51, $45, $42, $62
    db $43, $3e, $4f, $4a, $5e, $fa, $f7, $ef, $ee, $46, $51, $68, $62, $54, $46, $49
    db $41, $4b, $42, $50, $50, $62, $54, $46, $49, $49, $ef, $ee, $46, $4b, $40, $4f
    db $42, $3e, $50, $42, $5f, $f7, $f0
TextStr_4e_54d9:           ; id $0883
    ; "*:Would you like to learn about the / Gate of Anger? [YES/NO]"
    db $ea, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $51, $4c, $62, $49, $42, $3e, $4f, $4b, $62, $3e, $3f, $4c, $52
    db $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43
    db $62, $24, $4b, $44, $42, $4f, $64, $ef, $ee, $ff, $f0
TextStr_4e_5514:           ; id $0884
    ; "*:There were GiantWorms, / Poisongons, GiantSlugs, / CatFlys, / *:Eyeders, Putrepups, and / DrakSlimes there. / *:DrakSlime's BlazeAir is / ..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $42, $4f, $42, $ef, $ee, $2a
    db $46, $3e, $4b, $51, $3a, $4c, $4f, $4a, $50, $5e, $fa, $f7, $ef, $ee, $33, $4c
    db $46, $50, $4c, $4b, $44, $4c, $4b, $50, $5e, $ef, $ee, $2a, $46, $3e, $4b, $51
    db $36, $49, $52, $44, $50, $5e, $fa, $f7, $ef, $ee, $26, $3e, $51, $29, $49, $56
    db $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $28, $56, $42, $41, $42, $4f
    db $50, $5e, $ef, $ee, $33, $52, $51, $4f, $42, $4d, $52, $4d, $50, $5e, $62, $3e
    db $4b, $41, $fa, $f7, $ef, $ee, $27, $4f, $3e, $48, $36, $49, $46, $4a, $42, $50
    db $62, $51, $45, $42, $4f, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $27
    db $4f, $3e, $48, $36, $49, $46, $4a, $42, $68, $ef, $ee, $25, $49, $3e, $57, $42
    db $24, $46, $4f, $62, $46, $50, $fa, $f7, $ef, $ee, $4d, $4c, $54, $42, $4f, $43
    db $52, $49, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $51, $46, $41
    db $4c, $51, $42, $62, $46, $50, $62, $3e, $ef, $ee, $4a, $52, $50, $51, $62, $3f
    db $42, $40, $3e, $52, $50, $42, $62, $51, $45, $42, $4f, $42, $fa, $f7, $ef, $ee
    db $3e, $4f, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46, $51
    db $45, $ef, $ee, $4d, $4c, $46, $50, $4c, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $51, $45
    db $42, $4f, $42, $62, $46, $50, $fa, $f7, $ef, $ee, $25, $3e, $51, $51, $49, $42
    db $35, $42, $55, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62
    db $28, $53, $46, $49, $36, $49, $3e, $50, $45, $ef, $ee, $46, $50, $62, $3e, $4b
    db $62, $4c, $52, $51, $4f, $3e, $44, $42, $4c, $52, $50, $fa, $f7, $ef, $ee, $50
    db $48, $46, $49, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $27, $4f, $3e
    db $44, $4c, $4b, $50, $62, $3e, $4f, $42, $ef, $ee, $4f, $42, $3e, $49, $49, $56
    db $62, $4f, $42, $50, $46, $50, $51, $3e, $4b, $51, $fa, $f7, $ef, $ee, $51, $4c
    db $62, $43, $46, $4f, $42, $62, $3e, $51, $51, $3e, $40, $48, $50, $63, $ef, $ee
    db $f7, $f0
TextStr_4e_5696:           ; id $0885
    ; "*:Want to know about the monsters / behind the Gate of Strength? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $36, $51, $4f, $42, $4b
    db $44, $51, $45, $64, $ff, $f0
TextStr_4e_56dc:           ; id $0886
    ; "*:There are MudDolls, / TreeSlimes, SkulRiders, / WingTrees, / *:FairyDraks, and DrakSlimes living / there! / *:TreeSlimes there will get yo..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $30, $52
    db $41, $27, $4c, $49, $49, $50, $5e, $fa, $f7, $ef, $ee, $37, $4f, $42, $42, $36
    db $49, $46, $4a, $42, $50, $5e, $ef, $ee, $36, $48, $52, $49, $35, $46, $41, $42
    db $4f, $50, $5e, $fa, $f7, $ef, $ee, $3a, $46, $4b, $44, $37, $4f, $42, $42, $50
    db $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $29, $3e, $46, $4f, $56, $27, $4f
    db $3e, $48, $50, $5e, $62, $3e, $4b, $41, $ef, $ee, $27, $4f, $3e, $48, $36, $49
    db $46, $4a, $42, $50, $62, $49, $46, $53, $46, $4b, $44, $fa, $f7, $ef, $ee, $51
    db $45, $42, $4f, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4f, $42
    db $42, $36, $49, $46, $4a, $42, $50, $62, $51, $45, $42, $4f, $42, $ef, $ee, $54
    db $46, $49, $49, $62, $44, $42, $51, $62, $56, $4c, $52, $62, $54, $46, $51, $45
    db $fa, $f7, $ef, $ee, $33, $3e, $4f, $3e, $49, $56, $57, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $27, $4c, $4b, $67, $62, $43, $4c, $4f, $44, $42, $51
    db $62, $51, $4c, $ef, $ee, $51, $3e, $48, $42, $62, $50, $4c, $4a, $42, $fa, $f7
    db $ef, $ee, $30, $4c, $4c, $4b, $2b, $42, $4f, $3f, $50, $62, $54, $46, $51, $45
    db $ef, $ee, $56, $4c, $52, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62
    db $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62
    db $46, $50, $62, $3e, $fa, $f7, $ef, $ee, $36, $51, $4c, $4b, $42, $30, $3e, $4b
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $32, $3f, $47, $42, $40, $51, $50
    db $62, $3e, $4f, $42, $ef, $ee, $4f, $42, $50, $46, $50, $51, $3e, $4b, $51, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $2c, $40, $42, $25, $4c, $49, $51, $62, $3e, $4b
    db $41, $ef, $ee, $25, $49, $46, $57, $57, $3e, $4f, $41, $63, $f7, $f0
TextStr_4e_582a:           ; id $0887
    ; "*:When the family of the pedigree / and the family of the other monster / are the same, / *:In principle, the same monster / will be born. /..."
    db $ea, $9f, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $62, $43, $3e, $4a, $46
    db $49, $56, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $4d, $42, $41, $46, $44
    db $4f, $42, $42, $fa, $f7, $ef, $ee, $3e, $4b, $41, $62, $51, $45, $42, $62, $43
    db $3e, $4a, $46, $49, $56, $62, $4c, $43, $ef, $ee, $51, $45, $42, $62, $4c, $51
    db $45, $42, $4f, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $3e
    db $4f, $42, $62, $51, $45, $42, $62, $50, $3e, $4a, $42, $5e, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $4b, $62, $4d, $4f, $46, $4b, $40, $46, $4d, $49, $42
    db $5e, $ef, $ee, $51, $45, $42, $62, $50, $3e, $4a, $42, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $fa, $f7, $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $3f
    db $4c, $4f, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $4c, $4a, $42
    db $51, $46, $4a, $42, $50, $62, $56, $4c, $52, $66, $49, $ef, $ee, $54, $3e, $4b
    db $51, $62, $51, $4c, $62, $40, $45, $3e, $4b, $44, $42, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $44, $42, $4b, $41, $42, $4f, $62, $4c, $43, $62, $3e, $4b, $62
    db $42, $44, $44, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c, $62, $41
    db $4c, $62, $50, $4c, $5e, $ef, $ee, $51, $3e, $48, $42, $62, $51, $45, $42, $62
    db $42, $44, $44, $62, $51, $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $28, $44
    db $44, $62, $26, $4c, $4b, $50, $52, $49, $51, $3e, $4b, $51, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $56, $62, $40, $3e, $4b, $62, $3f, $49, $42
    db $50, $50, $ef, $ee, $51, $45, $42, $62, $42, $44, $44, $62, $3e, $4b, $41, $62
    db $40, $45, $3e, $4b, $44, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $44, $42
    db $4b, $41, $42, $4f, $63, $ef, $ee, $f7, $f0
TextStr_4e_5973:           ; id $0888
    ; "*:There are foreign masters / whose monsters are not attached / to them. / *:You can get those monsters to / be your pal by flattering them!"
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $43, $4c
    db $4f, $42, $46, $44, $4b, $62, $4a, $3e, $50, $51, $42, $4f, $50, $fa, $f7, $ef
    db $ee, $54, $45, $4c, $50, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef
    db $ee, $3e, $4f, $42, $62, $4b, $4c, $51, $62, $3e, $51, $51, $3e, $40, $45, $42
    db $41, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $45, $42, $4a, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $44, $42, $51
    db $ef, $ee, $51, $45, $4c, $50, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $62, $51, $4c, $fa, $f7, $ef, $ee, $3f, $42, $62, $56, $4c, $52, $4f, $62, $4d
    db $3e, $49, $62, $3f, $56, $ef, $ee, $43, $49, $3e, $51, $51, $42, $4f, $46, $4b
    db $44, $62, $51, $45, $42, $4a, $63, $f7, $f0
TextStr_4e_5a0c:           ; id $0889
    ; "[HERO] reads the blackboard. / *:There are characteristics / for monsters / *:such as resistance / to fire or ice. / *:For example, Metaly i..."
    db $f6, $62, $4f, $42, $3e, $41, $50, $62, $51, $45, $42, $ef, $ee, $3f, $49, $3e
    db $40, $48, $3f, $4c, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45
    db $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $40, $45, $3e, $4f, $3e, $40, $51
    db $42, $4f, $46, $50, $51, $46, $40, $50, $fa, $f7, $ef, $ee, $43, $4c, $4f, $62
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $50, $52, $40, $45, $62, $3e, $50, $ef, $ee, $4f, $42, $50, $46, $50, $51, $3e
    db $4b, $40, $42, $fa, $f7, $ef, $ee, $51, $4c, $62, $43, $46, $4f, $42, $62, $4c
    db $4f, $62, $46, $40, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $29, $4c
    db $4f, $62, $42, $55, $3e, $4a, $4d, $49, $42, $5e, $ef, $ee, $30, $42, $51, $3e
    db $49, $56, $62, $46, $50, $fa, $f7, $ef, $ee, $4f, $42, $50, $46, $50, $51, $3e
    db $4b, $51, $62, $51, $4c, $ef, $ee, $42, $53, $42, $4f, $56, $51, $45, $46, $4b
    db $44, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $50, $42, $ef, $ee, $40
    db $45, $3e, $4f, $3e, $40, $51, $42, $4f, $46, $50, $51, $46, $40, $50, $fa, $f7
    db $ef, $ee, $40, $3e, $4b, $62, $3f, $42, $62, $46, $4b, $45, $42, $4f, $46, $51
    db $42, $41, $ef, $ee, $3f, $56, $62, $51, $45, $42, $46, $4f, $62, $48, $46, $41
    db $50, $5f, $fa, $f7, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $4f, $42
    db $3e, $41, $ef, $ee, $4a, $4c, $4f, $42, $64, $ff, $f0
TextStr_4e_5b17:           ; id $088A
    ; "*:Namely, dragons with Metaly / parents / *:are more resistant to a / variety of things. / *:The more the + for breeding, the / greater the ..."
    db $9f, $a3, $31, $3e, $4a, $42, $49, $56, $5e, $62, $41, $4f, $3e, $44, $4c, $4b
    db $50, $ef, $ee, $54, $46, $51, $45, $62, $30, $42, $51, $3e, $49, $56, $fa, $f7
    db $ef, $ee, $4d, $3e, $4f, $42, $4b, $51, $50, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $3e, $4f, $42, $62, $4a, $4c, $4f, $42, $ef, $ee, $4f, $42, $50, $46, $50
    db $51, $3e, $4b, $51, $62, $51, $4c, $62, $3e, $fa, $f7, $ef, $ee, $53, $3e, $4f
    db $46, $42, $51, $56, $62, $4c, $43, $62, $51, $45, $46, $4b, $44, $50, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4a, $4c, $4f, $42, $62
    db $51, $45, $42, $62, $a2, $ef, $ee, $43, $4c, $4f, $62, $3f, $4f, $42, $42, $41
    db $46, $4b, $44, $5e, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44, $4f, $42, $3e
    db $51, $42, $4f, $62, $51, $45, $42, $ef, $ee, $51, $42, $4b, $41, $42, $4b, $40
    db $56, $62, $43, $4c, $4f, $62, $51, $45, $3e, $51, $5f, $f7, $f0
TextStr_4e_5bc4:           ; id $088B
    ; "*:A mnemonic for useful skills / and monsters... mumbling... / *:Antidote Dracky NumbOff Snaily / *:DeChaos CoilBird CurseOff DeadNite / *:S..."
    db $ea, $9f, $a3, $24, $62, $4a, $4b, $42, $4a, $4c, $4b, $46, $40, $ef, $ee, $43
    db $4c, $4f, $62, $52, $50, $42, $43, $52, $49, $62, $50, $48, $46, $49, $49, $50
    db $fa, $f7, $ef, $ee, $3e, $4b, $41, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $5f, $5f, $5f, $ef, $ee, $4a, $52, $4a, $3f, $49, $46, $4b, $44, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b, $51, $46, $41, $4c, $51, $42, $62, $27
    db $4f, $3e, $40, $48, $56, $ef, $ee, $31, $52, $4a, $3f, $32, $43, $43, $62, $36
    db $4b, $3e, $46, $49, $56, $fa, $f7, $ef, $ee, $9f, $a3, $27, $42, $26, $45, $3e
    db $4c, $50, $62, $26, $4c, $46, $49, $25, $46, $4f, $41, $ef, $ee, $26, $52, $4f
    db $50, $42, $32, $43, $43, $62, $27, $42, $3e, $41, $31, $46, $51, $42, $fa, $f7
    db $ef, $ee, $9f, $a3, $36, $51, $42, $4d, $2a, $52, $3e, $4f, $41, $ef, $ee, $3a
    db $46, $4b, $44, $37, $4f, $42, $42, $5e, $fa, $f7, $ef, $ee, $30, $3e, $4d, $30
    db $3e, $44, $46, $40, $62, $28, $56, $42, $41, $42, $4f, $5f, $5f, $5f, $ef, $ee
    db $f7, $f0
TextStr_4e_5c86:           ; id $088C
    ; "*:Would you like to learn about the / Gate of Joy? [YES/NO]"
    db $ea, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $51, $4c, $62, $49, $42, $3e, $4f, $4b, $62, $3e, $3f, $4c, $52
    db $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43
    db $62, $2d, $4c, $56, $64, $ef, $ee, $ff, $f0
TextStr_4e_5cbf:           ; id $088D
    ; "*:There were Snailys, Saccers, / Gulpples, MadPeckers, / *:EyeBalls, Babbles, & Mummys / living there. / *:Beware of monsters with / Paralyz..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $42, $4f, $42, $ef, $ee, $36
    db $4b, $3e, $46, $49, $56, $50, $5e, $62, $36, $3e, $40, $40, $42, $4f, $50, $5e
    db $fa, $f7, $ef, $ee, $2a, $52, $49, $4d, $4d, $49, $42, $50, $5e, $ef, $ee, $30
    db $3e, $41, $33, $42, $40, $48, $42, $4f, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3
    db $28, $56, $42, $25, $3e, $49, $49, $50, $5e, $ef, $ee, $25, $3e, $3f, $3f, $49
    db $42, $50, $5e, $62, $b6, $62, $30, $52, $4a, $4a, $56, $50, $fa, $f7, $ef, $ee
    db $49, $46, $53, $46, $4b, $44, $62, $51, $45, $42, $4f, $42, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $25, $42, $54, $3e, $4f, $42, $62, $4c, $43, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $54, $46, $51, $45, $fa, $f7, $ef
    db $ee, $33, $3e, $4f, $3e, $49, $56, $57, $42, $62, $b6, $ef, $ee, $33, $4c, $46
    db $50, $4c, $4b, $2b, $46, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52
    db $62, $4a, $46, $44, $45, $51, $62, $54, $3e, $4b, $51, $ef, $ee, $51, $4c, $62
    db $51, $3e, $48, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7, $ef
    db $ee, $54, $46, $51, $45, $62, $24, $4b, $51, $46, $41, $4c, $51, $42, $62, $b6
    db $ef, $ee, $31, $52, $4a, $3f, $32, $43, $43, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $51, $45
    db $42, $4f, $42, $62, $46, $50, $62, $3e, $fa, $f7, $ef, $ee, $29, $52, $4b, $48
    db $56, $25, $46, $4f, $41, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51
    db $62, $54, $46, $49, $49, $62, $40, $4c, $4b, $43, $52, $50, $42, $ef, $ee, $56
    db $4c, $52, $62, $3f, $56, $62, $41, $3e, $4b, $40, $46, $4b, $44, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $33, $3e, $4b, $46, $27, $3e, $4b, $40, $42, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $66, $49, $62, $4b, $42, $42
    db $41, $62, $3e, $ef, $ee, $36, $48, $56, $25, $42, $49, $49, $62, $51, $4c, $62
    db $40, $52, $4f, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $40, $4c, $4b, $43
    db $52, $50, $46, $4c, $4b, $5f, $ef, $ee, $f7, $f0
TextStr_4e_5e49:           ; id $088E
    ; "*:Want to know about the monsters / behind the Gate of Wisdom? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $3a, $46, $50, $41, $4c
    db $4a, $64, $ff, $f0
TextStr_4e_5e8d:           ; id $088F
    ; "*:There are Facers, / Tonguellas, Florajays, / Pteranods, and / *:ArmorPedes living there! / *:Florajays use BeastCut. / *:The guardian ther..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $29, $3e
    db $40, $42, $4f, $50, $5e, $fa, $f7, $ef, $ee, $37, $4c, $4b, $44, $52, $42, $49
    db $49, $3e, $50, $5e, $ef, $ee, $29, $49, $4c, $4f, $3e, $47, $3e, $56, $50, $5e
    db $fa, $f7, $ef, $ee, $33, $51, $42, $4f, $3e, $4b, $4c, $41, $50, $5e, $ef, $ee
    db $3e, $4b, $41, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4f, $4a, $4c, $4f, $33, $42
    db $41, $42, $50, $ef, $ee, $49, $46, $53, $46, $4b, $44, $62, $51, $45, $42, $4f
    db $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $29, $49, $4c, $4f, $3e, $47, $3e, $56
    db $50, $62, $52, $50, $42, $ef, $ee, $25, $42, $3e, $50, $51, $26, $52, $51, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46
    db $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $fa, $f7
    db $ef, $ee, $36, $48, $56, $27, $4f, $3e, $44, $4c, $4b, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $51, $50, $62, $36, $40, $4c, $4f, $40, $45, $46, $4b
    db $44, $62, $46, $50, $ef, $ee, $4d, $4c, $54, $42, $4f, $43, $52, $49, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $4a, $46, $44, $45, $51, $62, $54
    db $3e, $4b, $51, $ef, $ee, $51, $4c, $62, $51, $3e, $48, $42, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $fa, $f7, $ef, $ee, $43, $4f, $4c, $4a, $62, $51, $45
    db $42, $62, $32, $3f, $47, $42, $40, $51, $50, $ef, $ee, $4c, $4f, $62, $27, $4f
    db $3e, $44, $4c, $4b, $50, $fa, $f7, $ef, $ee, $43, $3e, $4a, $46, $49, $46, $42
    db $50, $5f, $ef, $ee, $f7, $f0
TextStr_4e_5fb3:           ; id $0890
    ; "*:Would you like to hear about the / Gate of Happiness? [YES/NO]"
    db $ea, $9f, $a3, $3a, $4c, $52, $49, $41, $62, $56, $4c, $52, $62, $49, $46, $48
    db $42, $ef, $ee, $51, $4c, $62, $45, $42, $3e, $4f, $62, $3e, $3f, $4c, $52, $51
    db $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $4c, $43, $62
    db $2b, $3e, $4d, $4d, $46, $4b, $42, $50, $50, $64, $ef, $ee, $ff, $f0
TextStr_4e_5ff1:           ; id $0891
    ; "*:There are Onionos, / Gophecadas, Pixys, / Gasgons, / *:DeadNites, StubBirds, and / SpikyBoys living there. / *:Gophecades use Beat. Get'em..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $32, $4b
    db $46, $4c, $4b, $4c, $50, $5e, $fa, $f7, $ef, $ee, $2a, $4c, $4d, $45, $42, $40
    db $3e, $41, $3e, $50, $5e, $ef, $ee, $33, $46, $55, $56, $50, $5e, $fa, $f7, $ef
    db $ee, $2a, $3e, $50, $44, $4c, $4b, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $27, $42, $3e, $41, $31, $46, $51, $42, $50, $5e, $ef, $ee, $36, $51, $52
    db $3f, $25, $46, $4f, $41, $50, $5e, $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $36
    db $4d, $46, $48, $56, $25, $4c, $56, $50, $62, $49, $46, $53, $46, $4b, $44, $ef
    db $ee, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $4d
    db $45, $42, $40, $3e, $41, $42, $50, $62, $52, $50, $42, $ef, $ee, $25, $42, $3e
    db $51, $5f, $62, $2a, $42, $51, $6e, $4a, $fa, $f7, $ef, $ee, $3f, $42, $43, $4c
    db $4f, $42, $62, $51, $45, $42, $56, $62, $44, $42, $51, $ef, $ee, $56, $4c, $52
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41
    db $46, $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $fa
    db $f7, $ef, $ee, $2d, $3e, $4a, $46, $4f, $52, $50, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3a, $3e, $51, $40, $45, $62, $4c, $52, $51, $62, $43, $4c, $4f
    db $ef, $ee, $46, $51, $50, $62, $34, $52, $3e, $41, $2b, $46, $51, $50, $63, $f7
    db $f0
TextStr_4e_60f2:           ; id $0892
    ; "*:Want to know about the monsters / behind the Gate of Temptation? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $37, $42, $4a, $4d, $51
    db $3e, $51, $46, $4c, $4b, $64, $ff, $f0
TextStr_4e_613a:           ; id $0893
    ; "*:There are SpikyBoys, / KingCobras, Mommonjas, / SlimeNites, / *:StagBugs, MistyWings, and / DarkEyes living there. / *:KingCobras use a po..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $36, $4d
    db $46, $48, $56, $25, $4c, $56, $50, $5e, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44
    db $26, $4c, $3f, $4f, $3e, $50, $5e, $ef, $ee, $30, $4c, $4a, $4a, $4c, $4b, $47
    db $3e, $50, $5e, $fa, $f7, $ef, $ee, $36, $49, $46, $4a, $42, $31, $46, $51, $42
    db $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $51, $3e, $44, $25, $52
    db $44, $50, $5e, $ef, $ee, $30, $46, $50, $51, $56, $3a, $46, $4b, $44, $50, $5e
    db $62, $3e, $4b, $41, $fa, $f7, $ef, $ee, $27, $3e, $4f, $48, $28, $56, $42, $50
    db $62, $49, $46, $53, $46, $4b, $44, $ef, $ee, $51, $45, $42, $4f, $42, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $2e, $46, $4b, $44, $26, $4c, $3f, $4f, $3e, $50, $62
    db $52, $50, $42, $ef, $ee, $3e, $62, $4d, $4c, $46, $50, $4c, $4b, $4c, $52, $50
    db $fa, $f7, $ef, $ee, $3e, $51, $51, $3e, $40, $48, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $33, $3e, $49, $50, $56, $24, $46, $4f, $62, $4c, $43, $ef, $ee
    db $27, $3e, $4f, $48, $28, $56, $42, $62, $54, $46, $49, $49, $fa, $f7, $ef, $ee
    db $4d, $3e, $4f, $3e, $49, $56, $57, $42, $62, $3e, $49, $49, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $50, $45, $4c, $52, $49, $41, $62
    db $51, $3e, $48, $42, $ef, $ee, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62
    db $54, $46, $51, $45, $fa, $f7, $ef, $ee, $31, $52, $4a, $3f, $32, $43, $43, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f
    db $41, $46, $3e, $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e
    db $fa, $f7, $ef, $ee, $36, $42, $4f, $53, $3e, $4b, $51, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $51, $62, $3e, $49, $54, $3e, $56, $50, $ef, $ee, $50
    db $45, $4c, $54, $50, $62, $52, $4d, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee
    db $26, $42, $4b, $51, $3e, $50, $3e, $52, $4f, $62, $3e, $4b, $41, $ef, $ee, $28
    db $53, $46, $49, $24, $4f, $4a, $4c, $4f, $63, $f7, $f0
TextStr_4e_62b5:           ; id $0894
    ; "*:The Hork downstairs wants / to learn Vivify. / *:But it's impossible! Why? / *:Today's lecture is about how to / inherit skills. Want to l..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $2b, $4c, $4f, $48, $ef, $ee, $41, $4c, $54
    db $4b, $50, $51, $3e, $46, $4f, $50, $62, $54, $3e, $4b, $51, $50, $fa, $f7, $ef
    db $ee, $51, $4c, $62, $49, $42, $3e, $4f, $4b, $62, $39, $46, $53, $46, $43, $56
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $46, $51, $68
    db $ef, $ee, $46, $4a, $4d, $4c, $50, $50, $46, $3f, $49, $42, $63, $62, $3a, $45
    db $56, $64, $fa, $f7, $ef, $ee, $9f, $a3, $37, $4c, $41, $3e, $56, $68, $62, $49
    db $42, $40, $51, $52, $4f, $42, $ef, $ee, $46, $50, $62, $3e, $3f, $4c, $52, $51
    db $62, $45, $4c, $54, $62, $51, $4c, $fa, $f7, $ef, $ee, $46, $4b, $45, $42, $4f
    db $46, $51, $62, $50, $48, $46, $49, $49, $50, $5f, $ef, $ee, $3a, $3e, $4b, $51
    db $62, $51, $4c, $62, $49, $46, $50, $51, $42, $4b, $64, $ff, $f0
TextStr_4e_6352:           ; id $0895
    ; "*:Monsters can inherit all the / skills of their parents. / *:They can learn skills of their / grandparents. / *:But not all skills of the /..."
    db $ea, $9f, $a3, $30, $4c, $4b, $50, $51, $42, $4f, $50, $62, $40, $3e, $4b, $ef
    db $ee, $46, $4b, $45, $42, $4f, $46, $51, $62, $3e, $49, $49, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $50, $48, $46, $49, $49, $50, $62, $4c, $43, $62, $51, $45
    db $42, $46, $4f, $ef, $ee, $4d, $3e, $4f, $42, $4b, $51, $50, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $45, $42, $56, $62, $40, $3e, $4b, $62, $49, $42, $3e, $4f
    db $4b, $ef, $ee, $50, $48, $46, $49, $49, $50, $62, $4c, $43, $62, $51, $45, $42
    db $46, $4f, $fa, $f7, $ef, $ee, $44, $4f, $3e, $4b, $41, $4d, $3e, $4f, $42, $4b
    db $51, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $4b
    db $4c, $51, $62, $3e, $49, $49, $ef, $ee, $50, $48, $46, $49, $49, $50, $62, $4c
    db $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $44, $4f, $3e, $4b, $41, $4d, $3e
    db $4f, $42, $4b, $51, $50, $ef, $ee, $40, $3e, $4b, $62, $3f, $42, $62, $49, $42
    db $3e, $4f, $4b, $42, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $4b, $62, $43
    db $3e, $40, $51, $5e, $62, $51, $45, $42, $56, $ef, $ee, $46, $4b, $45, $42, $4f
    db $46, $51, $62, $4c, $4b, $49, $56, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $50
    db $48, $46, $49, $49, $50, $62, $51, $45, $3e, $51, $62, $46, $51, $50, $ef, $ee
    db $4d, $3e, $4f, $42, $4b, $51, $50, $62, $49, $42, $3e, $4f, $4b, $42, $41, $63
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $42, $55, $4d, $49, $3e, $46
    db $4b, $ef, $ee, $52, $50, $46, $4b, $44, $62, $51, $45, $42, $62, $2b, $4c, $4f
    db $48, $fa, $f7, $ef, $ee, $41, $4c, $54, $4b, $50, $51, $3e, $46, $4f, $50, $62
    db $3e, $50, $ef, $ee, $3e, $4b, $62, $42, $55, $3e, $4a, $4d, $49, $42, $5f, $ff
    db $f0
TextStr_4e_6493:           ; id $0896
    ; "*:Its parents only learned Heal, / *:among the skills it inherited from / Grandpa. / *:It's parents could've learned / Vivify, but / *:It wa..."
    db $ea, $9f, $a3, $2c, $51, $50, $62, $4d, $3e, $4f, $42, $4b, $51, $50, $62, $4c
    db $4b, $49, $56, $ef, $ee, $49, $42, $3e, $4f, $4b, $42, $41, $62, $2b, $42, $3e
    db $49, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4a, $4c, $4b, $44, $62, $51, $45
    db $42, $62, $50, $48, $46, $49, $49, $50, $ef, $ee, $46, $51, $62, $46, $4b, $45
    db $42, $4f, $46, $51, $42, $41, $62, $43, $4f, $4c, $4a, $fa, $f7, $ef, $ee, $2a
    db $4f, $3e, $4b, $41, $4d, $3e, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $51, $68, $62, $4d, $3e, $4f, $42, $4b, $51, $50, $ef, $ee, $40, $4c, $52, $49
    db $41, $6c, $42, $62, $49, $42, $3e, $4f, $4b, $42, $41, $fa, $f7, $ef, $ee, $39
    db $46, $53, $46, $43, $56, $5e, $62, $3f, $52, $51, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $51, $62, $54, $3e, $50, $62, $3f, $4f, $42, $41, $ef, $ee, $3f
    db $42, $43, $4c, $4f, $42, $62, $51, $45, $42, $56, $fa, $f7, $ef, $ee, $49, $42
    db $3e, $4f, $4b, $42, $41, $62, $39, $46, $53, $46, $43, $56, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $52, $50, $5e, $62, $51, $45, $42, $62, $2b
    db $4c, $4f, $48, $ef, $ee, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $9f, $a3, $40
    db $3e, $4b, $62, $4c, $4b, $49, $56, $62, $49, $42, $3e, $4f, $4b, $ef, $ee, $2b
    db $42, $3e, $49, $5e, $62, $46, $5f, $42, $5f, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $50, $48, $46, $49, $49, $62, $46, $51, $68, $62, $4d, $3e, $4f, $42, $4b
    db $51, $50, $ef, $ee, $49, $42, $3e, $4f, $4b, $42, $41, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $51, $62, $40, $3e, $4b, $4b, $4c, $51, $ef, $ee, $49, $42, $3e
    db $4f, $4b, $62, $39, $46, $53, $46, $43, $56, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $5f, $5f, $5f, $3f, $42, $40, $3e, $52, $50, $42, $62, $46, $51, $68
    db $ef, $ee, $4d, $3e, $4f, $42, $4b, $51, $50, $62, $41, $46, $41, $4b, $67, $fa
    db $f7, $ef, $ee, $49, $42, $3e, $4f, $4b, $62, $39, $46, $53, $46, $43, $56, $5f
    db $ef, $ee, $f7, $f0
TextStr_4e_6607:           ; id $0897
    ; "*:I took notes on how to change / the gender of a monster. / *:Want to take a look? [YES/NO]"
    db $eb, $9f, $a3, $2c, $62, $51, $4c, $4c, $48, $62, $4b, $4c, $51, $42, $50, $ef
    db $ee, $4c, $4b, $62, $45, $4c, $54, $62, $51, $4c, $62, $40, $45, $3e, $4b, $44
    db $42, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $44, $42, $4b, $41, $42, $4f, $62
    db $4c, $43, $62, $3e, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $51, $3e, $48, $42
    db $62, $3e, $ef, $ee, $49, $4c, $4c, $48, $64, $ff, $f0
TextStr_4e_6662:           ; id $0898
    ; "[HERO] opened the notebook. / :When the family of the pedigree / and the family of the other monster / are the same, / :In principle, the sa..."
    db $f6, $62, $4c, $4d, $42, $4b, $42, $41, $ef, $ee, $51, $45, $42, $62, $4b, $4c
    db $51, $42, $3f, $4c, $4c, $48, $5f, $fa, $f7, $ef, $ee, $a3, $3a, $45, $42, $4b
    db $62, $51, $45, $42, $62, $43, $3e, $4a, $46, $49, $56, $ef, $ee, $4c, $43, $62
    db $51, $45, $42, $62, $4d, $42, $41, $46, $44, $4f, $42, $42, $fa, $f7, $ef, $ee
    db $3e, $4b, $41, $62, $51, $45, $42, $62, $43, $3e, $4a, $46, $49, $56, $62, $4c
    db $43, $ef, $ee, $51, $45, $42, $62, $4c, $51, $45, $42, $4f, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $3e, $4f, $42, $62, $51, $45, $42, $62
    db $50, $3e, $4a, $42, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $2c, $4b, $62, $4d
    db $4f, $46, $4b, $40, $46, $4d, $49, $42, $5e, $ef, $ee, $51, $45, $42, $62, $50
    db $3e, $4a, $42, $62, $48, $46, $4b, $41, $62, $4c, $43, $fa, $f7, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $62, $54, $46, $49, $49, $62, $3f, $42, $ef, $ee
    db $3f, $4c, $4f, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40
    db $3e, $4b, $62, $40, $45, $3e, $4b, $44, $42, $ef, $ee, $51, $45, $42, $62, $44
    db $42, $4b, $41, $42, $4f, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee
    db $42, $44, $44, $62, $43, $4f, $4c, $4a, $62, $51, $45, $46, $50, $ef, $ee, $4a
    db $3e, $51, $40, $45, $5f, $fa, $f7, $ef, $ee, $a3, $37, $3e, $48, $42, $62, $51
    db $45, $42, $62, $42, $44, $44, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $28
    db $44, $44, $fa, $f7, $ef, $ee, $26, $4c, $4b, $50, $52, $49, $51, $3e, $4b, $51
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $56, $62, $40, $3e, $4b
    db $ef, $ee, $3f, $49, $42, $50, $50, $62, $46, $51, $62, $3e, $4b, $41, $fa, $f7
    db $ef, $ee, $40, $45, $3e, $4b, $44, $42, $62, $51, $45, $42, $62, $44, $42, $4b
    db $41, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_4e_67ba:           ; id $0899
    ; "*:I took notes on how to catch / monsters. Wanna take a look? [YES/NO]"
    db $eb, $9f, $a3, $2c, $62, $51, $4c, $4c, $48, $62, $4b, $4c, $51, $42, $50, $ef
    db $ee, $4c, $4b, $62, $45, $4c, $54, $62, $51, $4c, $62, $40, $3e, $51, $40, $45
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $62, $3a, $3e
    db $4b, $4b, $3e, $ef, $ee, $51, $3e, $48, $42, $62, $3e, $62, $49, $4c, $4c, $48
    db $64, $ff, $f0
TextStr_4e_67fd:           ; id $089A
    ; "*:Foreign masters have lots of kinds / of monsters! / *:Like, LavaMan, IceMan, / *:Unicorn, Metaly, / Tortragon, and KingSlime!"
    db $ea, $9f, $a3, $29, $4c, $4f, $42, $46, $44, $4b, $62, $4a, $3e, $50, $51, $42
    db $4f, $50, $ef, $ee, $45, $3e, $53, $42, $62, $49, $4c, $51, $50, $62, $4c, $43
    db $62, $48, $46, $4b, $41, $50, $fa, $f7, $ef, $ee, $4c, $43, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $46
    db $48, $42, $5e, $62, $2f, $3e, $53, $3e, $30, $3e, $4b, $5e, $ef, $ee, $2c, $40
    db $42, $30, $3e, $4b, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $38, $4b, $46, $40, $4c
    db $4f, $4b, $5e, $ef, $ee, $30, $42, $51, $3e, $49, $56, $5e, $fa, $f7, $ef, $ee
    db $37, $4c, $4f, $51, $4f, $3e, $44, $4c, $4b, $5e, $ef, $ee, $3e, $4b, $41, $62
    db $2e, $46, $4b, $44, $36, $49, $46, $4a, $42, $63, $f7, $f0
TextStr_4e_6889:           ; id $089B
    ; "*:Gate of Labyrinth. Want to / learn about it? [YES/NO]"
    db $ea, $9f, $a3, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $2f, $3e, $3f, $56
    db $4f, $46, $4b, $51, $45, $5f, $62, $3a, $3e, $4b, $51, $62, $51, $4c, $fa, $f7
    db $ef, $ee, $49, $42, $3e, $4f, $4b, $62, $3e, $3f, $4c, $52, $51, $62, $46, $51
    db $64, $ef, $ee, $ff, $f0
TextStr_4e_68be:           ; id $089C
    ; "*:There are RockSlimes, / Chamelgons, CactiBalls, / *:TailEaters, DuckKites, / AgDevils, / *:and WindMerges living there. / *:TailEaters use..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $35, $4c
    db $40, $48, $36, $49, $46, $4a, $42, $50, $5e, $fa, $f7, $ef, $ee, $26, $45, $3e
    db $4a, $42, $49, $44, $4c, $4b, $50, $5e, $ef, $ee, $26, $3e, $40, $51, $46, $25
    db $3e, $49, $49, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $37, $3e, $46, $49, $28
    db $3e, $51, $42, $4f, $50, $5e, $ef, $ee, $27, $52, $40, $48, $2e, $46, $51, $42
    db $50, $5e, $fa, $f7, $ef, $ee, $24, $44, $27, $42, $53, $46, $49, $50, $5e, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $3a, $46, $4b, $41, $30
    db $42, $4f, $44, $42, $50, $ef, $ee, $49, $46, $53, $46, $4b, $44, $62, $51, $45
    db $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $3e, $46, $49, $28, $3e
    db $51, $42, $4f, $50, $62, $52, $50, $42, $ef, $ee, $33, $4c, $46, $50, $4c, $4b
    db $24, $46, $4f, $5e, $fa, $f7, $ef, $ee, $27, $52, $40, $48, $2e, $46, $51, $42
    db $50, $62, $52, $50, $42, $ef, $ee, $26, $52, $4f, $50, $42, $5e, $fa, $f7, $ef
    db $ee, $9f, $a3, $26, $3e, $51, $46, $25, $3e, $49, $49, $50, $62, $52, $50, $42
    db $ef, $ee, $33, $3e, $4f, $3e, $49, $56, $57, $42, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $51
    db $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $fa, $f7, $ef, $ee, $27, $3e, $4f
    db $48, $2b, $4c, $4f, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51
    db $62, $3f, $49, $4c, $40, $48, $50, $ef, $ee, $50, $4d, $42, $49, $49, $50, $62
    db $54, $46, $51, $45, $fa, $f7, $ef, $ee, $36, $51, $4c, $4d, $36, $4d, $42, $49
    db $49, $63, $ef, $ee, $f7, $f0
TextStr_4e_69f4:           ; id $089D
    ; "*:Want to know about the monsters / behind the Gate of Judgment? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $2d, $52, $41, $44, $4a
    db $42, $4b, $51, $64, $ff, $f0
TextStr_4e_6a3a:           ; id $089E
    ; "*:There are WeedBugs, / HammerMen, MadGeese, / *:TreeBoys, are SpotKings, Drolls, / LizardFlys, / *:And GiantMoths living there. / *:Beware ..."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee, $3a, $42
    db $42, $41, $25, $52, $44, $50, $5e, $fa, $f7, $ef, $ee, $2b, $3e, $4a, $4a, $42
    db $4f, $30, $42, $4b, $5e, $ef, $ee, $30, $3e, $41, $2a, $42, $42, $50, $42, $5e
    db $fa, $f7, $ef, $ee, $9f, $a3, $37, $4f, $42, $42, $25, $4c, $56, $50, $5e, $62
    db $3e, $4f, $42, $ef, $ee, $36, $4d, $4c, $51, $2e, $46, $4b, $44, $50, $5e, $62
    db $27, $4f, $4c, $49, $49, $50, $5e, $fa, $f7, $ef, $ee, $2f, $46, $57, $3e, $4f
    db $41, $29, $49, $56, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4b
    db $41, $62, $2a, $46, $3e, $4b, $51, $30, $4c, $51, $45, $50, $ef, $ee, $49, $46
    db $53, $46, $4b, $44, $62, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $25, $42, $54, $3e, $4f, $42, $62, $4c, $43, $ef, $ee, $28, $53, $46, $49
    db $36, $49, $3e, $50, $45, $62, $3e, $4b, $41, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $2b, $3e, $4a, $4a, $42, $4f, $30, $42, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $44, $52, $4f, $3e, $41, $46, $3e, $4b, $ef, $ee
    db $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $4b, $fa, $f7, $ef, $ee, $24
    db $48, $52, $3f, $3e, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51
    db $62, $52, $50, $42, $50, $ef, $ee, $29, $4c, $40, $52, $50, $62, $3e, $4b, $41
    db $fa, $f7, $ef, $ee, $28, $55, $4d, $49, $4c, $41, $42, $51, $63, $ef, $ee, $f7
    db $f0
TextStr_4e_6b4b:           ; id $089F
    ; "*:You want to learn about / the Gate of Reflection!? [YES/NO]"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $ef, $ee
    db $49, $42, $3e, $4f, $4b, $62, $3e, $3f, $4c, $52, $51, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $35, $42, $43, $49
    db $42, $40, $51, $46, $4c, $4b, $63, $64, $ff, $f0
TextStr_4e_6b85:           ; id $08A0
    ; "*:I don't want to tell you this. / *:I think EvilBeasts, / Shadows, EvilWands, / SlimeBorgs, / *:LizardMen, Grizzlys, / and FireWeeds were t..."
    db $ea, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $54, $3e, $4b, $51, $ef, $ee
    db $51, $4c, $62, $51, $42, $49, $49, $62, $56, $4c, $52, $62, $51, $45, $46, $50
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $51, $45, $46, $4b, $48, $ef, $ee
    db $28, $53, $46, $49, $25, $42, $3e, $50, $51, $50, $5e, $fa, $f7, $ef, $ee, $36
    db $45, $3e, $41, $4c, $54, $50, $5e, $ef, $ee, $28, $53, $46, $49, $3a, $3e, $4b
    db $41, $50, $5e, $fa, $f7, $ef, $ee, $36, $49, $46, $4a, $42, $25, $4c, $4f, $44
    db $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $46, $57, $3e, $4f, $41
    db $30, $42, $4b, $5e, $ef, $ee, $2a, $4f, $46, $57, $57, $49, $56, $50, $5e, $fa
    db $f7, $ef, $ee, $3e, $4b, $41, $62, $29, $46, $4f, $42, $3a, $42, $42, $41, $50
    db $ef, $ee, $54, $42, $4f, $42, $62, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $4f, $42, $4a, $42, $4a, $3f, $42, $4f, $62, $51, $45
    db $42, $4f, $42, $ef, $ee, $54, $3e, $50, $62, $3e, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $62, $51, $45, $3e, $51, $fa, $f7, $ef, $ee, $52, $50, $42, $50, $62
    db $33, $3e, $49, $50, $56, $24, $46, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee, $51
    db $45, $42, $4f, $42, $62, $54, $3e, $50, $62, $27, $52, $4f, $4f, $3e, $4b, $5e
    db $fa, $f7, $ef, $ee, $4c, $4f, $62, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44
    db $ef, $ee, $49, $46, $48, $42, $62, $51, $45, $3e, $51, $5f, $5f, $5f, $f7, $f0
TextStr_4e_6ca5:           ; id $08A1
    ; "*:I don't want to be reminded of / that Travelers' Gate..."
    db $ea, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $54, $3e, $4b, $51, $62, $51
    db $4c, $ef, $ee, $3f, $42, $62, $4f, $42, $4a, $46, $4b, $41, $42, $41, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $51, $45, $3e, $51, $62, $37, $4f, $3e, $53, $42, $49
    db $42, $4f, $50, $5c, $ef, $ee, $2a, $3e, $51, $42, $5f, $5f, $5f, $f7, $f0
TextStr_4e_6ce4:           ; id $08A2
    ; "*:What? You want to know / about the Gate of Reflection!? [YES/NO]"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $ef, $ee, $54, $3e
    db $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $fa, $f7, $ef, $ee, $3e, $3f
    db $4c, $52, $51, $62, $51, $45, $42, $62, $2a, $3e, $51, $42, $ef, $ee, $4c, $43
    db $62, $35, $42, $43, $49, $42, $40, $51, $46, $4c, $4b, $63, $64, $ff, $f0
TextStr_4e_6d23:           ; id $08A3
    ; "*:I see... I don't remember much... / *:But I think there were / Wyverns, Lionexes, / MadHornets, RotRavens, / *:and JewelBags living there...."
    db $ea, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $5f, $5f, $62, $2c, $62, $41, $4c
    db $4b, $67, $ef, $ee, $4f, $42, $4a, $42, $4a, $3f, $42, $4f, $62, $4a, $52, $40
    db $45, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $2c, $62
    db $51, $45, $46, $4b, $48, $ef, $ee, $51, $45, $42, $4f, $42, $62, $54, $42, $4f
    db $42, $fa, $f7, $ef, $ee, $3a, $56, $53, $42, $4f, $4b, $50, $5e, $ef, $ee, $2f
    db $46, $4c, $4b, $42, $55, $42, $50, $5e, $fa, $f7, $ef, $ee, $30, $3e, $41, $2b
    db $4c, $4f, $4b, $42, $51, $50, $5e, $ef, $ee, $35, $4c, $51, $35, $3e, $53, $42
    db $4b, $50, $5e, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $4b, $41, $62, $2d, $42, $54
    db $42, $49, $25, $3e, $44, $50, $ef, $ee, $49, $46, $53, $46, $4b, $44, $62, $51
    db $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $51, $45, $46
    db $4b, $48, $5e, $ef, $ee, $30, $3e, $41, $2b, $4c, $4f, $4b, $42, $51, $50, $fa
    db $f7, $ef, $ee, $3e, $51, $51, $3e, $40, $48, $62, $54, $46, $51, $45, $ef, $ee
    db $4d, $4c, $46, $50, $4c, $4b, $fa, $f7, $ef, $ee, $3e, $4b, $41, $62, $4d, $3e
    db $4f, $3e, $49, $56, $50, $46, $50, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e, $4b, $ef, $ee
    db $51, $45, $42, $4f, $42, $62, $54, $3e, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee
    db $31, $4c, $5e, $62, $2c, $62, $40, $3e, $4b, $4b, $4c, $51, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $3e, $ef, $ee, $45
    db $42, $3e, $41, $3e, $40, $45, $42, $63, $fa, $f7, $ef, $ee, $2f, $42, $3e, $53
    db $42, $62, $4a, $42, $62, $3e, $49, $4c, $4b, $42, $63, $ef, $ee, $f7, $f0
TextStr_4e_6e62:           ; id $08A4
    ; "*:Tut, you remind me of bad / memories!"
    db $ea, $9f, $a3, $37, $52, $51, $5e, $62, $56, $4c, $52, $62, $4f, $42, $4a, $46
    db $4b, $41, $ef, $ee, $4a, $42, $62, $4c, $43, $62, $3f, $3e, $41, $fa, $f7, $ef
    db $ee, $4a, $42, $4a, $4c, $4f, $46, $42, $50, $63, $ef, $ee, $f7, $f0
TextStr_4e_6e90:           ; id $08A5
    ; "*:I,I thought you went to the Gate / of Reflection. / *:Why!? Are you okay!? / *:...I see. Maybe you'll win a / victory!"
    db $ea, $9f, $a3, $2c, $5e, $2c, $62, $51, $45, $4c, $52, $44, $45, $51, $62, $56
    db $4c, $52, $ef, $ee, $54, $42, $4b, $51, $62, $51, $4c, $62, $51, $45, $42, $62
    db $2a, $3e, $51, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $35, $42, $43, $49, $42
    db $40, $51, $46, $4c, $4b, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45
    db $56, $63, $64, $62, $24, $4f, $42, $62, $56, $4c, $52, $ef, $ee, $4c, $48, $3e
    db $56, $63, $64, $fa, $f7, $ef, $ee, $9f, $a3, $5f, $5f, $5f, $2c, $62, $50, $42
    db $42, $5f, $62, $30, $3e, $56, $3f, $42, $ef, $ee, $56, $4c, $52, $66, $49, $62
    db $54, $46, $4b, $62, $3e, $fa, $f7, $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56
    db $63, $ef, $ee, $f7, $f0
TextStr_4e_6f15:           ; id $08A6
    ; "*:Oh, you haven't visited the Gate / of Reflection yet. / *:What? You've been there!? / Why,why you look fine? / *:Hmmm, I don't believe it...."
    db $ea, $9f, $a3, $32, $45, $5e, $62, $56, $4c, $52, $62, $45, $3e, $53, $42, $4b
    db $67, $ef, $ee, $53, $46, $50, $46, $51, $42, $41, $62, $51, $45, $42, $62, $2a
    db $3e, $51, $42, $fa, $f7, $ef, $ee, $4c, $43, $62, $35, $42, $43, $49, $42, $40
    db $51, $46, $4c, $4b, $ef, $ee, $56, $42, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $45, $3e, $51, $64, $62, $3c, $4c, $52, $6c, $42, $ef, $ee, $3f, $42, $42
    db $4b, $62, $51, $45, $42, $4f, $42, $63, $64, $fa, $f7, $ef, $ee, $3a, $45, $56
    db $5e, $54, $45, $56, $62, $56, $4c, $52, $62, $49, $4c, $4c, $48, $ef, $ee, $43
    db $46, $4b, $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4a, $4a, $4a, $5e, $62
    db $2c, $62, $41, $4c, $4b, $67, $ef, $ee, $3f, $42, $49, $46, $42, $53, $42, $62
    db $46, $51, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $2a, $4c, $4c, $41, $62, $49, $52
    db $40, $48, $62, $3e, $51, $62, $51, $45, $42, $ef, $ee, $51, $4c, $52, $4f, $4b
    db $3e, $4a, $42, $4b, $51, $63, $f7, $f0
TextStr_4e_6fcd:           ; id $08A7
    ; "*:You, must obey me. / *:I want to see a KingLeo! / *:Bring KingLeo, the beast of / beasts!"
    db $eb, $9f, $a3, $3c, $4c, $52, $5e, $62, $4a, $52, $50, $51, $62, $4c, $3f, $42
    db $56, $ef, $ee, $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e
    db $4b, $51, $62, $51, $4c, $62, $50, $42, $42, $62, $3e, $ef, $ee, $2e, $46, $4b
    db $44, $2f, $42, $4c, $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4f, $46, $4b, $44
    db $62, $2e, $46, $4b, $44, $2f, $42, $4c, $5e, $ef, $ee, $51, $45, $42, $62, $3f
    db $42, $3e, $50, $51, $62, $4c, $43, $fa, $f7, $ef, $ee, $3f, $42, $3e, $50, $51
    db $50, $63, $ef, $ee, $f7, $f0
TextStr_4e_7033:           ; id $08A8
    ; "*:Oh, It is KingLeo! / How majestic! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $32, $45, $5e, $62, $2c, $51, $62, $46, $50, $ef, $ee, $2e, $46
    db $4b, $44, $2f, $42, $4c, $63, $fa, $f7, $ef, $ee, $2b, $4c, $54, $62, $4a, $3e
    db $47, $42, $50, $51, $46, $40, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $2c, $66, $49, $62, $44
    db $46, $53, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $3e, $62, $4f, $42, $54
    db $3e, $4f, $41, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4e_708c:           ; id $08A9
    ; "*:It's a SmartBk Use it wisely!"
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $62, $36, $4a, $3e, $4f, $51, $25, $48
    db $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54, $46, $50, $42, $49, $56, $63
    db $f7, $f0
TextStr_4e_70ae:           ; id $08AA
    ; "*:You, must obey me! / *:Bring me a RainHawk! / *:The RainHawk that comes when / flame melts ice!"
    db $eb, $9f, $a3, $3c, $4c, $52, $5e, $62, $4a, $52, $50, $51, $62, $4c, $3f, $42
    db $56, $ef, $ee, $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4f, $46, $4b
    db $44, $62, $4a, $42, $ef, $ee, $3e, $62, $35, $3e, $46, $4b, $2b, $3e, $54, $48
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $35, $3e, $46, $4b, $2b
    db $3e, $54, $48, $ef, $ee, $51, $45, $3e, $51, $62, $40, $4c, $4a, $42, $50, $62
    db $54, $45, $42, $4b, $fa, $f7, $ef, $ee, $43, $49, $3e, $4a, $42, $62, $4a, $42
    db $49, $51, $50, $62, $46, $40, $42, $63, $ef, $ee, $f7, $f0
TextStr_4e_711a:           ; id $08AB
    ; "*:Oh, It is RainHawk! / What beautiful wings! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $32, $45, $5e, $62, $2c, $51, $62, $46, $50, $ef, $ee, $35, $3e
    db $46, $4b, $2b, $3e, $54, $48, $63, $fa, $f7, $ef, $ee, $3a, $45, $3e, $51, $62
    db $3f, $42, $3e, $52, $51, $46, $43, $52, $49, $ef, $ee, $54, $46, $4b, $44, $50
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42
    db $63, $ef, $ee, $2c, $66, $49, $62, $44, $46, $53, $42, $62, $56, $4c, $52, $fa
    db $f7, $ef, $ee, $3e, $62, $4f, $42, $54, $3e, $4f, $41, $5f, $ef, $ee, $fa, $f7
    db $f0
TextStr_4e_717b:           ; id $08AC
    ; "*:It's a BeNiceBK. Use it wisely."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $62, $25, $42, $31, $46, $40, $42, $25
    db $2e, $5f, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54, $46, $50, $42, $49
    db $56, $5f, $f7, $f0
TextStr_4e_719f:           ; id $08AD
    ; "*:You must obey me! / *:I want to see an Armorpion! / *:Armorpion, the strongest / of all bugs!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $4c, $3f, $42, $56
    db $ef, $ee, $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b
    db $51, $62, $51, $4c, $62, $50, $42, $42, $ef, $ee, $3e, $4b, $62, $24, $4f, $4a
    db $4c, $4f, $4d, $46, $4c, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4f, $4a
    db $4c, $4f, $4d, $46, $4c, $4b, $5e, $ef, $ee, $51, $45, $42, $62, $50, $51, $4f
    db $4c, $4b, $44, $42, $50, $51, $fa, $f7, $ef, $ee, $4c, $43, $62, $3e, $49, $49
    db $62, $3f, $52, $44, $50, $63, $ef, $ee, $f7, $f0
TextStr_4e_7209:           ; id $08AE
    ; "*:Oh! it is Armorpion! / What a scary looking tail! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $32, $45, $63, $62, $46, $51, $62, $46, $50, $ef, $ee, $24, $4f
    db $4a, $4c, $4f, $4d, $46, $4c, $4b, $63, $fa, $f7, $ef, $ee, $3a, $45, $3e, $51
    db $62, $3e, $62, $50, $40, $3e, $4f, $56, $ef, $ee, $49, $4c, $4c, $48, $46, $4b
    db $44, $62, $51, $3e, $46, $49, $63, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49
    db $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $2c, $66, $49, $62, $44, $46, $53
    db $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $3e, $62, $4f, $42, $54, $3e, $4f
    db $41, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4e_7270:           ; id $08AF
    ; "*:It is QuestBK. Use it wisely."
    db $eb, $9f, $a3, $2c, $51, $62, $46, $50, $62, $34, $52, $42, $50, $51, $25, $2e
    db $5f, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54, $46, $50, $42, $49, $56
    db $5f, $f7, $f0
TextStr_4e_7293:           ; id $08B0
    ; "*:You must obey me. / *:I want to see a Rosevine. / *:I want to touch those snaky vines."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $4c, $3f, $42, $56
    db $ef, $ee, $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b
    db $51, $62, $51, $4c, $62, $50, $42, $42, $62, $3e, $ef, $ee, $35, $4c, $50, $42
    db $53, $46, $4b, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b
    db $51, $62, $51, $4c, $62, $51, $4c, $52, $40, $45, $ef, $ee, $51, $45, $4c, $50
    db $42, $62, $50, $4b, $3e, $48, $56, $62, $53, $46, $4b, $42, $50, $5f, $f7, $f0
TextStr_4e_72f3:           ; id $08B1
    ; "*:It's a Rosevine! How / snaky it is! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $ef, $ee, $35, $4c, $50, $42, $53, $46
    db $4b, $42, $63, $62, $2b, $4c, $54, $fa, $f7, $ef, $ee, $50, $4b, $3e, $48, $56
    db $62, $46, $51, $62, $46, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $2c, $66, $49, $62, $44
    db $46, $53, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $3e, $62, $4f, $42, $54
    db $3e, $4f, $41, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4e_734c:           ; id $08B2
    ; "It's a LifeAcorn. Use it wisely."
    db $eb, $2c, $51, $68, $62, $3e, $62, $2f, $46, $43, $42, $24, $40, $4c, $4f, $4b
    db $5f, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54, $46, $50, $42, $49, $56
    db $5f, $f7, $f0
TextStr_4e_736f:           ; id $08B3
    ; "*:You must obey me. / *:I want to see a GoldGolem. / *:GoldGolem, the Material of / Materials."
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $4c, $3f, $42, $56
    db $ef, $ee, $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b
    db $51, $62, $51, $4c, $62, $50, $42, $42, $62, $3e, $ef, $ee, $2a, $4c, $49, $41
    db $2a, $4c, $49, $42, $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4c, $49, $41
    db $2a, $4c, $49, $42, $4a, $5e, $ef, $ee, $51, $45, $42, $62, $30, $3e, $51, $42
    db $4f, $46, $3e, $49, $62, $4c, $43, $fa, $f7, $ef, $ee, $30, $3e, $51, $42, $4f
    db $46, $3e, $49, $50, $5f, $ef, $ee, $f7, $f0
TextStr_4e_73d8:           ; id $08B4
    ; "*:It's GoldGolem! I could be blinded / by its gold shine! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $2a, $4c, $49, $41, $2a, $4c, $49, $42, $4a
    db $63, $ef, $ee, $2c, $62, $40, $4c, $52, $49, $41, $62, $3f, $42, $62, $3f, $49
    db $46, $4b, $41, $42, $41, $fa, $f7, $ef, $ee, $3f, $56, $62, $46, $51, $50, $62
    db $44, $4c, $49, $41, $62, $50, $45, $46, $4b, $42, $63, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $2c
    db $66, $49, $62, $44, $46, $53, $42, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $3e
    db $62, $4f, $42, $54, $3e, $4f, $41, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4e_7445:           ; id $08B5
    ; "*:It's a TinyMedal. / Use it wisely."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $ef, $ee, $37, $46, $4b, $56, $30, $42
    db $41, $3e, $49, $5f, $fa, $f7, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54
    db $46, $50, $42, $49, $56, $5f, $ef, $ee, $f7, $f0
TextStr_4e_746f:           ; id $08B6
    ; "*:You must obey me. / *:I want to see a Divinegon. / *:The Dragon of Dragons with / godlike power!"
    db $eb, $9f, $a3, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $4c, $3f, $42, $56
    db $ef, $ee, $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $4b
    db $51, $62, $51, $4c, $62, $50, $42, $42, $62, $3e, $ef, $ee, $27, $46, $53, $46
    db $4b, $42, $44, $4c, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62
    db $27, $4f, $3e, $44, $4c, $4b, $62, $4c, $43, $ef, $ee, $27, $4f, $3e, $44, $4c
    db $4b, $50, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $44, $4c, $41, $49, $46
    db $48, $42, $62, $4d, $4c, $54, $42, $4f, $63, $ef, $ee, $f7, $f0
TextStr_4e_74dc:           ; id $08B7
    ; "*:It's Divinegon! / How noble! / *:Well done! I'll give you / a reward."
    db $eb, $9f, $a3, $2c, $51, $68, $ef, $ee, $27, $46, $53, $46, $4b, $42, $44, $4c
    db $4b, $63, $fa, $f7, $ef, $ee, $2b, $4c, $54, $62, $4b, $4c, $3f, $49, $42, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b
    db $42, $63, $ef, $ee, $2c, $66, $49, $62, $44, $46, $53, $42, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $3e, $62, $4f, $42, $54, $3e, $4f, $41, $5f, $ef, $ee, $fa
    db $f7, $f0
TextStr_4e_752e:           ; id $08B8
    ; "*:It's a TinyMedal. / Use it wisely."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $ef, $ee, $37, $46, $4b, $56, $30, $42
    db $41, $3e, $49, $5f, $fa, $f7, $ef, $ee, $38, $50, $42, $62, $46, $51, $62, $54
    db $46, $50, $42, $49, $56, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4e_7559:           ; id $08B9
    ; "*:[HERO], my hearts content. / *:There's no other master / like you in the world. / *:... Maybe it's time for me to go / back to the castle."
    db $eb, $9f, $a3, $f6, $5e, $62, $4a, $56, $ef, $ee, $45, $42, $3e, $4f, $51, $50
    db $62, $40, $4c, $4b, $51, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $4f, $42, $68, $ef, $ee, $4b, $4c, $62, $4c, $51, $45, $42, $4f, $62
    db $4a, $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $49, $46, $48, $42, $62, $56
    db $4c, $52, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $54, $4c, $4f, $49, $41
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $5f, $5f, $5f, $62, $30, $3e, $56, $3f, $42
    db $62, $46, $51, $68, $ef, $ee, $51, $46, $4a, $42, $62, $43, $4c, $4f, $62, $4a
    db $42, $62, $51, $4c, $62, $44, $4c, $fa, $f7, $ef, $ee, $3f, $3e, $40, $48, $62
    db $51, $4c, $62, $51, $45, $42, $ef, $ee, $40, $3e, $50, $51, $49, $42, $5f, $f7
    db $f0
TextStr_4e_75ea:           ; id $08BA
    ; "*:Her Majesty, the Queen of / GreatTree, / *:and her guest, Mick. / *:Her Majesty desires / a WingSlime. / *:If a Slime is bred with a bird,..."
    db $ea, $9f, $a3, $2b, $42, $4f, $62, $30, $3e, $47, $42, $50, $51, $56, $5e, $ef
    db $ee, $51, $45, $42, $62, $34, $52, $42, $42, $4b, $62, $4c, $43, $fa, $f7, $ef
    db $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5e, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $3e, $4b, $41, $62, $45, $42, $4f, $62, $44, $52, $42, $50, $51
    db $5e, $ef, $ee, $30, $46, $40, $48, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42
    db $4f, $62, $30, $3e, $47, $42, $50, $51, $56, $ef, $ee, $41, $42, $50, $46, $4f
    db $42, $50, $fa, $f7, $ef, $ee, $3e, $62, $3a, $46, $4b, $44, $36, $49, $46, $4a
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $3e, $62, $36
    db $49, $46, $4a, $42, $62, $46, $50, $ef, $ee, $3f, $4f, $42, $41, $62, $54, $46
    db $51, $45, $62, $3e, $62, $3f, $46, $4f, $41, $5e, $fa, $f7, $ef, $ee, $4d, $42
    db $4f, $45, $3e, $4d, $50, $62, $3e, $ef, $ee, $3a, $46, $4b, $44, $36, $49, $46
    db $4a, $42, $62, $54, $46, $49, $49, $62, $3f, $42, $fa, $f7, $ef, $ee, $25, $4c
    db $4f, $4b, $a4, $ef, $ee, $f7, $f0
TextStr_4e_76b1:           ; id $08BB
    ; "*:Her Majesty desires / a KingSlime. / *:I heard KingSlimes can / use Vivify!"
    db $ea, $9f, $a3, $2b, $42, $4f, $62, $30, $3e, $47, $42, $50, $51, $56, $ef, $ee
    db $41, $42, $50, $46, $4f, $42, $50, $fa, $f7, $ef, $ee, $3e, $62, $2e, $46, $4b
    db $44, $36, $49, $46, $4a, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $62, $45, $42, $3e, $4f, $41, $ef, $ee, $2e, $46, $4b, $44, $36, $49, $46, $4a
    db $42, $50, $62, $40, $3e, $4b, $fa, $f7, $ef, $ee, $52, $50, $42, $62, $39, $46
    db $53, $46, $43, $56, $63, $ef, $ee, $f7, $f0
TextStr_4e_770a:           ; id $08BC
    ; "*:Her Majesty desires / a Florajay. / *:I heard Florajays can / sing LifeSong!"
    db $ea, $9f, $a3, $2b, $42, $4f, $62, $30, $3e, $47, $42, $50, $51, $56, $ef, $ee
    db $41, $42, $50, $46, $4f, $42, $50, $fa, $f7, $ef, $ee, $3e, $62, $29, $49, $4c
    db $4f, $3e, $47, $3e, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62
    db $45, $42, $3e, $4f, $41, $ef, $ee, $29, $49, $4c, $4f, $3e, $47, $3e, $56, $50
    db $62, $40, $3e, $4b, $fa, $f7, $ef, $ee, $50, $46, $4b, $44, $62, $2f, $46, $43
    db $42, $36, $4c, $4b, $44, $63, $ef, $ee, $f7, $f0
TextStr_4e_7764:           ; id $08BD
    ; "*:Her Majesty desires / a CurseLamp. / *:I heard CurseLamps are / in the Material family."
    db $ea, $9f, $a3, $2b, $42, $4f, $62, $30, $3e, $47, $42, $50, $51, $56, $ef, $ee
    db $41, $42, $50, $46, $4f, $42, $50, $fa, $f7, $ef, $ee, $3e, $62, $26, $52, $4f
    db $50, $42, $2f, $3e, $4a, $4d, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c
    db $62, $45, $42, $3e, $4f, $41, $ef, $ee, $26, $52, $4f, $50, $42, $2f, $3e, $4a
    db $4d, $50, $62, $3e, $4f, $42, $fa, $f7, $ef, $ee, $46, $4b, $62, $51, $45, $42
    db $62, $30, $3e, $51, $42, $4f, $46, $3e, $49, $ef, $ee, $43, $3e, $4a, $46, $49
    db $56, $5f, $f7, $f0
TextStr_4e_77c8:           ; id $08BE
    ; "*:I'm Mick. Those clingy fans / are annoying. / *:Breeding between weaklings is not / useful. / *:It's better to breed trained / monsters. /..."
    db $ea, $9f, $a3, $2c, $6a, $62, $30, $46, $40, $48, $5f, $ef, $ee, $37, $45, $4c
    db $50, $42, $62, $40, $49, $46, $4b, $44, $56, $62, $43, $3e, $4b, $50, $fa, $f7
    db $ef, $ee, $3e, $4f, $42, $62, $3e, $4b, $4b, $4c, $56, $46, $4b, $44, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $4f, $42, $42, $41, $46, $4b, $44, $62
    db $3f, $42, $51, $54, $42, $42, $4b, $ef, $ee, $54, $42, $3e, $48, $49, $46, $4b
    db $44, $50, $62, $46, $50, $62, $4b, $4c, $51, $fa, $f7, $ef, $ee, $52, $50, $42
    db $43, $52, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62
    db $3f, $42, $51, $51, $42, $4f, $62, $51, $4c, $ef, $ee, $3f, $4f, $42, $42, $41
    db $62, $51, $4f, $3e, $46, $4b, $42, $41, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $33, $5e
    db $62, $30, $33, $5e, $62, $3e, $4b, $41, $ef, $ee, $4c, $51, $45, $42, $4f, $62
    db $53, $3e, $49, $52, $42, $50, $62, $4c, $43, $fa, $f7, $ef, $ee, $51, $45, $42
    db $62, $4b, $42, $54, $3f, $4c, $4f, $4b, $50, $5e, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $3e, $4f, $42, $62, $41, $42, $51, $42, $4f, $4a, $46, $4b, $42, $41
    db $ef, $ee, $3f, $56, $62, $51, $45, $42, $62, $3e, $53, $42, $4f, $3e, $44, $42
    db $62, $4c, $43, $fa, $f7, $ef, $ee, $51, $45, $42, $46, $4f, $62, $4d, $3e, $4f
    db $42, $4b, $51, $50, $5c, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43
    db $62, $51, $45, $42, $62, $4b, $42, $54, $3f, $4c, $4f, $4b, $50, $ef, $ee, $45
    db $3e, $53, $42, $62, $3e, $62, $45, $46, $44, $45, $62, $2b, $33, $5e, $fa, $f7
    db $ef, $ee, $30, $33, $5e, $62, $3e, $4b, $41, $62, $4c, $51, $45, $42, $4f, $ef
    db $ee, $53, $3e, $49, $52, $42, $50, $62, $3e, $51, $62, $49, $42, $53, $42, $49
    db $62, $01, $5e, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4b, $42, $54, $3f, $4c
    db $4f, $4b, $50, $62, $40, $3e, $4b, $ef, $ee, $4e, $52, $46, $40, $48, $49, $56
    db $62, $46, $4b, $4f, $42, $3e, $50, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $46
    db $4f, $62, $49, $42, $53, $42, $49, $50, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $36, $4c, $5e, $62, $51, $45, $46, $50, $62, $46, $50, $62, $4a, $52, $40
    db $45, $ef, $ee, $3f, $42, $51, $51, $42, $4f, $62, $51, $45, $3e, $4b, $fa, $f7
    db $ef, $ee, $50, $51, $3e, $4f, $51, $46, $4b, $44, $62, $43, $4f, $4c, $4a, $ef
    db $ee, $49, $42, $53, $42, $49, $62, $01, $62, $54, $46, $51, $45, $fa, $f7, $ef
    db $ee, $49, $4c, $54, $62, $53, $3e, $49, $52, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_4e_79a8:           ; id $08BF
    ; "*:Her Majesty desires / WildApe. / *:I wonder what would happen if / a WildApe is inbred?"
    db $ea, $9f, $a3, $2b, $42, $4f, $62, $30, $3e, $47, $42, $50, $51, $56, $ef, $ee
    db $41, $42, $50, $46, $4f, $42, $50, $fa, $f7, $ef, $ee, $3a, $46, $49, $41, $24
    db $4d, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b
    db $41, $42, $4f, $62, $54, $45, $3e, $51, $ef, $ee, $54, $4c, $52, $49, $41, $62
    db $45, $3e, $4d, $4d, $42, $4b, $62, $46, $43, $fa, $f7, $ef, $ee, $3e, $62, $3a
    db $46, $49, $41, $24, $4d, $42, $62, $46, $50, $ef, $ee, $46, $4b, $3f, $4f, $42
    db $41, $64, $f7, $f0, $00
; --- END re-sectioned text run (bank $4e) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

