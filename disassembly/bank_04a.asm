; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $04a", ROMX[$4000], BANK[$4a]

    db $4A ; Bank number

    ; Cross-bank dispatch table (293 entries)
    ; Called via: ld hl, $4AXX / rst $10
    dw LoadB4a_424b                  ; Entry 0
    dw TextRunB4A_4263               ; Entry 1
    dw TextShowRefreshB4A_427b       ; Entry 2
    dw $400B                          ; Entry 3 — mode 0 -> table $400B (mode list $4007)
    dw $404B                          ; Entry 4 — mode 1 -> table $404B (mode list $4007)
    dw TextStr_4a_4293               ; Entry 5 — [table $400B]; text $05E0 "*:Humpf, I don't need you!"
    dw TextStr_4a_42b0               ; Entry 6 — text $05E1 "*:I don't have such a name! Don't…"
    dw TextStr_4a_4339               ; Entry 7 — text $05E2 "*:Yep. It's Santi. How did you kn…"
    dw TextStr_4a_437e               ; Entry 8 — text $05E3 "Santi:Wait here for me!"
    dw TextStr_4a_439a               ; Entry 9 — text $05E4 "Santi:Talk to my Grandpa!!"
    dw TextStr_4a_43b8               ; Entry 10 — text $05E5 "Santi:C'mon, go talk to my Grandp…"
    dw TextStr_4a_43e5               ; Entry 11 — text $05E6 "Santi:You talked to my Grandpa, r…"
    dw TextStr_4a_445b               ; Entry 12 — text $05E7 "Santi:Don't just stand there! Go …"
    dw TextStr_4a_449a               ; Entry 13 — text $05E8 "Santi:Was the Travelers' Gate use…"
    dw TextStr_4a_44cf               ; Entry 14 — text $05E9 "Santi:Y...Ya big fool!"
    dw TextStr_4a_44e9               ; Entry 15 — text $05EA "Santi:I...I'm... happy....blush."
    dw TextStr_4a_450c               ; Entry 16 — text $05EB "*:Oh our hero [HERO]! Welcome to …"
    dw TextStr_4a_453c               ; Entry 17 — text $05EC "*:What a good feeling to be the w…"
    dw TextStr_4a_45a7               ; Entry 18 — text $05ED "*:La la la [HERO] and Milayou La …"
    dw TextStr_4a_460c               ; Entry 19 — text $05EE "*:I didn't think you could win..."
    dw TextStr_4a_4630               ; Entry 20 — text $05EF "*:Giggle giggle! Listen listen! *…"
    dw TextStr_4a_46b2               ; Entry 21 — text $05F0 "*:Well well, Congratulations!! I …"
    dw TextStr_4a_47c1               ; Entry 22 — text $05F1 "*:Well of course! You're the vict…"
    dw TextStr_4a_47e8               ; Entry 23 — text $05F2 "*:Hi! *:How about a reward for yo…"
    dw TextStr_4a_4822               ; Entry 24 — text $05F3 "*:Okay."
    dw TextStr_4a_482e               ; Entry 25 — text $05F4 "*:...tickle ...tickle, tickle *:t…"
    dw TextStr_4a_4886               ; Entry 26 — text $05F5 "*:Oh, what a joy! [HERO] won! *:T…"
    dw TextStr_4a_4940               ; Entry 27 — text $05F6 "*:Oh, the hero of GreatTree, Mast…"
    dw TextStr_4a_49b6               ; Entry 28 — text $05F7 "*:Yes, of course. The victor woul…"
    dw TextStr_4a_49f5               ; Entry 29 — text $05F8 "*:The monstrous master was your s…"
    dw TextStr_4a_4ae9               ; Entry 30 — text $05F9 "*:Hey! Our hero [HERO]! *:The two…"
    dw TextStr_4a_4b52               ; Entry 31 — text $05FA "*:Missing... Something missing. *…"
    dw TextStr_4a_4c7b               ; Entry 32 — text $05FB "*:...I wonder if you brought a mo…"
    dw TextStr_4a_4cb5               ; Entry 33 — text $05FC "*:Oh! You brought it here! Show m…"
    dw TextStr_4a_4ceb               ; Entry 34 — text $05FD "[INS 00] cast Call! But nothing h…"
    dw TextStr_4a_4d15               ; Entry 35 — text $05FE "*:What the heck? Nothing happened…"
    dw TextStr_4a_4dd0               ; Entry 36 — text $05FF "*:You knew it right? This is the …"
    dw TextStr_4a_4e50               ; Entry 37 — [table $404B]; text $0600 "*:Come to me when you want to bre…"
    dw TextStr_4a_4e8e               ; Entry 38 — text $0601 "Why not breed with my [INS 00]?"
    dw TextStr_4a_4eaa               ; Entry 39 — text $0602 "*:Which monster do you want to br…"
    dw TextStr_4a_4edf               ; Entry 40 — text $0603 "*:You can't breed low level monst…"
    dw TextStr_4a_4f0d               ; Entry 41 — text $0604 "*:There will be no monsters to ta…"
    dw TextStr_4a_4f44               ; Entry 42 — text $0605 "*:Are you okay with this monster?"
    dw TextStr_4a_4f68               ; Entry 43 — text $0606 "*:Start the breeding ceremony?"
    dw TextStr_4a_4f89               ; Entry 44 — text $0607 "*:I have no idea what kind of egg…"
    dw TextStr_4a_4ff8               ; Entry 45 — text $0608 "*:Let's begin the breeding ceremo…"
    dw TextStr_4a_501f               ; Entry 46 — text $0609 "*:I hope a strong monster will be…"
    dw TextStr_4a_5073               ; Entry 47 — text $060A "*:My Eyeder loves devils. Want to…"
    dw TextStr_4a_50a4               ; Entry 48 — text $060B "*:Which monster will you breed wi…"
    dw TextStr_4a_50db               ; Entry 49 — text $060C "*:Why not breed with my Yeti?"
    dw TextStr_4a_50fc               ; Entry 50 — text $060D "*:Which monster will you breed wi…"
    dw TextStr_4a_5131               ; Entry 51 — text $060E "*:Tut, stingy. Hic..."
    dw TextStr_4a_5131               ; Entry 52 — text $060F "*:Tut, stingy. Hic..."
    dw TextStr_4a_5131               ; Entry 53 — text $0610 "*:Tut, stingy. Hic..."
    dw TextStr_4a_514a               ; Entry 54 — text $0611 "Why don't you breed with my CatFl…"
    dw TextStr_4a_5174               ; Entry 55 — text $0612 "*:Which monster do you want to br…"
    dw TextStr_4a_51b0               ; Entry 56 — text $0613 "*:I can't let mine breed with low…"
    dw TextStr_4a_51ea               ; Entry 57 — text $0614 "*:You won't have any monsters to …"
    dw TextStr_4a_5221               ; Entry 58 — text $0615 "*:With this monster? Are you sure?"
    dw TextStr_4a_524b               ; Entry 59 — text $0616 "*:Start the breeding ceremony?"
    dw TextStr_4a_526c               ; Entry 60 — text $0617 "*:I can't tell what kinda monster…"
    dw TextStr_4a_52d0               ; Entry 61 — text $0618 "*:Let's begin the breeding ceremo…"
    dw TextStr_4a_52f7               ; Entry 62 — text $0619 "*:Hope a strong monster will be b…"
    dw TextStr_4a_5349               ; Entry 63 — text $061A "*:Well, if you want to breed agai…"
    dw TextStr_4a_5349               ; Entry 64 — text $061B "*:Well, if you want to breed agai…"
    dw TextStr_4a_5349               ; Entry 65 — text $061C "*:Well, if you want to breed agai…"
    dw TextStr_4a_5349               ; Entry 66 — text $061D "*:Well, if you want to breed agai…"
    dw TextStr_4a_5349               ; Entry 67 — text $061E "*:Well, if you want to breed agai…"
    dw TextStr_4a_5349               ; Entry 68 — text $061F "*:Well, if you want to breed agai…"
    dw TextStr_4a_5349               ; Entry 69 — text $0620 "*:Well, if you want to breed agai…"
    dw TextStr_4a_53b1               ; Entry 70 — text $0621 "*:Why not breed with my LizardMan?"
    dw TextStr_4a_53db               ; Entry 71 — text $0622 "*:Which one are you gonna breed w…"
    dw TextStr_4a_5415               ; Entry 72 — text $0623 "*:Hey, your monster is weak. That…"
    dw TextStr_4a_546d               ; Entry 73 — text $0624 "*:Hey! You won't have any monster…"
    dw TextStr_4a_54aa               ; Entry 74 — text $0625 "*:Are you okay with this monster?"
    dw TextStr_4a_54ce               ; Entry 75 — text $0626 "*:Start the breeding ceremony?"
    dw TextStr_4a_54ef               ; Entry 76 — text $0627 "*:I don't know what kind of egg w…"
    dw TextStr_4a_5563               ; Entry 77 — text $0628 "*:Let's begin the breeding ceremo…"
    dw TextStr_4a_558a               ; Entry 78 — text $0629 "*:Well, you should be at least ha…"
    dw TextStr_4a_55e4               ; Entry 79 — text $062A "Mick:I'll be on my journey by the…"
    dw TextStr_4a_55e4               ; Entry 80 — text $062B "Mick:I'll be on my journey by the…"
    dw TextStr_4a_55e4               ; Entry 81 — text $062C "Mick:I'll be on my journey by the…"
    dw TextStr_4a_55e4               ; Entry 82 — text $062D "Mick:I'll be on my journey by the…"
    dw TextStr_4a_55e4               ; Entry 83 — text $062E "Mick:I'll be on my journey by the…"
    dw TextStr_4a_55e4               ; Entry 84 — text $062F "Mick:I'll be on my journey by the…"
    dw TextStr_4a_55e4               ; Entry 85 — text $0630 "Mick:I'll be on my journey by the…"
    dw TextStr_4a_5627               ; Entry 86 — text $0631 "Mick:Let's breed with my DeadNite…"
    dw TextStr_4a_564c               ; Entry 87 — text $0632 "Mick:Who do you want to pick for …"
    dw TextStr_4a_567e               ; Entry 88 — text $0633 "Mick:Your monster's level is too …"
    dw TextStr_4a_56b4               ; Entry 89 — text $0634 "Mick:You won't have any monsters …"
    dw TextStr_4a_56ef               ; Entry 90 — text $0635 "Mick:With this one? Are you sure?"
    dw TextStr_4a_5713               ; Entry 91 — text $0636 "Mick:Start the breeding ceremony?"
    dw TextStr_4a_5737               ; Entry 92 — text $0637 "*:I have no idea what kind of egg…"
    dw TextStr_4a_579e               ; Entry 93 — text $0638 "*:Let's begin the breeding ceremo…"
    dw TextStr_4a_57c5               ; Entry 94 — text $0639 "*:This egg is the proof of our fr…"
    dw TextStr_4a_5817               ; Entry 95 — text $063A "*:Please come to me when you want…"
    dw TextStr_4a_5817               ; Entry 96 — text $063B "*:Please come to me when you want…"
    dw TextStr_4a_5817               ; Entry 97 — text $063C "*:Please come to me when you want…"
    dw TextStr_4a_5817               ; Entry 98 — text $063D "*:Please come to me when you want…"
    dw TextStr_4a_5817               ; Entry 99 — text $063E "*:Please come to me when you want…"
    dw TextStr_4a_5817               ; Entry 100 — text $063F "*:Please come to me when you want…"
    dw TextStr_4a_5817               ; Entry 101 — text $0640 "*:Please come to me when you want…"
    dw TextStr_4a_586f               ; Entry 102 — text $0641 "*:Want to breed with my Rayburn?"
    dw TextStr_4a_5892               ; Entry 103 — text $0642 "*:Which monster are you picking f…"
    dw TextStr_4a_58c9               ; Entry 104 — text $0643 "*:I don't want to breed with a lo…"
    dw TextStr_4a_5903               ; Entry 105 — text $0644 "*:You'll have no monsters to take…"
    dw TextStr_4a_5937               ; Entry 106 — text $0645 "*:Is this monster okay?"
    dw TextStr_4a_5951               ; Entry 107 — text $0646 "*:Can I start the breeding ceremo…"
    dw TextStr_4a_5978               ; Entry 108 — text $0647 "*:I have no idea what kind of egg…"
    dw TextStr_4a_59d2               ; Entry 109 — text $0648 "*:Let's start the breeding ceremo…"
    dw TextStr_4a_59f9               ; Entry 110 — text $0649 "*:I hope it'll be a strong monste…"
    dw TextStr_4a_5a43               ; Entry 111 — text $064A "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a43               ; Entry 112 — text $064B "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a43               ; Entry 113 — text $064C "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a43               ; Entry 114 — text $064D "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a43               ; Entry 115 — text $064E "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a43               ; Entry 116 — text $064F "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a43               ; Entry 117 — text $0650 "*:Pay me a visit when you want to…"
    dw TextStr_4a_5a74               ; Entry 118 — text $0651 "*:Why not breed with my [INS 00]?"
    dw TextStr_4a_5a92               ; Entry 119 — text $0652 "*:Which monster are you going to …"
    dw TextStr_4a_5acb               ; Entry 120 — text $0653 "*:Cannot breed with a low level m…"
    dw TextStr_4a_5afd               ; Entry 121 — text $0654 "*:You'll have no monsters to take…"
    dw TextStr_4a_5b31               ; Entry 122 — text $0655 "*:This monster? Are you sure?"
    dw TextStr_4a_5b51               ; Entry 123 — text $0656 "*:Can we start the breeding cerem…"
    dw TextStr_4a_5b79               ; Entry 124 — text $0657 "*:I can't imagine what kind of eg…"
    dw TextStr_4a_5bf0               ; Entry 125 — text $0658 "*:Then, let us begin the ceremony."
    dw TextStr_4a_5c1b               ; Entry 126 — text $0659 "*:Hopefully a strong monster will…"
    dw TextStr_4a_5c72               ; Entry 127 — text $065A "*:Why not breed with my Metabble!"
    dw TextStr_4a_5c97               ; Entry 128 — text $065B "*:Which monster do you want to br…"
    dw TextStr_4a_5cd6               ; Entry 129 — text $065C "Milayou:Come back when you wanna …"
    dw TextStr_4a_5cd6               ; Entry 130 — text $065D "Milayou:Come back when you wanna …"
    dw TextStr_4a_5cd6               ; Entry 131 — text $065E "Milayou:Come back when you wanna …"
    dw TextStr_4a_5cd6               ; Entry 132 — text $065F "Milayou:Come back when you wanna …"
    dw TextStr_4a_5cd6               ; Entry 133 — text $0660 "Milayou:Come back when you wanna …"
    dw TextStr_4a_5d06               ; Entry 134 — text $0661 "Milayou:Breed with my Skeletor!"
    dw TextStr_4a_5d28               ; Entry 135 — text $0662 "Milayou:Which monster will you pi…"
    dw TextStr_4a_5d63               ; Entry 136 — text $0663 "Milayou:A low level monster can't…"
    dw TextStr_4a_5d94               ; Entry 137 — text $0664 "Milayou:You won't have any monste…"
    dw TextStr_4a_5dd1               ; Entry 138 — text $0665 "Milayou:Is this monster okay?"
    dw TextStr_4a_5df1               ; Entry 139 — text $0666 "Milayou:I'll start the breeding c…"
    dw TextStr_4a_5e27               ; Entry 140 — text $0667 "Milayou:I don't know what kind of…"
    dw TextStr_4a_5e8f               ; Entry 141 — text $0668 "Milayou:Let's breed!"
    dw TextStr_4a_5ea6               ; Entry 142 — text $0669 "Milayou:I hope it'll be a strong …"
    dw TextStr_4a_5f0b               ; Entry 143 — text $066A "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 144 — text $066B "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 145 — text $066C "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 146 — text $066D "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 147 — text $066E "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 148 — text $066F "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 149 — text $0670 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 150 — text $0671 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 151 — text $0672 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 152 — text $0673 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 153 — text $0674 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 154 — text $0675 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 155 — text $0676 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 156 — text $0677 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 157 — text $0678 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 158 — text $0679 "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 159 — text $067A "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 160 — text $067B "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 161 — text $067C "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 162 — text $067D "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 163 — text $067E "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 164 — text $067F "*:Item shop. May I help you?"
    dw TextStr_4a_5f0b               ; Entry 165 — text $0680 "*:Item shop. May I help you?"
    dw TextStr_4a_5f2a               ; Entry 166 — text $0681 "*:Anything else?"
    dw TextStr_4a_5f3e               ; Entry 167 — text $0682 "*:Thank you. Come again!"
    dw TextStr_4a_5f5a               ; Entry 168 — text $0683 "*:What would you like?"
    dw TextStr_4a_5f73               ; Entry 169 — text $0684 "*:What would you like?"
    dw TextStr_4a_5f8c               ; Entry 170 — text $0685 "*:How many?"
    dw TextStr_4a_5f9b               ; Entry 171 — text $0686 "[INS 10] X [INS 00] is [INS 20]G."
    dw TextStr_4a_5fad               ; Entry 172 — text $0687 "*:You don't have enough money."
    dw TextStr_4a_5fcf               ; Entry 173 — text $0688 "*:You can only carry 20 items!"
    dw TextStr_4a_5ff2               ; Entry 174 — text $0689 "*:Thank you!"
    dw TextStr_4a_6003               ; Entry 175 — text $068A "*:Which items will you sell to me?"
    dw TextStr_4a_6028               ; Entry 176 — text $068B "*:You don't have items I can buy."
    dw TextStr_4a_604d               ; Entry 177 — text $068C "*:How many would you like to sell?"
    dw TextStr_4a_6072               ; Entry 178 — text $068D "[INS 10] X [INS 00] is [INS 20]G."
    dw TextStr_4a_6084               ; Entry 179 — text $068E "*:You can only have up to 99999G!"
    dw TextStr_4a_60af               ; Entry 180 — text $068F "*:Thanks again!"
    dw TextStr_4a_60c3               ; Entry 181 — text $0690 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 182 — text $0691 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 183 — text $0692 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 184 — text $0693 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 185 — text $0694 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 186 — text $0695 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 187 — text $0696 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 188 — text $0697 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 189 — text $0698 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 190 — text $0699 "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 191 — text $069A "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 192 — text $069B "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 193 — text $069C "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 194 — text $069D "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 195 — text $069E "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 196 — text $069F "*:Vault. May I help you?"
    dw TextStr_4a_60c3               ; Entry 197 — text $06A0 "*:Vault. May I help you?"
    dw TextStr_4a_60de               ; Entry 198 — text $06A1 "*:Something else?"
    dw TextStr_4a_60f3               ; Entry 199 — text $06A2 "*:Come again anytime."
    dw TextStr_4a_610c               ; Entry 200 — text $06A3 "*:What would you like us to store?"
    dw TextStr_4a_6131               ; Entry 201 — text $06A4 "*:Which one?"
    dw TextStr_4a_6141               ; Entry 202 — text $06A5 "*:You don't have anything."
    dw TextStr_4a_615f               ; Entry 203 — text $06A6 "*:Sorry. We can't store anymore."
    dw TextStr_4a_6183               ; Entry 204 — text $06A7 "*:How many?"
    dw TextStr_4a_6190               ; Entry 205 — text $06A8 "*:Too much!"
    dw TextStr_4a_619f               ; Entry 206 — text $06A9 "*:You're in safe hands with us."
    dw TextStr_4a_61c2               ; Entry 207 — text $06AA "*:How much do you want to deposit?"
    dw TextStr_4a_61e7               ; Entry 208 — text $06AB "*:Not enough money."
    dw TextStr_4a_61ff               ; Entry 209 — text $06AC "*:Excuse me but you can only depo…"
    dw TextStr_4a_623b               ; Entry 210 — text $06AD "*:You're in safe hands with us."
    dw TextStr_4a_625e               ; Entry 211 — text $06AE "*:What would you like to take out?"
    dw TextStr_4a_6283               ; Entry 212 — text $06AF "*:We don't have any of your gold."
    dw TextStr_4a_62a8               ; Entry 213 — text $06B0 "*:Take out items or withdraw gold?"
    dw TextStr_4a_62cd               ; Entry 214 — text $06B1 "*:We don't have any of your items."
    dw TextStr_4a_62f3               ; Entry 215 — text $06B2 "*:Too much stuff to store."
    dw TextStr_4a_6312               ; Entry 216 — text $06B3 "*:Take out how many?"
    dw TextStr_4a_6329               ; Entry 217 — text $06B4 "*:You have too much to carry!"
    dw TextStr_4a_634b               ; Entry 218 — text $06B5 "*:Here it is."
    dw TextStr_4a_635e               ; Entry 219 — text $06B6 "*:Withdraw how much?"
    dw TextStr_4a_6375               ; Entry 220 — text $06B7 "*:You don't have that much money."
    dw TextStr_4a_639a               ; Entry 221 — text $06B8 "*:You can't carry that much money."
    dw TextStr_4a_63c0               ; Entry 222 — text $06B9 "*:Here it is."
    dw TextStr_4a_63d3               ; Entry 223 — text $06BA "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63d3               ; Entry 224 — text $06BB "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63d3               ; Entry 225 — text $06BC "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63d3               ; Entry 226 — text $06BD "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63d3               ; Entry 227 — text $06BE "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63d3               ; Entry 228 — text $06BF "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63d3               ; Entry 229 — text $06C0 "Pulio:Hey there! Whadayagonnado?"
    dw TextStr_4a_63f6               ; Entry 230 — text $06C1 "Pulio:Anything else?"
    dw TextStr_4a_640d               ; Entry 231 — text $06C2 "Pulio:Later! We'll be here for ya!"
    dw TextStr_4a_6432               ; Entry 232 — text $06C3 "Pulio:Drop off which one?"
    dw TextStr_4a_644e               ; Entry 233 — text $06C4 "Pulio:Hey, you're not gonna have …"
    dw TextStr_4a_648d               ; Entry 234 — text $06C5 "Pulio:Drop off this one?"
    dw TextStr_4a_64a8               ; Entry 235 — text $06C6 "Pulio:Stop by once in a while to …"
    dw TextStr_4a_64e7               ; Entry 236 — text $06C7 "Pulio:Replace it?"
    dw TextStr_4a_64fb               ; Entry 237 — text $06C8 "Pulio:Replace it with which one?"
    dw TextStr_4a_651e               ; Entry 238 — text $06C9 "Pulio:Replace it with this one?"
    dw TextStr_4a_6540               ; Entry 239 — text $06CA "Pulio:I replaced [INS 00] with [I…"
    dw TextStr_4a_6561               ; Entry 240 — text $06CB "Pulio:Picking up which one, [HERO…"
    dw TextStr_4a_6582               ; Entry 241 — text $06CC "Pulio:No monsters here to take."
    dw TextStr_4a_65a6               ; Entry 242 — text $06CD "Pulio:You can't take any more!"
    dw TextStr_4a_65c8               ; Entry 243 — text $06CE "Pulio:You're gonna pick this one …"
    dw TextStr_4a_65ee               ; Entry 244 — text $06CF "Pulio:Train it well, [HERO]!"
    dw TextStr_4a_660a               ; Entry 245 — text $06D0 "Pulio:Replacing a monster, [HERO]?"
    dw TextStr_4a_662a               ; Entry 246 — text $06D1 "Pulio:Which one are you replacing?"
    dw TextStr_4a_664f               ; Entry 247 — text $06D2 "Pulio:Replace this one?"
    dw TextStr_4a_6669               ; Entry 248 — text $06D3 "Pulio:Replace with which one?"
    dw TextStr_4a_6689               ; Entry 249 — text $06D4 "Pulio:Replace this one?"
    dw TextStr_4a_66a3               ; Entry 250 — text $06D5 "Pulio:I replaced [INS 00] with [I…"
    dw TextStr_4a_66c4               ; Entry 251 — text $06D6 "Pulio:Check on which one?"
    dw TextStr_4a_66e0               ; Entry 252 — text $06D7 "Pulio:Hey, none to check on!"
    dw TextStr_4a_6701               ; Entry 253 — text $06D8 "Pulio:Check on which one, [HERO]?"
    dw TextStr_4a_6720               ; Entry 254 — text $06D9 "Pulio:Check on which one, [HERO]?"
    dw TextStr_4a_673f               ; Entry 255 — text $06DA "Pulio:Separate with which one?"
    dw TextStr_4a_6760               ; Entry 256 — text $06DB "Pulio:Hey, nothing here!"
    dw TextStr_4a_677d               ; Entry 257 — text $06DC "Pulio:Separate with which one?"
    dw TextStr_4a_679e               ; Entry 258 — text $06DD "Pulio:Are you sure? You'll lose i…"
    dw TextStr_4a_67d0               ; Entry 259 — text $06DE "[INS 00] was returned to the wild."
    dw TextStr_4a_67f5               ; Entry 260 — text $06DF "Pulio:Are you sure? You'll lose i…"
    dw TextStr_4a_6827               ; Entry 261 — text $06E0 "[INS 00] was returned to the wild."
    dw TextStr_4a_684c               ; Entry 262 — text $06E1 "Pulio:Select [PICK UP] to take th…"
    dw TextStr_4a_6887               ; Entry 263 — text $06E2 "Pulio:You wanna make the monsters…"
    dw TextStr_4a_68d1               ; Entry 264 — text $06E3 "Pulio:All the monsters here went …"
    dw TextStr_4a_690e               ; Entry 265 — text $06E4 "Pulio:I put all the monsters not …"
    dw TextStr_4a_6986               ; Entry 266 — text $06E5 "Pulio:Wanna wake up the sleeping …"
    dw TextStr_4a_69b8               ; Entry 267 — text $06E6 "Pulio:I woke up the sleeping mons…"
    dw TextStr_4a_69e8               ; Entry 268 — text $06E7 "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 269 — text $06E8 "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 270 — text $06E9 "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 271 — text $06EA "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 272 — text $06EB "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 273 — text $06EC "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 274 — text $06ED "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 275 — text $06EE "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 276 — text $06EF "*:What can I do for you?"
    dw TextStr_4a_69e8               ; Entry 277 — text $06F0 "*:What can I do for you?"
    dw TextStr_4a_6a03               ; Entry 278 — text $06F1 "*:Anything else?"
    dw TextStr_4a_6a15               ; Entry 279 — text $06F2 "*:Create the ultimate monsters!"
    dw TextStr_4a_6a38               ; Entry 280 — text $06F3 "*:Which monster for the pedigree?"
    dw TextStr_4a_6a5c               ; Entry 281 — text $06F4 "*:Which monster to breed with?"
    dw TextStr_4a_6a7d               ; Entry 282 — text $06F5 "*:That one? Are you sure?"
    dw TextStr_4a_6a99               ; Entry 283 — text $06F6 "*:There will be no monsters left!"
    dw TextStr_4a_6abf               ; Entry 284 — text $06F7 "*:Sorry, it's not old enough."
    dw TextStr_4a_6ae0               ; Entry 285 — text $06F8 "*:The same gender. Cannot breed."
    dw TextStr_4a_6b05               ; Entry 286 — text $06F9 "*:I bet [INS 20] will be born! *:…"
    dw TextStr_4a_6b4d               ; Entry 287 — text $06FA "*:Hmm. Seems like a new monster?!"
    dw TextStr_4a_6b73               ; Entry 288 — text $06FB "*:Can I record this joyful event?"
    dw TextStr_4a_6b97               ; Entry 289 — text $06FC "*:OK! Wait overnight."
    dw TextStr_4a_6bb0               ; Entry 290 — text $06FD "[INS 00] & [INS 10] disappeared."
    dw TextStr_4a_6bc8               ; Entry 291 — text $06FE "*:Wow! It's a rare breed!"
    dw TextStr_4a_6be5               ; Entry 292 — text $06FF "*:Inside it is a baby [INS 20]! *…"

