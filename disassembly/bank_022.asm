; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $022", ROMX[$4000], BANK[$22]

    db $22 ; Bank number

    ; Cross-bank dispatch table (196 entries)
    ; Called via: ld hl, $22XX / rst $10
    dw SetAnim22_4189                  ; Entry 0
    dw $4190                          ; Entry 1
    dw $4197                          ; Entry 2
    dw $4009                          ; Entry 3 — mode 0 -> table $4009 (mode list $4007)
    dw $419E                          ; Entry 4 — [table $4009]; text $0700 "*:OK! Wait overnight."
    dw $41B7                          ; Entry 5 — text $0701 "*:Then I'll send the egg to the f…"
    dw $41E5                          ; Entry 6 — text $0702 "*:Which egg do you want to hatch?"
    dw $4209                          ; Entry 7 — text $0703 "*:There's no egg!"
    dw $421F                          ; Entry 8 — text $0704 "*:Costs [INS 30]G to hatch it. Ok…"
    dw $4240                          ; Entry 9 — text $0705 "*:OK! Wait overnight."
    dw $4259                          ; Entry 10 — text $0706 "[INS 10] was born. Give it a name."
    dw $427D                          ; Entry 11 — text $0707 "*:I'll send [INS 00] to the farm."
    dw $429C                          ; Entry 12 — text $0708 "*:Take [INS 00] with you now?"
    dw $42B6                          ; Entry 13 — text $0709 "*:Send which one to the farm?"
    dw $42D6                          ; Entry 14 — text $070A "*:That one? Are you sure?"
    dw $42F2                          ; Entry 15 — text $070B "*:I sent [INS 00] to the farm!"
    dw $430F                          ; Entry 16 — text $070C "*:I suspect [INS 20] will be born…"
    dw $435C                          ; Entry 17 — text $070D "*:Oh, you don't have enough money."
    dw $435C                          ; Entry 18 — text $070E "*:Oh, you don't have enough money."
    dw jr_022_4382                    ; Entry 19 — text $070F "*:Take good care of it."
    dw $439E                          ; Entry 20 — text $0710 "*:Welcome! Which class are you re…"
    dw $43D5                          ; Entry 21 — text $0711 "*:Which class are you registering…"
    dw $4403                          ; Entry 22 — text $0712 "*:Too bad. Try again?"
    dw $441B                          ; Entry 23 — text $0713 "*:Better luck next time."
    dw $4437                          ; Entry 24 — text $0714 "*:Are you okay with registering i…"
    dw $446B                          ; Entry 25 — text $0715 "*:Sorry but it seems you don't ha…"
    dw $44A4                          ; Entry 26 — text $0716 "*:What! Are you going to fight wi…"
    dw $44E7                          ; Entry 27 — text $0717 "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 28 — text $0718 "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 29 — text $0719 "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 30 — text $071A "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 31 — text $071B "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 32 — text $071C "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 33 — text $071D "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 34 — text $071E "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 35 — text $071F "*:I'm collecting medals that are …"
    dw $44E7                          ; Entry 36 — text $0720 "*:I'm collecting medals that are …"
    dw $452D                          ; Entry 37 — text $0721 "*:Oh, You have medals. Let me tak…"
    dw $4567                          ; Entry 38 — text $0722 "*:[HERO], you brought a total of …"
    dw $45DA                          ; Entry 39 — text $0723 "*:It's an egg of a ZapBird! I'll …"
    dw $4615                          ; Entry 40 — text $0724 "*:It's an egg of a Trumpeter! I'l…"
    dw $4652                          ; Entry 41 — text $0725 "*:It's an egg of a Spikerous! I'l…"
    dw $468F                          ; Entry 42 — text $0726 "*:It's an egg of a Metabble! I'll…"
    dw $473E                          ; Entry 43 — text $0727 "*:It's a Trumpeter egg! I'll send…"
    dw $4776                          ; Entry 44 — text $0728 "*:It's a ChopClown egg! I'll send…"
    dw $47AE                          ; Entry 45 — text $0729 "*:It's a Spikerous egg! I'll send…"
    dw $47E6                          ; Entry 46 — text $072A "*:It's a Metabble egg! I'll send …"
    dw $4890                          ; Entry 47 — text $072B "*:I'll take it back. It seems you…"
    dw $48FF                          ; Entry 48 — text $072C "*:[HERO], you brought a total of …"
    dw $496B                          ; Entry 49 — text $072D "*:Oh no! Hmmmm. *:I have no more …"
    dw $49DD                          ; Entry 50 — text $072E "*:Thank you [HERO]! You're so kin…"
    dw $49FF                          ; Entry 51 — text $072F "*:Ohh! TinyMedals!"
    dw $4A15                          ; Entry 52 — text $0730 "*:Ah, you brought [INS 00] medal(…"
    dw $4A70                          ; Entry 53 — text $0731 "*:Sorry, I don't have anymore rew…"
    dw $4B0D                          ; Entry 54 — text $0732 "*:[HERO], I want to give you a re…"
    dw $4B7A                          ; Entry 55 — text $0733 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 56 — text $0734 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 57 — text $0735 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 58 — text $0736 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 59 — text $0737 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 60 — text $0738 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 61 — text $0739 "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 62 — text $073A "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 63 — text $073B "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 64 — text $073C "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 65 — text $073D "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 66 — text $073E "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 67 — text $073F "*:You're at the library. Which fa…"
    dw $4B7A                          ; Entry 68 — text $0740 "*:You're at the library. Which fa…"
    dw $4BB9                          ; Entry 69 — text $0741 "*:Anything else to look up?"
    dw $4BD7                          ; Entry 70 — text $0742 "*:You're always welcome."
    dw $4BF2                          ; Entry 71 — text $0743 "*:Look up which monster?"
    dw $4C0D                          ; Entry 72 — text $0744 "*:You haven't caught any from tha…"
    dw $4C44                          ; Entry 73 — text $0745 "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 74 — text $0746 "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 75 — text $0747 "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 76 — text $0748 "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 77 — text $0749 "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 78 — text $074A "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 79 — text $074B "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 80 — text $074C "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 81 — text $074D "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 82 — text $074E "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 83 — text $074F "*:Oh my little [HERO], welcome!"
    dw $4C44                          ; Entry 84 — text $0750 "*:Oh my little [HERO], welcome!"
    dw $4C66                          ; Entry 85 — text $0751 "*:WHAT! Leaving?! Do something!!"
    dw $4C89                          ; Entry 86 — text $0752 "*:Oh! You're leaving so soon. *:C…"
    dw $4CBC                          ; Entry 87 — text $0753 "*:Which egg needs my evaluation?"
    dw $4CDF                          ; Entry 88 — text $0754 "*:Oh! You don't have any eggs."
    dw $4D00                          ; Entry 89 — text $0755 "*:It'll be 20G. Wanna evaluation?…"
    dw $4D4C                          ; Entry 90 — text $0756 "*:Mmm! Cute little egg! *:Talk to…"
    dw $4D8A                          ; Entry 91 — text $0757 "*:Oh! It's a very healthy one. *:…"
    dw $4DD1                          ; Entry 92 — text $0758 "*:Wow! This cutie has lots of pow…"
    dw $4E22                          ; Entry 93 — text $0759 "*:[HERO], don't give this baby aw…"
    dw $4E6A                          ; Entry 94 — text $075A "*:It inherited lots of skills."
    dw $4E8D                          ; Entry 95 — text $075B "*:Oh! It inherited various skills."
    dw $4EB4                          ; Entry 96 — text $075C "*:Wow! Such versatility! It has i…"
    dw $4EF6                          ; Entry 97 — text $075D "*:This baby will grow up very fas…"
    dw $4F1E                          ; Entry 98 — text $075E "*:It'll grow up pretty fast. S.m.…"
    dw $4F50                          ; Entry 99 — text $075F "*:This baby will take some time t…"
    dw $4F85                          ; Entry 100 — text $0760 "*:Hmmm. *:It'll take time to grow…"
    dw $4FEE                          ; Entry 101 — text $0761 "*:It will be vulnerable to enemy …"
    dw $502A                          ; Entry 102 — text $0762 "*:It will be somewhat resistant t…"
    dw $506E                          ; Entry 103 — text $0763 "*:Giggle.. A boy?! Maybe."
    dw $508C                          ; Entry 104 — text $0764 "*:Giggle.. A girl?! Maybe."
    dw $50AB                          ; Entry 105 — text $0765 "*:That's all I can tell you for n…"
    dw $50D3                          ; Entry 106 — text $0766 "*:Which egg needs my blessing?"
    dw $50F4                          ; Entry 107 — text $0767 "*:Oh, you don't have any eggs!"
    dw $5115                          ; Entry 108 — text $0768 "*:It'll be [INS 00]G for a blessi…"
    dw $514B                          ; Entry 109 — text $0769 "*:Oh boy! This baby was already b…"
    dw $517D                          ; Entry 110 — text $076A "*:La la la la la!! Laaaaaaaaaaaaa…"
    dw $51A7                          ; Entry 111 — text $076B "*:Done!"
    dw $51B2                          ; Entry 112 — text $076C "*:I'm sorry, you are short of cas…"
    dw $51D9                          ; Entry 113 — text $076D "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 114 — text $076E "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 115 — text $076F "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 116 — text $0770 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 117 — text $0771 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 118 — text $0772 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 119 — text $0773 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 120 — text $0774 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 121 — text $0775 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 122 — text $0776 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 123 — text $0777 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 124 — text $0778 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 125 — text $0779 "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 126 — text $077A "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 127 — text $077B "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 128 — text $077C "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 129 — text $077D "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 130 — text $077E "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 131 — text $077F "*:I'm the Master Monster Namer. W…"
    dw $51D9                          ; Entry 132 — text $0780 "*:I'm the Master Monster Namer. W…"
    dw $521C                          ; Entry 133 — text $0781 "*:Wanna change your pal's name?"
    dw $523D                          ; Entry 134 — text $0782 "*:Come back when you need me."
    dw $525E                          ; Entry 135 — text $0783 "*:Which one's name do you want to…"
    dw $528E                          ; Entry 136 — text $0784 "*:Hm, this monster used to belong…"
    dw $531C                          ; Entry 137 — text $0785 "*:Are you sure you want to change…"
    dw $534F                          ; Entry 138 — text $0786 "*:How many monsters have you had …"
    dw $534F                          ; Entry 139 — text $0787 "*:How many monsters have you had …"
    dw $534F                          ; Entry 140 — text $0788 "*:How many monsters have you had …"
    dw $534F                          ; Entry 141 — text $0789 "*:How many monsters have you had …"
    dw $534F                          ; Entry 142 — text $078A "*:How many monsters have you had …"
    dw $534F                          ; Entry 143 — text $078B "*:How many monsters have you had …"
    dw $534F                          ; Entry 144 — text $078C "*:How many monsters have you had …"
    dw $534F                          ; Entry 145 — text $078D "*:How many monsters have you had …"
    dw $534F                          ; Entry 146 — text $078E "*:How many monsters have you had …"
    dw $534F                          ; Entry 147 — text $078F "*:How many monsters have you had …"
    dw $534F                          ; Entry 148 — text $0790 "*:How many monsters have you had …"
    dw $53B5                          ; Entry 149 — text $0791 "*:You just started didn't you? *:…"
    dw $53F8                          ; Entry 150 — text $0792 "*:You're still a beginner. Are yo…"
    dw $5434                          ; Entry 151 — text $0793 "*:Have you tried breeding your mo…"
    dw $554B                          ; Entry 152 — text $0794 "*:Finally, you look more like a m…"
    dw $55C1                          ; Entry 153 — text $0795 "*:For the time being, you should …"
    dw $565B                          ; Entry 154 — text $0796 "*:At last you exceeded 50 kinds. …"
    dw $56F8                          ; Entry 155 — text $0797 "*:You have lots of monsters! You'…"
    dw $5732                          ; Entry 156 — text $0798 "*:Great! Over 100 species! *:Nobo…"
    dw $577F                          ; Entry 157 — text $0799 "*:You're amazing! *:You reached t…"
    dw $57E3                          ; Entry 158 — text $079A "*:At last you're challenging a re…"
    dw $589D                          ; Entry 159 — text $079B "*:Unbelievable number of monsters…"
    dw $58FB                          ; Entry 160 — text $079C "*:Ta-da! Congratulations! *:At la…"
    dw $59A0                          ; Entry 161 — text $079D "*:Looking at the Travelers' Gate …"
    dw $59A0                          ; Entry 162 — text $079E "*:Looking at the Travelers' Gate …"
    dw $59A0                          ; Entry 163 — text $079F "*:Looking at the Travelers' Gate …"
    dw $59A0                          ; Entry 164 — text $07A0 "*:Looking at the Travelers' Gate …"
    dw $5A1C                          ; Entry 165 — text $07A1 "*:I wonder where this Travelers' …"
    dw $5A54                          ; Entry 166 — text $07A2 "*:Oh, Master [HERO] Welcome back!…"
    dw $5B0E                          ; Entry 167 — text $07A3 "*:The Room of Joy & Wisdom is to …"
    dw $5BC8                          ; Entry 168 — text $07A4 "*:Oh it's Sir [HERO]! You're at t…"
    dw $5CD0                          ; Entry 169 — text $07A5 "*:Ah it's Master [HERO]! You're a…"
    dw $5DDA                          ; Entry 170 — text $07A6 "*:The path on the right side was …"
    dw $5E2B                          ; Entry 171 — text $07A7 "*:[HERO], congratulations on your…"
    dw $5FA8                          ; Entry 172 — text $07A8 "*:Welcome to the new Chamber of T…"
    dw $617B                          ; Entry 173 — text $07A9 "*:Welcome to the new Chamber of T…"
    dw $634E                          ; Entry 174 — text $07AA "Splat, a FunkyBird is flying abov…"
    dw $6379                          ; Entry 175 — text $07AB "*:I wonder where we monsters came…"
    dw $63BD                          ; Entry 176 — text $07AC "*:The sky is crystal clear! The s…"
    dw $63FD                          ; Entry 177 — text $07AD "*:I wonder if I can be a lone wol…"
    dw $644A                          ; Entry 178 — text $07AE "*:The Starry Night is over!"
    dw $6469                          ; Entry 179 — text $07AF "*:We spent the Starry Night toget…"
    dw $64CF                          ; Entry 180 — text $07B0 "*:Hey you! I fished out a big one!"
    dw $64FA                          ; Entry 181 — text $07B1 "[HERO] looked into the jar. *:A f…"
    dw $653C                          ; Entry 182 — text $07B2 "*:Go down to the stable. Bleat! W…"
    dw $658B                          ; Entry 183 — text $07B3 "*:Go down to the stable. Bleat! K…"
    dw $65C5                          ; Entry 184 — text $07B4 "*:You're at the monster farm, Bao…"
    dw $662C                          ; Entry 185 — text $07B5 "*:Have you met all the monsters? …"
    dw $666D                          ; Entry 186 — text $07B6 "*:My buddy is living behind the G…"
    dw $66D2                          ; Entry 187 — text $07B7 "*:Yippee! Congratulations on your…"
    dw $6705                          ; Entry 188 — text $07B8 "*:Copycopy. I wanna copycopy Wata…"
    dw $673B                          ; Entry 189 — text $07B9 "*:I wanna be with a wonderful mas…"
    dw $6770                          ; Entry 190 — text $07BA "*:ZZZ... there are monsters that …"
    dw $67B5                          ; Entry 191 — text $07BB "*:Did you find all the hidden Tra…"
    dw $6823                          ; Entry 192 — text $07BC "*:Mr. DeadNoble is good at Call!"
    dw $6847                          ; Entry 193 — text $07BD "*:I..I am going to show you a gre…"
    dw $6880                          ; Entry 194 — text $07BE "But nothing happened."
    dw $6898                          ; Entry 195 — text $07BF "*:I'm HammerMan. I am the stronge…"

