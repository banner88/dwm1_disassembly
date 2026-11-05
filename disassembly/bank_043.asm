; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $043", ROMX[$4000], BANK[$43]
;TEXT BANK
    db $43 ; Bank number

    ; Cross-bank dispatch table (147 entries)
    ; Called via: ld hl, $43XX / rst $10
    dw LoadB43_4127                  ; Entry 0
    dw TextRunB43_414b               ; Entry 1
    dw TextShowRefreshB43_416f       ; Entry 2
    dw $400B                          ; Entry 3 — mode 0 -> table $400B (mode list $4007)
    dw $4047                          ; Entry 4 — mode 1 -> table $4047 (mode list $4007)
    dw TextStr_43_4193               ; Entry 5 — [table $400B]; text $00E2 "*:Welcome to the arena. *:Huh? Me…"
    dw TextStr_43_436d               ; Entry 6 — text $00E3 "*:Too bad. You need more training…"
    dw TextStr_43_43f5               ; Entry 7 — text $00E4 "*:Well done! You survived G class!"
    dw TextStr_43_4420               ; Entry 8 — text $00E5 "*:Oh, Sir [HERO]. Congratulations…"
    dw TextStr_43_4490               ; Entry 9 — text $00E6 "*:Welcome to the arena! Want to h…"
    dw TextStr_43_44ce               ; Entry 10 — text $00E7 "*:The battle classes go from S,A …"
    dw TextStr_43_46b7               ; Entry 11 — text $00E8 "*:The last battle in G class is w…"
    dw TextStr_43_470e               ; Entry 12 — text $00E9 "*:Eeek! What? Talk to me from the…"
    dw TextStr_43_473f               ; Entry 13 — text $00EA "*:Get out of my way! Huff!"
    dw TextStr_43_475d               ; Entry 14 — text $00EB "You hear a voice."
    dw TextStr_43_4772               ; Entry 15 — text $00EC "*:Only those registered are allow…"
    dw TextStr_43_47a4               ; Entry 16 — text $00ED "*:H...Hello! I'm T..T..Teto. *:I'…"
    dw TextStr_43_485a               ; Entry 17 — text $00EE "*:Gwrr, Gwrr..."
    dw TextStr_43_486e               ; Entry 18 — text $00EF "*:In the back, they teach kids ab…"
    dw TextStr_43_48cd               ; Entry 19 — text $00F0 "*:Where did the MiniDrak go?"
    dw TextStr_43_48ed               ; Entry 20 — text $00F1 "*:Let's play rock- paper-scissors…"
    dw TextStr_43_4912               ; Entry 21 — text $00F2 "*:Hm, its not fun."
    dw TextStr_43_4928               ; Entry 22 — text $00F3 "*:Select your choice by stepping …"
    dw TextStr_43_49ed               ; Entry 23 — text $00F4 "*:Darn! Again!"
    dw TextStr_43_4a00               ; Entry 24 — text $00F5 "*:I won! Challenge me anytime!"
    dw TextStr_43_4a22               ; Entry 25 — text $00F6 "*:It's a tie... In this case... *…"
    dw TextStr_43_4a62               ; Entry 26 — text $00F7 "*:You! You're good! *:Look! I'll …"
    dw TextStr_43_4ade               ; Entry 27 — text $00F8 "*:You're good..."
    dw TextStr_43_4af2               ; Entry 28 — text $00F9 "*:Want to know where the wife of …"
    dw TextStr_43_4b43               ; Entry 29 — text $00FA "*:I bet you wanna know."
    dw TextStr_43_4b5e               ; Entry 30 — text $00FB "*:You can meet her if you win at …"
    dw TextStr_43_4c04               ; Entry 31 — text $00FC "*:These statues are the protector…"
    dw TextStr_43_4c99               ; Entry 32 — text $00FD "*:May I help you? The restaurant …"
    dw TextStr_43_4cd1               ; Entry 33 — text $00FE "*:The guy at the entrance! He's m…"
    dw TextStr_43_4d02               ; Entry 34 — text $00FF "*:My rival's watching me from som…"
    dw TextStr_43_4dec               ; Entry 35 — [table $4047]; text $0100 "[HERO] looked into the jar. An ol…"
    dw TextStr_43_4e4f               ; Entry 36 — text $0101 "[HERO] looked into the jar. A pie…"
    dw TextStr_43_4eee               ; Entry 37 — text $0102 "*:Hm.. It doesn't listen to me mu…"
    dw TextStr_43_4f3c               ; Entry 38 — text $0103 "*:Hi Ho Hi Ho. *:Sigh.. I'm starv…"
    dw TextStr_43_4fa8               ; Entry 39 — text $0104 "*:Yo man, wanna know who your mat…"
    dw TextStr_43_4fe2               ; Entry 40 — text $0105 "*:Its the principal of the school."
    dw TextStr_43_500d               ; Entry 41 — text $0106 "*:Well,it'll be OK too."
    dw TextStr_43_5027               ; Entry 42 — text $0107 "*:Want to hear about my journey b…"
    dw TextStr_43_506b               ; Entry 43 — text $0108 "*:StubSucks & GoHoppers, Anteater…"
    dw TextStr_43_51a8               ; Entry 44 — text $0109 "*:My journey to the Travelers' Ga…"
    dw TextStr_43_51ee               ; Entry 45 — text $010A "*:Want to know about the monsters…"
    dw TextStr_43_5234               ; Entry 46 — text $010B "*:This is an 'onigiri'. C'mon BeB…"
    dw TextStr_43_526f               ; Entry 47 — text $010C "BeBe:Boo Baa Boo Baa."
    dw TextStr_43_5288               ; Entry 48 — text $010D "*:....."
    dw TextStr_43_5294               ; Entry 49 — text $010E "*:What the heck is an onigiri? Wh…"
    dw TextStr_43_52d7               ; Entry 50 — text $010F "*:We all gather here seeking vict…"
    dw TextStr_43_5375               ; Entry 51 — text $0110 "*:Oh, welcome Mas...ahem. I am th…"
    dw TextStr_43_547d               ; Entry 52 — text $0111 "*:I am Medal Man, the medal colle…"
    dw TextStr_43_54ac               ; Entry 53 — text $0112 "*:Both the Medal Man & myself lov…"
    dw TextStr_43_5555               ; Entry 54 — text $0113 "*:Welcome to the Master School! *…"
    dw TextStr_43_562e               ; Entry 55 — text $0114 "*:Sometimes monsters you beat wil…"
    dw TextStr_43_5793               ; Entry 56 — text $0115 "*:It's helpful to take a WarpWing…"
    dw TextStr_43_57f4               ; Entry 57 — text $0116 "*:Here's the Monster Master Schoo…"
    dw TextStr_43_581f               ; Entry 58 — text $0117 "[HERO] read the blackboard. :Do's…"
    dw TextStr_43_596b               ; Entry 59 — text $0118 "[HERO] read the blackboard. :Mast…"
    dw TextStr_43_59db               ; Entry 60 — text $0119 "*:Superior masters... *:have a we…"
    dw TextStr_43_5a92               ; Entry 61 — text $011A "*:Army Bomb Army, Bubble Army...!…"
    dw TextStr_43_5af2               ; Entry 62 — text $011B "*:Who the heck is that old woman …"
    dw TextStr_43_5b5e               ; Entry 63 — text $011C "*:I am the Queen of GreatTree. I …"
    dw TextStr_43_5c1b               ; Entry 64 — text $011D "*:Here is her majesty the Queen o…"
    dw TextStr_43_5cad               ; Entry 65 — text $011E "*:I'm Mick. Who are you? *:Whew, …"
    dw TextStr_43_5d7d               ; Entry 66 — text $011F "*:You are at the Room of Beginnin…"
    dw TextStr_43_5de8               ; Entry 67 — text $0120 "*:Ladies & Gents! Welcome to the …"
    dw TextStr_43_5e8f               ; Entry 68 — text $0121 "*:Leeet's Rumble!"
    dw TextStr_43_5ea4               ; Entry 69 — text $0122 "*:For the 1st match, the victory …"
    dw TextStr_43_5f06               ; Entry 70 — text $0123 "Watabou:Doing well huh? Let's go …"
    dw TextStr_43_5f34               ; Entry 71 — text $0124 "*:For the 2nd match, the victory …"
    dw TextStr_43_5f9d               ; Entry 72 — text $0125 "*:I'm the principal of the Master…"
    dw TextStr_43_6020               ; Entry 73 — text $0126 "*:Congratulations! We have a new …"
    dw TextStr_43_6083               ; Entry 74 — text $0127 "[HERO] got an Herb."
    dw TextStr_43_6094               ; Entry 75 — text $0128 "[HERO] found an Herb. But cannot …"
    dw TextStr_43_60fa               ; Entry 76 — text $0129 "Wow! [HERO] got a TinyMedal!"
    dw TextStr_43_6114               ; Entry 77 — text $012A "Wow! A TinyMedal was found! But c…"
    dw TextStr_43_617f               ; Entry 78 — text $012B "*:Hey you, do you have a TinyMeda…"
    dw TextStr_43_61a6               ; Entry 79 — text $012C "*:You don't have it? What are you…"
    dw TextStr_43_61eb               ; Entry 80 — text $012D "*:I see. Go to the room above the…"
    dw TextStr_43_624a               ; Entry 81 — text $012E "*:Great! Go to the room above the…"
    dw TextStr_43_6271               ; Entry 82 — text $012F "*:We can see the ground far below…"
    dw TextStr_43_62ce               ; Entry 83 — text $0130 "The Gate is shut tight."
    dw TextStr_43_62e8               ; Entry 84 — text $0131 "The Gate is shut tight."
    dw TextStr_43_6302               ; Entry 85 — text $0132 "The Gate is shut tight."
    dw TextStr_43_631c               ; Entry 86 — text $0133 "The Gate is shut tight. Something…"
    dw TextStr_43_637f               ; Entry 87 — text $0134 "The Gate is shut tight."
    dw TextStr_43_6399               ; Entry 88 — text $0135 "The Gate is shut tight."
    dw TextStr_43_63b3               ; Entry 89 — text $0136 "The Gate is shut tight."
    dw TextStr_43_63cd               ; Entry 90 — text $0137 "[HERO] looked into the barrel. So…"
    dw TextStr_43_642d               ; Entry 91 — text $0138 "[HERO] looked into the barrel."
    dw TextStr_43_644a               ; Entry 92 — text $0139 "Wow,a TinyMedal! But cannot carry…"
    dw TextStr_43_64ae               ; Entry 93 — text $013A "[HERO] looked into the barrel. No…"
    dw TextStr_43_64de               ; Entry 94 — text $013B "[HERO] looked into the barrel. A …"
    dw TextStr_43_652b               ; Entry 95 — text $013C "[HERO] looked in the treasure che…"
    dw TextStr_43_655f               ; Entry 96 — text $013D "*:Have you been using the Bookmar…"
    dw TextStr_43_65f7               ; Entry 97 — text $013E "*:Uuu Hmm... *:I wonder who'll wi…"
    dw TextStr_43_6649               ; Entry 98 — text $013F "*:How many times do I have to say…"
    dw TextStr_43_668d               ; Entry 99 — text $0140 "King:Well done, [HERO]! You beat …"
    dw TextStr_43_6702               ; Entry 100 — text $0141 "*:Oh...King..."
    dw TextStr_43_6715               ; Entry 101 — text $0142 "King:Train hard! You're dismissed…"
    dw TextStr_43_675b               ; Entry 102 — text $0143 "Empty"
    dw TextStr_43_6765               ; Entry 103 — text $0144 "*:Thanks [HERO]! For bringing the…"
    dw TextStr_43_681d               ; Entry 104 — text $0145 "*:I found it! A big trial's waiti…"
    dw TextStr_43_685f               ; Entry 105 — text $0146 "Watabou:Right on! [HERO]! I'll ta…"
    dw TextStr_43_689c               ; Entry 106 — text $0147 "King:Oh [HERO]! I heard you survi…"
    dw TextStr_43_6901               ; Entry 107 — text $0148 "*:How are you, King of GreatTree?…"
    dw TextStr_43_6997               ; Entry 108 — text $0149 "*:Oh, what a cute little child. *…"
    dw TextStr_43_69ff               ; Entry 109 — text $014A "King of GreatLog: King of GreatTr…"
    dw TextStr_43_6a71               ; Entry 110 — text $014B "King:Argh, we will see who has th…"
    dw TextStr_43_6b82               ; Entry 111 — text $014C "*:The Room of Villager & Talisman…"
    dw TextStr_43_6c71               ; Entry 112 — text $014D "King:Oh [HERO]! You beat the Drag…"
    dw TextStr_43_6d0e               ; Entry 113 — text $014E "King:Well maybe I'm exaggerating …"
    dw TextStr_43_6db5               ; Entry 114 — text $014F "[HERO] returned the diary to the …"
    dw TextStr_43_6de3               ; Entry 115 — text $0150 "King:Oh [HERO]! You beat CopyCat!…"
    dw TextStr_43_6e6f               ; Entry 116 — text $0151 "King:Oh [HERO]! You beat Golem! K…"
    dw TextStr_43_6f0b               ; Entry 117 — text $0152 "*:Are you familiar with the Gate …"
    dw TextStr_43_6f41               ; Entry 118 — text $0153 "*:Dragon loves girls.It carried a…"
    dw TextStr_43_6fc4               ; Entry 119 — text $0154 "*:Are you familiar with the Gate …"
    dw TextStr_43_6ffa               ; Entry 120 — text $0155 "*:I see...Hm.."
    dw TextStr_43_700d               ; Entry 121 — text $0156 "*:The stone guard fell asleep fro…"
    dw TextStr_43_7097               ; Entry 122 — text $0157 "*:Who do you think you are! What?…"
    dw TextStr_43_7107               ; Entry 123 — text $0158 "*:Almost there to the bottom! *:W…"
    dw TextStr_43_7142               ; Entry 124 — text $0159 "*:{AC} is added to the monster le…"
    dw TextStr_43_71c9               ; Entry 125 — text $015A "*:Enter here to the Vault."
    dw TextStr_43_71e7               ; Entry 126 — text $015B "*:The Bazaar's to the right!"
    dw TextStr_43_7206               ; Entry 127 — text $015C "*:Hello, welcome to the Bazaar!"
    dw TextStr_43_7229               ; Entry 128 — text $015D "[HERO] looked into the jar. But t…"
    dw TextStr_43_7263               ; Entry 129 — text $015E "[HERO] looked into the jar. It wa…"
    dw TextStr_43_72b3               ; Entry 130 — text $015F "*:Rumor has it that the BeastTail…"
    dw TextStr_43_73a2               ; Entry 131 — text $0160 "*:During this season, everyone sp…"
    dw TextStr_43_7425               ; Entry 132 — text $0161 "*:There were stores here at the l…"
    dw TextStr_43_746a               ; Entry 133 — text $0162 "*:The store there is terrible! He…"
    dw TextStr_43_74a7               ; Entry 134 — text $0163 "*:You? A master? You're just a ki…"
    dw TextStr_43_74e4               ; Entry 135 — text $0164 "*:So, you don't have enough money…"
    dw TextStr_43_751b               ; Entry 136 — text $0165 "[HERO] looked in front. There are…"
    dw TextStr_43_754f               ; Entry 137 — text $0166 "*:Darn,why can't I start the fire…"
    dw TextStr_43_75b4               ; Entry 138 — text $0167 "*:Can you give me a monster that …"
    dw TextStr_43_75e9               ; Entry 139 — text $0168 "*:You don't have one? Come on!"
    dw TextStr_43_760a               ; Entry 140 — text $0169 "*:Oh you have one! Then..."
    dw TextStr_43_7629               ; Entry 141 — text $016A "Can you give us your [INS 00]? [Y…"
    dw TextStr_43_7645               ; Entry 142 — text $016B "[HERO] gave your [INS 00]!"
    dw TextStr_43_7658               ; Entry 143 — text $016C "*:Wow! No way! *:Such a thing in …"
    dw TextStr_43_76cb               ; Entry 144 — text $016D "*:Well,too bad..."
    dw TextStr_43_76e1               ; Entry 145 — text $016E "*:Well then, can I have [INS 00]?…"
    dw TextStr_43_7700               ; Entry 146 — text $016F "*:Where does this Travelers' Gate…"