LoadB4a_424b:
    ld a, [$c822]
    cp $02
    jr nz, jr_04a_425c

    ld a, $00
    ld [$c822], a
    ld hl, $2200
    rst $10
    ret


jr_04a_425c:
    ld de, $4007
    call CallTextEngine
    ret


; [S166] copy a text of this bank (RunTextHandler); ids past the bank's range go to its overflow bank (TEXT_SYSTEM "Text id resolution")
TextRunB4A_4263:
    ld a, [$c822]
    cp $02
    jr nz, jr_04a_4274

    ld a, $00
    ld [$c822], a
    ld hl, $2201
    rst $10
    ret


jr_04a_4274:
    ld de, $4007
    call RunTextHandler
    ret


; [S166] show a text (entry 0) then RequestScreenUpdate
TextShowRefreshB4A_427b:
    ld a, [$c822]
    cp $02
    jr nz, jr_04a_428c

    ld a, $00
    ld [$c822], a
    ld hl, $2202
    rst $10
    ret


jr_04a_428c:
    call LoadB4a_424b
    call RequestScreenUpdate
    ret


; --- BEGIN re-sectioned text run (bank $4a: $4293-$6c26) ---
; DTE-encoded dialogue strings, one label per text id (text_id_map.json).
; Labels/comments only; bytes are byte-identical to the original ROM.
TextStr_4a_4293:           ; id $05E0
    ; "*:Humpf, I don't need you!"
    db $eb, $9f, $a3, $2b, $52, $4a, $4d, $43, $5e, $62, $2c, $62, $41, $4c, $4b, $67
    db $ef, $ee, $4b, $42, $42, $41, $62, $56, $4c, $52, $63, $f7, $f0
TextStr_4a_42b0:           ; id $05E1
    ; "*:I don't have such a name! / Don't lie to me! / *:You don't even know my name. / Too bad. / *:I was gonna give you a reward."
    db $eb, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42, $62, $ef
    db $ee, $50, $52, $40, $45, $62, $3e, $62, $4b, $3e, $4a, $42, $63, $fa, $f7, $ef
    db $ee, $27, $4c, $4b, $67, $62, $49, $46, $42, $62, $51, $4c, $62, $4a, $42, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67
    db $62, $42, $53, $42, $4b, $ef, $ee, $48, $4b, $4c, $54, $62, $4a, $56, $62, $4b
    db $3e, $4a, $42, $5f, $fa, $f7, $ef, $ee, $37, $4c, $4c, $62, $3f, $3e, $41, $5f
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $54, $3e, $50, $62, $44, $4c
    db $4b, $4b, $3e, $62, $44, $46, $53, $42, $ef, $ee, $56, $4c, $52, $62, $3e, $62
    db $4f, $42, $54, $3e, $4f, $41, $5f, $f7, $f0
TextStr_4a_4339:           ; id $05E2
    ; "*:Yep. It's Santi. How did you know? / Santi:Humph... Follow me!"
    db $eb, $9f, $a3, $3c, $42, $4d, $5f, $62, $2c, $51, $68, $62, $36, $3e, $4b, $51
    db $46, $5f, $ef, $ee, $2b, $4c, $54, $62, $41, $46, $41, $62, $56, $4c, $52, $62
    db $48, $4b, $4c, $54, $64, $fa, $f7, $ef, $ee, $36, $3e, $4b, $51, $46, $a3, $2b
    db $52, $4a, $4d, $45, $5f, $5f, $5f, $ef, $ee, $29, $4c, $49, $49, $4c, $54, $62
    db $4a, $42, $63, $f7, $f0