SetAnim22_4189:
    ld de, $4007
    call CallTextEngine
    ret


    ld de, $4007
    call RunTextHandler
    ret


    call SetAnim22_4189
    call RequestScreenUpdate
    ret


    ld [$a39f], a
    ld [hl-], a
    ld l, $63
    rst $28
    xor $3a
    ld a, $46
    ld d, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld b, c
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
    ld b, l
    ld a, $51
    ld b, b
    ld b, l
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4c
    ld d, b
    ld d, c
    ld d, b
    ld h, d
    ld sp, hl
    jr nc, jr_022_4255

    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, l
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld h, d
    ld [hl-], a
    ld c, b
    ld a, $56
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld l, $63
    rst $28
    xor $3a
    ld a, $46
    ld d, c
    ld h, d
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l

jr_022_4255:
    ld d, c
    ld e, a
    rst $30
    ldh a, [$f9]
    db $10
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $3f
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $2a
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $62
    ld c, e
    ld a, $4a
    ld b, d
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
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
    ld sp, hl
    nop
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld sp, hl
    nop
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $42
    ld c, e
    ld b, c
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld a, $51
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    rst $28
    xor $24
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld sp, hl
    nop
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld h, d
    ld d, b
    ld d, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    rst $28
    xor $f9
    jr nz, jr_022_4382

    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, a
    ld c, e
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld c, d
    ld a, $51
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    ld a, [$f0f7]