LoadB43_4127:
    ld a, [$c822]
    cp $01
    jr nz, jr_043_4144

    ld a, [$c823]
    cp $70
    jr c, jr_043_4144

    sub $70
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $1a00
    rst $10
    ret


jr_043_4144:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB43_414b:
    ld a, [$c822]
    cp $01
    jr nz, jr_043_4168

    ld a, [$c823]
    cp $70
    jr c, jr_043_4168

    sub $70
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $1a01
    rst $10
    ret


jr_043_4168:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB43_416f:
    ld a, [$c822]
    cp $01
    jr nz, jr_043_418c

    ld a, [$c823]
    cp $70
    jr c, jr_043_418c

    sub $70
    ld [$c823], a
    ld a, $01
    ld [$c822], a
    ld hl, $1a02
    rst $10
    ret


jr_043_418c:
    call LoadB43_4127
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $43: $4193-$772f) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_43_4193:           ; id $00E2
    ; "*:Welcome to the arena. / *:Huh? Me? I'm famous here. / *:Everyone likes me! Hee Hee Hee. / *:So, you want to become the champ / to find you..."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $3e, $4f, $42, $4b, $3e, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2b
    db $52, $45, $64, $62, $30, $42, $64, $62, $2c, $6a, $ef, $ee, $43, $3e, $4a, $4c
    db $52, $50, $62, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $28, $53
    db $42, $4f, $56, $4c, $4b, $42, $62, $49, $46, $48, $42, $50, $ef, $ee, $4a, $42
    db $63, $62, $2b, $42, $42, $62, $2b, $42, $42, $62, $2b, $42, $42, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $36, $4c, $5e, $62, $56, $4c, $52, $62, $54, $3e, $4b, $51
    db $62, $51, $4c, $ef, $ee, $3f, $42, $40, $4c, $4a, $42, $62, $51, $45, $42, $62
    db $40, $45, $3e, $4a, $4d, $fa, $f7, $ef, $ee, $51, $4c, $62, $43, $46, $4b, $41
    db $62, $56, $4c, $52, $4f, $ef, $ee, $50, $46, $50, $51, $42, $4f, $64, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $4c, $62, $41, $4c, $62, $51, $45, $3e, $51, $5e, $62
    db $56, $4c, $52, $ef, $ee, $4a, $52, $50, $51, $62, $50, $52, $4f, $53, $46, $53
    db $42, $62, $45, $42, $4f, $42, $fa, $f7, $ef, $ee, $51, $4c, $62, $4f, $42, $4d
    db $4f, $42, $50, $42, $4b, $51, $62, $4c, $52, $4f, $ef, $ee, $48, $46, $4b, $44
    db $41, $4c, $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $4f, $42, $62
    db $3e, $4f, $42, $ef, $ee, $40, $49, $3e, $50, $50, $42, $50, $62, $46, $4b, $62
    db $51, $45, $42, $fa, $f7, $ef, $ee, $3e, $4f, $42, $4b, $3e, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $56, $62, $50, $51, $3e, $4f, $51, $62
    db $43, $4f, $4c, $4a, $ef, $ee, $2a, $62, $3e, $4b, $41, $62, $44, $4c, $62, $3e
    db $49, $49, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $54, $3e, $56, $62, $52, $4d
    db $62, $51, $4c, $62, $27, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45
    db $42, $4f, $42, $62, $3e, $4f, $42, $62, $45, $46, $44, $45, $42, $4f, $ef, $ee
    db $40, $49, $3e, $50, $50, $42, $50, $62, $51, $45, $3e, $4b, $62, $27, $5e, $fa
    db $f7, $ef, $ee, $3f, $52, $51, $62, $56, $4c, $52, $69, $42, $62, $4b, $4c, $51
    db $ef, $ee, $4f, $42, $3e, $41, $56, $62, $43, $4c, $4f, $62, $51, $45, $42, $4a
    db $fa, $f7, $ef, $ee, $56, $42, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $45, $3e, $51, $62, $41, $4c, $62, $56, $4c, $52, $ef, $ee, $51, $45, $46
    db $4b, $48, $64, $fa, $f7, $ef, $ee, $35, $42, $3e, $41, $56, $62, $51, $4c, $62
    db $43, $46, $44, $45, $51, $64, $ef, $ee, $2a, $62, $40, $49, $3e, $50, $50, $62
    db $46, $50, $62, $43, $4f, $42, $42, $5f, $f7, $f0
TextStr_43_436d:           ; id $00E3
    ; "*:Too bad. You need more / training. / *:There are many veterans in the / arena. / *:Ask them how to become / stronger."
    db $ea, $9f, $a3, $37, $4c, $4c, $62, $3f, $3e, $41, $5f, $ef, $ee, $3c, $4c, $52
    db $62, $4b, $42, $42, $41, $62, $4a, $4c, $4f, $42, $fa, $f7, $ef, $ee, $51, $4f
    db $3e, $46, $4b, $46, $4b, $44, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $4f, $42, $62, $3e, $4f, $42, $62, $4a, $3e, $4b, $56, $ef, $ee, $53
    db $42, $51, $42, $4f, $3e, $4b, $50, $62, $46, $4b, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $3e, $4f, $42, $4b, $3e, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $24, $50, $48, $62, $51, $45, $42, $4a, $62, $45, $4c, $54, $ef, $ee, $51, $4c
    db $62, $3f, $42, $40, $4c, $4a, $42, $fa, $f7, $ef, $ee, $50, $51, $4f, $4c, $4b
    db $44, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_43_43f5:           ; id $00E4
    ; "*:Well done! You survived / G class!"
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $63, $ef, $ee, $3c
    db $4c, $52, $62, $50, $52, $4f, $53, $46, $53, $42, $41, $fa, $f7, $ef, $ee, $2a
    db $62, $40, $49, $3e, $50, $50, $63, $ef, $ee, $f7, $f0
TextStr_43_4420:           ; id $00E5
    ; "*:Oh, Sir [HERO]. Congratulations on / your victory in G class. / *:The King summons you. / Come this way!"
    db $ea, $9f, $a3, $32, $45, $5e, $62, $36, $46, $4f, $62, $f6, $5f, $ef, $ee, $26
    db $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c, $4b, $50, $62, $4c
    db $4b, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $62, $53, $46, $40, $51, $4c, $4f
    db $56, $62, $46, $4b, $62, $2a, $ef, $ee, $40, $49, $3e, $50, $50, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2e, $46, $4b, $44, $62, $50, $52, $4a
    db $4a, $4c, $4b, $50, $ef, $ee, $56, $4c, $52, $5f, $fa, $f7, $ef, $ee, $26, $4c
    db $4a, $42, $62, $51, $45, $46, $50, $62, $54, $3e, $56, $63, $ef, $ee, $f7, $f0
TextStr_43_4490:           ; id $00E6
    ; "*:Welcome to the arena! Want to / hear about the battle? [YES/NO]"
    db $eb, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $3e, $4f, $42, $4b, $3e, $63, $62, $3a, $3e, $4b, $51, $62, $51
    db $4c, $fa, $f7, $ef, $ee, $45, $42, $3e, $4f, $62, $3e, $3f, $4c, $52, $51, $62
    db $51, $45, $42, $ef, $ee, $3f, $3e, $51, $51, $49, $42, $64, $ff, $f0
TextStr_43_44ce:           ; id $00E7
    ; "*:The battle classes go from / S,A down to G for beginners. / *:You'll fight 3 masters per class. / *:You can go to the next class / when yo..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $3f, $3e, $51, $51, $49, $42, $ef, $ee, $40
    db $49, $3e, $50, $50, $42, $50, $62, $44, $4c, $62, $43, $4f, $4c, $4a, $fa, $f7
    db $ef, $ee, $36, $5e, $24, $62, $41, $4c, $54, $4b, $62, $51, $4c, $62, $2a, $ef
    db $ee, $43, $4c, $4f, $62, $3f, $42, $44, $46, $4b, $4b, $42, $4f, $50, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $66, $49, $62, $43, $46, $44, $45, $51
    db $62, $03, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $50, $62, $4d, $42, $4f, $62
    db $40, $49, $3e, $50, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62
    db $40, $3e, $4b, $62, $44, $4c, $62, $51, $4c, $ef, $ee, $51, $45, $42, $62, $4b
    db $42, $55, $51, $62, $40, $49, $3e, $50, $50, $fa, $f7, $ef, $ee, $54, $45, $42
    db $4b, $62, $56, $4c, $52, $62, $41, $42, $43, $42, $3e, $51, $ef, $ee, $51, $45
    db $42, $62, $03, $4f, $41, $62, $4a, $3e, $50, $51, $42, $4f, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $50, $52, $4f, $53, $46, $53
    db $42, $ef, $ee, $36, $62, $40, $49, $3e, $50, $50, $5e, $fa, $f7, $ef, $ee, $56
    db $4c, $52, $69, $42, $62, $42, $49, $46, $44, $46, $3f, $49, $42, $ef, $ee, $43
    db $4c, $4f, $62, $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $fa, $f7, $ef
    db $ee, $31, $46, $44, $45, $51, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b
    db $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $27, $52, $4f, $46, $4b, $44
    db $62, $51, $45, $42, $ef, $ee, $3f, $3e, $51, $51, $49, $42, $5e, $62, $56, $4c
    db $52, $62, $40, $3e, $4b, $fa, $f7, $ef, $ee, $4b, $4c, $51, $62, $44, $46, $53
    db $42, $62, $40, $4c, $4a, $4a, $3e, $4b, $41, $50, $ef, $ee, $51, $4c, $62, $51
    db $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4b, $4c, $51, $62, $52, $50
    db $42, $ef, $ee, $3e, $4b, $56, $62, $46, $51, $42, $4a, $50, $62, $42, $46, $51
    db $45, $42, $4f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52
    db $62, $40, $45, $4c, $4c, $50, $42, $62, $51, $4c, $ef, $ee, $35, $38, $31, $5e
    db $62, $56, $4c, $52, $62, $44, $46, $53, $42, $fa, $f7, $ef, $ee, $52, $4d, $62
    db $51, $45, $42, $62, $3f, $3e, $51, $51, $49, $42, $5f, $ef, $ee, $fa, $f7, $ef
    db $ee, $9f, $a3, $37, $4c, $62, $4f, $42, $44, $46, $50, $51, $42, $4f, $5e, $ef
    db $ee, $44, $4c, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4f, $42
    db $40, $42, $4d, $51, $46, $4c, $4b, $46, $50, $51, $ef, $ee, $4c, $53, $42, $4f
    db $62, $51, $45, $42, $4f, $42, $5f, $f7, $f0
TextStr_43_46b7:           ; id $00E8
    ; "*:The last battle in G class is with / the principal of / *:the Master School."
    db $eb, $9f, $a3, $37, $45, $42, $62, $49, $3e, $50, $51, $62, $3f, $3e, $51, $51
    db $49, $42, $ef, $ee, $46, $4b, $62, $2a, $62, $40, $49, $3e, $50, $50, $62, $46
    db $50, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4d, $4f
    db $46, $4b, $40, $46, $4d, $3e, $49, $62, $4c, $43, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $51, $45, $42, $62, $30, $3e, $50, $51, $42, $4f, $ef, $ee, $36, $40
    db $45, $4c, $4c, $49, $5f, $f7, $f0
TextStr_43_470e:           ; id $00E9
    ; "*:Eeek! What? Talk to me / from the front!"
    db $ea, $9f, $a3, $28, $42, $42, $48, $63, $62, $3a, $45, $3e, $51, $64, $ef, $ee
    db $37, $3e, $49, $48, $62, $51, $4c, $62, $4a, $42, $fa, $f7, $ef, $ee, $43, $4f
    db $4c, $4a, $62, $51, $45, $42, $62, $43, $4f, $4c, $4b, $51, $63, $ef, $ee, $f7
    db $f0
TextStr_43_473f:           ; id $00EA
    ; "*:Get out of my way! Huff!"
    db $eb, $9f, $a3, $2a, $42, $51, $62, $4c, $52, $51, $62, $4c, $43, $ef, $ee, $4a
    db $56, $62, $54, $3e, $56, $63, $62, $2b, $52, $43, $43, $63, $f7, $f0
TextStr_43_475d:           ; id $00EB
    ; "You hear a voice."
    db $3c, $4c, $52, $62, $45, $42, $3e, $4f, $62, $3e, $62, $53, $4c, $46, $40, $42
    db $5f, $ef, $ee, $f7, $f0
TextStr_43_4772:           ; id $00EC
    ; "*:Only those registered are / allowed here!"
    db $ea, $9f, $a3, $32, $4b, $49, $56, $62, $51, $45, $4c, $50, $42, $ef, $ee, $4f
    db $42, $44, $46, $50, $51, $42, $4f, $42, $41, $62, $3e, $4f, $42, $fa, $f7, $ef
    db $ee, $3e, $49, $49, $4c, $54, $42, $41, $62, $45, $42, $4f, $42, $63, $ef, $ee
    db $f7, $f0
TextStr_43_47a4:           ; id $00ED
    ; "*:H...Hello! I'm T..T..Teto. / *:I'm nervous 'cause the battle / starts soon! / *:Are you a new monster master / too? / *:You can learn usef..."
    db $ea, $9f, $a3, $2b, $5f, $5f, $5f, $2b, $42, $49, $49, $4c, $63, $ef, $ee, $2c
    db $6a, $62, $37, $5f, $5f, $37, $5f, $5f, $37, $42, $51, $4c, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $6a, $62, $4b, $42, $4f, $53, $4c, $52, $50, $ef, $ee, $6f
    db $3e, $52, $50, $42, $62, $51, $45, $42, $62, $3f, $3e, $51, $51, $49, $42, $fa
    db $f7, $ef, $ee, $50, $51, $3e, $4f, $51, $50, $62, $50, $4c, $4c, $4b, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $3e
    db $62, $4b, $42, $54, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $4a, $3e
    db $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $51, $4c, $4c, $64, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $49, $42, $3e, $4f
    db $4b, $ef, $ee, $52, $50, $42, $43, $52, $49, $62, $46, $4b, $43, $4c, $4f, $4a
    db $3e, $51, $46, $4c, $4b, $fa, $f7, $ef, $ee, $4c, $52, $51, $62, $3f, $3e, $40
    db $48, $63, $ef, $ee, $f7, $f0
TextStr_43_485a:           ; id $00EE
    ; "*:Gwrr, Gwrr..."
    db $ea, $9f, $a3, $2a, $54, $4f, $4f, $5e, $62, $2a, $54, $4f, $4f, $5f, $5f, $5f
    db $ef, $ee, $f7, $f0
TextStr_43_486e:           ; id $00EF
    ; "*:In the back, they teach kids / about the monsters. / *:Maybe you should check it out."
    db $ea, $9f, $a3, $2c, $4b, $62, $51, $45, $42, $62, $3f, $3e, $40, $48, $5e, $ef
    db $ee, $51, $45, $42, $56, $62, $51, $42, $3e, $40, $45, $62, $48, $46, $41, $50
    db $fa, $f7, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e
    db $56, $3f, $42, $62, $56, $4c, $52, $62, $50, $45, $4c, $52, $49, $41, $ef, $ee
    db $40, $45, $42, $40, $48, $62, $46, $51, $62, $4c, $52, $51, $5f, $f7, $f0
TextStr_43_48cd:           ; id $00F0
    ; "*:Where did the MiniDrak go?"
    db $ea, $9f, $a3, $3a, $45, $42, $4f, $42, $62, $41, $46, $41, $62, $51, $45, $42
    db $ef, $ee, $30, $46, $4b, $46, $27, $4f, $3e, $48, $62, $44, $4c, $64, $f7, $f0
TextStr_43_48ed:           ; id $00F1
    ; "*:Let's play rock- paper-scissors! [YES/NO]"
    db $eb, $9f, $a3, $2f, $42, $51, $68, $62, $4d, $49, $3e, $56, $62, $4f, $4c, $40
    db $48, $9c, $ef, $ee, $4d, $3e, $4d, $42, $4f, $9c, $50, $40, $46, $50, $50, $4c
    db $4f, $50, $63, $ff, $f0
TextStr_43_4912:           ; id $00F2
    ; "*:Hm, its not fun."
    db $eb, $9f, $a3, $2b, $4a, $5e, $62, $46, $51, $50, $ef, $ee, $4b, $4c, $51, $62
    db $43, $52, $4b, $5f, $f7, $f0