TextStr_4a_437e:           ; id $05E3
    ; "Santi:Wait here for me!"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $3a, $3e, $46, $51, $62, $45, $42, $4f, $42
    db $62, $ef, $ee, $43, $4c, $4f, $62, $4a, $42, $63, $f7, $f0
TextStr_4a_439a:           ; id $05E4
    ; "Santi:Talk to my Grandpa!!"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $37, $3e, $49, $48, $62, $51, $4c, $62, $4a
    db $56, $ef, $ee, $2a, $4f, $3e, $4b, $41, $4d, $3e, $63, $63, $f7, $f0
TextStr_4a_43b8:           ; id $05E5
    ; "Santi:C'mon, go talk to my / Grandpa!"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $26, $6a, $4c, $4b, $5e, $62, $44, $4c, $62
    db $ef, $ee, $51, $3e, $49, $48, $62, $51, $4c, $62, $4a, $56, $62, $fa, $f7, $ef
    db $ee, $2a, $4f, $3e, $4b, $41, $4d, $3e, $63, $ef, $ee, $f7, $f0
TextStr_4a_43e5:           ; id $05E6
    ; "Santi:You talked to my Grandpa, / right? / Santi:So what are you doing? Just go / to the Travelers' Gate!"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $3c, $4c, $52, $62, $51, $3e, $49, $48, $42
    db $41, $62, $ef, $ee, $51, $4c, $62, $4a, $56, $62, $2a, $4f, $3e, $4b, $41, $4d
    db $3e, $5e, $62, $fa, $f7, $ef, $ee, $4f, $46, $44, $45, $51, $64, $ef, $ee, $fa
    db $f7, $ef, $ee, $36, $3e, $4b, $51, $46, $a3, $36, $4c, $62, $54, $45, $3e, $51
    db $62, $3e, $4f, $42, $ef, $ee, $56, $4c, $52, $62, $41, $4c, $46, $4b, $44, $64
    db $62, $2d, $52, $50, $51, $62, $44, $4c, $fa, $f7, $ef, $ee, $51, $4c, $62, $51
    db $45, $42, $62, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $ef, $ee, $2a
    db $3e, $51, $42, $63, $f7, $f0
TextStr_4a_445b:           ; id $05E7
    ; "Santi:Don't just stand there! / Go to the Travelers' Gate!"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $27, $4c, $4b, $67, $62, $47, $52, $50, $51
    db $ef, $ee, $50, $51, $3e, $4b, $41, $62, $51, $45, $42, $4f, $42, $63, $fa, $f7
    db $ef, $ee, $2a, $4c, $62, $51, $4c, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e
    db $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42, $63, $f7, $f0
TextStr_4a_449a:           ; id $05E8
    ; "Santi:Was the Travelers' Gate / useful to ya? [YES/NO]"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $3a, $3e, $50, $62, $51, $45, $42, $62, $ef
    db $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50, $5c, $62, $2a, $3e, $51, $42
    db $fa, $f7, $ef, $ee, $52, $50, $42, $43, $52, $49, $62, $51, $4c, $62, $56, $3e
    db $64, $ef, $ee, $ff, $f0
TextStr_4a_44cf:           ; id $05E9
    ; "Santi:Y...Ya big fool!"
    db $eb, $36, $3e, $4b, $51, $46, $a3, $3c, $5f, $5f, $5f, $3c, $3e, $ef, $ee, $3f
    db $46, $44, $62, $43, $4c, $4c, $49, $63, $f7, $f0
TextStr_4a_44e9:           ; id $05EA
    ; "Santi:I...I'm... happy....blush."
    db $eb, $36, $3e, $4b, $51, $46, $a3, $2c, $5f, $5f, $5f, $2c, $6a, $5f, $5f, $5f
    db $ef, $ee, $45, $3e, $4d, $4d, $56, $5f, $5f, $5f, $5f, $3f, $49, $52, $50, $45
    db $5f, $f7, $f0
TextStr_4a_450c:           ; id $05EB
    ; "*:Oh our hero [HERO]! Welcome to / the Bazaar!"
    db $eb, $9f, $a3, $32, $45, $62, $4c, $52, $4f, $62, $45, $42, $4f, $4c, $ef, $ee
    db $f6, $63, $62, $3a, $42, $49, $40, $4c, $4a, $42, $62, $51, $4c, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $25, $3e, $57, $3e, $3e, $4f, $63, $ef, $ee, $f7, $f0
TextStr_4a_453c:           ; id $05EC
    ; "*:What a good feeling to be / the winning kingdom! / *:I danced so much that I almost lost / it!"
    db $eb, $9f, $a3, $3a, $45, $3e, $51, $62, $3e, $62, $44, $4c, $4c, $41, $ef, $ee
    db $43, $42, $42, $49, $46, $4b, $44, $62, $51, $4c, $62, $3f, $42, $fa, $f7, $ef
    db $ee, $51, $45, $42, $62, $54, $46, $4b, $4b, $46, $4b, $44, $ef, $ee, $48, $46
    db $4b, $44, $41, $4c, $4a, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $41, $3e
    db $4b, $40, $42, $41, $62, $50, $4c, $62, $4a, $52, $40, $45, $ef, $ee, $51, $45
    db $3e, $51, $62, $2c, $62, $3e, $49, $4a, $4c, $50, $51, $62, $49, $4c, $50, $51
    db $fa, $f7, $ef, $ee, $46, $51, $63, $ef, $ee, $f7, $f0
TextStr_4a_45a7:           ; id $05ED
    ; "*:La la la [HERO] and / Milayou La la la... / *:This is the hit song now! It's / about you guys!"
    db $eb, $9f, $a3, $2f, $3e, $62, $49, $3e, $62, $49, $3e, $ef, $ee, $f6, $62, $3e
    db $4b, $41, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56, $4c, $52, $ef, $ee, $2f
    db $3e, $62, $49, $3e, $62, $49, $3e, $5f, $5f, $5f, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $46, $50, $62, $46, $50, $62, $51, $45, $42, $62, $45, $46, $51, $ef
    db $ee, $50, $4c, $4b, $44, $62, $4b, $4c, $54, $63, $62, $2c, $51, $68, $fa, $f7
    db $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $56, $4c, $52, $62, $44, $52, $56, $50
    db $63, $ef, $ee, $f7, $f0
TextStr_4a_460c:           ; id $05EE
    ; "*:I didn't think you could win..."
    db $eb, $9f, $a3, $2c, $62, $41, $46, $41, $4b, $67, $62, $51, $45, $46, $4b, $48
    db $ef, $ee, $56, $4c, $52, $62, $40, $4c, $52, $49, $41, $62, $54, $46, $4b, $5f
    db $5f, $5f, $f7, $f0
TextStr_4a_4630:           ; id $05EF
    ; "*:Giggle giggle! Listen listen! / *:I can be a monster master / too! / *:Mommy & Daddy said I should / become like [HERO]!"
    db $eb, $9f, $a3, $2a, $46, $44, $44, $49, $42, $62, $44, $46, $44, $44, $49, $42
    db $63, $ef, $ee, $2f, $46, $50, $51, $42, $4b, $62, $49, $46, $50, $51, $42, $4b
    db $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $40, $3e, $4b, $62, $3f, $42, $62
    db $3e, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $4a, $3e, $50, $51, $42
    db $4f, $fa, $f7, $ef, $ee, $51, $4c, $4c, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f
    db $a3, $30, $4c, $4a, $4a, $56, $62, $b6, $62, $27, $3e, $41, $41, $56, $ef, $ee
    db $50, $3e, $46, $41, $62, $2c, $62, $50, $45, $4c, $52, $49, $41, $fa, $f7, $ef
    db $ee, $3f, $42, $40, $4c, $4a, $42, $62, $49, $46, $48, $42, $ef, $ee, $f6, $63
    db $f7, $f0
TextStr_4a_46b2:           ; id $05F0
    ; "*:Well well, Congratulations!! / I love festivals! / *:By the way, I heard a rumor. / *:Those evil lords in the Mystic / World will not beco..."
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $54, $42, $49, $49, $5e, $ef, $ee, $26
    db $4c, $4b, $44, $4f, $3e, $51, $52, $49, $3e, $51, $46, $4c, $4b, $50, $63, $63
    db $fa, $f7, $ef, $ee, $2c, $62, $49, $4c, $53, $42, $62, $43, $42, $50, $51, $46
    db $53, $3e, $49, $50, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $56, $62
    db $51, $45, $42, $62, $54, $3e, $56, $5e, $62, $2c, $62, $ef, $ee, $45, $42, $3e
    db $4f, $41, $62, $3e, $62, $4f, $52, $4a, $4c, $4f, $5f, $fa, $f7, $ef, $ee, $9f
    db $a3, $37, $45, $4c, $50, $42, $62, $42, $53, $46, $49, $62, $49, $4c, $4f, $41
    db $50, $ef, $ee, $46, $4b, $62, $51, $45, $42, $62, $30, $56, $50, $51, $46, $40
    db $fa, $f7, $ef, $ee, $3a, $4c, $4f, $49, $41, $62, $54, $46, $49, $49, $62, $4b
    db $4c, $51, $ef, $ee, $3f, $42, $40, $4c, $4a, $42, $62, $56, $4c, $52, $4f, $62
    db $4d, $3e, $49, $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $42
    db $53, $46, $49, $62, $49, $4c, $4f, $41, $50, $9c, $ef, $ee, $49, $46, $48, $42
    db $62, $40, $4f, $42, $3e, $51, $52, $4f, $42, $50, $62, $40, $3e, $4b, $fa, $f7
    db $ef, $ee, $3f, $42, $62, $4a, $3e, $41, $42, $62, $51, $45, $4f, $4c, $52, $44
    db $45, $62, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $5f, $fa, $f7, $ef
    db $ee, $9f, $a3, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $46, $43, $62, $46
    db $51, $68, $ef, $ee, $4d, $4c, $50, $50, $46, $3f, $49, $42, $64, $f7, $f0
TextStr_4a_47c1:           ; id $05F1
    ; "*:Well of course! You're the victor!"
    db $ea, $9f, $a3, $3a, $42, $49, $49, $62, $4c, $43, $62, $40, $4c, $52, $4f, $50
    db $42, $63, $ef, $ee, $3c, $4c, $52, $69, $42, $62, $51, $45, $42, $62, $53, $46
    db $40, $51, $4c, $4f, $63, $f7, $f0
TextStr_4a_47e8:           ; id $05F2
    ; "*:Hi! / *:How about a reward for your / victory? [YES/NO]"
    db $eb, $9f, $a3, $2b, $46, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2b, $4c
    db $54, $62, $3e, $3f, $4c, $52, $51, $62, $3e, $ef, $ee, $4f, $42, $54, $3e, $4f
    db $41, $62, $43, $4c, $4f, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $53, $46
    db $40, $51, $4c, $4f, $56, $64, $ef, $ee, $ff, $f0
TextStr_4a_4822:           ; id $05F3
    ; "*:Okay."
    db $eb, $9f, $a3, $32, $48, $3e, $56, $5f, $ef, $ee, $f7, $f0
TextStr_4a_482e:           ; id $05F4
    ; "*:...tickle ...tickle, tickle / *:tickle, tickle tickle, tickle / *:Keep it up!"
    db $eb, $9f, $a3, $5f, $5f, $5f, $51, $46, $40, $48, $49, $42, $ef, $ee, $5f, $5f
    db $5f, $51, $46, $40, $48, $49, $42, $5e, $62, $51, $46, $40, $48, $49, $42, $fa
    db $f7, $ef, $ee, $9f, $a3, $51, $46, $40, $48, $49, $42, $5e, $62, $51, $46, $40
    db $48, $49, $42, $ef, $ee, $51, $46, $40, $48, $49, $42, $5e, $62, $51, $46, $40
    db $48, $49, $42, $fa, $f7, $ef, $ee, $9f, $a3, $2e, $42, $42, $4d, $62, $46, $51
    db $62, $52, $4d, $63, $ef, $ee, $f7, $f0
TextStr_4a_4886:           ; id $05F5
    ; "*:Oh, what a joy! [HERO] won! / *:That merchant seems to have / changed his attitude! / *:This is probably because [HERO] / won! / *:You wan..."
    db $ea, $9f, $a3, $32, $45, $5e, $62, $54, $45, $3e, $51, $62, $3e, $62, $47, $4c
    db $56, $63, $ef, $ee, $f6, $62, $54, $4c, $4b, $63, $fa, $f7, $ef, $ee, $9f, $a3
    db $37, $45, $3e, $51, $62, $4a, $42, $4f, $40, $45, $3e, $4b, $51, $ef, $ee, $50
    db $42, $42, $4a, $50, $62, $51, $4c, $62, $45, $3e, $53, $42, $62, $fa, $f7, $ef
    db $ee, $40, $45, $3e, $4b, $44, $42, $41, $62, $45, $46, $50, $62, $ef, $ee, $3e
    db $51, $51, $46, $51, $52, $41, $42, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45
    db $46, $50, $62, $46, $50, $62, $4d, $4f, $4c, $3f, $3e, $3f, $49, $56, $ef, $ee
    db $3f, $42, $40, $3e, $52, $50, $42, $62, $f6, $fa, $f7, $ef, $ee, $54, $4c, $4b
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $62, $54, $3e, $4b
    db $4b, $3e, $62, $48, $4b, $4c, $54, $ef, $ee, $3e, $3f, $4c, $52, $51, $62, $51
    db $45, $42, $62, $3f, $4c, $4c, $48, $50, $62, $fa, $f7, $ef, $ee, $45, $42, $62
    db $50, $42, $49, $49, $50, $64, $ef, $ee, $ff, $f0
TextStr_4a_4940:           ; id $05F6
    ; "*:Oh, the hero of GreatTree, / Master [HERO]! / *:I bet you want to know about the / items sold in the store? [YES/NO]"
    db $ea, $9f, $a3, $32, $45, $5e, $62, $51, $45, $42, $62, $45, $42, $4f, $4c, $62
    db $4c, $43, $ef, $ee, $2a, $4f, $42, $3e, $51, $37, $4f, $42, $42, $5e, $62, $fa
    db $f7, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $f6, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $62, $3f, $42, $51, $62, $56, $4c, $52, $62, $54, $3e
    db $4b, $51, $62, $ef, $ee, $51, $4c, $62, $48, $4b, $4c, $54, $62, $3e, $3f, $4c
    db $52, $51, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $46, $51, $42, $4a, $50, $62
    db $50, $4c, $49, $41, $62, $46, $4b, $62, $51, $45, $42, $62, $ef, $ee, $50, $51
    db $4c, $4f, $42, $64, $ff, $f0
TextStr_4a_49b6:           ; id $05F7
    ; "*:Yes, of course. The victor / wouldn't ask such a thing!"
    db $ea, $9f, $a3, $3c, $42, $50, $5e, $62, $4c, $43, $62, $40, $4c, $52, $4f, $50
    db $42, $5f, $ef, $ee, $37, $45, $42, $62, $53, $46, $40, $51, $4c, $4f, $62, $fa
    db $f7, $ef, $ee, $54, $4c, $52, $49, $41, $4b, $67, $62, $3e, $50, $48, $62, $50
    db $52, $40, $45, $ef, $ee, $3e, $62, $51, $45, $46, $4b, $44, $63, $f7, $f0