jr_022_4382:
    ld [$a39f], a
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $40
    ld a, $4f
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    ld a, [hl-]
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    rst $28
    xor $40
    ld c, c
    ld a, $50
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld b, h
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
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
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld b, h
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    scf
    ld c, h
    ld c, h
    ld h, d
    ccf
    ld a, $41
    ld e, a
    rst $28
    xor $37
    ld c, a
    ld d, [hl]
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    dec h
    ld b, d
    ld d, c
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    rst $28
    xor $4b
    ld b, d
    ld d, l
    ld d, c
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
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
    ld c, h
    ld c, b
    ld a, $56
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, a
    ld b, d
    ld b, h
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld a, [$eff7]
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, e
    ld h, d
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $44
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, d
    ld a, $48
    ld b, d
    ld c, a
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld d, b
    rst $28
    xor $51
    ld b, l
    ld a, $4b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld h, h
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld l, d
    ld h, d
    ld b, b
    ld c, h
    ld c, c
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld b, d
    ld b, c
    ld a, $49
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld a, $4f
    ld b, d
    ld a, [$eff7]
    xor $50
    ld b, b
    ld a, $51
    ld d, c
    ld b, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld a, $49
    ld c, c
    rst $28
    xor $4c
    ld d, e
    ld b, d
    ld c, a
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
    ld a, [$f0f7]
    ld [$a39f], a
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $4a
    ld b, d
    ld b, c
    ld a, $49
    ld d, b
    ld e, a
    ld h, d
    cpl
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    or $5e
    ld h, d
    ld d, [hl]
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
    ld a, $62
    ld d, c
    ld c, h
    ld d, c
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $f9
    nop
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld a, $49
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
    ld d, h
    ld b, [hl]
    ld c, c
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
    ld c, a
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld a, $49
    ld d, b
    rst $28
    xor $42
    ld d, l
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $4b
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
    dec a
    ld a, $4d
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $50
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $4b
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
    scf
    ld c, a
    ld d, d
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $50
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $4b
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
    ld [hl], $4d
    ld b, [hl]
    ld c, b
    ld b, d
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $50
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $4b
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
    jr nc, @+$44

    ld d, c
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $50
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, e
    ld c, h
    ld h, e
    rst $28
    xor $2b
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    ld a, [$eff7]
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
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $43
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
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    scf
    ld c, a
    ld d, d
    ld c, d
    ld c, l
    ld b, d
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld h, $45
    ld c, h
    ld c, l
    ld h, $49
    ld c, h
    ld d, h
    ld c, e
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld [hl], $4d
    ld b, [hl]
    ld c, b
    ld b, d
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    jr nc, @+$44

    ld d, c
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    rst $28
    xor $42
    ld b, h
    ld b, h
    ld h, e
    ld h, d
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
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
    ld h, d
    ld c, e
    ld c, h
    ld h, e
    rst $28
    xor $2b
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    ld a, [$eff7]
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
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $43
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
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $3f
    ld a, $40
    ld c, b
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
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
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
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $51
    ld c, h
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
    xor $4c
    ld d, c
    ld b, l
    ld b, d
    ld c, a
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
    or $5e
    ld h, d
    ld d, [hl]
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
    ld a, $62
    ld d, c
    ld c, h
    ld d, c
    ld a, $49
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $f9
    nop
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld a, $49
    and b
    ld d, b
    and c
    ld e, a
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
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld bc, $eeef
    ld sp, hl
    jr nz, @+$64

    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $54
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld a, $49
    ld d, b
    rst $28
    xor $42
    ld d, l
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, e
    ld c, h
    ld h, e
    rst $28
    xor $2b
    ld c, d
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    ld a, [$eff7]
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
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, a
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, e
    ld c, a
    ld b, d
    ld b, d
    ld a, [$eff7]
    xor $43
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
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    or $63
    rst $28
    xor $3c
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    ld [hl-], a
    ld b, l
    ld b, l
    ld h, e
    ld h, d
    scf
    ld b, [hl]
    ld c, e
    ld d, [hl]
    jr nc, jr_022_4a4f

    ld b, c
    ld a, $49
    ld d, b
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    inc h
    ld b, l
    ld e, [hl]
    ld h, d
    ld d, [hl]
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
    xor $f9
    nop
    ld h, d
    ld c, d
    ld b, d
    ld b, c
    ld a, $49
    and b
    ld d, b
    and c
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $40
    ld d, c
    ld d, d
    ld a, $49
    ld c, c
    ld d, [hl]
    rst $28
    xor $4b
    ld c, h