TextStr_43_4928:           ; id $00F3
    ; "*:Select your choice by stepping / on the panels in front of me. / *:When you want to do it again, step / on the panel again. You don't / ne..."
    db $eb, $9f, $a3, $36, $42, $49, $42, $40, $51, $62, $56, $4c, $52, $4f, $ef, $ee
    db $40, $45, $4c, $46, $40, $42, $62, $3f, $56, $62, $50, $51, $42, $4d, $4d, $46
    db $4b, $44, $fa, $f7, $ef, $ee, $4c, $4b, $62, $51, $45, $42, $62, $4d, $3e, $4b
    db $42, $49, $50, $62, $46, $4b, $ef, $ee, $43, $4f, $4c, $4b, $51, $62, $4c, $43
    db $62, $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $42, $4b, $62, $56
    db $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $ef, $ee, $41, $4c, $62, $46
    db $51, $62, $3e, $44, $3e, $46, $4b, $5e, $62, $50, $51, $42, $4d, $fa, $f7, $ef
    db $ee, $4c, $4b, $62, $51, $45, $42, $62, $4d, $3e, $4b, $42, $49, $ef, $ee, $3e
    db $44, $3e, $46, $4b, $5f, $62, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $fa, $f7
    db $ef, $ee, $4b, $42, $42, $41, $62, $51, $4c, $62, $40, $4c, $4a, $42, $62, $52
    db $4d, $ef, $ee, $51, $4c, $62, $4a, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $35
    db $42, $3e, $41, $56, $64, $ef, $ee, $01, $5f, $5f, $02, $5f, $5f, $03, $5f, $5f
    db $44, $4c, $63, $f7, $f0
TextStr_43_49ed:           ; id $00F4
    ; "*:Darn! Again!"
    db $eb, $9f, $a3, $27, $3e, $4f, $4b, $63, $62, $24, $44, $3e, $46, $4b, $63, $ef
    db $ee, $f7, $f0
TextStr_43_4a00:           ; id $00F5
    ; "*:I won! Challenge me anytime!"
    db $eb, $9f, $a3, $2c, $62, $54, $4c, $4b, $63, $62, $26, $45, $3e, $49, $49, $42
    db $4b, $44, $42, $ef, $ee, $4a, $42, $62, $3e, $4b, $56, $51, $46, $4a, $42, $63
    db $f7, $f0
TextStr_43_4a22:           ; id $00F6
    ; "*:It's a tie... In this case... / *:I win anyway! Ha Ha Ha!"
    db $eb, $9f, $a3, $2c, $51, $68, $62, $3e, $62, $51, $46, $42, $5f, $5f, $5f, $ef
    db $ee, $2c, $4b, $62, $51, $45, $46, $50, $62, $40, $3e, $50, $42, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $46, $4b, $62, $3e, $4b, $56, $54
    db $3e, $56, $63, $ef, $ee, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $63, $f7, $f0
TextStr_43_4a62:           ; id $00F7
    ; "*:You! You're good! / *:Look! I'll tell you about a good / place for your prize. / *:Climb up the stairs over there!"
    db $eb, $9f, $a3, $3c, $4c, $52, $63, $62, $3c, $4c, $52, $69, $42, $ef, $ee, $44
    db $4c, $4c, $41, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $4c, $4c, $48, $63, $62
    db $2c, $66, $49, $62, $51, $42, $49, $49, $ef, $ee, $56, $4c, $52, $62, $3e, $3f
    db $4c, $52, $51, $62, $3e, $62, $44, $4c, $4c, $41, $fa, $f7, $ef, $ee, $4d, $49
    db $3e, $40, $42, $62, $43, $4c, $4f, $62, $56, $4c, $52, $4f, $ef, $ee, $4d, $4f
    db $46, $57, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $26, $49, $46, $4a, $3f, $62
    db $52, $4d, $62, $51, $45, $42, $ef, $ee, $50, $51, $3e, $46, $4f, $50, $62, $4c
    db $53, $42, $4f, $62, $51, $45, $42, $4f, $42, $63, $f7, $f0
TextStr_43_4ade:           ; id $00F8
    ; "*:You're good..."
    db $eb, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $44, $4c, $4c, $41, $5f, $5f, $5f
    db $ef, $ee, $f7, $f0
TextStr_43_4af2:           ; id $00F9
    ; "*:Want to know where the wife / of the King... / *:I mean, the Queen is? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $54, $45, $42, $4f, $42, $62, $51, $45, $42, $62, $54, $46, $43, $42, $fa
    db $f7, $ef, $ee, $4c, $43, $62, $51, $45, $42, $62, $2e, $46, $4b, $44, $5f, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $4a, $42, $3e, $4b, $5e
    db $62, $51, $45, $42, $ef, $ee, $34, $52, $42, $42, $4b, $62, $46, $50, $64, $ff
    db $f0
TextStr_43_4b43:           ; id $00FA
    ; "*:I bet you wanna know."
    db $ea, $9f, $a3, $2c, $62, $3f, $42, $51, $62, $56, $4c, $52, $62, $54, $3e, $4b
    db $4b, $3e, $ef, $ee, $48, $4b, $4c, $54, $5f, $f7, $f0
TextStr_43_4b5e:           ; id $00FB
    ; "*:You can meet her if you win at / rock- paper- scissors with / Goopi over there! / *:The tired man at the restaurant / might even give you ..."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4a, $42, $42, $51, $ef
    db $ee, $45, $42, $4f, $62, $46, $43, $62, $56, $4c, $52, $62, $54, $46, $4b, $62
    db $3e, $51, $fa, $f7, $ef, $ee, $4f, $4c, $40, $48, $9c, $62, $4d, $3e, $4d, $42
    db $4f, $9c, $ef, $ee, $50, $40, $46, $50, $50, $4c, $4f, $50, $62, $54, $46, $51
    db $45, $fa, $f7, $ef, $ee, $2a, $4c, $4c, $4d, $46, $62, $4c, $53, $42, $4f, $ef
    db $ee, $51, $45, $42, $4f, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42
    db $62, $51, $46, $4f, $42, $41, $62, $4a, $3e, $4b, $62, $3e, $51, $ef, $ee, $51
    db $45, $42, $62, $4f, $42, $50, $51, $3e, $52, $4f, $3e, $4b, $51, $fa, $f7, $ef
    db $ee, $4a, $46, $44, $45, $51, $62, $42, $53, $42, $4b, $62, $44, $46, $53, $42
    db $ef, $ee, $56, $4c, $52, $62, $3e, $62, $3f, $42, $51, $51, $42, $4f, $62, $46
    db $41, $42, $3e, $5f, $f7, $f0
TextStr_43_4c04:           ; id $00FC
    ; "*:These statues are the protectors / of GreatTree. / *:Before you go on your quest, make / an entry to the JOURNAL. / *:It's a good idea."
    db $ea, $9f, $a3, $37, $45, $42, $50, $42, $62, $50, $51, $3e, $51, $52, $42, $50
    db $ef, $ee, $3e, $4f, $42, $62, $51, $45, $42, $62, $4d, $4f, $4c, $51, $42, $40
    db $51, $4c, $4f, $50, $fa, $f7, $ef, $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51
    db $37, $4f, $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $43
    db $4c, $4f, $42, $62, $56, $4c, $52, $62, $44, $4c, $62, $4c, $4b, $ef, $ee, $56
    db $4c, $52, $4f, $62, $4e, $52, $42, $50, $51, $5e, $62, $4a, $3e, $48, $42, $fa
    db $f7, $ef, $ee, $3e, $4b, $62, $42, $4b, $51, $4f, $56, $62, $51, $4c, $62, $51
    db $45, $42, $ef, $ee, $2d, $32, $38, $35, $31, $24, $2f, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $51, $68, $62, $3e, $62, $44, $4c, $4c, $41, $ef, $ee, $46, $41
    db $42, $3e, $5f, $f7, $f0
TextStr_43_4c99:           ; id $00FD
    ; "*:May I help you? The restaurant is / back there."
    db $eb, $9f, $a3, $30, $3e, $56, $62, $2c, $62, $45, $42, $49, $4d, $62, $56, $4c
    db $52, $64, $ef, $ee, $37, $45, $42, $62, $4f, $42, $50, $51, $3e, $52, $4f, $3e
    db $4b, $51, $62, $46, $50, $fa, $f7, $ef, $ee, $3f, $3e, $40, $48, $62, $51, $45
    db $42, $4f, $42, $5f, $ef, $ee, $f7, $f0
TextStr_43_4cd1:           ; id $00FE
    ; "*:The guy at the entrance! / He's my rival!"
    db $ea, $9f, $a3, $37, $45, $42, $62, $44, $52, $56, $62, $3e, $51, $62, $51, $45
    db $42, $ef, $ee, $42, $4b, $51, $4f, $3e, $4b, $40, $42, $63, $fa, $f7, $ef, $ee
    db $2b, $42, $68, $62, $4a, $56, $62, $4f, $46, $53, $3e, $49, $63, $ef, $ee, $f7
    db $f0
TextStr_43_4d02:           ; id $00FF
    ; "*:My rival's watching me from / somewhere... / *:You are a master too? Lemme tell / ya.. / *:Watch out for the foreign / masters behind the ..."
    db $ea, $9f, $a3, $30, $56, $62, $4f, $46, $53, $3e, $49, $68, $ef, $ee, $54, $3e
    db $51, $40, $45, $46, $4b, $44, $62, $4a, $42, $62, $43, $4f, $4c, $4a, $fa, $f7
    db $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f, $42, $5f, $5f, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $3e, $62
    db $4a, $3e, $50, $51, $42, $4f, $ef, $ee, $51, $4c, $4c, $64, $62, $2f, $42, $4a
    db $4a, $42, $62, $51, $42, $49, $49, $fa, $f7, $ef, $ee, $56, $3e, $5f, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $3e, $51, $40, $45, $62, $4c, $52, $51
    db $62, $43, $4c, $4f, $ef, $ee, $51, $45, $42, $62, $43, $4c, $4f, $42, $46, $44
    db $4b, $fa, $f7, $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $50, $62, $3f, $42, $45
    db $46, $4b, $41, $ef, $ee, $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42
    db $4f, $50, $5c, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $50, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $56, $69, $42, $62, $44, $4c, $4b, $4b
    db $3e, $ef, $ee, $4a, $3e, $48, $42, $62, $4a, $46, $4b, $40, $42, $4a, $42, $3e
    db $51, $62, $4c, $52, $51, $fa, $f7, $ef, $ee, $4c, $43, $62, $56, $4c, $52, $5e
    db $62, $54, $46, $4a, $4d, $63, $ef, $ee, $f7, $f0
TextStr_43_4dec:           ; id $0100
    ; "[HERO] looked into the jar. / An old lady's notebook is there. / "Educational Guide" / Read it? [YES/NO]"
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $24, $4b, $62, $4c, $49
    db $41, $62, $49, $3e, $41, $56, $68, $ef, $ee, $4b, $4c, $51, $42, $3f, $4c, $4c
    db $48, $62, $46, $50, $62, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $65
    db $28, $41, $52, $40, $3e, $51, $46, $4c, $4b, $3e, $49, $ef, $ee, $2a, $52, $46
    db $41, $42, $65, $fa, $f7, $ef, $ee, $35, $42, $3e, $41, $62, $46, $51, $64, $ef
    db $ee, $ff, $f0
TextStr_43_4e4f:           ; id $0101
    ; "[HERO] looked into the jar. / A piece of paper is there. / Something is written on it. / :Good things will happen if you / defeat Goopi 5 ti..."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $24, $62, $4d, $46, $42
    db $40, $42, $62, $4c, $43, $62, $4d, $3e, $4d, $42, $4f, $ef, $ee, $46, $50, $62
    db $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $36, $4c, $4a, $42, $51, $45
    db $46, $4b, $44, $62, $46, $50, $ef, $ee, $54, $4f, $46, $51, $51, $42, $4b, $62
    db $4c, $4b, $62, $46, $51, $5f, $fa, $f7, $ef, $ee, $a3, $2a, $4c, $4c, $41, $62
    db $51, $45, $46, $4b, $44, $50, $62, $54, $46, $49, $49, $ef, $ee, $45, $3e, $4d
    db $4d, $42, $4b, $62, $46, $43, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $41, $42
    db $43, $42, $3e, $51, $62, $2a, $4c, $4c, $4d, $46, $ef, $ee, $05, $62, $51, $46
    db $4a, $42, $50, $62, $46, $4b, $62, $3e, $62, $4f, $4c, $54, $5f, $f7, $f0
TextStr_43_4eee:           ; id $0102
    ; "*:Hm.. It doesn't listen to me much. / *:Seems to need more intelligence."
    db $ea, $9f, $a3, $2b, $4a, $5f, $5f, $62, $2c, $51, $62, $41, $4c, $42, $50, $4b
    db $67, $ef, $ee, $49, $46, $50, $51, $42, $4b, $62, $51, $4c, $62, $4a, $42, $62
    db $4a, $52, $40, $45, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $42, $42, $4a, $50
    db $62, $51, $4c, $62, $4b, $42, $42, $41, $ef, $ee, $4a, $4c, $4f, $42, $62, $46
    db $4b, $51, $42, $49, $49, $46, $44, $42, $4b, $40, $42, $5f, $f7, $f0
TextStr_43_4f3c:           ; id $0103
    ; "*:Hi Ho Hi Ho. / *:Sigh.. I'm starving... / *:I'll be angry if somebody gives me / an order now..."
    db $ea, $9f, $a3, $2b, $46, $62, $2b, $4c, $62, $2b, $46, $62, $2b, $4c, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $46, $44, $45, $5f, $5f, $62, $2c, $6a
    db $ef, $ee, $50, $51, $3e, $4f, $53, $46, $4b, $44, $5f, $5f, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $66, $49, $62, $3f, $42, $62, $3e, $4b, $44, $4f, $56, $62
    db $46, $43, $ef, $ee, $50, $4c, $4a, $42, $3f, $4c, $41, $56, $62, $44, $46, $53
    db $42, $50, $62, $4a, $42, $fa, $f7, $ef, $ee, $3e, $4b, $62, $4c, $4f, $41, $42
    db $4f, $62, $4b, $4c, $54, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_43_4fa8:           ; id $0104
    ; "*:Yo man, wanna know who your / match is in G class? [YES/NO]"
    db $ea, $9f, $a3, $3c, $4c, $62, $4a, $3e, $4b, $5e, $62, $54, $3e, $4b, $4b, $3e
    db $ef, $ee, $48, $4b, $4c, $54, $62, $54, $45, $4c, $62, $56, $4c, $52, $4f, $fa
    db $f7, $ef, $ee, $4a, $3e, $51, $40, $45, $62, $46, $50, $62, $46, $4b, $ef, $ee
    db $2a, $62, $40, $49, $3e, $50, $50, $64, $ff, $f0
TextStr_43_4fe2:           ; id $0105
    ; "*:Its the principal of the / school."
    db $ea, $9f, $a3, $2c, $51, $50, $62, $51, $45, $42, $ef, $ee, $4d, $4f, $46, $4b
    db $40, $46, $4d, $3e, $49, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee
    db $50, $40, $45, $4c, $4c, $49, $5f, $ef, $ee, $f7, $f0
TextStr_43_500d:           ; id $0106
    ; "*:Well,it'll be OK too."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $5e, $46, $51, $66, $49, $62, $3f, $42, $ef
    db $ee, $32, $2e, $62, $51, $4c, $4c, $5f, $f7, $f0
TextStr_43_5027:           ; id $0107
    ; "*:Want to hear about my journey / beyond the Gate of Villager? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $45, $42, $3e, $4f, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $4a, $56, $62, $47, $4c, $52, $4f, $4b, $42
    db $56, $fa, $f7, $ef, $ee, $3f, $42, $56, $4c, $4b, $41, $62, $51, $45, $42, $62
    db $2a, $3e, $51, $42, $ef, $ee, $4c, $43, $62, $39, $46, $49, $49, $3e, $44, $42
    db $4f, $64, $ff, $f0