TextStr_4a_49f5:           ; id $05F8
    ; "*:The monstrous master was your / sister!! / *:I am happy that you were finally / able to find your sister! / *:I heard wishes come true whe..."
    db $eb, $9f, $a3, $37, $45, $42, $62, $4a, $4c, $4b, $50, $51, $4f, $4c, $52, $50
    db $ef, $ee, $4a, $3e, $50, $51, $42, $4f, $62, $54, $3e, $50, $62, $56, $4c, $52
    db $4f, $62, $fa, $f7, $ef, $ee, $50, $46, $50, $51, $42, $4f, $63, $63, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $3e, $4a, $62, $45, $3e, $4d, $4d, $56
    db $62, $51, $45, $3e, $51, $62, $ef, $ee, $56, $4c, $52, $62, $54, $42, $4f, $42
    db $62, $43, $46, $4b, $3e, $49, $49, $56, $fa, $f7, $ef, $ee, $3e, $3f, $49, $42
    db $62, $51, $4c, $62, $43, $46, $4b, $41, $62, $56, $4c, $52, $4f, $ef, $ee, $50
    db $46, $50, $51, $42, $4f, $63, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42
    db $3e, $4f, $41, $62, $54, $46, $50, $45, $42, $50, $ef, $ee, $40, $4c, $4a, $42
    db $62, $51, $4f, $52, $42, $62, $54, $45, $42, $4b, $fa, $f7, $ef, $ee, $56, $4c
    db $52, $62, $54, $46, $4b, $62, $51, $45, $42, $62, $ef, $ee, $51, $4c, $52, $4f
    db $4b, $3e, $4a, $42, $4b, $51, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52
    db $4f, $62, $54, $46, $50, $45, $ef, $ee, $40, $3e, $4a, $42, $62, $51, $4f, $52
    db $42, $63, $62, $2c, $62, $fa, $f7, $ef, $ee, $54, $4c, $4b, $41, $42, $4f, $62
    db $46, $43, $62, $4a, $46, $4b, $42, $ef, $ee, $54, $46, $49, $49, $62, $51, $4c
    db $4c, $5f, $f7, $f0
TextStr_4a_4ae9:           ; id $05F9
    ; "*:Hey! Our hero [HERO]! / *:The two of us are eating this / yummy meat to celebrate your / victory!"
    db $ea, $9f, $a3, $2b, $42, $56, $63, $62, $32, $52, $4f, $62, $45, $42, $4f, $4c
    db $ef, $ee, $f6, $63, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $51, $54
    db $4c, $62, $4c, $43, $62, $52, $50, $ef, $ee, $3e, $4f, $42, $62, $42, $3e, $51
    db $46, $4b, $44, $62, $51, $45, $46, $50, $fa, $f7, $ef, $ee, $56, $52, $4a, $4a
    db $56, $62, $4a, $42, $3e, $51, $62, $51, $4c, $ef, $ee, $40, $42, $49, $42, $3f
    db $4f, $3e, $51, $42, $62, $56, $4c, $52, $4f, $fa, $f7, $ef, $ee, $53, $46, $40
    db $51, $4c, $4f, $56, $63, $ef, $ee, $f7, $f0
TextStr_4a_4b52:           ; id $05FA
    ; "*:Missing... Something missing. / *:Entertainment! Gimme / entertainment!! / *:Master [HERO], Do you know of / the skill Call? / *:I really ..."
    db $ea, $9f, $a3, $30, $46, $50, $50, $46, $4b, $44, $5f, $5f, $5f, $ef, $ee, $36
    db $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $4a, $46, $50, $50, $46, $4b, $44
    db $5f, $fa, $f7, $ef, $ee, $9f, $a3, $28, $4b, $51, $42, $4f, $51, $3e, $46, $4b
    db $4a, $42, $4b, $51, $63, $ef, $ee, $2a, $46, $4a, $4a, $42, $62, $fa, $f7, $ef
    db $ee, $42, $4b, $51, $42, $4f, $51, $3e, $46, $4b, $4a, $42, $4b, $51, $63, $63
    db $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $3e, $50, $51, $42, $4f, $62, $f6
    db $5e, $ef, $ee, $27, $4c, $62, $56, $4c, $52, $62, $48, $4b, $4c, $54, $62, $4c
    db $43, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $50, $48, $46, $49, $49, $62, $26
    db $3e, $49, $49, $64, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $4f, $42
    db $3e, $49, $49, $56, $62, $54, $3e, $4b, $51, $62, $51, $4c, $ef, $ee, $50, $42
    db $42, $62, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $51, $45, $3e, $51
    db $fa, $f7, $ef, $ee, $40, $3e, $4b, $62, $52, $50, $42, $62, $26, $3e, $49, $49
    db $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $45, $42, $3e, $4f, $41
    db $62, $26, $3e, $49, $49, $ef, $ee, $40, $3e, $4b, $62, $46, $4b, $50, $51, $3e
    db $4b, $51, $49, $56, $fa, $f7, $ef, $ee, $40, $3e, $49, $49, $62, $43, $4c, $4f
    db $51, $45, $62, $3e, $49, $49, $56, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $51, $62, $50, $4c, $52, $4b, $41
    db $50, $62, $43, $52, $4b, $63, $ef, $ee, $36, $45, $4c, $54, $62, $46, $51, $62
    db $51, $4c, $62, $4a, $42, $63, $63, $f7, $f0
TextStr_4a_4c7b:           ; id $05FB
    ; "*:...I wonder if you brought a / monster with Call?"
    db $ea, $9f, $a3, $5f, $5f, $5f, $2c, $62, $54, $4c, $4b, $41, $42, $4f, $62, $46
    db $43, $ef, $ee, $56, $4c, $52, $62, $3f, $4f, $4c, $52, $44, $45, $51, $62, $3e
    db $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $46, $51, $45
    db $ef, $ee, $26, $3e, $49, $49, $64, $fa, $f7, $f0
TextStr_4a_4cb5:           ; id $05FC
    ; "*:Oh! You brought it here! Show me / the magic!"
    db $ea, $9f, $a3, $32, $45, $63, $62, $3c, $4c, $52, $62, $3f, $4f, $4c, $52, $44
    db $45, $51, $ef, $ee, $46, $51, $62, $45, $42, $4f, $42, $63, $62, $36, $45, $4c
    db $54, $62, $4a, $42, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4a, $3e, $44, $46
    db $40, $63, $ef, $ee, $f7, $f0
TextStr_4a_4ceb:           ; id $05FD
    ; "[INS 00] cast Call! / But nothing happened."
    db $f9, $00, $62, $40, $3e, $50, $51, $ef, $ee, $26, $3e, $49, $49, $63, $fa, $f7
    db $ef, $ee, $25, $52, $51, $62, $4b, $4c, $51, $45, $46, $4b, $44, $ef, $ee, $45
    db $3e, $4d, $4d, $42, $4b, $42, $41, $5f, $f7, $f0
TextStr_4a_4d15:           ; id $05FE
    ; "*:What the heck? Nothing happened! / What's going on Master [HERO]? / *:What? The monsters said it / doesn't want to be put in a show? / *:...."
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $51, $45, $42, $62, $45, $42, $40, $48
    db $64, $ef, $ee, $31, $4c, $51, $45, $46, $4b, $44, $62, $45, $3e, $4d, $4d, $42
    db $4b, $42, $41, $63, $fa, $f7, $ef, $ee, $3a, $45, $3e, $51, $68, $62, $44, $4c
    db $46, $4b, $44, $62, $4c, $4b, $ef, $ee, $30, $3e, $50, $51, $42, $4f, $62, $f6
    db $64, $fa, $f7, $ef, $ee, $9f, $a3, $3a, $45, $3e, $51, $64, $62, $37, $45, $42
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $50, $3e, $46, $41, $62
    db $46, $51, $fa, $f7, $ef, $ee, $41, $4c, $42, $50, $4b, $67, $62, $54, $3e, $4b
    db $51, $62, $51, $4c, $ef, $ee, $3f, $42, $62, $4d, $52, $51, $62, $46, $4b, $62
    db $3e, $62, $50, $45, $4c, $54, $64, $fa, $f7, $ef, $ee, $9f, $a3, $5f, $5f, $5f
    db $32, $45, $62, $54, $42, $49, $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3
    db $36, $4c, $4f, $4f, $56, $62, $f6, $5f, $ef, $ee, $30, $56, $62, $3e, $4d, $4c
    db $49, $4c, $44, $46, $42, $50, $5f, $5f, $5f, $f7, $f0
TextStr_4a_4dd0:           ; id $05FF
    ; "*:You knew it right? / This is the Travelers' Gate. / *:I don't think you're surprised. / But its my way of apologizing."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $48, $4b, $42, $54, $62, $46, $51, $ef, $ee
    db $4f, $46, $44, $45, $51, $64, $fa, $f7, $ef, $ee, $37, $45, $46, $50, $62, $46
    db $50, $62, $51, $45, $42, $ef, $ee, $37, $4f, $3e, $53, $42, $49, $42, $4f, $50
    db $5c, $62, $2a, $3e, $51, $42, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $62, $41
    db $4c, $4b, $67, $62, $51, $45, $46, $4b, $48, $ef, $ee, $56, $4c, $52, $69, $42
    db $62, $50, $52, $4f, $4d, $4f, $46, $50, $42, $41, $5f, $fa, $f7, $ef, $ee, $25
    db $52, $51, $62, $46, $51, $50, $62, $4a, $56, $62, $54, $3e, $56, $62, $4c, $43
    db $ef, $ee, $3e, $4d, $4c, $49, $4c, $44, $46, $57, $46, $4b, $44, $5f, $f7, $f0
TextStr_4a_4e50:           ; id $0600
    ; "*:Come to me when you want to breed / with my monsters!"
    db $ea, $9f, $a3, $26, $4c, $4a, $42, $62, $51, $4c, $62, $4a, $42, $62, $54, $45
    db $42, $4b, $ef, $ee, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c, $62
    db $3f, $4f, $42, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $4a, $56
    db $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee, $f7, $f0
TextStr_4a_4e8e:           ; id $0601
    ; "Why not breed with my [INS 00]?"
    db $ea, $3a, $45, $56, $62, $4b, $4c, $51, $62, $3f, $4f, $42, $42, $41, $62, $54
    db $46, $51, $45, $ef, $ee, $4a, $56, $62, $f9, $00, $64, $f0
TextStr_4a_4eaa:           ; id $0602
    ; "*:Which monster do you want to breed / with [INS 00]?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $41, $4c, $ef, $ee, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c
    db $62, $3f, $4f, $42, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $f9
    db $00, $64, $ef, $ee, $f0
TextStr_4a_4edf:           ; id $0603
    ; "*:You can't breed low level / monsters!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $67, $62, $3f, $4f, $42, $42
    db $41, $ef, $ee, $49, $4c, $54, $62, $49, $42, $53, $42, $49, $fa, $f7, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_4f0d:           ; id $0604
    ; "*:There will be no monsters to take / with you!"
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $46, $49, $49, $62, $3f, $42
    db $62, $4b, $4c, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $4c
    db $62, $51, $3e, $48, $42, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c
    db $52, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_4f44:           ; id $0605
    ; "*:Are you okay with this monster?"
    db $ea, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $4c, $48, $3e, $56, $ef
    db $ee, $54, $46, $51, $45, $62, $51, $45, $46, $50, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $64, $f0
TextStr_4a_4f68:           ; id $0606
    ; "*:Start the breeding ceremony?"
    db $ea, $9f, $a3, $36, $51, $3e, $4f, $51, $62, $51, $45, $42, $ef, $ee, $3f, $4f
    db $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42, $4a, $4c, $4b, $56, $64
    db $f0
TextStr_4a_4f89:           ; id $0607
    ; "*:I have no idea what kind of egg / it will be... / *:But can I record the results in the / Journal?"
    db $ea, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $4b, $4c, $62, $46, $41, $42
    db $3e, $ef, $ee, $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $62
    db $42, $44, $44, $fa, $f7, $ef, $ee, $46, $51, $62, $54, $46, $49, $49, $62, $3f
    db $42, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62
    db $40, $3e, $4b, $62, $2c, $62, $4f, $42, $40, $4c, $4f, $41, $ef, $ee, $51, $45
    db $42, $62, $4f, $42, $50, $52, $49, $51, $50, $62, $46, $4b, $62, $51, $45, $42
    db $fa, $f7, $ef, $ee, $2d, $4c, $52, $4f, $4b, $3e, $49, $64, $ef, $ee, $f0
TextStr_4a_4ff8:           ; id $0608
    ; "*:Let's begin the breeding ceremony!"
    db $ea, $9f, $a3, $2f, $42, $51, $68, $62, $3f, $42, $44, $46, $4b, $62, $51, $45
    db $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42
    db $4a, $4c, $4b, $56, $63, $f7, $f0
TextStr_4a_501f:           ; id $0609
    ; "*:I hope a strong monster will be / born! / *:I'll send the egg to the farm!"
    db $ea, $9f, $a3, $2c, $62, $45, $4c, $4d, $42, $62, $3e, $62, $50, $51, $4f, $4c
    db $4b, $44, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $46, $49, $49
    db $62, $3f, $42, $fa, $f7, $ef, $ee, $3f, $4c, $4f, $4b, $63, $ef, $ee, $fa, $f7
    db $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $42, $4b, $41, $62, $51, $45, $42
    db $ef, $ee, $42, $44, $44, $62, $51, $4c, $62, $51, $45, $42, $62, $43, $3e, $4f
    db $4a, $63, $f7, $f0
TextStr_4a_5073:           ; id $060A
    ; "*:My Eyeder loves devils. Want to / breed?"
    db $ea, $9f, $a3, $30, $56, $62, $28, $56, $42, $41, $42, $4f, $62, $49, $4c, $53
    db $42, $50, $ef, $ee, $41, $42, $53, $46, $49, $50, $5f, $62, $3a, $3e, $4b, $51
    db $62, $51, $4c, $fa, $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $64, $ef, $ee, $f7
    db $f0
TextStr_4a_50a4:           ; id $060B
    ; "*:Which monster will you breed / with my Eyeder?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $54, $46, $49, $49, $62, $56, $4c, $52, $62, $3f, $4f, $42, $42, $41
    db $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $28, $56, $42, $41
    db $42, $4f, $64, $ef, $ee, $f7, $f0
TextStr_4a_50db:           ; id $060C
    ; "*:Why not breed with my Yeti?"
    db $ea, $9f, $a3, $3a, $45, $56, $62, $4b, $4c, $51, $62, $3f, $4f, $42, $42, $41
    db $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $3c, $42, $51, $46, $64, $f7
    db $f0
TextStr_4a_50fc:           ; id $060D
    ; "*:Which monster will you breed / with my Yeti?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $54, $46, $49, $49, $62, $56, $4c, $52, $62, $3f, $4f, $42, $42, $41
    db $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $3c, $42, $51, $46
    db $64, $ef, $ee, $f7, $f0
TextStr_4a_5131:           ; id $060E $060F $0610
    ; "*:Tut, stingy. Hic..."
    db $ea, $9f, $a3, $37, $52, $51, $5e, $62, $50, $51, $46, $4b, $44, $56, $5f, $ef
    db $ee, $2b, $46, $40, $5f, $5f, $5f, $f7, $f0
TextStr_4a_514a:           ; id $0611
    ; "Why don't you breed with / my CatFly?"
    db $ea, $3a, $45, $56, $62, $41, $4c, $4b, $67, $62, $56, $4c, $52, $ef, $ee, $3f
    db $4f, $42, $42, $41, $62, $54, $46, $51, $45, $fa, $f7, $ef, $ee, $4a, $56, $62
    db $26, $3e, $51, $29, $49, $56, $64, $ef, $ee, $f0
TextStr_4a_5174:           ; id $0612
    ; "*:Which monster do you want to breed / with my CatFly?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $41, $4c, $ef, $ee, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c
    db $62, $3f, $4f, $42, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $4a
    db $56, $62, $26, $3e, $51, $29, $49, $56, $64, $ef, $ee, $f0