jr_022_4a4f:
    ld d, c
    ld h, d
    ld a, $62
    ccf
    ld a, $41
    ld h, d
    ld c, l
    ld b, d
    ld c, a
    ld d, b
    ld c, h
    ld c, e
    ld a, [$eff7]
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld a, $49
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld d, b
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld a, $41
    ld e, [hl]
    ld h, d
    inc l
    ld h, [hl]
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
    xor $3e
    ld b, c
    ld d, e
    ld b, [hl]
    ld b, b
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $40
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    ld h, d
    daa
    ld c, a
    ld a, $40
    ld c, h
    cpl
    ld c, h
    ld c, a
    ld b, c
    ld a, [$eff7]
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, e
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $41
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    or $5e
    ld h, d
    inc l
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    rst $28
    xor $51
    ld c, h
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
    ld a, $fa
    rst $30
    rst $28
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, [hl]
    ld h, d
    ccf
    ld d, d
    ld d, c
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, @+$40

    ld c, b
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld c, h
    ld c, d
    ld h, d
    ld a, $4b
    ld b, c
    rst $28
    xor $40
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
    ld h, e
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $49
    ld b, [hl]
    ccf
    ld c, a
    ld a, $4f
    ld d, [hl]
    ld e, a
    ld h, d
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld a, [$eff7]
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, l
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld c, e
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, d
    ld c, c
    ld d, b
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, d
    ld c, l
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $49
    ld d, h
    ld a, $56
    ld d, b
    rst $28
    xor $54
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld c, e
    ld h, a
    rst $28
    xor $40
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, e
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld e, a
    rst $28
    xor $fa
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
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    rst $28
    xor $f6
    ld e, [hl]
    ld a, [$eff7]
    xor $54
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, e
    rst $28
    xor $f0
    db $eb
    sbc a
    and e
    ld a, [hl-]
    dec hl
    inc h
    scf
    ld h, e
    ld h, d
    cpl
    ld b, d
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ld h, e
    rst $28
    xor $27
    ld c, h
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
    ld h, e
    ld h, e
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld a, $53
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld d, b
    ld c, h
    ld c, h
    ld c, e
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld h, $4c
    ld c, d
    ld b, d
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
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld d, b
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld b, d
    ld d, e
    ld a, $49
    ld d, d
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, h
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
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
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld e, a
    rst $30
    ldh a, [$eb]
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
    ld [bc], a
    nop
    ld a, [hl+]
    ld e, a
    rst $28
    xor $3a
    ld a, $4b
    ld c, e
    ld a, $62
    ld b, d
    ld d, e
    ld a, $49
    ld d, d
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld e, [hl]
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
    xor $42
    ld b, h
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, d
    ld d, e
    ld a, $49
    ld d, d
    ld a, $51
    ld b, d
    ld h, h
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    jr nc, jr_022_4d9b

    ld c, d
    ld h, e
    rst $28
    xor $26
    ld d, d
    ld d, c
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, e
    ld a, [$eff7]
    xor $9f
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
    ld h, e
    rst $28
    xor $37
    ld a, $49
    ld c, b
    ld b, [hl]
    ld b, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld b, [hl]
    ld b, d
    ld h, e
    ld a, [$f0f7]
    db $eb
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
    ld a, $62
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]