TextStr_43_506b:           ; id $0108
    ; "*:StubSucks & GoHoppers, / Anteaters & Gremlins were / there.. / *:StubSucks can cast Sleep. / Be careful! / *:Be careful when GoHoppers cha..."
    db $ea, $9f, $a3, $36, $51, $52, $3f, $36, $52, $40, $48, $50, $62, $b6, $ef, $ee
    db $2a, $4c, $2b, $4c, $4d, $4d, $42, $4f, $50, $5e, $fa, $f7, $ef, $ee, $24, $4b
    db $51, $42, $3e, $51, $42, $4f, $50, $62, $b6, $ef, $ee, $2a, $4f, $42, $4a, $49
    db $46, $4b, $50, $62, $54, $42, $4f, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $4f
    db $42, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $51, $52, $3f, $36
    db $52, $40, $48, $50, $62, $40, $3e, $4b, $ef, $ee, $40, $3e, $50, $51, $62, $36
    db $49, $42, $42, $4d, $5f, $fa, $f7, $ef, $ee, $25, $42, $62, $40, $3e, $4f, $42
    db $43, $52, $49, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $42, $62, $40
    db $3e, $4f, $42, $43, $52, $49, $62, $54, $45, $42, $4b, $ef, $ee, $2a, $4c, $2b
    db $4c, $4d, $4d, $42, $4f, $50, $62, $40, $45, $3e, $4f, $44, $42, $fa, $f7, $ef
    db $ee, $51, $45, $42, $46, $4f, $62, $4d, $4c, $54, $42, $4f, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $44, $52, $3e, $4f, $41, $46, $3e
    db $4b, $ef, $ee, $51, $45, $42, $4f, $42, $62, $46, $50, $62, $3e, $62, $27, $4f
    db $3e, $44, $4c, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $50, $62, $29
    db $46, $4f, $42, $24, $46, $4f, $62, $54, $46, $49, $49, $ef, $ee, $40, $3e, $52
    db $50, $42, $62, $44, $4f, $42, $3e, $51, $62, $41, $3e, $4a, $3e, $44, $42, $fa
    db $f7, $ef, $ee, $51, $4c, $62, $56, $4c, $52, $4f, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $3e, $48, $42
    db $62, $4d, $49, $42, $4b, $51, $56, $62, $4c, $43, $ef, $ee, $45, $42, $4f, $3f
    db $50, $62, $54, $46, $51, $45, $62, $56, $4c, $52, $5f, $f7, $f0
TextStr_43_51a8:           ; id $0109
    ; "*:My journey to the Travelers' / Gate is a fond Memory for me..."
    db $ea, $9f, $a3, $30, $56, $62, $47, $4c, $52, $4f, $4b, $42, $56, $62, $51, $4c
    db $ef, $ee, $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c
    db $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $62, $46, $50, $62, $3e, $62, $43, $4c
    db $4b, $41, $ef, $ee, $30, $42, $4a, $4c, $4f, $56, $62, $43, $4c, $4f, $62, $4a
    db $42, $5f, $5f, $5f, $f7, $f0
TextStr_43_51ee:           ; id $010A
    ; "*:Want to know about the monsters / behind the Gate of Talisman? [YES/NO]"
    db $ea, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $48, $4b, $4c, $54, $ef
    db $ee, $3e, $3f, $4c, $52, $51, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45
    db $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $37, $3e, $49, $46, $50
    db $4a, $3e, $4b, $64, $ff, $f0
TextStr_43_5234:           ; id $010B
    ; "*:This is an "onigiri". C'mon / BeBe, repeat after me!"
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $46, $50, $62, $3e, $4b, $ef, $ee, $65
    db $4c, $4b, $46, $44, $46, $4f, $46, $65, $5f, $62, $26, $6a, $4c, $4b, $fa, $f7
    db $ef, $ee, $25, $42, $25, $42, $5e, $62, $4f, $42, $4d, $42, $3e, $51, $ef, $ee
    db $3e, $43, $51, $42, $4f, $62, $4a, $42, $63, $f7, $f0
TextStr_43_526f:           ; id $010C
    ; "BeBe:Boo Baa Boo Baa."
    db $ea, $25, $42, $25, $42, $a3, $25, $4c, $4c, $62, $25, $3e, $3e, $ef, $ee, $25
    db $4c, $4c, $62, $25, $3e, $3e, $5f, $f7, $f0
TextStr_43_5288:           ; id $010D
    ; "*:....."
    db $ea, $9f, $a3, $5f, $5f, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_43_5294:           ; id $010E
    ; "*:What the heck is an onigiri? / Why can't you say rice balls?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $51, $45, $42, $62, $45, $42, $40, $48
    db $ef, $ee, $46, $50, $62, $3e, $4b, $62, $4c, $4b, $46, $44, $46, $4f, $46, $64
    db $fa, $f7, $ef, $ee, $3a, $45, $56, $62, $40, $3e, $4b, $67, $62, $56, $4c, $52
    db $ef, $ee, $50, $3e, $56, $62, $4f, $46, $40, $42, $62, $3f, $3e, $49, $49, $50
    db $64, $f7, $f0
TextStr_43_52d7:           ; id $010F
    ; "*:We all gather here seeking / victory. / *:The battle is not to be taken / lightly. / *:Many lack the courage to see / it through to the en..."
    db $ea, $9f, $a3, $3a, $42, $62, $3e, $49, $49, $62, $44, $3e, $51, $45, $42, $4f
    db $ef, $ee, $45, $42, $4f, $42, $62, $50, $42, $42, $48, $46, $4b, $44, $fa, $f7
    db $ef, $ee, $53, $46, $40, $51, $4c, $4f, $56, $5f, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $37, $45, $42, $62, $3f, $3e, $51, $51, $49, $42, $62, $46, $50, $ef
    db $ee, $4b, $4c, $51, $62, $51, $4c, $62, $3f, $42, $62, $51, $3e, $48, $42, $4b
    db $fa, $f7, $ef, $ee, $49, $46, $44, $45, $51, $49, $56, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $30, $3e, $4b, $56, $62, $49, $3e, $40, $48, $62, $51, $45
    db $42, $ef, $ee, $40, $4c, $52, $4f, $3e, $44, $42, $62, $51, $4c, $62, $50, $42
    db $42, $fa, $f7, $ef, $ee, $46, $51, $62, $51, $45, $4f, $4c, $52, $44, $45, $62
    db $51, $4c, $62, $51, $45, $42, $ef, $ee, $42, $4b, $41, $63, $f7, $f0
TextStr_43_5375:           ; id $0110
    ; "*:Oh, welcome Mas...ahem. / I am the Medal Man. / *:I collect TinyMedals / scattered all over the world. / *:If you find some give'm to me! ..."
    db $ea, $9f, $a3, $32, $45, $5e, $62, $54, $42, $49, $40, $4c, $4a, $42, $ef, $ee
    db $30, $3e, $50, $5f, $5f, $5f, $3e, $45, $42, $4a, $5f, $fa, $f7, $ef, $ee, $2c
    db $62, $3e, $4a, $62, $51, $45, $42, $62, $30, $42, $41, $3e, $49, $ef, $ee, $30
    db $3e, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $4c, $49, $49, $42
    db $40, $51, $ef, $ee, $37, $46, $4b, $56, $30, $42, $41, $3e, $49, $50, $fa, $f7
    db $ef, $ee, $50, $40, $3e, $51, $51, $42, $4f, $42, $41, $62, $3e, $49, $49, $62
    db $4c, $53, $42, $4f, $ef, $ee, $51, $45, $42, $62, $54, $4c, $4f, $49, $41, $5f
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $43, $46, $4b
    db $41, $62, $50, $4c, $4a, $42, $ef, $ee, $44, $46, $53, $42, $6a, $62, $51, $4c
    db $62, $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $4f, $42
    db $54, $3e, $4f, $41, $62, $56, $4c, $52, $63, $ef, $ee, $37, $45, $42, $62, $4a
    db $4c, $4f, $42, $62, $4a, $42, $41, $3e, $49, $50, $fa, $f7, $ef, $ee, $51, $45
    db $42, $62, $3f, $42, $51, $51, $42, $4f, $62, $56, $4c, $52, $4f, $ef, $ee, $4f
    db $42, $54, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $6a, $62, $40
    db $4c, $52, $4b, $51, $46, $4b, $44, $ef, $ee, $4c, $4b, $62, $56, $4c, $52, $63
    db $fa, $f7, $ef, $ee, $25, $52, $50, $56, $62, $25, $52, $50, $56, $ef, $ee, $25
    db $52, $50, $56, $5f, $5f, $5f, $f7, $f0
TextStr_43_547d:           ; id $0111
    ; "*:I am Medal Man, the medal / collector."
    db $ea, $9f, $a3, $2c, $62, $3e, $4a, $62, $30, $42, $41, $3e, $49, $62, $30, $3e
    db $4b, $5e, $ef, $ee, $51, $45, $42, $62, $4a, $42, $41, $3e, $49, $fa, $f7, $ef
    db $ee, $40, $4c, $49, $49, $42, $40, $51, $4c, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_43_54ac:           ; id $0112
    ; "*:Both the Medal Man & myself / love medals! / *:If you bring medals, then he'll / reward you! / *:If you collect a lot, I might / give you ..."
    db $eb, $9f, $a3, $25, $4c, $51, $45, $62, $51, $45, $42, $62, $30, $42, $41, $3e
    db $49, $ef, $ee, $30, $3e, $4b, $62, $b6, $62, $4a, $56, $50, $42, $49, $43, $fa
    db $f7, $ef, $ee, $49, $4c, $53, $42, $62, $4a, $42, $41, $3e, $49, $50, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $3f, $4f
    db $46, $4b, $44, $ef, $ee, $4a, $42, $41, $3e, $49, $50, $5e, $62, $51, $45, $42
    db $4b, $62, $45, $42, $66, $49, $fa, $f7, $ef, $ee, $4f, $42, $54, $3e, $4f, $41
    db $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62
    db $56, $4c, $52, $62, $40, $4c, $49, $49, $42, $40, $51, $ef, $ee, $3e, $62, $49
    db $4c, $51, $5e, $62, $2c, $62, $4a, $46, $44, $45, $51, $fa, $f7, $ef, $ee, $44
    db $46, $53, $42, $62, $56, $4c, $52, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46
    db $4b, $44, $62, $51, $4c, $4c, $5f, $f7, $f0
TextStr_43_5555:           ; id $0113
    ; "*:Welcome to the Master School! / *:I am the principal of / the school. / *:I teach the do's & don'ts of / becoming a powerful master. / *:T..."
    db $ea, $9f, $a3, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $36, $40, $45, $4c, $4c, $49
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $51, $45, $42, $ef
    db $ee, $4d, $4f, $46, $4b, $40, $46, $4d, $3e, $49, $62, $4c, $43, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $50, $40, $45, $4c, $4c, $49, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $62, $51, $42, $3e, $40, $45, $62, $51, $45, $42, $ef
    db $ee, $41, $4c, $68, $62, $b6, $62, $41, $4c, $4b, $67, $50, $62, $4c, $43, $fa
    db $f7, $ef, $ee, $3f, $42, $40, $4c, $4a, $46, $4b, $44, $62, $3e, $ef, $ee, $4d
    db $4c, $54, $42, $4f, $43, $52, $49, $62, $4a, $3e, $50, $51, $42, $4f, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $37, $4c, $41, $3e, $56, $68, $62, $49, $42, $40, $51
    db $52, $4f, $42, $ef, $ee, $46, $50, $62, $4c, $4b, $62, $40, $3e, $51, $40, $45
    db $46, $4b, $44, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $49, $46
    db $50, $51, $42, $4b, $64, $ef, $ee, $ff, $f0
TextStr_43_562e:           ; id $0114
    ; "*:Sometimes monsters you beat / will become your pal. / *:They are more likely to become / your pal if you give them meat / treats. / *:Pric..."
    db $ea, $9f, $a3, $36, $4c, $4a, $42, $51, $46, $4a, $42, $50, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $50, $62, $56, $4c, $52, $62, $3f, $42, $3e, $51, $fa
    db $f7, $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $40, $4c, $4a, $42, $62, $56
    db $4c, $52, $4f, $ef, $ee, $4d, $3e, $49, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37
    db $45, $42, $56, $62, $3e, $4f, $42, $62, $4a, $4c, $4f, $42, $ef, $ee, $49, $46
    db $48, $42, $49, $56, $62, $51, $4c, $62, $3f, $42, $40, $4c, $4a, $42, $fa, $f7
    db $ef, $ee, $56, $4c, $52, $4f, $62, $4d, $3e, $49, $62, $46, $43, $62, $56, $4c
    db $52, $ef, $ee, $44, $46, $53, $42, $62, $51, $45, $42, $4a, $62, $4a, $42, $3e
    db $51, $fa, $f7, $ef, $ee, $51, $4f, $42, $3e, $51, $50, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $33, $4f, $46, $40, $42, $56, $62, $51, $4f, $42, $3e, $51
    db $50, $ef, $ee, $3e, $4f, $42, $62, $3f, $42, $51, $51, $42, $4f, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $43, $62, $4c, $4b, $42, $62, $41, $4c, $42, $50, $4b
    db $67, $ef, $ee, $54, $4c, $4f, $48, $5e, $62, $44, $46, $53, $42, $62, $51, $45
    db $42, $4a, $fa, $f7, $ef, $ee, $51, $54, $4c, $62, $4c, $4f, $62, $51, $45, $4f
    db $42, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $68, $62, $46
    db $4a, $4d, $4c, $4f, $51, $3e, $4b, $51, $ef, $ee, $56, $4c, $52, $62, $41, $42
    db $43, $42, $3e, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $62, $56, $4c, $52, $62, $54, $3e, $4b, $51, $ef, $ee, $49, $3e
    db $50, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $32, $4b, $49, $56, $62, $51, $45
    db $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $41, $42, $43, $42, $3e
    db $51, $42, $41, $62, $49, $3e, $50, $51, $62, $54, $46, $49, $49, $fa, $f7, $ef
    db $ee, $3f, $42, $40, $4c, $4a, $42, $62, $56, $4c, $52, $4f, $62, $4d, $3e, $49
    db $5f, $ef, $ee, $f7, $f0
TextStr_43_5793:           ; id $0115
    ; "*:It's helpful to take a WarpWing / with you. / *:The principal told me that. / Ha Ha."
    db $eb, $9f, $a3, $2c, $51, $68, $62, $45, $42, $49, $4d, $43, $52, $49, $62, $51
    db $4c, $ef, $ee, $51, $3e, $48, $42, $62, $3e, $62, $3a, $3e, $4f, $4d, $3a, $46
    db $4b, $44, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c, $52, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4d, $4f, $46, $4b, $40
    db $46, $4d, $3e, $49, $ef, $ee, $51, $4c, $49, $41, $62, $4a, $42, $62, $51, $45
    db $3e, $51, $5f, $fa, $f7, $ef, $ee, $2b, $3e, $62, $2b, $3e, $5f, $ef, $ee, $f7
    db $f0
TextStr_43_57f4:           ; id $0116
    ; "*:Here's the Monster Master / School."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $68, $62, $51, $45, $42, $ef, $ee, $30, $4c
    db $4b, $50, $51, $42, $4f, $62, $30, $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee
    db $36, $40, $45, $4c, $4c, $49, $5f, $ef, $ee, $f7, $f0