TextStr_4a_51b0:           ; id $0613
    ; "*:I can't let mine breed with low / level monsters."
    db $ea, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $49, $42, $51, $62, $4a, $46
    db $4b, $42, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $62, $49
    db $4c, $54, $fa, $f7, $ef, $ee, $49, $42, $53, $42, $49, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $50, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4a_51ea:           ; id $0614
    ; "*:You won't have any monsters / to take with ya!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $54, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $3e, $4b, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $fa, $f7
    db $ef, $ee, $51, $4c, $62, $51, $3e, $48, $42, $62, $54, $46, $51, $45, $62, $56
    db $3e, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_5221:           ; id $0615
    ; "*:With this monster? / Are you sure?"
    db $ea, $9f, $a3, $3a, $46, $51, $45, $62, $51, $45, $46, $50, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $64, $fa, $f7, $ef, $ee, $24, $4f, $42, $62, $56, $4c
    db $52, $62, $50, $52, $4f, $42, $64, $ef, $ee, $f0
TextStr_4a_524b:           ; id $0616
    ; "*:Start the breeding ceremony?"
    db $ea, $9f, $a3, $36, $51, $3e, $4f, $51, $62, $51, $45, $42, $ef, $ee, $3f, $4f
    db $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42, $4a, $4c, $4b, $56, $64
    db $f0
TextStr_4a_526c:           ; id $0617
    ; "*:I can't tell what kinda / monster it'll be. / *:Is it okay to record it in the / Journal?"
    db $ea, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $51, $42, $49, $49, $ef, $ee
    db $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $3e, $fa, $f7, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $62, $46, $51, $66, $49, $62, $3f, $42, $5f, $ef, $ee
    db $fa, $f7, $ef, $ee, $9f, $a3, $2c, $50, $62, $46, $51, $62, $4c, $48, $3e, $56
    db $62, $51, $4c, $ef, $ee, $4f, $42, $40, $4c, $4f, $41, $62, $46, $51, $62, $46
    db $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2d, $4c, $52, $4f, $4b, $3e, $49
    db $64, $ef, $ee, $f0
TextStr_4a_52d0:           ; id $0618
    ; "*:Let's begin the breeding ceremony!"
    db $ea, $9f, $a3, $2f, $42, $51, $68, $62, $3f, $42, $44, $46, $4b, $62, $51, $45
    db $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42
    db $4a, $4c, $4b, $56, $63, $f7, $f0
TextStr_4a_52f7:           ; id $0619
    ; "*:Hope a strong monster will be / born! / *:I'll send the egg to the farm!"
    db $ea, $9f, $a3, $2b, $4c, $4d, $42, $62, $3e, $62, $50, $51, $4f, $4c, $4b, $44
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $46, $49, $49, $62, $3f
    db $42, $fa, $f7, $ef, $ee, $3f, $4c, $4f, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee
    db $9f, $a3, $2c, $66, $49, $62, $50, $42, $4b, $41, $62, $51, $45, $42, $ef, $ee
    db $42, $44, $44, $62, $51, $4c, $62, $51, $45, $42, $62, $43, $3e, $4f, $4a, $63
    db $f7, $f0
TextStr_4a_5349:           ; id $061A $061B $061C $061D $061E $061F $0620
    ; "*:Well, if you want to breed / again, stop by. / *:The LizardMan says AgDevil is / its type!"
    db $ea, $9f, $a3, $3a, $42, $49, $49, $5e, $62, $46, $43, $62, $56, $4c, $52, $ef
    db $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $3f, $4f, $42, $42, $41, $fa, $f7
    db $ef, $ee, $3e, $44, $3e, $46, $4b, $5e, $62, $50, $51, $4c, $4d, $62, $3f, $56
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $37, $45, $42, $62, $2f, $46, $57
    db $3e, $4f, $41, $30, $3e, $4b, $ef, $ee, $50, $3e, $56, $50, $62, $24, $44, $27
    db $42, $53, $46, $49, $62, $46, $50, $fa, $f7, $ef, $ee, $46, $51, $50, $62, $51
    db $56, $4d, $42, $63, $ef, $ee, $f7, $f0
TextStr_4a_53b1:           ; id $0621
    ; "*:Why not breed with my / LizardMan?"
    db $ea, $9f, $a3, $3a, $45, $56, $62, $4b, $4c, $51, $ef, $ee, $3f, $4f, $42, $42
    db $41, $62, $54, $46, $51, $45, $62, $4a, $56, $fa, $f7, $ef, $ee, $2f, $46, $57
    db $3e, $4f, $41, $30, $3e, $4b, $64, $ef, $ee, $f0
TextStr_4a_53db:           ; id $0622
    ; "*:Which one are you gonna breed / with the LizardMan?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4c, $4b, $42, $62, $3e, $4f, $42
    db $ef, $ee, $56, $4c, $52, $62, $44, $4c, $4b, $4b, $3e, $62, $3f, $4f, $42, $42
    db $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $42, $ef, $ee, $2f
    db $46, $57, $3e, $4f, $41, $30, $3e, $4b, $64, $f0
TextStr_4a_5415:           ; id $0623
    ; "*:Hey, your monster is weak. / That monster level is out of / the question...!"
    db $ea, $9f, $a3, $2b, $42, $56, $5e, $62, $56, $4c, $52, $4f, $ef, $ee, $4a, $4c
    db $4b, $50, $51, $42, $4f, $62, $46, $50, $62, $54, $42, $3e, $48, $5f, $fa, $f7
    db $ef, $ee, $37, $45, $3e, $51, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $ef, $ee
    db $49, $42, $53, $42, $49, $62, $46, $50, $62, $4c, $52, $51, $62, $4c, $43, $fa
    db $f7, $ef, $ee, $51, $45, $42, $62, $4e, $52, $42, $50, $51, $46, $4c, $4b, $5f
    db $5f, $5f, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_546d:           ; id $0624
    ; "*:Hey! You won't have any monsters / to take with you!"
    db $ea, $9f, $a3, $2b, $42, $56, $63, $62, $3c, $4c, $52, $62, $54, $4c, $4b, $67
    db $ef, $ee, $45, $3e, $53, $42, $62, $3e, $4b, $56, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $3e, $48, $42, $62, $54
    db $46, $51, $45, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_54aa:           ; id $0625
    ; "*:Are you okay with this monster?"
    db $ea, $9f, $a3, $24, $4f, $42, $62, $56, $4c, $52, $62, $4c, $48, $3e, $56, $ef
    db $ee, $54, $46, $51, $45, $62, $51, $45, $46, $50, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $64, $f0
TextStr_4a_54ce:           ; id $0626
    ; "*:Start the breeding ceremony?"
    db $ea, $9f, $a3, $36, $51, $3e, $4f, $51, $62, $51, $45, $42, $ef, $ee, $3f, $4f
    db $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42, $4a, $4c, $4b, $56, $64
    db $f0
TextStr_4a_54ef:           ; id $0627
    ; "*:I don't know what kind of egg / will be born. / *:But I'm gonna record the results / in the Journal. Okay?"
    db $ea, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $48, $4b, $4c, $54, $ef, $ee
    db $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $62, $42, $44, $44
    db $fa, $f7, $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $3f, $4c, $4f, $4b
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $2c, $6a, $62
    db $44, $4c, $4b, $4b, $3e, $ef, $ee, $4f, $42, $40, $4c, $4f, $41, $62, $51, $45
    db $42, $62, $4f, $42, $50, $52, $49, $51, $50, $fa, $f7, $ef, $ee, $46, $4b, $62
    db $51, $45, $42, $62, $2d, $4c, $52, $4f, $4b, $3e, $49, $5f, $ef, $ee, $32, $48
    db $3e, $56, $64, $f0
TextStr_4a_5563:           ; id $0628
    ; "*:Let's begin the breeding ceremony!"
    db $ea, $9f, $a3, $2f, $42, $51, $68, $62, $3f, $42, $44, $46, $4b, $62, $51, $45
    db $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42
    db $4a, $4c, $4b, $56, $63, $f7, $f0
TextStr_4a_558a:           ; id $0629
    ; "*:Well, you should be at least half / my level. / *:I'll send the egg to the farm!"
    db $ea, $9f, $a3, $3a, $42, $49, $49, $5e, $62, $56, $4c, $52, $62, $50, $45, $4c
    db $52, $49, $41, $ef, $ee, $3f, $42, $62, $3e, $51, $62, $49, $42, $3e, $50, $51
    db $62, $45, $3e, $49, $43, $fa, $f7, $ef, $ee, $4a, $56, $62, $49, $42, $53, $42
    db $49, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $42
    db $4b, $41, $62, $51, $45, $42, $ef, $ee, $42, $44, $44, $62, $51, $4c, $62, $51
    db $45, $42, $62, $43, $3e, $4f, $4a, $63, $f7, $f0
TextStr_4a_55e4:           ; id $062A $062B $062C $062D $062E $062F $0630
    ; "Mick:I'll be on my journey by the / time you fight in C class."
    db $ea, $30, $46, $40, $48, $a3, $2c, $66, $49, $62, $3f, $42, $62, $4c, $4b, $ef
    db $ee, $4a, $56, $62, $47, $4c, $52, $4f, $4b, $42, $56, $62, $3f, $56, $62, $51
    db $45, $42, $fa, $f7, $ef, $ee, $51, $46, $4a, $42, $62, $56, $4c, $52, $62, $43
    db $46, $44, $45, $51, $62, $46, $4b, $ef, $ee, $26, $62, $40, $49, $3e, $50, $50
    db $5f, $f7, $f0
TextStr_4a_5627:           ; id $0631
    ; "Mick:Let's breed with my DeadNite!!"
    db $ea, $30, $46, $40, $48, $a3, $2f, $42, $51, $68, $62, $3f, $4f, $42, $42, $41
    db $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $27, $42, $3e, $41, $31, $46
    db $51, $42, $63, $63, $f0
TextStr_4a_564c:           ; id $0632
    ; "Mick:Who do you want to pick for / DeadNite?"
    db $ea, $30, $46, $40, $48, $a3, $3a, $45, $4c, $62, $41, $4c, $62, $56, $4c, $52
    db $ef, $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $4d, $46, $40, $48, $62, $43
    db $4c, $4f, $fa, $f7, $ef, $ee, $27, $42, $3e, $41, $31, $46, $51, $42, $64, $ef
    db $ee, $f0
TextStr_4a_567e:           ; id $0633
    ; "Mick:Your monster's level is / too low to breed."
    db $ea, $30, $46, $40, $48, $a3, $3c, $4c, $52, $4f, $ef, $ee, $4a, $4c, $4b, $50
    db $51, $42, $4f, $68, $62, $49, $42, $53, $42, $49, $62, $46, $50, $fa, $f7, $ef
    db $ee, $51, $4c, $4c, $62, $49, $4c, $54, $62, $51, $4c, $62, $3f, $4f, $42, $42
    db $41, $5f, $ef, $ee, $f7, $f0
TextStr_4a_56b4:           ; id $0634
    ; "Mick:You won't have any monsters / to take with you!"
    db $ea, $30, $46, $40, $48, $a3, $3c, $4c, $52, $62, $54, $4c, $4b, $67, $ef, $ee
    db $45, $3e, $53, $42, $62, $3e, $4b, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $3e, $48, $42, $62, $54, $46, $51
    db $45, $62, $56, $4c, $52, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_56ef:           ; id $0635
    ; "Mick:With this one? Are you sure?"
    db $ea, $30, $46, $40, $48, $a3, $3a, $46, $51, $45, $62, $51, $45, $46, $50, $ef
    db $ee, $4c, $4b, $42, $64, $62, $24, $4f, $42, $62, $56, $4c, $52, $62, $50, $52
    db $4f, $42, $64, $f0
TextStr_4a_5713:           ; id $0636
    ; "Mick:Start the breeding ceremony?"
    db $ea, $30, $46, $40, $48, $a3, $36, $51, $3e, $4f, $51, $62, $51, $45, $42, $ef
    db $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42, $4a, $4c
    db $4b, $56, $64, $f0
TextStr_4a_5737:           ; id $0637
    ; "*:I have no idea what kind of egg / it'll be... / *:Is it okay to record it in / the Journal?"
    db $ea, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $4b, $4c, $62, $46, $41, $42
    db $3e, $ef, $ee, $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $62
    db $42, $44, $44, $fa, $f7, $ef, $ee, $46, $51, $66, $49, $62, $3f, $42, $5f, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $50, $62, $46, $51, $62, $4c
    db $48, $3e, $56, $ef, $ee, $51, $4c, $62, $4f, $42, $40, $4c, $4f, $41, $62, $46
    db $51, $62, $46, $4b, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $2d, $4c, $52, $4f
    db $4b, $3e, $49, $64, $ef, $ee, $f0
TextStr_4a_579e:           ; id $0638
    ; "*:Let's begin the breeding ceremony!"
    db $ea, $9f, $a3, $2f, $42, $51, $68, $62, $3f, $42, $44, $46, $4b, $62, $51, $45
    db $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42
    db $4a, $4c, $4b, $56, $63, $f7, $f0
TextStr_4a_57c5:           ; id $0639
    ; "*:This egg is the proof of our / friendship. / *:I'll send it to the farm!"
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $42, $44, $44, $62, $46, $50, $62, $51
    db $45, $42, $ef, $ee, $4d, $4f, $4c, $4c, $43, $62, $4c, $43, $62, $4c, $52, $4f
    db $fa, $f7, $ef, $ee, $43, $4f, $46, $42, $4b, $41, $50, $45, $46, $4d, $5f, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $42, $4b, $41, $62
    db $46, $51, $62, $51, $4c, $ef, $ee, $51, $45, $42, $62, $43, $3e, $4f, $4a, $63
    db $f7, $f0
TextStr_4a_5817:           ; id $063A $063B $063C $063D $063E $063F $0640
    ; "*:Please come to me when you want / to breed again! / *:My Rayburn loves birds!"
    db $eb, $9f, $a3, $33, $49, $42, $3e, $50, $42, $62, $40, $4c, $4a, $42, $62, $51
    db $4c, $ef, $ee, $4a, $42, $62, $54, $45, $42, $4b, $62, $56, $4c, $52, $62, $54
    db $3e, $4b, $51, $fa, $f7, $ef, $ee, $51, $4c, $62, $3f, $4f, $42, $42, $41, $62
    db $3e, $44, $3e, $46, $4b, $63, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $30, $56
    db $62, $35, $3e, $56, $3f, $52, $4f, $4b, $62, $49, $4c, $53, $42, $50, $ef, $ee
    db $3f, $46, $4f, $41, $50, $63, $f7, $f0
TextStr_4a_586f:           ; id $0641
    ; "*:Want to breed with my Rayburn?"
    db $eb, $9f, $a3, $3a, $3e, $4b, $51, $62, $51, $4c, $62, $3f, $4f, $42, $42, $41
    db $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $35, $3e, $56, $3f, $52, $4f
    db $4b, $64, $f0
TextStr_4a_5892:           ; id $0642
    ; "*:Which monster are you picking / for my Rayburn?"
    db $eb, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $3e, $4f, $42, $62, $56, $4c, $52, $62, $4d, $46, $40, $48, $46, $4b
    db $44, $fa, $f7, $ef, $ee, $43, $4c, $4f, $62, $4a, $56, $62, $35, $3e, $56, $3f
    db $52, $4f, $4b, $64, $ef, $ee, $f0
TextStr_4a_58c9:           ; id $0643
    ; "*:I don't want to breed with a low / level monster!"
    db $eb, $9f, $a3, $2c, $62, $41, $4c, $4b, $67, $62, $54, $3e, $4b, $51, $62, $51
    db $4c, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $62, $3e, $62
    db $49, $4c, $54, $fa, $f7, $ef, $ee, $49, $42, $53, $42, $49, $62, $4a, $4c, $4b
    db $50, $51, $42, $4f, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_5903:           ; id $0644
    ; "*:You'll have no monsters to / take with you!"
    db $eb, $9f, $a3, $3c, $4c, $52, $66, $49, $62, $45, $3e, $53, $42, $ef, $ee, $4b
    db $4c, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $4c, $fa, $f7, $ef
    db $ee, $51, $3e, $48, $42, $62, $54, $46, $51, $45, $62, $56, $4c, $52, $63, $ef
    db $ee, $fa, $f7, $f0