jr_022_4d9b:
    rst $28
    xor $45
    ld b, d
    ld a, $49
    ld d, c
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld a, $56
    ld d, b
    ld e, [hl]
    ld h, d
    ld b, d
    ld d, l
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    rst $28
    xor $3e
    ld h, d
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld d, d
    ld d, c
    ld b, [hl]
    ld b, d
    rst $28
    xor $45
    ld a, $50
    ld h, d
    ld c, c
    ld c, h
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld a, $56
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $54
    ld a, $46
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    or $5e
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld a, $54
    ld a, $56
    ld h, e
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, b
    ld a, $56
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
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
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $53
    ld a, $4f
    ld b, [hl]
    ld c, h
    ld d, d
    ld d, b
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    ld [hl], $52
    ld b, b
    ld b, l
    rst $28
    xor $53
    ld b, d
    ld c, a
    ld d, b
    ld a, $51
    ld b, [hl]
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, [hl]
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ld b, [hl]
    ld c, e
    ld b, l
    ld b, d
    ld c, a
    ld b, [hl]
    ld d, c
    ld b, d
    ld b, c
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
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $50
    ld d, c
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $4d
    ld c, a
    ld b, d
    ld d, c
    ld d, c
    ld d, [hl]
    ld h, d
    ld b, e
    ld a, $50
    ld d, c
    ld e, a
    ld a, [$eff7]
    xor $36
    ld e, a
    ld c, d
    ld e, a
    ld a, $5f
    ld c, a
    ld e, a
    ld d, c
    ld e, a
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $44
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld c, d
    ld c, d
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, h
    ld h, d
    ld d, d
    ld c, l
    ld e, a
    ld a, [$eff7]
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
    ld b, b
    ld a, $4b
    rst $28
    xor $42
    ld d, l
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld d, c
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ccf
    ld a, $3f
    ld d, [hl]
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $53
    ld d, d
    ld c, c
    ld c, e
    ld b, d
    ld c, a
    ld a, $3f
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $42
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld d, c
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
    ld c, h
    ld c, d
    ld b, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, b
    rst $28
    xor $3e
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    ld a, [$f0f7]
    db $eb
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
    xor $24
    ld h, d
    ccf
    ld c, h
    ld d, [hl]
    ld h, h
    ld h, e
    ld h, d
    jr nc, jr_022_50c3

    ld d, [hl]
    ccf
    ld b, d
    ld e, a
    ld a, [$f0f7]
    db $eb
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
    xor $24
    ld h, d
    ld b, h
    ld b, [hl]
    ld c, a
    ld c, c
    ld h, h
    ld h, e
    ld h, d
    jr nc, jr_022_50e2

    ld d, [hl]
    ccf
    ld b, d
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    scf
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $51
    ld b, d
    ld c, c
    ld c, c

jr_022_50c3:
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld e, a
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld c, e
    ld b, d

jr_022_50e2:
    ld b, d
    ld b, c
    ld d, b
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
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
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
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
    ld sp, hl
    nop
    ld a, [hl+]
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld d, c
    ld h, d
    ld a, $62
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $28
    xor $f0
    db $eb
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
    xor $3f
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld a, [$eff7]
    xor $3f
    ld c, c
    ld b, d
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $63
    ld h, e
    rst $28
    xor $2f
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    daa
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    ld a, [$f0f7]
    db $eb
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    ld d, b
    ld c, h
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld c, a
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, b
    ld a, $50
    ld b, l
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld l, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_022_5223

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld sp, $4a3e
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $3a
    ld a, $4b
    ld c, e
    ld a, $62
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
    ld c, l
    ld a, $49
    ld l, b
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4b
    ld c, e