TextStr_43_581f:           ; id $0117
    ; "[HERO] read the blackboard. / :Do's & Don'ts of monster masters. / :Monsters learn through battles. / :They might do something wrong / or du..."
    db $f6, $62, $4f, $42, $3e, $41, $ef, $ee, $51, $45, $42, $62, $3f, $49, $3e, $40
    db $48, $3f, $4c, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee, $a3, $27, $4c, $68, $62
    db $b6, $62, $27, $4c, $4b, $67, $50, $62, $4c, $43, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $62, $4a, $3e, $50, $51, $42, $4f, $50, $5f, $fa, $f7, $ef, $ee
    db $a3, $30, $4c, $4b, $50, $51, $42, $4f, $50, $62, $49, $42, $3e, $4f, $4b, $ef
    db $ee, $51, $45, $4f, $4c, $52, $44, $45, $62, $3f, $3e, $51, $51, $49, $42, $50
    db $5f, $fa, $f7, $ef, $ee, $a3, $37, $45, $42, $56, $62, $4a, $46, $44, $45, $51
    db $62, $41, $4c, $ef, $ee, $50, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $54
    db $4f, $4c, $4b, $44, $fa, $f7, $ef, $ee, $4c, $4f, $62, $41, $52, $4a, $3f, $62
    db $3e, $51, $62, $43, $46, $4f, $50, $51, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $a3
    db $25, $52, $51, $62, $46, $51, $50, $62, $46, $4a, $4d, $4c, $4f, $51, $3e, $4b
    db $51, $ef, $ee, $51, $4c, $62, $40, $4c, $3e, $40, $45, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7
    db $ef, $ee, $a3, $3a, $45, $42, $4b, $62, $51, $45, $42, $56, $62, $4a, $3e, $51
    db $52, $4f, $42, $5e, $ef, $ee, $b6, $62, $51, $45, $42, $46, $4f, $fa, $f7, $ef
    db $ee, $46, $4b, $51, $42, $49, $49, $46, $44, $42, $4b, $40, $42, $ef, $ee, $46
    db $4a, $4d, $4f, $4c, $53, $42, $50, $5e, $fa, $f7, $ef, $ee, $51, $45, $42, $56
    db $62, $54, $46, $49, $49, $ef, $ee, $42, $53, $42, $4b, $51, $52, $3e, $49, $49
    db $56, $62, $50, $52, $4f, $4d, $3e, $50, $50, $fa, $f7, $ef, $ee, $51, $45, $42
    db $46, $4f, $62, $4a, $3e, $50, $51, $42, $4f, $68, $ef, $ee, $3f, $3e, $51, $51
    db $49, $42, $62, $50, $48, $46, $49, $49, $50, $5f, $f7, $f0
TextStr_43_596b:           ; id $0118
    ; "[HERO] read the blackboard. / :Masters are not created in a day. / Shoot for the Starry Night / Tournament!"
    db $f6, $62, $4f, $42, $3e, $41, $62, $51, $45, $42, $ef, $ee, $3f, $49, $3e, $40
    db $48, $3f, $4c, $3e, $4f, $41, $5f, $fa, $f7, $ef, $ee, $a3, $30, $3e, $50, $51
    db $42, $4f, $50, $62, $3e, $4f, $42, $62, $4b, $4c, $51, $ef, $ee, $40, $4f, $42
    db $3e, $51, $42, $41, $62, $46, $4b, $62, $3e, $62, $41, $3e, $56, $5f, $fa, $f7
    db $ef, $ee, $36, $45, $4c, $4c, $51, $62, $43, $4c, $4f, $62, $51, $45, $42, $ef
    db $ee, $36, $51, $3e, $4f, $4f, $56, $62, $31, $46, $44, $45, $51, $fa, $f7, $ef
    db $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $ef, $ee, $f7, $f0
TextStr_43_59db:           ; id $0119
    ; "*:Superior masters... / *:have a well-balanced / combination of monsters. / *:A monster that restores & a / monster that attacks i.e. / *:A ..."
    db $ea, $9f, $a3, $36, $52, $4d, $42, $4f, $46, $4c, $4f, $ef, $ee, $4a, $3e, $50
    db $51, $42, $4f, $50, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $45, $3e, $53
    db $42, $62, $3e, $ef, $ee, $54, $42, $49, $49, $9c, $3f, $3e, $49, $3e, $4b, $40
    db $42, $41, $fa, $f7, $ef, $ee, $40, $4c, $4a, $3f, $46, $4b, $3e, $51, $46, $4c
    db $4b, $62, $4c, $43, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $24, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $51
    db $45, $3e, $51, $ef, $ee, $4f, $42, $50, $51, $4c, $4f, $42, $50, $62, $b6, $62
    db $3e, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $51, $45, $3e
    db $51, $ef, $ee, $3e, $51, $51, $3e, $40, $48, $50, $62, $46, $5f, $42, $5f, $fa
    db $f7, $ef, $ee, $9f, $a3, $24, $62, $40, $4c, $4a, $3f, $46, $4b, $3e, $51, $46
    db $4c, $4b, $ef, $ee, $54, $46, $51, $45, $46, $4b, $62, $51, $45, $42, $62, $4d
    db $3e, $4f, $51, $56, $5f, $f7, $f0
TextStr_43_5a92:           ; id $011A
    ; "*:Army Bomb Army, Bubble Army...! / *:Uuu I wanna meet the Queen... / Army Bomb Army..."
    db $ea, $9f, $a3, $24, $4f, $4a, $56, $62, $25, $4c, $4a, $3f, $62, $24, $4f, $4a
    db $56, $5e, $ef, $ee, $25, $52, $3f, $3f, $49, $42, $62, $24, $4f, $4a, $56, $5f
    db $5f, $5f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $38, $52, $52, $62, $2c, $62, $54
    db $3e, $4b, $4b, $3e, $62, $4a, $42, $42, $51, $ef, $ee, $51, $45, $42, $62, $34
    db $52, $42, $42, $4b, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $24, $4f, $4a, $56, $62
    db $25, $4c, $4a, $3f, $62, $24, $4f, $4a, $56, $5f, $5f, $5f, $ef, $ee, $f7, $f0
TextStr_43_5af2:           ; id $011B
    ; "*:Who the heck is that old woman at / the reception? / *:Wearing a flashy costume / at her age!"
    db $ea, $9f, $a3, $3a, $45, $4c, $62, $51, $45, $42, $62, $45, $42, $40, $48, $62
    db $46, $50, $ef, $ee, $51, $45, $3e, $51, $62, $4c, $49, $41, $62, $54, $4c, $4a
    db $3e, $4b, $62, $3e, $51, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4f, $42, $40
    db $42, $4d, $51, $46, $4c, $4b, $64, $ef, $ee, $fa, $f7, $ef, $ee, $f3, $9f, $a3
    db $3a, $42, $3e, $4f, $46, $4b, $44, $62, $3e, $ef, $ee, $43, $49, $3e, $50, $45
    db $56, $62, $40, $4c, $50, $51, $52, $4a, $42, $fa, $f7, $ef, $ee, $3e, $51, $62
    db $45, $42, $4f, $62, $3e, $44, $42, $63, $ef, $ee, $f7, $f0
TextStr_43_5b5e:           ; id $011C
    ; "*:I am the Queen of GreatTree. / I like to watch battles. / *:It seems you haven't paid / a visit to the Starry Shrine. / *:Come back later...."
    db $eb, $9f, $a3, $2c, $62, $3e, $4a, $62, $51, $45, $42, $62, $34, $52, $42, $42
    db $4b, $ef, $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5f
    db $fa, $f7, $ef, $ee, $2c, $62, $49, $46, $48, $42, $62, $51, $4c, $62, $54, $3e
    db $51, $40, $45, $ef, $ee, $3f, $3e, $51, $51, $49, $42, $50, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $51, $62, $50, $42, $42, $4a, $50, $62, $56, $4c, $52, $ef
    db $ee, $45, $3e, $53, $42, $4b, $67, $62, $4d, $3e, $46, $41, $fa, $f7, $ef, $ee
    db $3e, $62, $53, $46, $50, $46, $51, $62, $51, $4c, $62, $51, $45, $42, $ef, $ee
    db $36, $51, $3e, $4f, $4f, $56, $62, $36, $45, $4f, $46, $4b, $42, $5f, $fa, $f7
    db $ef, $ee, $9f, $a3, $26, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $62, $49, $3e
    db $51, $42, $4f, $5f, $ef, $ee, $2c, $62, $3e, $4a, $62, $4b, $4c, $51, $fa, $f7
    db $ef, $ee, $46, $4b, $51, $42, $4f, $42, $50, $51, $42, $41, $ef, $ee, $46, $4b
    db $62, $54, $42, $3e, $48, $49, $46, $4b, $44, $50, $5f, $f7, $f0
TextStr_43_5c1b:           ; id $011D
    ; "*:Here is her majesty the Queen / of GreatTree. / *:Here is her guest, Mick. / *:Come back after you meet the / Master Monster Tamer."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $62, $46, $50, $62, $45, $42, $4f, $ef, $ee
    db $4a, $3e, $47, $42, $50, $51, $56, $62, $51, $45, $42, $62, $34, $52, $42, $42
    db $4b, $fa, $f7, $ef, $ee, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $37, $4f, $42
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $4f, $42, $62, $46
    db $50, $62, $45, $42, $4f, $ef, $ee, $44, $52, $42, $50, $51, $5e, $62, $30, $46
    db $40, $48, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $26, $4c, $4a, $42, $62, $3f, $3e
    db $40, $48, $62, $3e, $43, $51, $42, $4f, $ef, $ee, $56, $4c, $52, $62, $4a, $42
    db $42, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $30, $3e, $50, $51, $42, $4f
    db $62, $30, $4c, $4b, $50, $51, $42, $4f, $ef, $ee, $37, $3e, $4a, $42, $4f, $5f
    db $f7, $f0
TextStr_43_5cad:           ; id $011E
    ; "*:I'm Mick. Who are you? / *:Whew, those crazy fans are / annoying. / *:Still a rookie aren't ya? / *:You need to clear an upper / class / *..."
    db $ea, $9f, $a3, $2c, $6a, $62, $30, $46, $40, $48, $5f, $ef, $ee, $3a, $45, $4c
    db $62, $3e, $4f, $42, $62, $56, $4c, $52, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3a
    db $45, $42, $54, $5e, $62, $51, $45, $4c, $50, $42, $ef, $ee, $40, $4f, $3e, $57
    db $56, $62, $43, $3e, $4b, $50, $62, $3e, $4f, $42, $fa, $f7, $ef, $ee, $3e, $4b
    db $4b, $4c, $56, $46, $4b, $44, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36
    db $51, $46, $49, $49, $62, $3e, $62, $4f, $4c, $4c, $48, $46, $42, $ef, $ee, $3e
    db $4f, $42, $4b, $67, $62, $56, $3e, $64, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c
    db $52, $62, $4b, $42, $42, $41, $62, $51, $4c, $ef, $ee, $40, $49, $42, $3e, $4f
    db $62, $3e, $4b, $62, $52, $4d, $4d, $42, $4f, $fa, $f7, $ef, $ee, $40, $49, $3e
    db $50, $50, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $51, $4c, $62, $50, $42, $42
    db $62, $51, $45, $42, $ef, $ee, $36, $51, $3e, $4f, $4f, $56, $62, $36, $45, $4f
    db $46, $4b, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $49, $49, $5e, $62
    db $51, $3e, $48, $42, $ef, $ee, $46, $51, $62, $42, $3e, $50, $56, $5f, $f7, $f0
TextStr_43_5d7d:           ; id $011F
    ; "*:You are at the Room of Beginning. / *:The Travelers' Gate in the back / is the Gate of Beginning."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $3e, $4f, $42, $62, $3e, $51, $62, $51, $45
    db $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $25, $42, $44, $46, $4b
    db $4b, $46, $4b, $44, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $37
    db $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $ef, $ee, $2a, $3e, $51, $42, $62
    db $46, $4b, $62, $51, $45, $42, $62, $3f, $3e, $40, $48, $fa, $f7, $ef, $ee, $46
    db $50, $62, $51, $45, $42, $62, $2a, $3e, $51, $42, $62, $4c, $43, $ef, $ee, $25
    db $42, $44, $46, $4b, $4b, $46, $4b, $44, $5f, $f7, $f0
TextStr_43_5de8:           ; id $0120
    ; "*:Ladies & Gents! Welcome to the / Arena! / *:A new challenger is here today! / *:Ladies & Gents! Please welcome / [HERO]! / *:Now we begin ..."
    db $eb, $9f, $a3, $2f, $3e, $41, $46, $42, $50, $62, $b6, $62, $2a, $42, $4b, $51
    db $50, $63, $ef, $ee, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $24, $4f, $42, $4b, $3e, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $24, $62, $4b, $42, $54, $62, $40, $45, $3e, $49, $49, $42
    db $4b, $44, $42, $4f, $ef, $ee, $46, $50, $62, $45, $42, $4f, $42, $62, $51, $4c
    db $41, $3e, $56, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2f, $3e, $41, $46, $42, $50
    db $62, $b6, $62, $2a, $42, $4b, $51, $50, $63, $ef, $ee, $33, $49, $42, $3e, $50
    db $42, $62, $54, $42, $49, $40, $4c, $4a, $42, $fa, $f7, $ef, $ee, $f6, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $54, $62, $54, $42, $62, $3f, $42
    db $44, $46, $4b, $62, $51, $45, $42, $ef, $ee, $43, $46, $4f, $50, $51, $62, $4a
    db $3e, $51, $40, $45, $63, $f7, $f0
TextStr_43_5e8f:           ; id $0121
    ; "*:Leeet's Rumble!"
    db $eb, $9f, $a3, $2f, $42, $42, $42, $51, $68, $62, $35, $52, $4a, $3f, $49, $42
    db $63, $ef, $ee, $f7, $f0
TextStr_43_5ea4:           ; id $0122
    ; "*:For the 1st match, the victory / goes to the challenger! / *:Now we begin the 2nd match!"
    db $eb, $9f, $a3, $29, $4c, $4f, $62, $51, $45, $42, $62, $01, $50, $51, $ef, $ee
    db $4a, $3e, $51, $40, $45, $5e, $62, $51, $45, $42, $62, $53, $46, $40, $51, $4c
    db $4f, $56, $fa, $f7, $ef, $ee, $44, $4c, $42, $50, $62, $51, $4c, $62, $51, $45
    db $42, $ef, $ee, $40, $45, $3e, $49, $49, $42, $4b, $44, $42, $4f, $63, $fa, $f7
    db $ef, $ee, $9f, $a3, $31, $4c, $54, $62, $54, $42, $62, $3f, $42, $44, $46, $4b
    db $62, $51, $45, $42, $ef, $ee, $02, $4b, $41, $62, $4a, $3e, $51, $40, $45, $63
    db $f7, $f0
TextStr_43_5f06:           ; id $0123
    ; "Watabou:Doing well huh? / Let's go home."
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $27, $4c, $46, $4b, $44, $ef, $ee
    db $54, $42, $49, $49, $62, $45, $52, $45, $64, $fa, $f7, $ef, $ee, $2f, $42, $51
    db $68, $62, $44, $4c, $62, $45, $4c, $4a, $42, $5f, $ef, $ee, $f7, $f0
TextStr_43_5f34:           ; id $0124
    ; "*:For the 2nd match, the victory / again goes to the challenger! / *:Now we begin the 3rd match!"
    db $eb, $9f, $a3, $29, $4c, $4f, $62, $51, $45, $42, $62, $02, $4b, $41, $ef, $ee
    db $4a, $3e, $51, $40, $45, $5e, $62, $51, $45, $42, $62, $53, $46, $40, $51, $4c
    db $4f, $56, $fa, $f7, $ef, $ee, $3e, $44, $3e, $46, $4b, $62, $44, $4c, $42, $50
    db $62, $51, $4c, $62, $51, $45, $42, $ef, $ee, $40, $45, $3e, $49, $49, $42, $4b
    db $44, $42, $4f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $31, $4c, $54, $62, $54, $42
    db $62, $3f, $42, $44, $46, $4b, $62, $51, $45, $42, $ef, $ee, $03, $4f, $41, $62
    db $4a, $3e, $51, $40, $45, $63, $fa, $f7, $f0
TextStr_43_5f9d:           ; id $0125
    ; "*:I'm the principal of the / Master School! / *:If you survive me, G class is / yours! / *:Show me what you're made of!"
    db $ea, $9f, $a3, $2c, $6a, $62, $51, $45, $42, $ef, $ee, $4d, $4f, $46, $4b, $40
    db $46, $4d, $3e, $49, $62, $4c, $43, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $30
    db $3e, $50, $51, $42, $4f, $62, $36, $40, $45, $4c, $4c, $49, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56, $4c, $52, $62, $50, $52, $4f, $53
    db $46, $53, $42, $ef, $ee, $4a, $42, $5e, $62, $2a, $62, $40, $49, $3e, $50, $50
    db $62, $46, $50, $fa, $f7, $ef, $ee, $56, $4c, $52, $4f, $50, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $36, $45, $4c, $54, $62, $4a, $42, $62, $54, $45, $3e
    db $51, $ef, $ee, $56, $4c, $52, $69, $42, $62, $4a, $3e, $41, $42, $62, $4c, $43
    db $63, $f7, $f0