TextStr_4a_5937:           ; id $0645
    ; "*:Is this monster okay?"
    db $eb, $9f, $a3, $2c, $50, $62, $51, $45, $46, $50, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $ef, $ee, $4c, $48, $3e, $56, $64, $f0
TextStr_4a_5951:           ; id $0646
    ; "*:Can I start the breeding ceremony?"
    db $eb, $9f, $a3, $26, $3e, $4b, $62, $2c, $62, $50, $51, $3e, $4f, $51, $62, $51
    db $45, $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f
    db $42, $4a, $4c, $4b, $56, $64, $f0
TextStr_4a_5978:           ; id $0647
    ; "*:I have no idea what kind of egg / it'll be... / *:Can I record it in the Journal?"
    db $eb, $9f, $a3, $2c, $62, $45, $3e, $53, $42, $62, $4b, $4c, $62, $46, $41, $42
    db $3e, $ef, $ee, $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $62
    db $42, $44, $44, $fa, $f7, $ef, $ee, $46, $51, $66, $49, $62, $3f, $42, $5f, $5f
    db $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $26, $3e, $4b, $62, $2c, $62, $4f
    db $42, $40, $4c, $4f, $41, $62, $46, $51, $ef, $ee, $46, $4b, $62, $51, $45, $42
    db $62, $2d, $4c, $52, $4f, $4b, $3e, $49, $64, $f0
TextStr_4a_59d2:           ; id $0648
    ; "*:Let's start the breeding ceremony!"
    db $eb, $9f, $a3, $2f, $42, $51, $68, $62, $50, $51, $3e, $4f, $51, $62, $51, $45
    db $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42, $4f, $42
    db $4a, $4c, $4b, $56, $63, $f7, $f0
TextStr_4a_59f9:           ; id $0649
    ; "*:I hope it'll be a strong monster. / *:I'll send the egg to the farm."
    db $eb, $9f, $a3, $2c, $62, $45, $4c, $4d, $42, $62, $46, $51, $66, $49, $62, $3f
    db $42, $ef, $ee, $3e, $62, $50, $51, $4f, $4c, $4b, $44, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $5f, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $42
    db $4b, $41, $62, $51, $45, $42, $ef, $ee, $42, $44, $44, $62, $51, $4c, $62, $51
    db $45, $42, $62, $43, $3e, $4f, $4a, $5f, $f7, $f0
TextStr_4a_5a43:           ; id $064A $064B $064C $064D $064E $064F $0650
    ; "*:Pay me a visit when you want to / breed."
    db $ea, $9f, $a3, $33, $3e, $56, $62, $4a, $42, $62, $3e, $62, $53, $46, $50, $46
    db $51, $ef, $ee, $54, $45, $42, $4b, $62, $56, $4c, $52, $62, $54, $3e, $4b, $51
    db $62, $51, $4c, $fa, $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $5f, $ef, $ee, $f7
    db $f0
TextStr_4a_5a74:           ; id $0651
    ; "*:Why not breed with my [INS 00]?"
    db $ea, $9f, $a3, $3a, $45, $56, $62, $4b, $4c, $51, $62, $3f, $4f, $42, $42, $41
    db $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $f9, $00, $64, $f0
TextStr_4a_5a92:           ; id $0652
    ; "*:Which monster are you going to / breed with my [INS 00]?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $3e, $4f, $42, $62, $56, $4c, $52, $62, $44, $4c, $46, $4b, $44, $62
    db $51, $4c, $fa, $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45
    db $62, $4a, $56, $ef, $ee, $f9, $00, $64, $f0
TextStr_4a_5acb:           ; id $0653
    ; "*:Cannot breed with a low level / monster."
    db $ea, $9f, $a3, $26, $3e, $4b, $4b, $4c, $51, $62, $3f, $4f, $42, $42, $41, $ef
    db $ee, $54, $46, $51, $45, $62, $3e, $62, $49, $4c, $54, $62, $49, $42, $53, $42
    db $49, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $5f, $ef, $ee, $fa
    db $f7, $f0
TextStr_4a_5afd:           ; id $0654
    ; "*:You'll have no monsters to take / with you!"
    db $ea, $9f, $a3, $3c, $4c, $52, $66, $49, $62, $45, $3e, $53, $42, $62, $4b, $4c
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $51, $4c, $62, $51, $3e
    db $48, $42, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c, $52, $63, $ef
    db $ee, $fa, $f7, $f0
TextStr_4a_5b31:           ; id $0655
    ; "*:This monster? Are you sure?"
    db $ea, $9f, $a3, $37, $45, $46, $50, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $64
    db $ef, $ee, $24, $4f, $42, $62, $56, $4c, $52, $62, $50, $52, $4f, $42, $64, $f0
TextStr_4a_5b51:           ; id $0656
    ; "*:Can we start the breeding ceremony?"
    db $ea, $9f, $a3, $26, $3e, $4b, $62, $54, $42, $62, $50, $51, $3e, $4f, $51, $62
    db $51, $45, $42, $ef, $ee, $3f, $4f, $42, $42, $41, $46, $4b, $44, $62, $40, $42
    db $4f, $42, $4a, $4c, $4b, $56, $64, $f0
TextStr_4a_5b79:           ; id $0657
    ; "*:I can't imagine what kind of egg / it will be. / *:But are you sure this is to be / recorded in the Journal?"
    db $ea, $9f, $a3, $2c, $62, $40, $3e, $4b, $67, $62, $46, $4a, $3e, $44, $46, $4b
    db $42, $ef, $ee, $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $62, $4c, $43, $62
    db $42, $44, $44, $fa, $f7, $ef, $ee, $46, $51, $62, $54, $46, $49, $49, $62, $3f
    db $42, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $9f, $a3, $25, $52, $51, $62, $3e, $4f
    db $42, $62, $56, $4c, $52, $62, $50, $52, $4f, $42, $ef, $ee, $51, $45, $46, $50
    db $62, $46, $50, $62, $51, $4c, $62, $3f, $42, $fa, $f7, $ef, $ee, $4f, $42, $40
    db $4c, $4f, $41, $42, $41, $62, $46, $4b, $62, $51, $45, $42, $ef, $ee, $2d, $4c
    db $52, $4f, $4b, $3e, $49, $64, $f0
TextStr_4a_5bf0:           ; id $0658
    ; "*:Then, let us begin the / ceremony."
    db $ea, $9f, $a3, $37, $45, $42, $4b, $5e, $62, $49, $42, $51, $62, $52, $50, $ef
    db $ee, $3f, $42, $44, $46, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $40, $42
    db $4f, $42, $4a, $4c, $4b, $56, $5f, $ef, $ee, $f7, $f0
TextStr_4a_5c1b:           ; id $0659
    ; "*:Hopefully a strong monster / will be born! / *:I'll send the egg to the farm!"
    db $ea, $9f, $a3, $2b, $4c, $4d, $42, $43, $52, $49, $49, $56, $62, $3e, $ef, $ee
    db $50, $51, $4f, $4c, $4b, $44, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7
    db $ef, $ee, $54, $46, $49, $49, $62, $3f, $42, $62, $3f, $4c, $4f, $4b, $63, $ef
    db $ee, $fa, $f7, $ef, $ee, $9f, $a3, $2c, $66, $49, $62, $50, $42, $4b, $41, $62
    db $51, $45, $42, $ef, $ee, $42, $44, $44, $62, $51, $4c, $62, $51, $45, $42, $62
    db $43, $3e, $4f, $4a, $63, $f7, $f0
TextStr_4a_5c72:           ; id $065A
    ; "*:Why not breed with my Metabble!"
    db $ea, $9f, $a3, $3a, $45, $56, $62, $4b, $4c, $51, $62, $3f, $4f, $42, $42, $41
    db $ef, $ee, $54, $46, $51, $45, $62, $4a, $56, $62, $30, $42, $51, $3e, $3f, $3f
    db $49, $42, $63, $f7, $f0
TextStr_4a_5c97:           ; id $065B
    ; "*:Which monster do you want to breed / with my Metabble?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $41, $4c, $ef, $ee, $56, $4c, $52, $62, $54, $3e, $4b, $51, $62, $51, $4c
    db $62, $3f, $4f, $42, $42, $41, $fa, $f7, $ef, $ee, $54, $46, $51, $45, $62, $4a
    db $56, $62, $30, $42, $51, $3e, $3f, $3f, $49, $42, $64, $ef, $ee, $f7, $f0
TextStr_4a_5cd6:           ; id $065C $065D $065E $065F $0660
    ; "Milayou:Come back when you wanna / breed."
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $26, $4c, $4a, $42, $62, $3f, $3e
    db $40, $48, $ef, $ee, $54, $45, $42, $4b, $62, $56, $4c, $52, $62, $54, $3e, $4b
    db $4b, $3e, $fa, $f7, $ef, $ee, $3f, $4f, $42, $42, $41, $5f, $ef, $ee, $f7, $f0
TextStr_4a_5d06:           ; id $0661
    ; "Milayou:Breed with my Skeletor!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $25, $4f, $42, $42, $41, $62, $54
    db $46, $51, $45, $ef, $ee, $4a, $56, $62, $36, $48, $42, $49, $42, $51, $4c, $4f
    db $63, $f0
TextStr_4a_5d28:           ; id $0662
    ; "Milayou:Which monster will you / pick for my Skeletor?"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $3a, $45, $46, $40, $45, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $62, $54, $46, $49, $49, $62, $56, $4c, $52
    db $fa, $f7, $ef, $ee, $4d, $46, $40, $48, $62, $43, $4c, $4f, $62, $4a, $56, $ef
    db $ee, $36, $48, $42, $49, $42, $51, $4c, $4f, $64, $f0
TextStr_4a_5d63:           ; id $0663
    ; "Milayou:A low level monster / can't breed!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $24, $62, $49, $4c, $54, $ef, $ee
    db $49, $42, $53, $42, $49, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $fa, $f7, $ef
    db $ee, $40, $3e, $4b, $67, $62, $3f, $4f, $42, $42, $41, $63, $ef, $ee, $fa, $f7
    db $f0
TextStr_4a_5d94:           ; id $0664
    ; "Milayou:You won't have any monster / to take with you."
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $3c, $4c, $52, $62, $54, $4c, $4b
    db $67, $ef, $ee, $45, $3e, $53, $42, $62, $3e, $4b, $56, $62, $4a, $4c, $4b, $50
    db $51, $42, $4f, $fa, $f7, $ef, $ee, $51, $4c, $62, $51, $3e, $48, $42, $62, $54
    db $46, $51, $45, $62, $56, $4c, $52, $5f, $ef, $ee, $fa, $f7, $f0
TextStr_4a_5dd1:           ; id $0665
    ; "Milayou:Is this monster okay?"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2c, $50, $62, $51, $45, $46, $50
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $4c, $48, $3e, $56, $64, $f0
TextStr_4a_5df1:           ; id $0666
    ; "Milayou:I'll start the breeding / ceremony, okay?"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2c, $66, $49, $62, $50, $51, $3e
    db $4f, $51, $ef, $ee, $51, $45, $42, $62, $3f, $4f, $42, $42, $41, $46, $4b, $44
    db $fa, $f7, $ef, $ee, $40, $42, $4f, $42, $4a, $4c, $4b, $56, $5e, $62, $4c, $48
    db $3e, $56, $64, $ef, $ee, $f0
TextStr_4a_5e27:           ; id $0667
    ; "Milayou:I don't know what kind of / egg it'll be... / Milayou:Can I record it in the / Journal?"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2c, $62, $41, $4c, $4b, $67, $ef
    db $ee, $48, $4b, $4c, $54, $62, $54, $45, $3e, $51, $62, $48, $46, $4b, $41, $62
    db $4c, $43, $fa, $f7, $ef, $ee, $42, $44, $44, $62, $46, $51, $66, $49, $62, $3f
    db $42, $5f, $5f, $5f, $ef, $ee, $fa, $f7, $ef, $ee, $30, $46, $49, $3e, $56, $4c
    db $52, $a3, $26, $3e, $4b, $62, $2c, $ef, $ee, $4f, $42, $40, $4c, $4f, $41, $62
    db $46, $51, $62, $46, $4b, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $2d, $4c, $52
    db $4f, $4b, $3e, $49, $64, $ef, $ee, $f0
TextStr_4a_5e8f:           ; id $0668
    ; "Milayou:Let's breed!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2f, $42, $51, $68, $ef, $ee, $3f
    db $4f, $42, $42, $41, $63, $f7, $f0
TextStr_4a_5ea6:           ; id $0669
    ; "Milayou:I hope it'll be a strong / monster! / Milayou:I'm gonna send the egg to / the farm!"
    db $eb, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2c, $62, $45, $4c, $4d, $42, $ef
    db $ee, $46, $51, $66, $49, $62, $3f, $42, $62, $3e, $62, $50, $51, $4f, $4c, $4b
    db $44, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $30, $46, $49, $3e, $56, $4c, $52, $a3, $2c, $6a, $62, $44, $4c
    db $4b, $4b, $3e, $ef, $ee, $50, $42, $4b, $41, $62, $51, $45, $42, $62, $42, $44
    db $44, $62, $51, $4c, $fa, $f7, $ef, $ee, $51, $45, $42, $62, $43, $3e, $4f, $4a
    db $63, $ef, $ee, $f7, $f0
TextStr_4a_5f0b:           ; id $066A $066B $066C $066D $066E $066F $0670 $0671 $0672 $0673 $0674 $0675 $0676 $0677 $0678 $0679 $067A $067B $067C $067D $067E $067F $0680
    ; "*:Item shop. May I help you?"
    db $ea, $9f, $a3, $2c, $51, $42, $4a, $62, $50, $45, $4c, $4d, $5f, $ef, $ee, $30
    db $3e, $56, $62, $2c, $62, $45, $42, $49, $4d, $62, $56, $4c, $52, $64, $f0
TextStr_4a_5f2a:           ; id $0681
    ; "*:Anything else?"
    db $ea, $9f, $a3, $24, $4b, $56, $51, $45, $46, $4b, $44, $62, $42, $49, $50, $42
    db $64, $ef, $ee, $f0
TextStr_4a_5f3e:           ; id $0682
    ; "*:Thank you. Come again!"
    db $ea, $9f, $a3, $37, $45, $3e, $4b, $48, $62, $56, $4c, $52, $5f, $ef, $ee, $26
    db $4c, $4a, $42, $62, $3e, $44, $3e, $46, $4b, $63, $f7, $f0
TextStr_4a_5f5a:           ; id $0683
    ; "*:What would you like?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $54, $4c, $52, $49, $41, $62, $56, $4c
    db $52, $ef, $ee, $49, $46, $48, $42, $64, $f0
TextStr_4a_5f73:           ; id $0684
    ; "*:What would you like?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $54, $4c, $52, $49, $41, $62, $56, $4c
    db $52, $ef, $ee, $49, $46, $48, $42, $64, $f0
TextStr_4a_5f8c:           ; id $0685
    ; "*:How many?"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $4a, $3e, $4b, $56, $64, $ef, $ee, $f0
TextStr_4a_5f9b:           ; id $0686
    ; "[INS 10] X [INS 00] is [INS 20]G."
    db $ea, $f9, $10, $62, $3b, $62, $f9, $00, $ef, $ee, $46, $50, $62, $f9, $20, $2a
    db $5f, $f0
TextStr_4a_5fad:           ; id $0687
    ; "*:You don't have enough money."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $42, $4b, $4c, $52, $44, $45, $62, $4a, $4c, $4b, $42, $56, $5f, $fa
    db $f7, $f0