jr_022_5223:
    ld a, $62
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
    ld c, l
    ld a, $49
    ld l, b
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
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
    ld c, e
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld c, d
    ld b, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld l, b
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    rst $28
    xor $41
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
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    dec hl
    ld c, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $52
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, [hl]
    rst $28
    xor $41
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld a, [$eff7]
    xor $4b
    ld a, $4a
    ld b, d
    ld d, b
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $4c
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld b, d
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
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld h, h
    rst $28
    xor $f0
    db $eb
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
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
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $45
    ld a, $41
    ld h, d
    ld a, $50
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, l
    ld a, $49
    ld d, b
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld d, d
    ld b, l
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    rst $28
    xor $f9
    nop
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld d, b
    ld h, h
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
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld b, d
    ld b, c
    rst $28
    xor $41
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, h
    ld a, [$eff7]
    xor $9f
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
    ld a, $41
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, l
    ld a, $49
    ld d, b
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
    ld b, [hl]
    ld c, c
    ld c, c
    rst $28
    xor $3e
    ld h, d
    ccf
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, d
    ld c, a
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
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $4a
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld d, b
    ld h, h
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld b, c
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld a, $4b
    ld b, c
    rst $28
    xor $4d
    ld d, d
    ld d, c
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_022_54e5

    ld b, d
    ld c, e
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
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld b, c
    ld e, [hl]
    ld h, d
    ld c, h
    ld c, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    rst $28
    xor $3e
    ld b, e
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e

jr_022_54e5:
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, h
    ld b, d
    ld d, c
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
    ld c, d
    ld h, d
    ld c, h
    ld c, e
    ld b, b
    ld b, d
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld a, $49
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, c
    ld d, d
    ld b, b
    ld c, b
    rst $28
    xor $3e
    ld b, c
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld a, [$eff7]
    xor $4d
    ld a, $49
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    add hl, hl
    ld b, [hl]
    ld c, e
    ld a, $49
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
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
    ld l, h
    ld b, d
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $50
    ld d, c
    ld a, $4f
    ld d, c
    ld b, d
    ld b, c
    ld e, a
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld a, [$eff7]
    xor $44
    ld c, h
    ld d, c
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld a, $56
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, h
    ld c, h
    ld e, a
    rst $30
    ldh a, [$eb]
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
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    rst $28
    xor $3f
    ld b, d
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld b, [hl]
    ld c, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    dec b
    nop
    rst $28
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
    ld d, b
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $4d
    ld a, $49
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld h, d
    ld c, a
    ld b, d
    ld a, $49
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
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
    rst $28
    xor $42
    ld d, l
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld b, d
    ld b, c
    ld h, d
    dec b
    nop
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
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
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $50
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld a, [$eff7]
    xor $4a
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld h, d
    ld b, e
    ld b, d
    ld d, h
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld d, c
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
    xor $9f
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $3e
    ld c, e
    ld h, d
    ld c, h
    ld c, a
    ld b, c
    ld b, [hl]
    ld c, e
    ld a, $4f
    ld d, [hl]
    ld a, [$eff7]
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, c
    ld c, h
    ld d, c
    ld d, b
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
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $44
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl+]
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    ld h, d
    ld [hl-], a
    ld d, e
    ld b, d
    ld c, a
    rst $28
    xor $01
    nop
    nop
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $3f4c
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ld c, d
    ld a, $48
    ld b, d
    rst $28
    xor $43
    ld d, d
    ld c, e
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
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
    ld a, $4a
    ld a, $57
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
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld a, $40
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $45
    ld b, [hl]
    ld b, h
    ld b, l
    ld b, d
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ld c, d
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3f
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
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
    ld l, c
    ld b, d
    rst $28
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
    ld a, $fa
    rst $30
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld c, e
    ld c, h
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    rst $28
    xor $40
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld a, $51
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    ld [hl], $4c
    ld h, d
    ld b, e
    ld a, $4f
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_022_5888

    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $37
    ld a, $4a
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld b, l
    ld c, h
    ld h, d
    ld b, d
    ld d, l
    ld b, b
    ld b, d
    ld b, d
    ld b, c
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $02
    nop
    nop
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
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
    ld a, $4a
    ld h, d
    ld d, h
    ld b, [hl]

jr_022_5888:
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
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
    jr c, jr_022_58ed

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
    xor $4b
    ld d, d
    ld c, d
    ccf
    ld b, d
    ld c, a
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
    ld h, e
    ld h, d
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld b, e
    ld a, $4f
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld sp, $3f4c
    ld c, h
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, b
    ld a, $4b
    rst $28
    xor $50

jr_022_58ed:
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    scf
    ld a, $9c
    ld b, c
    ld a, $63
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
    xor $9f
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
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
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
    ld d, b
    ld c, l
    ld b, d
    ld b, b
    ld b, [hl]
    ld b, d
    ld d, b
    rst $28
    xor $3e
    ld d, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld d, b
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    or $5e
    ld h, d
    ld c, e
    ld c, h
    rst $28
    xor $30
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    jr nc, jr_022_59b2

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $f6
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
    ld a, $4f
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $40
    ld b, l
    ld c, h
    ld d, b
    ld b, d
    ld c, e
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28

jr_022_59b2:
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
    ld a, [$eff7]
    xor $4a
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, a
    ld d, a
    ld d, [hl]
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $4b
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
    xor $2c
    ld h, d
    ld d, b
    ld c, d
    ld b, d
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
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, jr_022_5a47

    ld d, c
    ld b, d
    ld c, a
    ld b, [hl]
    ld a, $49
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    ld e, a
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
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
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