TextStr_43_6020:           ; id $0126
    ; "*:Congratulations! We have a new / winner! / *:Give a round of applause for / Master [HERO]!"
    db $eb, $9f, $a3, $26, $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c
    db $4b, $50, $63, $ef, $ee, $3a, $42, $62, $45, $3e, $53, $42, $62, $3e, $62, $4b
    db $42, $54, $fa, $f7, $ef, $ee, $54, $46, $4b, $4b, $42, $4f, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2a, $46, $53, $42, $62, $3e, $62, $4f, $4c, $52, $4b
    db $41, $ef, $ee, $4c, $43, $62, $3e, $4d, $4d, $49, $3e, $52, $50, $42, $62, $43
    db $4c, $4f, $fa, $f7, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $f6, $63, $ef
    db $ee, $f7, $f0
TextStr_43_6083:           ; id $0127
    ; "[HERO] got an Herb."
    db $f6, $62, $44, $4c, $51, $62, $3e, $4b, $ef, $ee, $2b, $42, $4f, $3f, $5f, $f7
    db $f0
TextStr_43_6094:           ; id $0128
    ; "[HERO] found an Herb. / But cannot carry any more. / [HERO] returned the herb to the / treasure chest."
    db $f6, $62, $43, $4c, $52, $4b, $41, $62, $3e, $4b, $ef, $ee, $2b, $42, $4f, $3f
    db $5f, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $40, $3e, $4b, $4b, $4c, $51, $62
    db $40, $3e, $4f, $4f, $56, $ef, $ee, $3e, $4b, $56, $62, $4a, $4c, $4f, $42, $5f
    db $fa, $f7, $ef, $ee, $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $ef, $ee
    db $51, $45, $42, $62, $45, $42, $4f, $3f, $62, $51, $4c, $62, $51, $45, $42, $fa
    db $f7, $ef, $ee, $51, $4f, $42, $3e, $50, $52, $4f, $42, $62, $40, $45, $42, $50
    db $51, $5f, $ef, $ee, $f7, $f0
TextStr_43_60fa:           ; id $0129
    ; "Wow! [HERO] got a TinyMedal!"
    db $3a, $4c, $54, $63, $62, $f6, $62, $44, $4c, $51, $ef, $ee, $3e, $62, $37, $46
    db $4b, $56, $30, $42, $41, $3e, $49, $63, $f7, $f0
TextStr_43_6114:           ; id $012A
    ; "Wow! A TinyMedal was found! But / cannot carry any more. / [HERO] returned the TinyMedal to / the jar."
    db $3a, $4c, $54, $63, $62, $24, $62, $37, $46, $4b, $56, $30, $42, $41, $3e, $49
    db $ef, $ee, $54, $3e, $50, $62, $43, $4c, $52, $4b, $41, $63, $62, $25, $52, $51
    db $fa, $f7, $ef, $ee, $40, $3e, $4b, $4b, $4c, $51, $62, $40, $3e, $4f, $4f, $56
    db $ef, $ee, $3e, $4b, $56, $62, $4a, $4c, $4f, $42, $5f, $fa, $f7, $ef, $ee, $f6
    db $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $ef, $ee, $51, $45, $42, $62, $37
    db $46, $4b, $56, $30, $42, $41, $3e, $49, $62, $51, $4c, $fa, $f7, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_43_617f:           ; id $012B
    ; "*:Hey you, do you have a TinyMedal? [YES/NO]"
    db $ea, $9f, $a3, $2b, $42, $56, $62, $56, $4c, $52, $5e, $62, $41, $4c, $62, $56
    db $4c, $52, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $62, $37, $46, $4b, $56, $30
    db $42, $41, $3e, $49, $64, $ff, $f0
TextStr_43_61a6:           ; id $012C
    ; "*:You don't have it? What are you / doing? It must be somewhere!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $46, $51, $64, $62, $3a, $45, $3e, $51, $62, $3e, $4f, $42, $62, $56
    db $4c, $52, $fa, $f7, $ef, $ee, $41, $4c, $46, $4b, $44, $64, $62, $2c, $51, $62
    db $4a, $52, $50, $51, $62, $3f, $42, $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42
    db $4f, $42, $63, $f7, $f0
TextStr_43_61eb:           ; id $012D
    ; "*:I see. Go to the room above then. / *:You will be welcomed if you / have TinyMedals."
    db $ea, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $62, $2a, $4c, $62, $51, $4c, $62
    db $51, $45, $42, $ef, $ee, $4f, $4c, $4c, $4a, $62, $3e, $3f, $4c, $53, $42, $62
    db $51, $45, $42, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $54
    db $46, $49, $49, $62, $3f, $42, $ef, $ee, $54, $42, $49, $40, $4c, $4a, $42, $41
    db $62, $46, $43, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $45, $3e, $53, $42, $62
    db $37, $46, $4b, $56, $30, $42, $41, $3e, $49, $50, $5f, $ef, $ee, $f7, $f0
TextStr_43_624a:           ; id $012E
    ; "*:Great! Go to the room above then."
    db $ea, $9f, $a3, $2a, $4f, $42, $3e, $51, $63, $62, $2a, $4c, $62, $51, $4c, $62
    db $51, $45, $42, $ef, $ee, $4f, $4c, $4c, $4a, $62, $3e, $3f, $4c, $53, $42, $62
    db $51, $45, $42, $4b, $5f, $f7, $f0
TextStr_43_6271:           ; id $012F
    ; "*:We can see the ground far below. / *:GreatTree is a small kingdom in / a big tree."
    db $eb, $9f, $a3, $3a, $42, $62, $40, $3e, $4b, $62, $50, $42, $42, $62, $51, $45
    db $42, $ef, $ee, $44, $4f, $4c, $52, $4b, $41, $62, $43, $3e, $4f, $62, $3f, $42
    db $49, $4c, $54, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4f, $42, $3e, $51, $37
    db $4f, $42, $42, $62, $46, $50, $62, $3e, $ef, $ee, $50, $4a, $3e, $49, $49, $62
    db $48, $46, $4b, $44, $41, $4c, $4a, $62, $46, $4b, $fa, $f7, $ef, $ee, $3e, $62
    db $3f, $46, $44, $62, $51, $4f, $42, $42, $5f, $ef, $ee, $f7, $f0
TextStr_43_62ce:           ; id $0130
    ; "The Gate is shut tight."
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_43_62e8:           ; id $0131
    ; "The Gate is shut tight."
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_43_6302:           ; id $0132
    ; "The Gate is shut tight."
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_43_631c:           ; id $0133
    ; "The Gate is shut tight. / Something's engraved on the / Gate. / "Room of Strength & Anger""
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $fa, $f7, $ef, $ee, $36, $4c, $4a, $42
    db $51, $45, $46, $4b, $44, $68, $ef, $ee, $42, $4b, $44, $4f, $3e, $53, $42, $41
    db $62, $4c, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2a, $3e, $51, $42, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $65, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $36
    db $51, $4f, $42, $4b, $44, $51, $45, $ef, $ee, $b6, $62, $24, $4b, $44, $42, $4f
    db $65, $f7, $f0
TextStr_43_637f:           ; id $0134
    ; "The Gate is shut tight."
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_43_6399:           ; id $0135
    ; "The Gate is shut tight."
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_43_63b3:           ; id $0136
    ; "The Gate is shut tight."
    db $37, $45, $42, $62, $2a, $3e, $51, $42, $62, $46, $50, $62, $50, $45, $52, $51
    db $ef, $ee, $51, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_43_63cd:           ; id $0137
    ; "[HERO] looked into the barrel. / Something's engraved on the / barrel. / :Warubou was here."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $3f, $3e, $4f, $4f, $42, $49, $5f, $fa, $f7, $ef, $ee, $36, $4c
    db $4a, $42, $51, $45, $46, $4b, $44, $68, $ef, $ee, $42, $4b, $44, $4f, $3e, $53
    db $42, $41, $62, $4c, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $3f, $3e, $4f
    db $4f, $42, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $f3, $a3, $3a, $3e, $4f, $52
    db $3f, $4c, $52, $62, $54, $3e, $50, $ef, $ee, $45, $42, $4f, $42, $5f, $f7, $f0
TextStr_43_642d:           ; id $0138
    ; "[HERO] looked into the barrel."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $3f, $3e, $4f, $4f, $42, $49, $5f, $fa, $f7, $f0
TextStr_43_644a:           ; id $0139
    ; "Wow,a TinyMedal! But cannot carry / any more. / [HERO] returned the TinyMedal to / the barrel."
    db $3a, $4c, $54, $5e, $3e, $62, $37, $46, $4b, $56, $30, $42, $41, $3e, $49, $63
    db $ef, $ee, $25, $52, $51, $62, $40, $3e, $4b, $4b, $4c, $51, $62, $40, $3e, $4f
    db $4f, $56, $fa, $f7, $ef, $ee, $3e, $4b, $56, $62, $4a, $4c, $4f, $42, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $ef
    db $ee, $51, $45, $42, $62, $37, $46, $4b, $56, $30, $42, $41, $3e, $49, $62, $51
    db $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $3f, $3e, $4f, $4f, $42, $49, $5f
    db $ef, $ee, $f7, $f0
TextStr_43_64ae:           ; id $013A
    ; "[HERO] looked into the barrel. / Nothing in it."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $3f, $3e, $4f, $4f, $42, $49, $5f, $fa, $f7, $ef, $ee, $31, $4c
    db $51, $45, $46, $4b, $44, $62, $46, $4b, $62, $46, $51, $5f, $ef, $ee, $f7, $f0
TextStr_43_64de:           ; id $013B
    ; "[HERO] looked into the barrel. / A monster is sleeping / peacefully there."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $3f, $3e, $4f, $4f, $42, $49, $5f, $fa, $f7, $ef, $ee, $24, $62
    db $4a, $4c, $4b, $50, $51, $42, $4f, $62, $46, $50, $ef, $ee, $50, $49, $42, $42
    db $4d, $46, $4b, $44, $fa, $f7, $ef, $ee, $4d, $42, $3e, $40, $42, $43, $52, $49
    db $49, $56, $62, $51, $45, $42, $4f, $42, $5f, $ef, $ee, $f7, $f0
TextStr_43_652b:           ; id $013C
    ; "[HERO] looked in the treasure chest / It was empty."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $62, $51, $45, $42, $ef
    db $ee, $51, $4f, $42, $3e, $50, $52, $4f, $42, $62, $40, $45, $42, $50, $51, $fa
    db $f7, $ef, $ee, $2c, $51, $62, $54, $3e, $50, $62, $42, $4a, $4d, $51, $56, $5f
    db $ef, $ee, $f7, $f0
TextStr_43_655f:           ; id $013D
    ; "*:Have you been using the / Bookmark? / *:It's very useful. / *:I saw one in the Bazaar before / but I don't know if they still / have it."
    db $ea, $9f, $a3, $2b, $3e, $53, $42, $62, $56, $4c, $52, $62, $3f, $42, $42, $4b
    db $ef, $ee, $52, $50, $46, $4b, $44, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $25
    db $4c, $4c, $48, $4a, $3e, $4f, $48, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $51, $68, $62, $53, $42, $4f, $56, $ef, $ee, $52, $50, $42, $43, $52, $49
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $50, $3e, $54, $62, $4c, $4b, $42
    db $62, $46, $4b, $ef, $ee, $51, $45, $42, $62, $25, $3e, $57, $3e, $3e, $4f, $62
    db $3f, $42, $43, $4c, $4f, $42, $fa, $f7, $ef, $ee, $3f, $52, $51, $62, $2c, $62
    db $41, $4c, $4b, $67, $62, $48, $4b, $4c, $54, $ef, $ee, $46, $43, $62, $51, $45
    db $42, $56, $62, $50, $51, $46, $49, $49, $fa, $f7, $ef, $ee, $45, $3e, $53, $42
    db $62, $46, $51, $5f, $ef, $ee, $f7, $f0
TextStr_43_65f7:           ; id $013E
    ; "*:Uuu Hmm... / *:I wonder who'll win this year... / *:I have no idea. uuu."
    db $ea, $9f, $a3, $38, $52, $52, $62, $2b, $4a, $4a, $5f, $5f, $5f, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $54, $45
    db $4c, $66, $49, $ef, $ee, $54, $46, $4b, $62, $51, $45, $46, $50, $62, $56, $42
    db $3e, $4f, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $3e, $53
    db $42, $62, $4b, $4c, $62, $46, $41, $42, $3e, $5f, $ef, $ee, $52, $52, $52, $5f
    db $f7, $f0
TextStr_43_6649:           ; id $013F
    ; "*:How many times do I have to say / it?! I don't wanna go back!"
    db $eb, $9f, $a3, $2b, $4c, $54, $62, $4a, $3e, $4b, $56, $62, $51, $46, $4a, $42
    db $50, $ef, $ee, $41, $4c, $62, $2c, $62, $45, $3e, $53, $42, $62, $51, $4c, $62
    db $50, $3e, $56, $fa, $f7, $ef, $ee, $46, $51, $64, $63, $62, $2c, $62, $41, $4c
    db $4b, $67, $62, $54, $3e, $4b, $4b, $3e, $ef, $ee, $44, $4c, $62, $3f, $3e, $40
    db $48, $63, $f7, $f0
TextStr_43_668d:           ; id $0140
    ; "King:Well done, [HERO]! / You beat another monster! / *:It's amazing how a young master / like you can even win."
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $5e
    db $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $3c, $4c, $52, $62, $3f, $42, $3e, $51
    db $62, $3e, $4b, $4c, $51, $45, $42, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $5c, $50, $62, $3e, $4a, $3e
    db $57, $46, $4b, $44, $62, $45, $4c, $54, $ef, $ee, $3e, $62, $56, $4c, $52, $4b
    db $44, $62, $4a, $3e, $50, $51, $42, $4f, $fa, $f7, $ef, $ee, $49, $46, $48, $42
    db $62, $56, $4c, $52, $62, $40, $3e, $4b, $ef, $ee, $42, $53, $42, $4b, $62, $54
    db $46, $4b, $5f, $f7, $f0
TextStr_43_6702:           ; id $0141
    ; "*:Oh...King..."
    db $eb, $9f, $a3, $32, $45, $5f, $5f, $5f, $2e, $46, $4b, $44, $5f, $5f, $5f, $ef
    db $ee, $f7, $f0
TextStr_43_6715:           ; id $0142
    ; "King:Train hard! You're dismissed. / King:Busy! Busy! Busy! Busy!"
    db $ea, $2e, $46, $4b, $44, $a3, $37, $4f, $3e, $46, $4b, $62, $45, $3e, $4f, $41
    db $63, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $41, $46, $50, $4a, $46, $50, $50
    db $42, $41, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50, $56
    db $63, $62, $25, $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $62, $25
    db $52, $50, $56, $63, $f7, $f0
TextStr_43_675b:           ; id $0143
    ; "Empty"
    db $ea, $28, $4a, $4d, $51, $56, $ef, $ee, $f7, $f0
TextStr_43_6765:           ; id $0144
    ; "*:Thanks [HERO]! For bringing the / medals! / *:I'll open the Travelers' Gate / in return! / *:The man hid it somewhere... / Where is it? / ..."
    db $eb, $9f, $a3, $37, $45, $3e, $4b, $48, $50, $62, $f6, $63, $ef, $ee, $29, $4c
    db $4f, $62, $3f, $4f, $46, $4b, $44, $46, $4b, $44, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $4a, $42, $41, $3e, $49, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $2c, $66, $49, $62, $4c, $4d, $42, $4b, $62, $51, $45, $42, $ef, $ee, $37
    db $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $fa, $f7
    db $ef, $ee, $46, $4b, $62, $4f, $42, $51, $52, $4f, $4b, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $37, $45, $42, $62, $4a, $3e, $4b, $62, $45, $46, $41, $62
    db $46, $51, $ef, $ee, $50, $4c, $4a, $42, $54, $45, $42, $4f, $42, $5f, $5f, $5f
    db $fa, $f7, $ef, $ee, $3a, $45, $42, $4f, $42, $62, $46, $50, $62, $46, $51, $64
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $43, $46, $4b, $41
    db $62, $46, $51, $5f, $ef, $ee, $26, $4c, $4a, $42, $62, $3f, $3e, $40, $48, $62
    db $49, $3e, $51, $42, $4f, $63, $f7, $f0