TextStr_4a_5fcf:           ; id $0688
    ; "*:You can only carry 20 items!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4c, $4b, $49, $56, $ef
    db $ee, $40, $3e, $4f, $4f, $56, $62, $02, $00, $62, $46, $51, $42, $4a, $50, $63
    db $fa, $f7, $f0
TextStr_4a_5ff2:           ; id $0689
    ; "*:Thank you!"
    db $ea, $9f, $a3, $37, $45, $3e, $4b, $48, $62, $56, $4c, $52, $63, $ef, $ee, $f7
    db $f0
TextStr_4a_6003:           ; id $068A
    ; "*:Which items will you sell to me?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $46, $51, $42, $4a, $50, $62, $54
    db $46, $49, $49, $ef, $ee, $56, $4c, $52, $62, $50, $42, $49, $49, $62, $51, $4c
    db $62, $4a, $42, $64, $f0
TextStr_4a_6028:           ; id $068B
    ; "*:You don't have items I can buy."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $46, $51, $42, $4a, $50, $62, $2c, $62, $40, $3e, $4b, $62, $3f, $52
    db $56, $5f, $fa, $f7, $f0
TextStr_4a_604d:           ; id $068C
    ; "*:How many would you like to sell?"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $4a, $3e, $4b, $56, $62, $54, $4c, $52, $49
    db $41, $ef, $ee, $56, $4c, $52, $62, $49, $46, $48, $42, $62, $51, $4c, $62, $50
    db $42, $49, $49, $64, $f0
TextStr_4a_6072:           ; id $068D
    ; "[INS 10] X [INS 00] is [INS 20]G."
    db $ea, $f9, $10, $62, $3b, $62, $f9, $00, $ef, $ee, $46, $50, $62, $f9, $20, $2a
    db $5f, $f0
TextStr_4a_6084:           ; id $068E
    ; "*:You can only have up to / 99999G!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $62, $4c, $4b, $49, $56, $ef
    db $ee, $45, $3e, $53, $42, $62, $52, $4d, $62, $51, $4c, $fa, $f7, $ef, $ee, $09
    db $09, $09, $09, $09, $2a, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_60af:           ; id $068F
    ; "*:Thanks again!"
    db $ea, $9f, $a3, $37, $45, $3e, $4b, $48, $50, $62, $3e, $44, $3e, $46, $4b, $63
    db $ef, $ee, $f7, $f0
TextStr_4a_60c3:           ; id $0690 $0691 $0692 $0693 $0694 $0695 $0696 $0697 $0698 $0699 $069A $069B $069C $069D $069E $069F $06A0
    ; "*:Vault. May I help you?"
    db $ea, $9f, $a3, $39, $3e, $52, $49, $51, $5f, $ef, $ee, $30, $3e, $56, $62, $2c
    db $62, $45, $42, $49, $4d, $62, $56, $4c, $52, $64, $f0
TextStr_4a_60de:           ; id $06A1
    ; "*:Something else?"
    db $ea, $9f, $a3, $36, $4c, $4a, $42, $51, $45, $46, $4b, $44, $62, $42, $49, $50
    db $42, $64, $ef, $ee, $f0
TextStr_4a_60f3:           ; id $06A2
    ; "*:Come again anytime."
    db $ea, $9f, $a3, $26, $4c, $4a, $42, $62, $3e, $44, $3e, $46, $4b, $ef, $ee, $3e
    db $4b, $56, $51, $46, $4a, $42, $5f, $f7, $f0
TextStr_4a_610c:           ; id $06A3
    ; "*:What would you like us to store?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $54, $4c, $52, $49, $41, $62, $56, $4c
    db $52, $ef, $ee, $49, $46, $48, $42, $62, $52, $50, $62, $51, $4c, $62, $50, $51
    db $4c, $4f, $42, $64, $f0
TextStr_4a_6131:           ; id $06A4
    ; "*:Which one?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4c, $4b, $42, $64, $ef, $ee, $f0
TextStr_4a_6141:           ; id $06A5
    ; "*:You don't have anything."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $3e, $4b, $56, $51, $45, $46, $4b, $44, $5f, $fa, $f7, $f0
TextStr_4a_615f:           ; id $06A6
    ; "*:Sorry. We can't store anymore."
    db $ea, $9f, $a3, $36, $4c, $4f, $4f, $56, $5f, $62, $3a, $42, $62, $40, $3e, $4b
    db $67, $ef, $ee, $50, $51, $4c, $4f, $42, $62, $3e, $4b, $56, $4a, $4c, $4f, $42
    db $5f, $fa, $f7, $f0
TextStr_4a_6183:           ; id $06A7
    ; "*:How many?"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $4a, $3e, $4b, $56, $64, $f0
TextStr_4a_6190:           ; id $06A8
    ; "*:Too much!"
    db $ea, $9f, $a3, $37, $4c, $4c, $62, $4a, $52, $40, $45, $63, $fa, $f7, $f0
TextStr_4a_619f:           ; id $06A9
    ; "*:You're in safe hands with us."
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $46, $4b, $62, $50, $3e, $43, $42
    db $ef, $ee, $45, $3e, $4b, $41, $50, $62, $54, $46, $51, $45, $62, $52, $50, $5f
    db $fa, $f7, $f0
TextStr_4a_61c2:           ; id $06AA
    ; "*:How much do you want to deposit?"
    db $ea, $9f, $a3, $2b, $4c, $54, $62, $4a, $52, $40, $45, $62, $41, $4c, $62, $56
    db $4c, $52, $ef, $ee, $54, $3e, $4b, $51, $62, $51, $4c, $62, $41, $42, $4d, $4c
    db $50, $46, $51, $64, $f0
TextStr_4a_61e7:           ; id $06AB
    ; "*:Not enough money."
    db $ea, $9f, $a3, $31, $4c, $51, $62, $42, $4b, $4c, $52, $44, $45, $ef, $ee, $4a
    db $4c, $4b, $42, $56, $5f, $fa, $f7, $f0
TextStr_4a_61ff:           ; id $06AC
    ; "*:Excuse me but you can only / deposit up to 999999G."
    db $ea, $9f, $a3, $28, $55, $40, $52, $50, $42, $62, $4a, $42, $62, $3f, $52, $51
    db $ef, $ee, $56, $4c, $52, $62, $40, $3e, $4b, $62, $4c, $4b, $49, $56, $fa, $f7
    db $ef, $ee, $41, $42, $4d, $4c, $50, $46, $51, $62, $52, $4d, $62, $51, $4c, $ef
    db $ee, $09, $09, $09, $09, $09, $09, $2a, $5f, $fa, $f7, $f0
TextStr_4a_623b:           ; id $06AD
    ; "*:You're in safe hands with us."
    db $ea, $9f, $a3, $3c, $4c, $52, $69, $42, $62, $46, $4b, $62, $50, $3e, $43, $42
    db $ef, $ee, $45, $3e, $4b, $41, $50, $62, $54, $46, $51, $45, $62, $52, $50, $5f
    db $fa, $f7, $f0
TextStr_4a_625e:           ; id $06AE
    ; "*:What would you like to take out?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $54, $4c, $52, $49, $41, $62, $56, $4c
    db $52, $ef, $ee, $49, $46, $48, $42, $62, $51, $4c, $62, $51, $3e, $48, $42, $62
    db $4c, $52, $51, $64, $f0
TextStr_4a_6283:           ; id $06AF
    ; "*:We don't have any of your gold."
    db $ea, $9f, $a3, $3a, $42, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42, $ef
    db $ee, $3e, $4b, $56, $62, $4c, $43, $62, $56, $4c, $52, $4f, $62, $44, $4c, $49
    db $41, $5f, $fa, $f7, $f0
TextStr_4a_62a8:           ; id $06B0
    ; "*:Take out items or withdraw gold?"
    db $ea, $9f, $a3, $37, $3e, $48, $42, $62, $4c, $52, $51, $62, $46, $51, $42, $4a
    db $50, $ef, $ee, $4c, $4f, $62, $54, $46, $51, $45, $41, $4f, $3e, $54, $62, $44
    db $4c, $49, $41, $64, $f0
TextStr_4a_62cd:           ; id $06B1
    ; "*:We don't have any of your items."
    db $ea, $9f, $a3, $3a, $42, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42, $ef
    db $ee, $3e, $4b, $56, $62, $4c, $43, $62, $56, $4c, $52, $4f, $62, $46, $51, $42
    db $4a, $50, $5f, $fa, $f7, $f0
TextStr_4a_62f3:           ; id $06B2
    ; "*:Too much stuff to store."
    db $ea, $9f, $a3, $37, $4c, $4c, $62, $4a, $52, $40, $45, $62, $50, $51, $52, $43
    db $43, $ef, $ee, $51, $4c, $62, $50, $51, $4c, $4f, $42, $5f, $fa, $f7, $f0
TextStr_4a_6312:           ; id $06B3
    ; "*:Take out how many?"
    db $ea, $9f, $a3, $37, $3e, $48, $42, $62, $4c, $52, $51, $62, $45, $4c, $54, $ef
    db $ee, $4a, $3e, $4b, $56, $64, $f0
TextStr_4a_6329:           ; id $06B4
    ; "*:You have too much to carry!"
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $45, $3e, $53, $42, $62, $51, $4c, $4c, $ef
    db $ee, $4a, $52, $40, $45, $62, $51, $4c, $62, $40, $3e, $4f, $4f, $56, $63, $fa
    db $f7, $f0
TextStr_4a_634b:           ; id $06B5
    ; "*:Here it is."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $62, $46, $51, $62, $46, $50, $5f, $ef, $ee
    db $fa, $f7, $f0
TextStr_4a_635e:           ; id $06B6
    ; "*:Withdraw how much?"
    db $ea, $9f, $a3, $3a, $46, $51, $45, $41, $4f, $3e, $54, $ef, $ee, $45, $4c, $54
    db $62, $4a, $52, $40, $45, $64, $f0
TextStr_4a_6375:           ; id $06B7
    ; "*:You don't have that much money."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $41, $4c, $4b, $67, $62, $45, $3e, $53, $42
    db $ef, $ee, $51, $45, $3e, $51, $62, $4a, $52, $40, $45, $62, $4a, $4c, $4b, $42
    db $56, $5f, $fa, $f7, $f0
TextStr_4a_639a:           ; id $06B8
    ; "*:You can't carry that much money."
    db $ea, $9f, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $67, $62, $40, $3e, $4f, $4f
    db $56, $ef, $ee, $51, $45, $3e, $51, $62, $4a, $52, $40, $45, $62, $4a, $4c, $4b
    db $42, $56, $5f, $fa, $f7, $f0
TextStr_4a_63c0:           ; id $06B9
    ; "*:Here it is."
    db $ea, $9f, $a3, $2b, $42, $4f, $42, $62, $46, $51, $62, $46, $50, $5f, $ef, $ee
    db $fa, $f7, $f0
TextStr_4a_63d3:           ; id $06BA $06BB $06BC $06BD $06BE $06BF $06C0
    ; "Pulio:Hey there! Whadayagonnado?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2b, $42, $56, $62, $51, $45, $42, $4f, $42
    db $63, $ef, $ee, $3a, $45, $3e, $41, $3e, $56, $3e, $44, $4c, $4b, $4b, $3e, $41
    db $4c, $64, $f0
TextStr_4a_63f6:           ; id $06C1
    ; "Pulio:Anything else?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $24, $4b, $56, $51, $45, $46, $4b, $44, $ef
    db $ee, $42, $49, $50, $42, $64, $f0
TextStr_4a_640d:           ; id $06C2
    ; "Pulio:Later! We'll be here for ya!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2f, $3e, $51, $42, $4f, $63, $62, $3a, $42
    db $66, $49, $ef, $ee, $3f, $42, $62, $45, $42, $4f, $42, $62, $43, $4c, $4f, $62
    db $56, $3e, $63, $f7, $f0
TextStr_4a_6432:           ; id $06C3
    ; "Pulio:Drop off which one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $27, $4f, $4c, $4d, $62, $4c, $43, $43, $ef
    db $ee, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $64, $f0
TextStr_4a_644e:           ; id $06C4
    ; "Pulio:Hey, you're not gonna have / any monsters with you."
    db $eb, $33, $52, $49, $46, $4c, $a3, $2b, $42, $56, $5e, $62, $56, $4c, $52, $69
    db $42, $ef, $ee, $4b, $4c, $51, $62, $44, $4c, $4b, $4b, $3e, $62, $45, $3e, $53
    db $42, $fa, $f7, $ef, $ee, $3e, $4b, $56, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $50, $ef, $ee, $54, $46, $51, $45, $62, $56, $4c, $52, $5f, $fa, $f7, $f0
TextStr_4a_648d:           ; id $06C5
    ; "Pulio:Drop off this one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $27, $4f, $4c, $4d, $62, $4c, $43, $43, $ef
    db $ee, $51, $45, $46, $50, $62, $4c, $4b, $42, $64, $f0
TextStr_4a_64a8:           ; id $06C6
    ; "Pulio:Stop by once in a while / to see how we are doing!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $36, $51, $4c, $4d, $62, $3f, $56, $ef, $ee
    db $4c, $4b, $40, $42, $62, $46, $4b, $62, $3e, $62, $54, $45, $46, $49, $42, $fa
    db $f7, $ef, $ee, $51, $4c, $62, $50, $42, $42, $62, $45, $4c, $54, $62, $54, $42
    db $ef, $ee, $3e, $4f, $42, $62, $41, $4c, $46, $4b, $44, $63, $fa, $f7, $f0
TextStr_4a_64e7:           ; id $06C7
    ; "Pulio:Replace it?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $42, $ef, $ee
    db $46, $51, $64, $f0
TextStr_4a_64fb:           ; id $06C8
    ; "Pulio:Replace it with which one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $42, $62, $46
    db $51, $ef, $ee, $54, $46, $51, $45, $62, $54, $45, $46, $40, $45, $62, $4c, $4b
    db $42, $64, $f0
TextStr_4a_651e:           ; id $06C9
    ; "Pulio:Replace it with this one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $42, $62, $46
    db $51, $ef, $ee, $54, $46, $51, $45, $62, $51, $45, $46, $50, $62, $4c, $4b, $42
    db $64, $f0
TextStr_4a_6540:           ; id $06CA
    ; "Pulio:I replaced [INS 00] with [INS 10]!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2c, $62, $4f, $42, $4d, $49, $3e, $40, $42
    db $41, $ef, $ee, $f9, $00, $62, $54, $46, $51, $45, $62, $f9, $10, $63, $fa, $f7
    db $f0
TextStr_4a_6561:           ; id $06CB
    ; "Pulio:Picking up which one, [HERO]?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $33, $46, $40, $48, $46, $4b, $44, $62, $52
    db $4d, $ef, $ee, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $5e, $62, $f6, $64
    db $f0
TextStr_4a_6582:           ; id $06CC
    ; "Pulio:No monsters here to take."
    db $eb, $33, $52, $49, $46, $4c, $a3, $31, $4c, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $50, $ef, $ee, $45, $42, $4f, $42, $62, $51, $4c, $62, $51, $3e, $48, $42
    db $5f, $fa, $f7, $f0
TextStr_4a_65a6:           ; id $06CD
    ; "Pulio:You can't take any more!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $3c, $4c, $52, $62, $40, $3e, $4b, $67, $ef
    db $ee, $51, $3e, $48, $42, $62, $3e, $4b, $56, $62, $4a, $4c, $4f, $42, $63, $fa
    db $f7, $f0
TextStr_4a_65c8:           ; id $06CE
    ; "Pulio:You're gonna pick this one up?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $3c, $4c, $52, $69, $42, $62, $44, $4c, $4b
    db $4b, $3e, $ef, $ee, $4d, $46, $40, $48, $62, $51, $45, $46, $50, $62, $4c, $4b
    db $42, $62, $52, $4d, $64, $f0