jr_022_5a47:
    ld c, c
    ld b, d
    ld a, $41
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld e, [hl]
    ld h, d
    jr nc, @+$40

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $ef
    xor $3a
    ld b, d
    ld c, c
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
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
    ld h, d
    dec l
    ld c, h
    ld d, [hl]
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $3a
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
    ld h, d
    ld [hl], $51
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $3e
    ld c, e
    ld b, c
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
    ld h, d
    inc sp
    ld b, d
    ld a, $40
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $25
    ld c, a
    ld a, $53
    ld b, d
    ld c, a
    ld d, [hl]
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
    rst $28
    xor $b6
    ld h, d
    ld a, [hl-]
    ld b, [hl]
    ld d, b
    ld b, c
    ld c, h
    ld c, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld e, a
    ld h, d
    scf
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
    ld [hl], $51
    ld c, a
    ld b, d
    ld c, e
    ld b, h
    ld d, c
    ld b, l
    ld a, [$eff7]
    xor $b6
    ld h, d
    inc h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc h
    ld c, e
    ld b, c
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
    rst $28
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
    ld a, [$eff7]
    xor $46
    ld d, b
    ld h, d
    ld d, c
    ld c, h
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
    ld e, a
    rst $28
    xor $2b
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld a, $43
    ld b, d
    ld a, [$eff7]
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld [hl], $46
    ld c, a
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld l, c
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
    xor $9f
    and e
    scf
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
    rst $28
    xor $39
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld e, a
    ld h, d
    scf
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
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
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
    rst $28
    xor $30
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld h, d
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $50
    ld a, $43
    ld b, d
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    inc h
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    jr nc, jr_022_5d1a

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $3c
    ld c, h
    ld d, d
    ld l, c
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

jr_022_5d1a:
    xor $9f
    and e
    scf
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
    rst $28
    xor $39
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $49
    ld b, d
    ld b, e
    ld d, c
    ld e, a
    ld h, d
    scf
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld b, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld e, [hl]
    ld a, [$eff7]
    xor $9f
    and e
    ld a, $4b
    ld b, c
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
    rst $28
    xor $30
    ld b, d
    ld c, d
    ld c, h
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $25
    ld b, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    ld h, d
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $50
    ld a, $43
    ld b, d
    ld h, d
    ld b, a
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
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
    ld c, l
    ld a, $51
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld d, h
    ld a, $50
    ld a, [$eff7]
    xor $47
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld a, $43
    ld b, d
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    or $5e
    rst $28
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
    inc l
    ld h, d
    ld a, $4a
    ld h, d
    ld d, b
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $9f
    ld d, b
    ld c, e
    ld b, [hl]
    ld b, e
    ld b, e
    ld c, c
    ld b, d
    sbc a
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld e, a
    ld e, a
    ld e, a
    ld a, [$eff7]
    xor $50
    ld c, h
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $3e
    ld a, $ef
    xor $54
    ld a, $3e
    ld a, $3e
    ld a, $3e
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld e, a
    ld e, a
    ld e, a
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
    xor $51
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld l, c
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
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld b, d
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
    rst $28
    xor $54
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld c, h
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld a, $4b
    ld d, [hl]
    rst $28
    xor $43
    ld a, $4a
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld l, c
    ld b, d
    ld h, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    or [hl]
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
    ccf
    ld b, d
    ld a, $51
    ld l, [hl]
    ld c, d
    ld e, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    rst $28
    xor $54
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $4d
    ld a, $49
    ld d, b
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
    ld b, d
    ld d, [hl]
    ld l, c
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    rst $28
    xor $50
    ld d, c
    ld c, a
    ld c, h
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
    ld l, l
    ld a, [$eff7]
    xor $41
    ld c, h
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4a
    ld a, $48
    ld b, d
    ld l, [hl]
    ld c, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld d, b
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
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, d
    ld d, h
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
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
    ld b, l
    ld b, d
    ld c, a
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $42
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld b, h
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $24
    ld c, d
    ccf
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld c, c
    ld a, $4b
    ld d, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $27
    ld b, d
    ld c, d
    ld c, h
    ld c, c
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $26
    ld c, h
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld c, c
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $28
    ld d, l
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
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
    dec a
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $36
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld a, $43
    ld b, d
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
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
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4b
    ld b, d
    ld d, h
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
    ld [hl-], a
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
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
    ld b, l
    ld b, d
    ld c, a
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $42
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld b, h
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $24
    ld c, d
    ccf
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc sp
    ld c, c
    ld a, $4b
    ld d, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $27
    ld b, d
    ld c, d
    ld c, h
    ld c, c
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, c
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $49
    ld b, [hl]
    ld c, d
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $26
    ld c, h
    ld c, e
    ld d, c
    ld c, a
    ld c, h
    ld c, c
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    daa
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $28
    ld d, l
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, [hl]
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
    dec a
    ld c, h
    ld c, d
    ccf
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld a, $4f
    ld b, d
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
    xor $36
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld a, $43
    ld b, d
    rst $28
    xor $47
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    rst $30
    ldh a, [$36]
    ld c, l
    ld c, c
    ld a, $51
    ld e, [hl]
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $3e
    ld h, d
    add hl, hl
    ld d, d
    ld c, e
    ld c, b
    ld d, [hl]
    dec h
    ld b, [hl]
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $43
    ld c, c
    ld d, [hl]
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld a, $3f
    ld c, h
    ld d, e
    ld b, d
    ld h, e
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
    rst $28
    xor $54
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
    ld b, b
    ld a, $4a
    ld b, d
    ld a, [$eff7]
    xor $43
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld a, $4b
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
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $40
    ld c, a
    ld d, [hl]
    ld d, b
    ld d, c
    ld a, $49
    ld h, d
    ld b, b
    ld c, c
    ld b, d
    ld a, $4f
    ld h, e
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, b
    ld h, d
    ld b, b
    ld c, c
    ld b, d
    ld a, $4b
    ld b, d
    ld b, c
    rst $28
    xor $46
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, d
    ld d, b
    ld h, e
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
    ld b, [hl]
    ld b, e
    ld h, d
    inc l
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, h
    ld c, h
    ld c, c
    ld b, e
    ld a, [$eff7]
    xor $46
    ld b, e
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld h, d
    ld a, $62
    ccf
    ld c, h
    ld c, h
    ld c, b
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc a
    ld a, $4c
    ld c, h
    ld c, h
    ld d, h
    ld c, c
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
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, e
    ld d, c
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
    xor $51
    ld c, h
    ld b, h
    ld b, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld e, [hl]
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld d, h
    ld c, h
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, d
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld d, c
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld a, $62
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    rst $28
    xor $4f
    ld c, h
    ld c, d
    ld a, $4b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld c, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
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
    xor $2c
    ld h, d
    ld b, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    ld b, d
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
    xor $9f
    and e
    inc h
    ld h, d
    ld b, e
    ld c, a
    ld a, $44
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld a, $ef
    xor $50
    ld d, c
    ld a, $4f
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld d, h
    ld b, [hl]
    ld c, e
    ld c, b
    ld c, c
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
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld e, a
    ld h, d
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld h, e
    ld a, [$eff7]
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $54
    ld a, $46
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$eff7]
    xor $25
    ld c, c
    ld b, d
    ld a, $51
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl+]
    ld c, h
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $50
    ld d, c
    ld a, $3f
    ld c, c
    ld b, d
    ld e, a
    ld h, d
    dec h
    ld c, c
    ld b, d
    ld a, $51
    ld h, e
    ld a, [$eff7]
    xor $2e
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, d
    ld c, l
    ld e, a
    rst $28
    xor $25
    ld c, c
    ld b, d
    ld a, $51
    ld h, e
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
    ld e, [hl]
    ld a, [$eff7]
    xor $25
    ld a, $4c
    ld c, h
    ld c, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr z, jr_022_664a

    ld b, d
    ld c, a
    ld d, [hl]
    ccf
    ld c, h
    ld b, c
    ld d, [hl]
    ld l, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $6f
    ld a, $52
    ld d, b
    ld b, d
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
    xor $25
    ld a, $4c
    ld c, h
    ld c, d
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld a, $53
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, d
    ld b, d
    ld d, c
    ld h, d
    ld a, $49
    ld c, c
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