TextStr_43_681d:           ; id $0145
    ; "*:I found it! A big trial's / waiting for ya behind the gate."
    db $eb, $9f, $a3, $2c, $62, $43, $4c, $52, $4b, $41, $62, $46, $51, $63, $ef, $ee
    db $24, $62, $3f, $46, $44, $62, $51, $4f, $46, $3e, $49, $68, $fa, $f7, $ef, $ee
    db $54, $3e, $46, $51, $46, $4b, $44, $62, $43, $4c, $4f, $62, $56, $3e, $ef, $ee
    db $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $62, $44, $3e, $51, $42, $5f
    db $f7, $f0
TextStr_43_685f:           ; id $0146
    ; "Watabou:Right on! [HERO]! / I'll take you back to the castle!"
    db $eb, $3a, $3e, $51, $3e, $3f, $4c, $52, $a3, $35, $46, $44, $45, $51, $ef, $ee
    db $4c, $4b, $63, $62, $f6, $63, $fa, $f7, $ef, $ee, $2c, $66, $49, $62, $51, $3e
    db $48, $42, $62, $56, $4c, $52, $62, $3f, $3e, $40, $48, $ef, $ee, $51, $4c, $62
    db $51, $45, $42, $62, $40, $3e, $50, $51, $49, $42, $63, $f7, $f0
TextStr_43_689c:           ; id $0147
    ; "King:Oh [HERO]! I heard you / survived G class! / King:Well done! You're not b... / Never mind!"
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $2c, $62, $45
    db $42, $3e, $4f, $41, $62, $56, $4c, $52, $fa, $f7, $ef, $ee, $50, $52, $4f, $53
    db $46, $53, $42, $41, $62, $2a, $62, $40, $49, $3e, $50, $50, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b
    db $42, $63, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $4b, $4c, $51, $62, $3f, $5f
    db $5f, $5f, $fa, $f7, $ef, $ee, $31, $42, $53, $42, $4f, $62, $4a, $46, $4b, $41
    db $63, $ef, $ee, $f7, $f0
TextStr_43_6901:           ; id $0148
    ; "*:How are you, King of GreatTree? / *:I realized that you are the host / this time. / *:As the host, I hope you will / fight with honor!"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $3e, $4f, $42, $62, $56, $4c, $52, $5e, $ef
    db $ee, $2e, $46, $4b, $44, $62, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $37, $4f
    db $42, $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $4f, $42, $3e, $49, $46
    db $57, $42, $41, $62, $51, $45, $3e, $51, $ef, $ee, $56, $4c, $52, $62, $3e, $4f
    db $42, $62, $51, $45, $42, $62, $45, $4c, $50, $51, $fa, $f7, $ef, $ee, $51, $45
    db $46, $50, $62, $51, $46, $4a, $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $24, $50, $62, $51, $45, $42, $62, $45, $4c, $50, $51, $5e, $ef, $ee, $2c, $62
    db $45, $4c, $4d, $42, $62, $56, $4c, $52, $62, $54, $46, $49, $49, $fa, $f7, $ef
    db $ee, $43, $46, $44, $45, $51, $62, $54, $46, $51, $45, $62, $45, $4c, $4b, $4c
    db $4f, $63, $ef, $ee, $f7, $f0
TextStr_43_6997:           ; id $0149
    ; "*:Oh, what a cute little child. / *:Were you playing with the King? / I am the King of GreatLog."
    db $ea, $9f, $a3, $32, $45, $5e, $62, $54, $45, $3e, $51, $62, $3e, $62, $40, $52
    db $51, $42, $ef, $ee, $49, $46, $51, $51, $49, $42, $62, $40, $45, $46, $49, $41
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $42, $4f, $42, $62, $56, $4c, $52, $62
    db $4d, $49, $3e, $56, $46, $4b, $44, $ef, $ee, $54, $46, $51, $45, $62, $51, $45
    db $42, $62, $2e, $46, $4b, $44, $64, $fa, $f7, $ef, $ee, $2c, $62, $3e, $4a, $62
    db $51, $45, $42, $62, $2e, $46, $4b, $44, $62, $4c, $43, $ef, $ee, $2a, $4f, $42
    db $3e, $51, $2f, $4c, $44, $5f, $f7, $f0
TextStr_43_69ff:           ; id $014A
    ; "King of GreatLog: King of GreatTree, / it's going to be a quick battle. / King of GreatLog: Ha Ha Ha Ha Ha!"
    db $ea, $2e, $46, $4b, $44, $62, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $2f, $4c
    db $44, $a3, $ef, $ee, $2e, $46, $4b, $44, $62, $4c, $43, $62, $2a, $4f, $42, $3e
    db $51, $37, $4f, $42, $42, $5e, $fa, $f7, $ef, $ee, $46, $51, $68, $62, $44, $4c
    db $46, $4b, $44, $62, $51, $4c, $62, $3f, $42, $62, $3e, $ef, $ee, $4e, $52, $46
    db $40, $48, $62, $3f, $3e, $51, $51, $49, $42, $5f, $fa, $f7, $ef, $ee, $2e, $46
    db $4b, $44, $62, $4c, $43, $62, $2a, $4f, $42, $3e, $51, $2f, $4c, $44, $a3, $ef
    db $ee, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $62, $2b, $3e, $63
    db $f7, $f0
TextStr_43_6a71:           ; id $014B
    ; "King:Argh, we will see who has / the last laugh! / King:[HERO]! You must win! / King:I'll open the Room of Villager / & Talisman as a reward..."
    db $ea, $2e, $46, $4b, $44, $a3, $24, $4f, $44, $45, $5e, $62, $54, $42, $ef, $ee
    db $54, $46, $49, $49, $62, $50, $42, $42, $62, $54, $45, $4c, $62, $45, $3e, $50
    db $fa, $f7, $ef, $ee, $51, $45, $42, $62, $49, $3e, $50, $51, $62, $49, $3e, $52
    db $44, $45, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $f6, $63
    db $ef, $ee, $3c, $4c, $52, $62, $4a, $52, $50, $51, $62, $54, $46, $4b, $63, $fa
    db $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $66, $49, $62, $4c, $4d, $42, $4b
    db $62, $51, $45, $42, $ef, $ee, $35, $4c, $4c, $4a, $62, $4c, $43, $62, $39, $46
    db $49, $49, $3e, $44, $42, $4f, $fa, $f7, $ef, $ee, $b6, $62, $37, $3e, $49, $46
    db $50, $4a, $3e, $4b, $62, $3e, $50, $62, $3e, $ef, $ee, $4f, $42, $54, $3e, $4f
    db $41, $5f, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $2c, $51, $66, $49, $62
    db $3f, $42, $ef, $ee, $52, $50, $42, $43, $52, $49, $62, $43, $4c, $4f, $62, $56
    db $4c, $52, $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42
    db $62, $50, $51, $4f, $4c, $4b, $44, $42, $4f, $ef, $ee, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $62, $51, $45, $42, $4f, $42, $5f, $fa, $f7, $ef, $ee, $2e, $46
    db $4b, $44, $a3, $3c, $4c, $52, $69, $42, $ef, $ee, $41, $46, $50, $4a, $46, $50
    db $50, $42, $41, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $50
    db $56, $63, $62, $25, $52, $50, $56, $63, $ef, $ee, $25, $52, $50, $56, $63, $f7
    db $f0
TextStr_43_6b82:           ; id $014C
    ; "*:The Room of Villager & / Talisman is in the Travelers' / Chamber. / *:You will have to defeat your / rivals in the arena. / *:If you win, ..."
    db $ea, $9f, $a3, $37, $45, $42, $62, $35, $4c, $4c, $4a, $62, $4c, $43, $ef, $ee
    db $39, $46, $49, $49, $3e, $44, $42, $4f, $62, $b6, $fa, $f7, $ef, $ee, $37, $3e
    db $49, $46, $50, $4a, $3e, $4b, $62, $46, $50, $62, $46, $4b, $ef, $ee, $51, $45
    db $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $fa, $f7, $ef, $ee
    db $26, $45, $3e, $4a, $3f, $42, $4f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $3c, $4c, $52, $62, $54, $46, $49, $49, $62, $45, $3e, $53, $42, $62, $51, $4c
    db $ef, $ee, $41, $42, $43, $42, $3e, $51, $62, $56, $4c, $52, $4f, $fa, $f7, $ef
    db $ee, $4f, $46, $53, $3e, $49, $50, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee
    db $3e, $4f, $42, $4b, $3e, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $43, $62, $56
    db $4c, $52, $62, $54, $46, $4b, $5e, $ef, $ee, $56, $4c, $52, $66, $49, $62, $3f
    db $42, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $4f, $42, $4d, $4f, $42, $50, $42
    db $4b, $51, $3e, $51, $46, $53, $42, $ef, $ee, $4c, $43, $62, $4c, $52, $4f, $62
    db $48, $46, $4b, $44, $41, $4c, $4a, $fa, $f7, $ef, $ee, $9f, $a3, $3e, $51, $62
    db $51, $45, $42, $62, $36, $51, $3e, $4f, $4f, $56, $ef, $ee, $31, $46, $44, $45
    db $51, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42, $4b, $51, $63, $f7, $f0
TextStr_43_6c71:           ; id $014D
    ; "King:Oh [HERO]! You beat the / Dragon! / King:You're better than you look... / King:There are millions of / monsters behind the Travelers' /..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $27, $4f, $3e
    db $44, $4c, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c
    db $4c, $52, $69, $42, $62, $3f, $42, $51, $51, $42, $4f, $ef, $ee, $51, $45, $3e
    db $4b, $62, $56, $4c, $52, $62, $49, $4c, $4c, $48, $5f, $5f, $5f, $fa, $f7, $ef
    db $ee, $2e, $46, $4b, $44, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef
    db $ee, $4a, $46, $49, $49, $46, $4c, $4b, $50, $62, $4c, $43, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42, $45, $46, $4b, $41, $ef
    db $ee, $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $fa
    db $f7, $ef, $ee, $2a, $3e, $51, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_43_6d0e:           ; id $014E
    ; "King:Well maybe I'm exaggerating a / little, but it's up to you [HERO]! / King:Use the Vault & Library / well. / King:You're dismissed! / Ki..."
    db $ea, $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $4a, $3e, $56, $3f, $42
    db $ef, $ee, $2c, $6a, $62, $42, $55, $3e, $44, $44, $42, $4f, $3e, $51, $46, $4b
    db $44, $62, $3e, $fa, $f7, $ef, $ee, $49, $46, $51, $51, $49, $42, $5e, $62, $3f
    db $52, $51, $62, $46, $51, $68, $ef, $ee, $52, $4d, $62, $51, $4c, $62, $56, $4c
    db $52, $62, $f6, $63, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $38, $50, $42
    db $62, $51, $45, $42, $ef, $ee, $39, $3e, $52, $49, $51, $62, $b6, $62, $2f, $46
    db $3f, $4f, $3e, $4f, $56, $fa, $f7, $ef, $ee, $54, $42, $49, $49, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $3c, $4c, $52, $69, $42, $ef, $ee
    db $41, $46, $50, $4a, $46, $50, $50, $42, $41, $63, $fa, $f7, $ef, $ee, $2e, $46
    db $4b, $44, $a3, $25, $52, $50, $56, $63, $62, $25, $52, $50, $56, $63, $ef, $ee
    db $25, $52, $50, $56, $63, $f7, $f0
TextStr_43_6db5:           ; id $014F
    ; "[HERO] returned the diary to the / bookshelf."
    db $f6, $62, $4f, $42, $51, $52, $4f, $4b, $42, $41, $ef, $ee, $51, $45, $42, $62
    db $41, $46, $3e, $4f, $56, $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee
    db $3f, $4c, $4c, $48, $50, $45, $42, $49, $43, $5f, $ef, $ee, $f7, $f0
TextStr_43_6de3:           ; id $0150
    ; "King:Oh [HERO]! You beat CopyCat! / King:CopyCat loves to imitate / everything. / King:But nobody can imitate my / regal character."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $26, $4c, $4d, $56, $26, $3e, $51, $63, $fa, $f7
    db $ef, $ee, $2e, $46, $4b, $44, $a3, $26, $4c, $4d, $56, $26, $3e, $51, $62, $49
    db $4c, $53, $42, $50, $ef, $ee, $51, $4c, $62, $46, $4a, $46, $51, $3e, $51, $42
    db $fa, $f7, $ef, $ee, $42, $53, $42, $4f, $56, $51, $45, $46, $4b, $44, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $2e, $46, $4b, $44, $a3, $25, $52, $51, $62, $4b, $4c
    db $3f, $4c, $41, $56, $ef, $ee, $40, $3e, $4b, $62, $46, $4a, $46, $51, $3e, $51
    db $42, $62, $4a, $56, $fa, $f7, $ef, $ee, $4f, $42, $44, $3e, $49, $62, $40, $45
    db $3e, $4f, $3e, $40, $51, $42, $4f, $5f, $ef, $ee, $f7, $f0
TextStr_43_6e6f:           ; id $0151
    ; "King:Oh [HERO]! You beat Golem! / King:Well done, considering your / size! / King:There are millions of / monsters behind the Travelers' / G..."
    db $ea, $2e, $46, $4b, $44, $a3, $32, $45, $62, $f6, $63, $ef, $ee, $3c, $4c, $52
    db $62, $3f, $42, $3e, $51, $62, $2a, $4c, $49, $42, $4a, $63, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $3a, $42, $49, $49, $62, $41, $4c, $4b, $42, $5e, $ef
    db $ee, $40, $4c, $4b, $50, $46, $41, $42, $4f, $46, $4b, $44, $62, $56, $4c, $52
    db $4f, $fa, $f7, $ef, $ee, $50, $46, $57, $42, $63, $ef, $ee, $fa, $f7, $ef, $ee
    db $2e, $46, $4b, $44, $a3, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42, $ef, $ee
    db $4a, $46, $49, $49, $46, $4c, $4b, $50, $62, $4c, $43, $fa, $f7, $ef, $ee, $4a
    db $4c, $4b, $50, $51, $42, $4f, $50, $62, $3f, $42, $45, $46, $4b, $41, $ef, $ee
    db $51, $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $fa, $f7
    db $ef, $ee, $2a, $3e, $51, $42, $50, $5f, $ef, $ee, $f7, $f0
TextStr_43_6f0b:           ; id $0152
    ; "*:Are you familiar with the Gate of / Villager? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $39, $46, $49, $49, $3e, $44, $42
    db $4f, $64, $ef, $ee, $ff, $f0
TextStr_43_6f41:           ; id $0153
    ; "*:Dragon loves girls.It carried / a princess away & nobody knows what / happened after that. / *:It is an old fairy tale."
    db $eb, $9f, $a3, $27, $4f, $3e, $44, $4c, $4b, $62, $49, $4c, $53, $42, $50, $ef
    db $ee, $44, $46, $4f, $49, $50, $5f, $2c, $51, $62, $40, $3e, $4f, $4f, $46, $42
    db $41, $fa, $f7, $ef, $ee, $3e, $62, $4d, $4f, $46, $4b, $40, $42, $50, $50, $62
    db $3e, $54, $3e, $56, $62, $b6, $ef, $ee, $4b, $4c, $3f, $4c, $41, $56, $62, $48
    db $4b, $4c, $54, $50, $62, $54, $45, $3e, $51, $fa, $f7, $ef, $ee, $45, $3e, $4d
    db $4d, $42, $4b, $42, $41, $62, $3e, $43, $51, $42, $4f, $ef, $ee, $51, $45, $3e
    db $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $62, $46, $50, $62, $3e, $4b
    db $62, $4c, $49, $41, $ef, $ee, $43, $3e, $46, $4f, $56, $62, $51, $3e, $49, $42
    db $5f, $f7, $f0
TextStr_43_6fc4:           ; id $0154
    ; "*:Are you familiar with the Gate of / Talisman? [YES/NO]"
    db $eb, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $43, $3e, $4a, $46, $49
    db $46, $3e, $4f, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $62, $2a, $3e
    db $51, $42, $62, $4c, $43, $fa, $f7, $ef, $ee, $37, $3e, $49, $46, $50, $4a, $3e
    db $4b, $64, $ef, $ee, $ff, $f0
TextStr_43_6ffa:           ; id $0155
    ; "*:I see...Hm.."
    db $eb, $9f, $a3, $2c, $62, $50, $42, $42, $5f, $5f, $5f, $2b, $4a, $5f, $5f, $ef
    db $ee, $f7, $f0