TextStr_4a_65ee:           ; id $06CF
    ; "Pulio:Train it well, [HERO]!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $37, $4f, $3e, $46, $4b, $62, $46, $51, $ef
    db $ee, $54, $42, $49, $49, $5e, $62, $f6, $63, $fa, $f7, $f0
TextStr_4a_660a:           ; id $06D0
    ; "Pulio:Replacing a monster, [HERO]?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $46, $4b, $44
    db $ef, $ee, $3e, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $5e, $62, $f6, $64, $f0
TextStr_4a_662a:           ; id $06D1
    ; "Pulio:Which one are you replacing?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $3a, $45, $46, $40, $45, $62, $4c, $4b, $42
    db $ef, $ee, $3e, $4f, $42, $62, $56, $4c, $52, $62, $4f, $42, $4d, $49, $3e, $40
    db $46, $4b, $44, $64, $f0
TextStr_4a_664f:           ; id $06D2
    ; "Pulio:Replace this one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $42, $ef, $ee
    db $51, $45, $46, $50, $62, $4c, $4b, $42, $64, $f0
TextStr_4a_6669:           ; id $06D3
    ; "Pulio:Replace with which one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $42, $ef, $ee
    db $54, $46, $51, $45, $62, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $64, $f0
TextStr_4a_6689:           ; id $06D4
    ; "Pulio:Replace this one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $35, $42, $4d, $49, $3e, $40, $42, $ef, $ee
    db $51, $45, $46, $50, $62, $4c, $4b, $42, $64, $f0
TextStr_4a_66a3:           ; id $06D5
    ; "Pulio:I replaced [INS 00] with [INS 10]!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2c, $62, $4f, $42, $4d, $49, $3e, $40, $42
    db $41, $ef, $ee, $f9, $00, $62, $54, $46, $51, $45, $62, $f9, $10, $63, $fa, $f7
    db $f0
TextStr_4a_66c4:           ; id $06D6
    ; "Pulio:Check on which one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $26, $45, $42, $40, $48, $62, $4c, $4b, $ef
    db $ee, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $64, $f0
TextStr_4a_66e0:           ; id $06D7
    ; "Pulio:Hey, none to check on!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2b, $42, $56, $5e, $62, $4b, $4c, $4b, $42
    db $ef, $ee, $51, $4c, $62, $40, $45, $42, $40, $48, $62, $4c, $4b, $63, $fa, $f7
    db $f0
TextStr_4a_6701:           ; id $06D8
    ; "Pulio:Check on which one, [HERO]?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $26, $45, $42, $40, $48, $62, $4c, $4b, $ef
    db $ee, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $5e, $62, $f6, $64, $f0
TextStr_4a_6720:           ; id $06D9
    ; "Pulio:Check on which one, [HERO]?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $26, $45, $42, $40, $48, $62, $4c, $4b, $ef
    db $ee, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $5e, $62, $f6, $64, $f0
TextStr_4a_673f:           ; id $06DA
    ; "Pulio:Separate with which one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $36, $42, $4d, $3e, $4f, $3e, $51, $42, $ef
    db $ee, $54, $46, $51, $45, $62, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $64
    db $f0
TextStr_4a_6760:           ; id $06DB
    ; "Pulio:Hey, nothing here!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2b, $42, $56, $5e, $62, $4b, $4c, $51, $45
    db $46, $4b, $44, $ef, $ee, $45, $42, $4f, $42, $63, $fa, $f7, $f0
TextStr_4a_677d:           ; id $06DC
    ; "Pulio:Separate with which one?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $36, $42, $4d, $3e, $4f, $3e, $51, $42, $ef
    db $ee, $54, $46, $51, $45, $62, $54, $45, $46, $40, $45, $62, $4c, $4b, $42, $64
    db $f0
TextStr_4a_679e:           ; id $06DD
    ; "Pulio:Are you sure? You'll / lose it forever."
    db $eb, $33, $52, $49, $46, $4c, $a3, $24, $4f, $42, $62, $56, $4c, $52, $ef, $ee
    db $50, $52, $4f, $42, $64, $62, $3c, $4c, $52, $66, $49, $fa, $f7, $ef, $ee, $49
    db $4c, $50, $42, $62, $46, $51, $62, $43, $4c, $4f, $42, $53, $42, $4f, $5f, $ef
    db $ee, $f0
TextStr_4a_67d0:           ; id $06DE
    ; "[INS 00] was returned to the / wild."
    db $f9, $00, $62, $54, $3e, $50, $ef, $ee, $4f, $42, $51, $52, $4f, $4b, $42, $41
    db $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $54, $46, $49, $41, $5f
    db $ef, $ee, $fa, $f7, $f0
TextStr_4a_67f5:           ; id $06DF
    ; "Pulio:Are you sure? You'll / lose it forever."
    db $eb, $33, $52, $49, $46, $4c, $a3, $24, $4f, $42, $62, $56, $4c, $52, $ef, $ee
    db $50, $52, $4f, $42, $64, $62, $3c, $4c, $52, $66, $49, $fa, $f7, $ef, $ee, $49
    db $4c, $50, $42, $62, $46, $51, $62, $43, $4c, $4f, $42, $53, $42, $4f, $5f, $ef
    db $ee, $f0
TextStr_4a_6827:           ; id $06E0
    ; "[INS 00] was returned to the / wild."
    db $f9, $00, $62, $54, $3e, $50, $ef, $ee, $4f, $42, $51, $52, $4f, $4b, $42, $41
    db $62, $51, $4c, $62, $51, $45, $42, $fa, $f7, $ef, $ee, $54, $46, $49, $41, $5f
    db $ef, $ee, $fa, $f7, $f0
TextStr_4a_684c:           ; id $06E1
    ; "Pulio:Select [PICK UP] to take / the monster with you."
    db $eb, $33, $52, $49, $46, $4c, $a3, $36, $42, $49, $42, $40, $51, $ef, $ee, $96
    db $33, $2c, $26, $2e, $62, $38, $33, $97, $62, $51, $4c, $62, $51, $3e, $48, $42
    db $fa, $f7, $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $62
    db $54, $46, $51, $45, $ef, $ee, $56, $4c, $52, $5f, $f0
TextStr_4a_6887:           ; id $06E2
    ; "Pulio:You wanna make the monsters / you have in the farm go to sleep?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $3c, $4c, $52, $62, $54, $3e, $4b, $4b, $3e
    db $ef, $ee, $4a, $3e, $48, $42, $62, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51
    db $42, $4f, $50, $fa, $f7, $ef, $ee, $56, $4c, $52, $62, $45, $3e, $53, $42, $62
    db $46, $4b, $62, $51, $45, $42, $ef, $ee, $43, $3e, $4f, $4a, $62, $44, $4c, $62
    db $51, $4c, $62, $50, $49, $42, $42, $4d, $64, $f0
TextStr_4a_68d1:           ; id $06E3
    ; "Pulio:All the monsters here went / into a deep sleep!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $24, $49, $49, $62, $51, $45, $42, $ef, $ee
    db $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $45, $42, $4f, $42, $62, $54, $42
    db $4b, $51, $fa, $f7, $ef, $ee, $46, $4b, $51, $4c, $62, $3e, $62, $41, $42, $42
    db $4d, $62, $50, $49, $42, $42, $4d, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_690e:           ; id $06E4
    ; "Pulio:I put all the monsters not / sleeping into a deep sleep / Pulio:and woke up those who / were sleeping!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2c, $62, $4d, $52, $51, $62, $3e, $49, $49
    db $ef, $ee, $51, $45, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $4b
    db $4c, $51, $fa, $f7, $ef, $ee, $50, $49, $42, $42, $4d, $46, $4b, $44, $62, $46
    db $4b, $51, $4c, $62, $3e, $ef, $ee, $41, $42, $42, $4d, $62, $50, $49, $42, $42
    db $4d, $fa, $f7, $ef, $ee, $33, $52, $49, $46, $4c, $a3, $3e, $4b, $41, $62, $54
    db $4c, $48, $42, $ef, $ee, $52, $4d, $62, $51, $45, $4c, $50, $42, $62, $54, $45
    db $4c, $fa, $f7, $ef, $ee, $54, $42, $4f, $42, $62, $50, $49, $42, $42, $4d, $46
    db $4b, $44, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_6986:           ; id $06E5
    ; "Pulio:Wanna wake up the sleeping / monsters?"
    db $eb, $33, $52, $49, $46, $4c, $a3, $3a, $3e, $4b, $4b, $3e, $62, $54, $3e, $48
    db $42, $ef, $ee, $52, $4d, $62, $51, $45, $42, $62, $50, $49, $42, $42, $4d, $46
    db $4b, $44, $fa, $f7, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $64, $ef
    db $ee, $f0
TextStr_4a_69b8:           ; id $06E6
    ; "Pulio:I woke up the sleeping / monsters!"
    db $eb, $33, $52, $49, $46, $4c, $a3, $2c, $62, $54, $4c, $48, $42, $62, $52, $4d
    db $ef, $ee, $51, $45, $42, $62, $50, $49, $42, $42, $4d, $46, $4b, $44, $fa, $f7
    db $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $63, $ef, $ee, $fa, $f7, $f0
TextStr_4a_69e8:           ; id $06E7 $06E8 $06E9 $06EA $06EB $06EC $06ED $06EE $06EF $06F0
    ; "*:What can I do for you?"
    db $ea, $9f, $a3, $3a, $45, $3e, $51, $62, $40, $3e, $4b, $62, $2c, $62, $41, $4c
    db $ef, $ee, $43, $4c, $4f, $62, $56, $4c, $52, $64, $f0
TextStr_4a_6a03:           ; id $06F1
    ; "*:Anything else?"
    db $ea, $9f, $a3, $24, $4b, $56, $51, $45, $46, $4b, $44, $62, $42, $49, $50, $42
    db $64, $f0
TextStr_4a_6a15:           ; id $06F2
    ; "*:Create the ultimate monsters!"
    db $ea, $9f, $a3, $26, $4f, $42, $3e, $51, $42, $62, $51, $45, $42, $ef, $ee, $52
    db $49, $51, $46, $4a, $3e, $51, $42, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50
    db $63, $f7, $f0
TextStr_4a_6a38:           ; id $06F3
    ; "*:Which monster for the pedigree?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $ef, $ee, $43, $4c, $4f, $62, $51, $45, $42, $62, $4d, $42, $41, $46, $44, $4f
    db $42, $42, $64, $f0
TextStr_4a_6a5c:           ; id $06F4
    ; "*:Which monster to breed with?"
    db $ea, $9f, $a3, $3a, $45, $46, $40, $45, $62, $4a, $4c, $4b, $50, $51, $42, $4f
    db $62, $51, $4c, $ef, $ee, $3f, $4f, $42, $42, $41, $62, $54, $46, $51, $45, $64
    db $f0
TextStr_4a_6a7d:           ; id $06F5
    ; "*:That one? Are you sure?"
    db $ea, $9f, $a3, $37, $45, $3e, $51, $62, $4c, $4b, $42, $64, $ef, $ee, $24, $4f
    db $42, $62, $56, $4c, $52, $62, $50, $52, $4f, $42, $64, $f0
TextStr_4a_6a99:           ; id $06F6
    ; "*:There will be no monsters left!"
    db $ea, $9f, $a3, $37, $45, $42, $4f, $42, $62, $54, $46, $49, $49, $62, $3f, $42
    db $ef, $ee, $4b, $4c, $62, $4a, $4c, $4b, $50, $51, $42, $4f, $50, $62, $49, $42
    db $43, $51, $63, $fa, $f7, $f0
TextStr_4a_6abf:           ; id $06F7
    ; "*:Sorry, it's not old enough."
    db $ea, $9f, $a3, $36, $4c, $4f, $4f, $56, $5e, $62, $46, $51, $68, $62, $4b, $4c
    db $51, $ef, $ee, $4c, $49, $41, $62, $42, $4b, $4c, $52, $44, $45, $5f, $fa, $f7
    db $f0
TextStr_4a_6ae0:           ; id $06F8
    ; "*:The same gender. Cannot breed."
    db $ea, $9f, $a3, $37, $45, $42, $62, $50, $3e, $4a, $42, $62, $44, $42, $4b, $41
    db $42, $4f, $5f, $ef, $ee, $26, $3e, $4b, $4b, $4c, $51, $62, $3f, $4f, $42, $42
    db $41, $5f, $fa, $f7, $f0
TextStr_4a_6b05:           ; id $06F9
    ; "*:I bet [INS 20] / will be born! / *:You've had that monster before?!"
    db $ea, $9f, $a3, $2c, $62, $3f, $42, $51, $ef, $ee, $f9, $20, $fa, $f7, $ef, $ee
    db $54, $46, $49, $49, $62, $3f, $42, $62, $3f, $4c, $4f, $4b, $63, $ef, $ee, $fa
    db $f7, $ef, $ee, $9f, $a3, $3c, $4c, $52, $6c, $42, $62, $45, $3e, $41, $62, $51
    db $45, $3e, $51, $ef, $ee, $4a, $4c, $4b, $50, $51, $42, $4f, $62, $3f, $42, $43
    db $4c, $4f, $42, $64, $63, $fa, $f7, $f0
TextStr_4a_6b4d:           ; id $06FA
    ; "*:Hmm. Seems like a new monster?!"
    db $ea, $9f, $a3, $2b, $4a, $4a, $5f, $62, $36, $42, $42, $4a, $50, $62, $49, $46
    db $48, $42, $ef, $ee, $3e, $62, $4b, $42, $54, $62, $4a, $4c, $4b, $50, $51, $42
    db $4f, $64, $63, $fa, $f7, $f0
TextStr_4a_6b73:           ; id $06FB
    ; "*:Can I record this joyful event?"
    db $ea, $9f, $a3, $26, $3e, $4b, $62, $2c, $62, $4f, $42, $40, $4c, $4f, $41, $ef
    db $ee, $51, $45, $46, $50, $62, $47, $4c, $56, $43, $52, $49, $62, $42, $53, $42
    db $4b, $51, $64, $f0
TextStr_4a_6b97:           ; id $06FC
    ; "*:OK! Wait overnight."
    db $ea, $9f, $a3, $32, $2e, $63, $ef, $ee, $3a, $3e, $46, $51, $62, $4c, $53, $42
    db $4f, $4b, $46, $44, $45, $51, $5f, $f7, $f0
TextStr_4a_6bb0:           ; id $06FD
    ; "[INS 00] & [INS 10] disappeared."
    db $ea, $f9, $00, $62, $b6, $62, $f9, $10, $ef, $ee, $41, $46, $50, $3e, $4d, $4d
    db $42, $3e, $4f, $42, $41, $5f, $f7, $f0
TextStr_4a_6bc8:           ; id $06FE
    ; "*:Wow! It's a rare breed!"
    db $ea, $9f, $a3, $3a, $4c, $54, $63, $62, $2c, $51, $68, $62, $3e, $62, $4f, $3e
    db $4f, $42, $ef, $ee, $3f, $4f, $42, $42, $41, $63, $fa, $f7, $f0
TextStr_4a_6be5:           ; id $06FF
    ; "*:Inside it is a baby [INS 20]! / *:Costs [INS 30]G to hatch it. Okay? [YES/NO]"
    db $ea, $9f, $a3, $2c, $4b, $50, $46, $41, $42, $62, $46, $51, $62, $46, $50, $62
    db $3e, $ef, $ee, $3f, $3e, $3f, $56, $62, $f9, $20, $63, $fa, $f7, $ef, $ee, $9f
    db $a3, $26, $4c, $50, $51, $50, $62, $f9, $30, $2a, $ef, $ee, $51, $4c, $62, $45
    db $3e, $51, $40, $45, $62, $46, $51, $5f, $62, $32, $48, $3e, $56, $64, $ff, $f0
    db $00
; --- END re-sectioned text run (bank $4a) ---
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

jr_04a_6c39:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

jr_04a_6c63:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