jr_022_664a:
    ld b, d
    ld c, a
    ld d, b
    ld h, h
    ld a, [$eff7]
    xor $37
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_022_66c8

    ld h, d
    ccf
    ld d, d
    ld b, c
    ld b, c
    ld d, [hl]
    ld h, d
    ld b, [hl]
    ld d, b
    rst $28
    xor $49
    ld b, [hl]
    ld d, e
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2a
    ld a, $51
    ld b, d
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld [hl], $49
    ld b, d
    ld b, d
    ld c, l
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec hl
    ld b, d
    ld l, b
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld b, d
    ld b, c
    rst $28
    xor $27
    ld b, d
    ld a, $41
    ld sp, $3f4c
    ld c, c
    ld b, d
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $45
    ld b, d
    ld l, b

jr_022_66c8:
    ld h, d
    ld b, b
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld b, [hl]
    ld c, l
    ld c, l
    ld b, d
    ld b, d
    ld h, e
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
    xor $f7
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
    xor $3a
    ld a, $51
    ld a, $3f
    ld c, h
    ld d, d
    ld h, d
    ld d, b
    ld c, h
    ld c, d
    ld b, d
    ld b, c
    ld a, $56
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
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $3e
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
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
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec a
    dec a
    dec a
    ld e, a
    ld e, a
    ld e, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld a, $4f
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
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, c
    ld c, h
    ld a, [$eff7]
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
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
    daa
    ld b, [hl]
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld a, $49
    ld c, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, l
    ld b, [hl]
    ld b, c
    ld b, c
    ld b, d
    ld c, e
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
    ld c, d
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $45
    ld b, [hl]
    ld b, c
    ld b, c
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $52
    ld c, e
    ld b, d
    ld d, l
    ld c, l
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld d, b
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    jr nc, jr_022_6877

    ld e, a
    ld h, d
    daa
    ld b, d
    ld a, $41
    ld sp, $3f4c
    ld c, c
    ld b, d
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, d
    ld a, $51
    ld h, d
    ld h, $3e
    ld c, c
    ld c, c
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld e, a
    ld e, a
    inc l
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
    ld a, $62
    ld b, h
    ld c, a
    ld b, d
    ld a, $51
    ld a, [$eff7]
    xor $50
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, e
    ld h, e

jr_022_6877:
    ld h, d
    inc a
    ld a, $3e
    ld h, e
    rst $28
    xor $f7
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld l, d
    ld h, d
    dec hl
    ld a, $4a
    ld c, d
    ld b, d
    ld c, a
    jr nc, jr_022_68e4

    ld c, e
    ld e, a
    rst $28
    xor $2c
    ld h, d
    ld a, $4a
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
    xor $4c
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld b, d
    ld a, $50
    ld d, c
    ld d, b
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    ld a, $51
    ld h, d
    ld c, c
    ld b, d
    ld a, $50

jr_022_68e4:
    ld d, c
    rst $28
    xor $2c
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
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
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