TextStr_43_700d:           ; id $0156
    ; "*:The stone guard fell asleep from / the flute & became a mountain. / *:These words were written on a wall / in an ancient city."
    db $eb, $9f, $a3, $37, $45, $42, $62, $50, $51, $4c, $4b, $42, $62, $44, $52, $3e
    db $4f, $41, $ef, $ee, $43, $42, $49, $49, $62, $3e, $50, $49, $42, $42, $4d, $62
    db $43, $4f, $4c, $4a, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $43, $49, $52, $51
    db $42, $62, $b6, $ef, $ee, $3f, $42, $40, $3e, $4a, $42, $62, $3e, $62, $4a, $4c
    db $52, $4b, $51, $3e, $46, $4b, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42
    db $50, $42, $62, $54, $4c, $4f, $41, $50, $62, $54, $42, $4f, $42, $ef, $ee, $54
    db $4f, $46, $51, $51, $42, $4b, $62, $4c, $4b, $62, $3e, $62, $54, $3e, $49, $49
    db $fa, $f7, $ef, $ee, $46, $4b, $62, $3e, $4b, $62, $3e, $4b, $40, $46, $42, $4b
    db $51, $ef, $ee, $40, $46, $51, $56, $5f, $f7, $f0
TextStr_43_7097:           ; id $0157
    ; "*:Who do you think you are! What? / You're a master? / *:You look like a wimp. I won't let / you pass!"
    db $eb, $9f, $a3, $3a, $45, $4c, $62, $41, $4c, $62, $56, $4c, $52, $62, $51, $45
    db $46, $4b, $48, $ef, $ee, $56, $4c, $52, $62, $3e, $4f, $42, $63, $62, $3a, $45
    db $3e, $51, $64, $fa, $f7, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $3e, $62, $4a
    db $3e, $50, $51, $42, $4f, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c
    db $52, $62, $49, $4c, $4c, $48, $62, $49, $46, $48, $42, $62, $3e, $ef, $ee, $54
    db $46, $4a, $4d, $5f, $62, $2c, $62, $54, $4c, $4b, $67, $62, $49, $42, $51, $fa
    db $f7, $ef, $ee, $56, $4c, $52, $62, $4d, $3e, $50, $50, $63, $ef, $ee, $f7, $f0
TextStr_43_7107:           ; id $0158
    ; "*:Almost there to the bottom! / *:What is down there?"
    db $ea, $9f, $a3, $24, $49, $4a, $4c, $50, $51, $62, $51, $45, $42, $4f, $42, $ef
    db $ee, $51, $4c, $62, $51, $45, $42, $62, $3f, $4c, $51, $51, $4c, $4a, $63, $fa
    db $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e, $51, $62, $46, $50, $62, $41, $4c, $54
    db $4b, $ef, $ee, $51, $45, $42, $4f, $42, $64, $f7, $f0
TextStr_43_7142:           ; id $0159
    ; "*:{AC} is added to the monster level / when it fully grows. / *:I read it in the book from the / library but I don't really know."
    db $ea, $9f, $a3, $ac, $62, $46, $50, $62, $3e, $41, $41, $42, $41, $62, $51, $4c
    db $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $49, $42
    db $53, $42, $49, $fa, $f7, $ef, $ee, $54, $45, $42, $4b, $62, $46, $51, $62, $43
    db $52, $49, $49, $56, $ef, $ee, $44, $4f, $4c, $54, $50, $5f, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $62, $4f, $42, $3e, $41, $62, $46, $51, $62, $46, $4b, $62, $51
    db $45, $42, $ef, $ee, $3f, $4c, $4c, $48, $62, $43, $4f, $4c, $4a, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $49, $46, $3f, $4f, $3e, $4f, $56, $62, $3f, $52, $51
    db $62, $2c, $ef, $ee, $41, $4c, $4b, $67, $62, $4f, $42, $3e, $49, $49, $56, $62
    db $48, $4b, $4c, $54, $5f, $f7, $f0
TextStr_43_71c9:           ; id $015A
    ; "*:Enter here to the Vault."
    db $ea, $9f, $a3, $28, $4b, $51, $42, $4f, $62, $45, $42, $4f, $42, $62, $51, $4c
    db $ef, $ee, $51, $45, $42, $62, $39, $3e, $52, $49, $51, $5f, $f7, $f0
TextStr_43_71e7:           ; id $015B
    ; "*:The Bazaar's to the right!"
    db $eb, $9f, $a3, $37, $45, $42, $62, $25, $3e, $57, $3e, $3e, $4f, $68, $62, $51
    db $4c, $ef, $ee, $51, $45, $42, $62, $4f, $46, $44, $45, $51, $63, $f7, $f0
TextStr_43_7206:           ; id $015C
    ; "*:Hello, welcome to the Bazaar!"
    db $eb, $9f, $a3, $2b, $42, $49, $49, $4c, $5e, $62, $54, $42, $49, $40, $4c, $4a
    db $42, $ef, $ee, $51, $4c, $62, $51, $45, $42, $62, $25, $3e, $57, $3e, $3e, $4f
    db $63, $f7, $f0
TextStr_43_7229:           ; id $015D
    ; "[HERO] looked into the jar. / But there was nothing in it."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $25, $52, $51, $62, $51
    db $45, $42, $4f, $42, $62, $54, $3e, $50, $ef, $ee, $4b, $4c, $51, $45, $46, $4b
    db $44, $62, $46, $4b, $62, $46, $51, $5f, $f7, $f0
TextStr_43_7263:           ; id $015E
    ; "[HERO] looked into the jar. / It was filled with things from the / item shop."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $62, $46, $4b, $51, $4c, $ef, $ee, $51
    db $45, $42, $62, $47, $3e, $4f, $5f, $fa, $f7, $ef, $ee, $2c, $51, $62, $54, $3e
    db $50, $62, $43, $46, $49, $49, $42, $41, $62, $54, $46, $51, $45, $ef, $ee, $51
    db $45, $46, $4b, $44, $50, $62, $43, $4f, $4c, $4a, $62, $51, $45, $42, $fa, $f7
    db $ef, $ee, $46, $51, $42, $4a, $62, $50, $45, $4c, $4d, $5f, $ef, $ee, $f7, $f0
TextStr_43_72b3:           ; id $015F
    ; "*:Rumor has it that the / BeastTail is an useful item. / *:It points to the direction of the / mystic hole behind the / Travelers' Gates! / ..."
    db $eb, $9f, $a3, $35, $52, $4a, $4c, $4f, $62, $45, $3e, $50, $62, $46, $51, $ef
    db $ee, $51, $45, $3e, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $25, $42, $3e
    db $50, $51, $37, $3e, $46, $49, $62, $46, $50, $62, $3e, $4b, $ef, $ee, $52, $50
    db $42, $43, $52, $49, $62, $46, $51, $42, $4a, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $2c, $51, $62, $4d, $4c, $46, $4b, $51, $50, $62, $51, $4c, $62, $51, $45, $42
    db $ef, $ee, $41, $46, $4f, $42, $40, $51, $46, $4c, $4b, $62, $4c, $43, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $4a, $56, $50, $51, $46, $40, $62, $45, $4c, $49
    db $42, $ef, $ee, $3f, $42, $45, $46, $4b, $41, $62, $51, $45, $42, $fa, $f7, $ef
    db $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42
    db $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42, $3e, $4f
    db $41, $62, $3e, $49, $49, $62, $51, $45, $42, $ef, $ee, $4a, $3e, $50, $51, $42
    db $4f, $50, $62, $51, $3e, $48, $42, $62, $46, $51, $62, $4c, $4b, $fa, $f7, $ef
    db $ee, $51, $45, $42, $46, $4f, $62, $47, $4c, $52, $4f, $4b, $42, $56, $50, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $56, $62, $41, $4c, $4b, $67
    db $62, $56, $4c, $52, $ef, $ee, $51, $4f, $56, $62, $46, $51, $64, $f7, $f0
TextStr_43_73a2:           ; id $0160
    ; "*:During this season, everyone / speaks only of the Tournament. / *:GreatTree is the host this time! / *:We need to win!"
    db $eb, $9f, $a3, $27, $52, $4f, $46, $4b, $44, $62, $51, $45, $46, $50, $ef, $ee
    db $50, $42, $3e, $50, $4c, $4b, $5e, $62, $42, $53, $42, $4f, $56, $4c, $4b, $42
    db $fa, $f7, $ef, $ee, $50, $4d, $42, $3e, $48, $50, $62, $4c, $4b, $49, $56, $62
    db $4c, $43, $ef, $ee, $51, $45, $42, $62, $37, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2a, $4f, $42, $3e, $51, $37, $4f
    db $42, $42, $62, $46, $50, $62, $51, $45, $42, $ef, $ee, $45, $4c, $50, $51, $62
    db $51, $45, $46, $50, $62, $51, $46, $4a, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $3a, $42, $62, $4b, $42, $42, $41, $62, $51, $4c, $62, $54, $46, $4b, $63, $ef
    db $ee, $f7, $f0
TextStr_43_7425:           ; id $0161
    ; "*:There were stores here at the / last Starry Night Tournament."
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $42, $4f, $42, $ef, $ee, $50
    db $51, $4c, $4f, $42, $50, $62, $45, $42, $4f, $42, $62, $3e, $51, $62, $51, $45
    db $42, $fa, $f7, $ef, $ee, $49, $3e, $50, $51, $62, $36, $51, $3e, $4f, $4f, $56
    db $62, $31, $46, $44, $45, $51, $ef, $ee, $37, $4c, $52, $4f, $4b, $3e, $4a, $42
    db $4b, $51, $5f, $f7, $f0
TextStr_43_746a:           ; id $0162
    ; "*:The store there is terrible! / He won't sell anything."
    db $ea, $9f, $a3, $37, $45, $42, $62, $50, $51, $4c, $4f, $42, $62, $51, $45, $42
    db $4f, $42, $ef, $ee, $46, $50, $62, $51, $42, $4f, $4f, $46, $3f, $49, $42, $63
    db $fa, $f7, $ef, $ee, $2b, $42, $62, $54, $4c, $4b, $67, $62, $50, $42, $49, $49
    db $ef, $ee, $3e, $4b, $56, $51, $45, $46, $4b, $44, $5f, $f7, $f0
TextStr_43_74a7:           ; id $0163
    ; "*:You? A master? You're just a kid. / *:Scram! Go home!"
    db $ea, $9f, $a3, $3c, $4c, $52, $64, $62, $24, $62, $4a, $3e, $50, $51, $42, $4f
    db $64, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $47, $52, $50, $51, $62, $3e, $62
    db $48, $46, $41, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $36, $40, $4f, $3e, $4a, $63
    db $62, $2a, $4c, $62, $45, $4c, $4a, $42, $63, $ef, $ee, $f7, $f0
TextStr_43_74e4:           ; id $0164
    ; "*:So, you don't have enough money / to buy items? [YES/NO]"
    db $ea, $9f, $a3, $36, $4c, $5e, $62, $56, $4c, $52, $62, $41, $4c, $4b, $67, $ef
    db $ee, $45, $3e, $53, $42, $62, $42, $4b, $4c, $52, $44, $45, $62, $4a, $4c, $4b
    db $42, $56, $fa, $f7, $ef, $ee, $51, $4c, $62, $3f, $52, $56, $62, $46, $51, $42
    db $4a, $50, $64, $ef, $ee, $ff, $f0
TextStr_43_751b:           ; id $0165
    ; "[HERO] looked in front. / There are some yummy food."
    db $f6, $62, $49, $4c, $4c, $48, $42, $41, $ef, $ee, $46, $4b, $62, $43, $4f, $4c
    db $4b, $51, $5f, $fa, $f7, $ef, $ee, $37, $45, $42, $4f, $42, $62, $3e, $4f, $42
    db $62, $50, $4c, $4a, $42, $ef, $ee, $56, $52, $4a, $4a, $56, $62, $43, $4c, $4c
    db $41, $5f, $f7, $f0
TextStr_43_754f:           ; id $0166
    ; "*:Darn,why can't I start the fire? / *:Hey dude, don't you have some / monster that makes fire? [YES/NO]"
    db $ea, $9f, $a3, $27, $3e, $4f, $4b, $5e, $54, $45, $56, $62, $40, $3e, $4b, $67
    db $ef, $ee, $2c, $62, $50, $51, $3e, $4f, $51, $62, $51, $45, $42, $62, $43, $46
    db $4f, $42, $64, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $42, $56, $62, $41, $52, $41
    db $42, $5e, $62, $41, $4c, $4b, $67, $ef, $ee, $56, $4c, $52, $62, $45, $3e, $53
    db $42, $62, $50, $4c, $4a, $42, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42
    db $4f, $62, $51, $45, $3e, $51, $ef, $ee, $4a, $3e, $48, $42, $50, $62, $43, $46
    db $4f, $42, $64, $ff, $f0
TextStr_43_75b4:           ; id $0167
    ; "*:Can you give me a monster that / makes fire?"
    db $ea, $9f, $a3, $26, $3e, $4b, $62, $56, $4c, $52, $62, $44, $46, $53, $42, $62
    db $4a, $42, $ef, $ee, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $51, $45
    db $3e, $51, $fa, $f7, $ef, $ee, $4a, $3e, $48, $42, $50, $62, $43, $46, $4f, $42
    db $64, $ef, $ee, $f7, $f0
TextStr_43_75e9:           ; id $0168
    ; "*:You don't have one? Come on!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $4c, $4b, $42, $64, $62, $26, $4c, $4a, $42, $62, $4c, $4b, $63, $f7
    db $f0
TextStr_43_760a:           ; id $0169
    ; "*:Oh you have one! Then..."
    db $ea, $9f, $a3, $32, $45, $62, $56, $4c, $52, $62, $45, $3e, $53, $42, $62, $4c
    db $4b, $42, $63, $ef, $ee, $37, $45, $42, $4b, $5f, $5f, $5f, $fa, $f7, $f0
TextStr_43_7629:           ; id $016A
    ; "Can you give us your [INS 00]? [YES/NO]"
    db $ea, $26, $3e, $4b, $62, $56, $4c, $52, $62, $44, $46, $53, $42, $62, $52, $50
    db $ef, $ee, $56, $4c, $52, $4f, $62, $f9, $00, $64, $ff, $f0
TextStr_43_7645:           ; id $016B
    ; "[HERO] gave your [INS 00]!"
    db $f6, $62, $44, $3e, $53, $42, $ef, $ee, $56, $4c, $52, $4f, $62, $f9, $00, $63
    db $fa, $f7, $f0
TextStr_43_7658:           ; id $016C
    ; "*:Wow! No way! / *:Such a thing in a place like this. / *:Go ahead. It's yours. / Thanks for the monster!"
    db $ea, $9f, $a3, $3a, $4c, $54, $63, $62, $31, $4c, $62, $54, $3e, $56, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $36, $52, $40, $45, $62, $3e, $62, $51, $45
    db $46, $4b, $44, $62, $46, $4b, $ef, $ee, $3e, $62, $4d, $49, $3e, $40, $42, $62
    db $49, $46, $48, $42, $62, $51, $45, $46, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $2a, $4c, $62, $3e, $45, $42, $3e, $41, $5f, $ef, $ee, $2c, $51, $68, $62, $56
    db $4c, $52, $4f, $50, $5f, $fa, $f7, $ef, $ee, $37, $45, $3e, $4b, $48, $50, $62
    db $43, $4c, $4f, $62, $51, $45, $42, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $63, $f7, $f0
TextStr_43_76cb:           ; id $016D
    ; "*:Well,too bad..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $5e, $51, $4c, $4c, $62, $3f, $3e, $41, $5f
    db $5f, $5f, $ef, $ee, $f7, $f0
TextStr_43_76e1:           ; id $016E
    ; "*:Well then, can I have [INS 00]? [YES/NO]"
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $51, $45, $42, $4b, $5e, $62, $40, $3e
    db $4b, $ef, $ee, $2c, $62, $45, $3e, $53, $42, $62, $f9, $00, $64, $ff, $f0
TextStr_43_7700:           ; id $016F
    ; "*:Where does this Travelers' Gate / go?"
    db $ea, $9f, $a3, $3a, $45, $42, $4f, $42, $62, $41, $4c, $42, $50, $62, $51, $45
    db $46, $50, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a
    db $3e, $51, $42, $fa, $f7, $ef, $ee, $44, $4c, $64, $ef, $ee, $f7, $f0, $00
; --- END re-sectioned text run (bank $43) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

