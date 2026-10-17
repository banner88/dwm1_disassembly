; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $04a", ROMX[$4000], BANK[$4a]

    db $4A ; Bank number

    ; Cross-bank dispatch table (293 entries)
    ; Called via: ld hl, $4AXX / rst $10
    dw LoadB4a_424b                  ; Entry 0
    dw $4263                          ; Entry 1
    dw $427B                          ; Entry 2
    dw $400B                          ; Entry 3 — mode 0 -> table $400B (mode list $4007)
    dw $404B                          ; Entry 4 — mode 1 -> table $404B (mode list $4007)
    dw $4293                          ; Entry 5 — [table $400B]; text $05E0 "*:Humpf, I don't need you!"
    dw $42B0                          ; Entry 6 — text $05E1 "*:I don't have such a name! Don't…"
    dw $4339                          ; Entry 7 — text $05E2 "*:Yep. It's Santi. How did you kn…"
    dw $437E                          ; Entry 8 — text $05E3 "Santi:Wait here for me!"
    dw $439A                          ; Entry 9 — text $05E4 "Santi:Talk to my Grandpa!!"
    dw $43B8                          ; Entry 10 — text $05E5 "Santi:C'mon, go talk to my Grandp…"
    dw $43E5                          ; Entry 11 — text $05E6 "Santi:You talked to my Grandpa, r…"
    dw $445B                          ; Entry 12 — text $05E7 "Santi:Don't just stand there! Go …"
    dw $449A                          ; Entry 13 — text $05E8 "Santi:Was the Travelers' Gate use…"
    dw $44CF                          ; Entry 14 — text $05E9 "Santi:Y...Ya big fool!"
    dw $44E9                          ; Entry 15 — text $05EA "Santi:I...I'm... happy....blush."
    dw $450C                          ; Entry 16 — text $05EB "*:Oh our hero [HERO]! Welcome to …"
    dw $453C                          ; Entry 17 — text $05EC "*:What a good feeling to be the w…"
    dw $45A7                          ; Entry 18 — text $05ED "*:La la la [HERO] and Milayou La …"
    dw $460C                          ; Entry 19 — text $05EE "*:I didn't think you could win..."
    dw $4630                          ; Entry 20 — text $05EF "*:Giggle giggle! Listen listen! *…"
    dw $46B2                          ; Entry 21 — text $05F0 "*:Well well, Congratulations!! I …"
    dw $47C1                          ; Entry 22 — text $05F1 "*:Well of course! You're the vict…"
    dw $47E8                          ; Entry 23 — text $05F2 "*:Hi! *:How about a reward for yo…"
    dw $4822                          ; Entry 24 — text $05F3 "*:Okay."
    dw $482E                          ; Entry 25 — text $05F4 "*:...tickle ...tickle, tickle *:t…"
    dw $4886                          ; Entry 26 — text $05F5 "*:Oh, what a joy! [HERO] won! *:T…"
    dw $4940                          ; Entry 27 — text $05F6 "*:Oh, the hero of GreatTree, Mast…"
    dw $49B6                          ; Entry 28 — text $05F7 "*:Yes, of course. The victor woul…"
    dw $49F5                          ; Entry 29 — text $05F8 "*:The monstrous master was your s…"
    dw $4AE9                          ; Entry 30 — text $05F9 "*:Hey! Our hero [HERO]! *:The two…"
    dw $4B52                          ; Entry 31 — text $05FA "*:Missing... Something missing. *…"
    dw $4C7B                          ; Entry 32 — text $05FB "*:...I wonder if you brought a mo…"
    dw $4CB5                          ; Entry 33 — text $05FC "*:Oh! You brought it here! Show m…"
    dw $4CEB                          ; Entry 34 — text $05FD "[INS 00] cast Call! But nothing h…"
    dw $4D15                          ; Entry 35 — text $05FE "*:What the heck? Nothing happened…"
    dw $4DD0                          ; Entry 36 — text $05FF "*:You knew it right? This is the …"
    dw $4E50                          ; Entry 37 — [table $404B]; text $0600 "*:Come to me when you want to bre…"
    dw $4E8E                          ; Entry 38 — text $0601 "Why not breed with my [INS 00]?"
    dw $4EAA                          ; Entry 39 — text $0602 "*:Which monster do you want to br…"
    dw $4EDF                          ; Entry 40 — text $0603 "*:You can't breed low level monst…"
    dw $4F0D                          ; Entry 41 — text $0604 "*:There will be no monsters to ta…"
    dw $4F44                          ; Entry 42 — text $0605 "*:Are you okay with this monster?"
    dw $4F68                          ; Entry 43 — text $0606 "*:Start the breeding ceremony?"
    dw $4F89                          ; Entry 44 — text $0607 "*:I have no idea what kind of egg…"
    dw $4FF8                          ; Entry 45 — text $0608 "*:Let's begin the breeding ceremo…"
    dw $501F                          ; Entry 46 — text $0609 "*:I hope a strong monster will be…"
    dw $5073                          ; Entry 47 — text $060A "*:My Eyeder loves devils. Want to…"
    dw $50A4                          ; Entry 48 — text $060B "*:Which monster will you breed wi…"
    dw $50DB                          ; Entry 49 — text $060C "*:Why not breed with my Yeti?"
    dw $50FC                          ; Entry 50 — text $060D "*:Which monster will you breed wi…"
    dw $5131                          ; Entry 51 — text $060E "*:Tut, stingy. Hic..."
    dw $5131                          ; Entry 52 — text $060F "*:Tut, stingy. Hic..."
    dw $5131                          ; Entry 53 — text $0610 "*:Tut, stingy. Hic..."
    dw $514A                          ; Entry 54 — text $0611 "Why don't you breed with my CatFl…"
    dw $5174                          ; Entry 55 — text $0612 "*:Which monster do you want to br…"
    dw $51B0                          ; Entry 56 — text $0613 "*:I can't let mine breed with low…"
    dw $51EA                          ; Entry 57 — text $0614 "*:You won't have any monsters to …"
    dw $5221                          ; Entry 58 — text $0615 "*:With this monster? Are you sure?"
    dw $524B                          ; Entry 59 — text $0616 "*:Start the breeding ceremony?"
    dw $526C                          ; Entry 60 — text $0617 "*:I can't tell what kinda monster…"
    dw $52D0                          ; Entry 61 — text $0618 "*:Let's begin the breeding ceremo…"
    dw $52F7                          ; Entry 62 — text $0619 "*:Hope a strong monster will be b…"
    dw $5349                          ; Entry 63 — text $061A "*:Well, if you want to breed agai…"
    dw $5349                          ; Entry 64 — text $061B "*:Well, if you want to breed agai…"
    dw $5349                          ; Entry 65 — text $061C "*:Well, if you want to breed agai…"
    dw $5349                          ; Entry 66 — text $061D "*:Well, if you want to breed agai…"
    dw $5349                          ; Entry 67 — text $061E "*:Well, if you want to breed agai…"
    dw $5349                          ; Entry 68 — text $061F "*:Well, if you want to breed agai…"
    dw $5349                          ; Entry 69 — text $0620 "*:Well, if you want to breed agai…"
    dw $53B1                          ; Entry 70 — text $0621 "*:Why not breed with my LizardMan?"
    dw $53DB                          ; Entry 71 — text $0622 "*:Which one are you gonna breed w…"
    dw $5415                          ; Entry 72 — text $0623 "*:Hey, your monster is weak. That…"
    dw $546D                          ; Entry 73 — text $0624 "*:Hey! You won't have any monster…"
    dw $54AA                          ; Entry 74 — text $0625 "*:Are you okay with this monster?"
    dw $54CE                          ; Entry 75 — text $0626 "*:Start the breeding ceremony?"
    dw $54EF                          ; Entry 76 — text $0627 "*:I don't know what kind of egg w…"
    dw $5563                          ; Entry 77 — text $0628 "*:Let's begin the breeding ceremo…"
    dw $558A                          ; Entry 78 — text $0629 "*:Well, you should be at least ha…"
    dw $55E4                          ; Entry 79 — text $062A "Mick:I'll be on my journey by the…"
    dw $55E4                          ; Entry 80 — text $062B "Mick:I'll be on my journey by the…"
    dw $55E4                          ; Entry 81 — text $062C "Mick:I'll be on my journey by the…"
    dw $55E4                          ; Entry 82 — text $062D "Mick:I'll be on my journey by the…"
    dw $55E4                          ; Entry 83 — text $062E "Mick:I'll be on my journey by the…"
    dw $55E4                          ; Entry 84 — text $062F "Mick:I'll be on my journey by the…"
    dw $55E4                          ; Entry 85 — text $0630 "Mick:I'll be on my journey by the…"
    dw $5627                          ; Entry 86 — text $0631 "Mick:Let's breed with my DeadNite…"
    dw $564C                          ; Entry 87 — text $0632 "Mick:Who do you want to pick for …"
    dw $567E                          ; Entry 88 — text $0633 "Mick:Your monster's level is too …"
    dw $56B4                          ; Entry 89 — text $0634 "Mick:You won't have any monsters …"
    dw $56EF                          ; Entry 90 — text $0635 "Mick:With this one? Are you sure?"
    dw $5713                          ; Entry 91 — text $0636 "Mick:Start the breeding ceremony?"
    dw $5737                          ; Entry 92 — text $0637 "*:I have no idea what kind of egg…"
    dw $579E                          ; Entry 93 — text $0638 "*:Let's begin the breeding ceremo…"
    dw $57C5                          ; Entry 94 — text $0639 "*:This egg is the proof of our fr…"
    dw $5817                          ; Entry 95 — text $063A "*:Please come to me when you want…"
    dw $5817                          ; Entry 96 — text $063B "*:Please come to me when you want…"
    dw $5817                          ; Entry 97 — text $063C "*:Please come to me when you want…"
    dw $5817                          ; Entry 98 — text $063D "*:Please come to me when you want…"
    dw $5817                          ; Entry 99 — text $063E "*:Please come to me when you want…"
    dw $5817                          ; Entry 100 — text $063F "*:Please come to me when you want…"
    dw $5817                          ; Entry 101 — text $0640 "*:Please come to me when you want…"
    dw $586F                          ; Entry 102 — text $0641 "*:Want to breed with my Rayburn?"
    dw $5892                          ; Entry 103 — text $0642 "*:Which monster are you picking f…"
    dw $58C9                          ; Entry 104 — text $0643 "*:I don't want to breed with a lo…"
    dw $5903                          ; Entry 105 — text $0644 "*:You'll have no monsters to take…"
    dw $5937                          ; Entry 106 — text $0645 "*:Is this monster okay?"
    dw $5951                          ; Entry 107 — text $0646 "*:Can I start the breeding ceremo…"
    dw $5978                          ; Entry 108 — text $0647 "*:I have no idea what kind of egg…"
    dw $59D2                          ; Entry 109 — text $0648 "*:Let's start the breeding ceremo…"
    dw $59F9                          ; Entry 110 — text $0649 "*:I hope it'll be a strong monste…"
    dw $5A43                          ; Entry 111 — text $064A "*:Pay me a visit when you want to…"
    dw $5A43                          ; Entry 112 — text $064B "*:Pay me a visit when you want to…"
    dw $5A43                          ; Entry 113 — text $064C "*:Pay me a visit when you want to…"
    dw $5A43                          ; Entry 114 — text $064D "*:Pay me a visit when you want to…"
    dw $5A43                          ; Entry 115 — text $064E "*:Pay me a visit when you want to…"
    dw $5A43                          ; Entry 116 — text $064F "*:Pay me a visit when you want to…"
    dw $5A43                          ; Entry 117 — text $0650 "*:Pay me a visit when you want to…"
    dw $5A74                          ; Entry 118 — text $0651 "*:Why not breed with my [INS 00]?"
    dw $5A92                          ; Entry 119 — text $0652 "*:Which monster are you going to …"
    dw $5ACB                          ; Entry 120 — text $0653 "*:Cannot breed with a low level m…"
    dw $5AFD                          ; Entry 121 — text $0654 "*:You'll have no monsters to take…"
    dw $5B31                          ; Entry 122 — text $0655 "*:This monster? Are you sure?"
    dw $5B51                          ; Entry 123 — text $0656 "*:Can we start the breeding cerem…"
    dw $5B79                          ; Entry 124 — text $0657 "*:I can't imagine what kind of eg…"
    dw $5BF0                          ; Entry 125 — text $0658 "*:Then, let us begin the ceremony."
    dw $5C1B                          ; Entry 126 — text $0659 "*:Hopefully a strong monster will…"
    dw $5C72                          ; Entry 127 — text $065A "*:Why not breed with my Metabble!"
    dw $5C97                          ; Entry 128 — text $065B "*:Which monster do you want to br…"
    dw $5CD6                          ; Entry 129 — text $065C "Milayou:Come back when you wanna …"
    dw $5CD6                          ; Entry 130 — text $065D "Milayou:Come back when you wanna …"
    dw $5CD6                          ; Entry 131 — text $065E "Milayou:Come back when you wanna …"
    dw $5CD6                          ; Entry 132 — text $065F "Milayou:Come back when you wanna …"
    dw $5CD6                          ; Entry 133 — text $0660 "Milayou:Come back when you wanna …"
    dw $5D06                          ; Entry 134 — text $0661 "Milayou:Breed with my Skeletor!"
    dw $5D28                          ; Entry 135 — text $0662 "Milayou:Which monster will you pi…"
    dw $5D63                          ; Entry 136 — text $0663 "Milayou:A low level monster can't…"
    dw $5D94                          ; Entry 137 — text $0664 "Milayou:You won't have any monste…"
    dw $5DD1                          ; Entry 138 — text $0665 "Milayou:Is this monster okay?"
    dw $5DF1                          ; Entry 139 — text $0666 "Milayou:I'll start the breeding c…"
    dw $5E27                          ; Entry 140 — text $0667 "Milayou:I don't know what kind of…"
    dw $5E8F                          ; Entry 141 — text $0668 "Milayou:Let's breed!"
    dw $5EA6                          ; Entry 142 — text $0669 "Milayou:I hope it'll be a strong …"
    dw $5F0B                          ; Entry 143 — text $066A "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 144 — text $066B "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 145 — text $066C "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 146 — text $066D "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 147 — text $066E "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 148 — text $066F "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 149 — text $0670 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 150 — text $0671 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 151 — text $0672 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 152 — text $0673 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 153 — text $0674 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 154 — text $0675 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 155 — text $0676 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 156 — text $0677 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 157 — text $0678 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 158 — text $0679 "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 159 — text $067A "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 160 — text $067B "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 161 — text $067C "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 162 — text $067D "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 163 — text $067E "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 164 — text $067F "*:Item shop. May I help you?"
    dw $5F0B                          ; Entry 165 — text $0680 "*:Item shop. May I help you?"
    dw $5F2A                          ; Entry 166 — text $0681 "*:Anything else?"
    dw $5F3E                          ; Entry 167 — text $0682 "*:Thank you. Come again!"
    dw $5F5A                          ; Entry 168 — text $0683 "*:What would you like?"
    dw $5F73                          ; Entry 169 — text $0684 "*:What would you like?"
    dw $5F8C                          ; Entry 170 — text $0685 "*:How many?"
    dw $5F9B                          ; Entry 171 — text $0686 "[INS 10] X [INS 00] is [INS 20]G."
    dw $5FAD                          ; Entry 172 — text $0687 "*:You don't have enough money."
    dw $5FCF                          ; Entry 173 — text $0688 "*:You can only carry 20 items!"
    dw $5FF2                          ; Entry 174 — text $0689 "*:Thank you!"
    dw $6003                          ; Entry 175 — text $068A "*:Which items will you sell to me?"
    dw $6028                          ; Entry 176 — text $068B "*:You don't have items I can buy."
    dw $604D                          ; Entry 177 — text $068C "*:How many would you like to sell?"
    dw $6072                          ; Entry 178 — text $068D "[INS 10] X [INS 00] is [INS 20]G."
    dw $6084                          ; Entry 179 — text $068E "*:You can only have up to 99999G!"
    dw $60AF                          ; Entry 180 — text $068F "*:Thanks again!"
    dw $60C3                          ; Entry 181 — text $0690 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 182 — text $0691 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 183 — text $0692 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 184 — text $0693 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 185 — text $0694 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 186 — text $0695 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 187 — text $0696 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 188 — text $0697 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 189 — text $0698 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 190 — text $0699 "*:Vault. May I help you?"
    dw $60C3                          ; Entry 191 — text $069A "*:Vault. May I help you?"
    dw $60C3                          ; Entry 192 — text $069B "*:Vault. May I help you?"
    dw $60C3                          ; Entry 193 — text $069C "*:Vault. May I help you?"
    dw $60C3                          ; Entry 194 — text $069D "*:Vault. May I help you?"
    dw $60C3                          ; Entry 195 — text $069E "*:Vault. May I help you?"
    dw $60C3                          ; Entry 196 — text $069F "*:Vault. May I help you?"
    dw $60C3                          ; Entry 197 — text $06A0 "*:Vault. May I help you?"
    dw $60DE                          ; Entry 198 — text $06A1 "*:Something else?"
    dw $60F3                          ; Entry 199 — text $06A2 "*:Come again anytime."
    dw $610C                          ; Entry 200 — text $06A3 "*:What would you like us to store?"
    dw $6131                          ; Entry 201 — text $06A4 "*:Which one?"
    dw $6141                          ; Entry 202 — text $06A5 "*:You don't have anything."
    dw $615F                          ; Entry 203 — text $06A6 "*:Sorry. We can't store anymore."
    dw $6183                          ; Entry 204 — text $06A7 "*:How many?"
    dw $6190                          ; Entry 205 — text $06A8 "*:Too much!"
    dw $619F                          ; Entry 206 — text $06A9 "*:You're in safe hands with us."
    dw $61C2                          ; Entry 207 — text $06AA "*:How much do you want to deposit?"
    dw $61E7                          ; Entry 208 — text $06AB "*:Not enough money."
    dw $61FF                          ; Entry 209 — text $06AC "*:Excuse me but you can only depo…"
    dw $623B                          ; Entry 210 — text $06AD "*:You're in safe hands with us."
    dw $625E                          ; Entry 211 — text $06AE "*:What would you like to take out?"
    dw $6283                          ; Entry 212 — text $06AF "*:We don't have any of your gold."
    dw $62A8                          ; Entry 213 — text $06B0 "*:Take out items or withdraw gold?"
    dw $62CD                          ; Entry 214 — text $06B1 "*:We don't have any of your items."
    dw $62F3                          ; Entry 215 — text $06B2 "*:Too much stuff to store."
    dw $6312                          ; Entry 216 — text $06B3 "*:Take out how many?"
    dw $6329                          ; Entry 217 — text $06B4 "*:You have too much to carry!"
    dw $634B                          ; Entry 218 — text $06B5 "*:Here it is."
    dw $635E                          ; Entry 219 — text $06B6 "*:Withdraw how much?"
    dw $6375                          ; Entry 220 — text $06B7 "*:You don't have that much money."
    dw $639A                          ; Entry 221 — text $06B8 "*:You can't carry that much money."
    dw $63C0                          ; Entry 222 — text $06B9 "*:Here it is."
    dw $63D3                          ; Entry 223 — text $06BA "Pulio:Hey there! Whadayagonnado?"
    dw $63D3                          ; Entry 224 — text $06BB "Pulio:Hey there! Whadayagonnado?"
    dw $63D3                          ; Entry 225 — text $06BC "Pulio:Hey there! Whadayagonnado?"
    dw $63D3                          ; Entry 226 — text $06BD "Pulio:Hey there! Whadayagonnado?"
    dw $63D3                          ; Entry 227 — text $06BE "Pulio:Hey there! Whadayagonnado?"
    dw $63D3                          ; Entry 228 — text $06BF "Pulio:Hey there! Whadayagonnado?"
    dw $63D3                          ; Entry 229 — text $06C0 "Pulio:Hey there! Whadayagonnado?"
    dw $63F6                          ; Entry 230 — text $06C1 "Pulio:Anything else?"
    dw $640D                          ; Entry 231 — text $06C2 "Pulio:Later! We'll be here for ya!"
    dw $6432                          ; Entry 232 — text $06C3 "Pulio:Drop off which one?"
    dw $644E                          ; Entry 233 — text $06C4 "Pulio:Hey, you're not gonna have …"
    dw $648D                          ; Entry 234 — text $06C5 "Pulio:Drop off this one?"
    dw $64A8                          ; Entry 235 — text $06C6 "Pulio:Stop by once in a while to …"
    dw $64E7                          ; Entry 236 — text $06C7 "Pulio:Replace it?"
    dw $64FB                          ; Entry 237 — text $06C8 "Pulio:Replace it with which one?"
    dw $651E                          ; Entry 238 — text $06C9 "Pulio:Replace it with this one?"
    dw $6540                          ; Entry 239 — text $06CA "Pulio:I replaced [INS 00] with [I…"
    dw $6561                          ; Entry 240 — text $06CB "Pulio:Picking up which one, [HERO…"
    dw $6582                          ; Entry 241 — text $06CC "Pulio:No monsters here to take."
    dw $65A6                          ; Entry 242 — text $06CD "Pulio:You can't take any more!"
    dw $65C8                          ; Entry 243 — text $06CE "Pulio:You're gonna pick this one …"
    dw $65EE                          ; Entry 244 — text $06CF "Pulio:Train it well, [HERO]!"
    dw $660A                          ; Entry 245 — text $06D0 "Pulio:Replacing a monster, [HERO]?"
    dw $662A                          ; Entry 246 — text $06D1 "Pulio:Which one are you replacing?"
    dw $664F                          ; Entry 247 — text $06D2 "Pulio:Replace this one?"
    dw $6669                          ; Entry 248 — text $06D3 "Pulio:Replace with which one?"
    dw $6689                          ; Entry 249 — text $06D4 "Pulio:Replace this one?"
    dw $66A3                          ; Entry 250 — text $06D5 "Pulio:I replaced [INS 00] with [I…"
    dw $66C4                          ; Entry 251 — text $06D6 "Pulio:Check on which one?"
    dw $66E0                          ; Entry 252 — text $06D7 "Pulio:Hey, none to check on!"
    dw $6701                          ; Entry 253 — text $06D8 "Pulio:Check on which one, [HERO]?"
    dw $6720                          ; Entry 254 — text $06D9 "Pulio:Check on which one, [HERO]?"
    dw $673F                          ; Entry 255 — text $06DA "Pulio:Separate with which one?"
    dw $6760                          ; Entry 256 — text $06DB "Pulio:Hey, nothing here!"
    dw $677D                          ; Entry 257 — text $06DC "Pulio:Separate with which one?"
    dw $679E                          ; Entry 258 — text $06DD "Pulio:Are you sure? You'll lose i…"
    dw $67D0                          ; Entry 259 — text $06DE "[INS 00] was returned to the wild."
    dw $67F5                          ; Entry 260 — text $06DF "Pulio:Are you sure? You'll lose i…"
    dw $6827                          ; Entry 261 — text $06E0 "[INS 00] was returned to the wild."
    dw $684C                          ; Entry 262 — text $06E1 "Pulio:Select [PICK UP] to take th…"
    dw $6887                          ; Entry 263 — text $06E2 "Pulio:You wanna make the monsters…"
    dw $68D1                          ; Entry 264 — text $06E3 "Pulio:All the monsters here went …"
    dw $690E                          ; Entry 265 — text $06E4 "Pulio:I put all the monsters not …"
    dw $6986                          ; Entry 266 — text $06E5 "Pulio:Wanna wake up the sleeping …"
    dw $69B8                          ; Entry 267 — text $06E6 "Pulio:I woke up the sleeping mons…"
    dw $69E8                          ; Entry 268 — text $06E7 "*:What can I do for you?"
    dw $69E8                          ; Entry 269 — text $06E8 "*:What can I do for you?"
    dw $69E8                          ; Entry 270 — text $06E9 "*:What can I do for you?"
    dw $69E8                          ; Entry 271 — text $06EA "*:What can I do for you?"
    dw $69E8                          ; Entry 272 — text $06EB "*:What can I do for you?"
    dw $69E8                          ; Entry 273 — text $06EC "*:What can I do for you?"
    dw $69E8                          ; Entry 274 — text $06ED "*:What can I do for you?"
    dw $69E8                          ; Entry 275 — text $06EE "*:What can I do for you?"
    dw $69E8                          ; Entry 276 — text $06EF "*:What can I do for you?"
    dw $69E8                          ; Entry 277 — text $06F0 "*:What can I do for you?"
    dw $6A03                          ; Entry 278 — text $06F1 "*:Anything else?"
    dw $6A15                          ; Entry 279 — text $06F2 "*:Create the ultimate monsters!"
    dw $6A38                          ; Entry 280 — text $06F3 "*:Which monster for the pedigree?"
    dw $6A5C                          ; Entry 281 — text $06F4 "*:Which monster to breed with?"
    dw $6A7D                          ; Entry 282 — text $06F5 "*:That one? Are you sure?"
    dw $6A99                          ; Entry 283 — text $06F6 "*:There will be no monsters left!"
    dw $6ABF                          ; Entry 284 — text $06F7 "*:Sorry, it's not old enough."
    dw $6AE0                          ; Entry 285 — text $06F8 "*:The same gender. Cannot breed."
    dw $6B05                          ; Entry 286 — text $06F9 "*:I bet [INS 20] will be born! *:…"
    dw $6B4D                          ; Entry 287 — text $06FA "*:Hmm. Seems like a new monster?!"
    dw $6B73                          ; Entry 288 — text $06FB "*:Can I record this joyful event?"
    dw $6B97                          ; Entry 289 — text $06FC "*:OK! Wait overnight."
    dw $6BB0                          ; Entry 290 — text $06FD "[INS 00] & [INS 10] disappeared."
    dw $6BC8                          ; Entry 291 — text $06FE "*:Wow! It's a rare breed!"
    dw $6BE5                          ; Entry 292 — text $06FF "*:Inside it is a baby [INS 20]! *…"

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


    db $eb
    sbc a
    and e
    dec hl
    ld d, d
    ld c, d
    ld c, l
    ld b, e
    ld e, [hl]
    ld h, d

jr_04a_429d:
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $4b
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    rst $28
    xor $50
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld a, $62
    ld c, e
    ld a, $4a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $27
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
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
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    rst $28
    xor $48
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, e
    ld a, $4a
    ld b, d
    ld e, a
    ld a, [$eff7]
    xor $37
    ld c, h
    ld c, h
    ld h, d
    ccf
    ld a, $41
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
    ld a, $50
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
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
    ld c, a
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
    ld e, a
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc a
    ld b, d
    ld c, l
    ld e, a
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    ld e, a
    rst $28
    xor $2b
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
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, h
    ld a, [$eff7]
    xor $36
    ld a, $4b
    ld d, c
    ld b, [hl]
    and e
    dec hl
    ld d, d
    ld c, d
    ld c, l
    ld b, l
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $29
    ld c, h
    ld c, c
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    ld a, [hl-]
    ld a, $46
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    scf
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $2a
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $63
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    ld h, $6a
    ld c, h
    ld c, e
    ld e, [hl]
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    rst $28
    xor $51
    ld a, $49
    ld c, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld a, [$eff7]
    xor $2a
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $63
    rst $28
    xor $f7
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, c
    ld a, $49
    ld c, b
    ld b, d
    ld b, c
    ld h, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld a, [hl+]
    ld c, a
    ld a, $4b
    ld b, c
    ld c, l
    ld a, $5e
    ld h, d
    ld a, [$eff7]
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $36
    ld a, $4b
    ld d, c
    ld b, [hl]
    and e
    ld [hl], $4c
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ld h, d
    dec l
    ld d, d
    ld d, b
    ld d, c
    ld h, d
    ld b, h
    ld c, h
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
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    daa
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, a
    ld d, d
    ld d, b
    ld d, c
    rst $28
    xor $50
    ld d, c
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$eff7]
    xor $2a
    ld c, h
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
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    ld a, [hl-]
    ld a, $50
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
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
    ld a, [$eff7]
    xor $52
    ld d, b
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld a, $64
    rst $28
    xor $ff
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    inc a
    ld e, a
    ld e, a
    ld e, a
    inc a
    ld a, $ef
    xor $3f
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, e
    ld c, h
    ld c, h
    ld c, c
    ld h, e
    rst $30
    ldh a, [$eb]
    ld [hl], $3e
    ld c, e
    ld d, c
    ld b, [hl]
    and e
    inc l
    ld e, a
    ld e, a
    ld e, a
    inc l
    ld l, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $45
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld e, a
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
    sbc a
    and e
    ld [hl-], a
    ld b, l
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld c, h
    rst $28
    xor $f6
    ld h, e
    ld h, d
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
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld a, $57
    ld a, $3e
    ld c, a
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    rst $28
    xor $43
    ld b, d
    ld b, d
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $48
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, c
    ld c, h
    ld c, d
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    inc l
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld b, c
    ld h, d
    ld d, b
    ld c, h
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    inc l
    ld h, d
    ld a, $49
    ld c, d
    ld c, h
    ld d, b
    ld d, c
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld d, c
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $ef
    xor $f6
    ld h, d
    ld a, $4b
    ld b, c
    ld a, [$eff7]
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    rst $28
    xor $2f
    ld a, $62
    ld c, c
    ld a, $62
    ld c, c
    ld a, $5f
    ld e, a
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
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    rst $28
    xor $50
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld a, [$eff7]
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
    ld b, h
    ld d, d
    ld d, [hl]
    ld d, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld b, [hl]
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld e, a
    ld e, a
    ld e, a
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
    ld h, d
    ld b, h
    ld b, [hl]
    ld b, h
    ld b, h
    ld c, c
    ld b, d
    ld h, e
    rst $28
    xor $2f
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
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
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
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
    ld a, [$eff7]
    xor $51
    ld c, h
    ld c, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_04a_46cf

    ld c, d
    ld c, d
    ld d, [hl]
    ld h, d
    or [hl]
    ld h, d
    daa
    ld a, $41
    ld b, c
    ld d, [hl]
    rst $28
    xor $50
    ld a, $46
    ld b, c
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $f6
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
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

jr_04a_46cf:
    ld d, b
    ld h, e
    ld h, e
    ld a, [$eff7]
    xor $2c
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    ld h, d
    ld b, e
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld d, e
    ld a, $49
    ld d, b
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    dec h
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $56
    ld e, [hl]
    ld h, d
    inc l
    ld h, d
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
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld d, b
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    jr nc, @+$58

    ld d, b
    ld d, c
    ld b, [hl]
    ld b, b
    ld a, [$eff7]
    xor $3a
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $3f
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
    ld h, d
    ld c, l
    ld a, $49
    ld d, b
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld c, h
    ld c, a
    ld b, c
    ld d, b
    sbc h
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld d, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    ld b, b
    ld a, $4b
    ld a, [$eff7]
    xor $3f
    ld b, d
    ld h, d
    ld c, d
    ld a, $41
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
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
    ld l, b
    rst $28
    xor $4d
    ld c, h
    ld d, b
    ld d, b
    ld b, [hl]
    ccf
    ld c, c
    ld b, d
    ld h, h
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
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
    ld h, e
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
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    dec hl
    ld b, [hl]
    ld h, e
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
    ld a, $3f
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld a, $ef
    xor $4f
    ld b, d
    ld d, h
    ld a, $4f
    ld b, c
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
    xor $53
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld d, [hl]
    ld h, h
    rst $28
    xor $ff
    ldh a, [$eb]
    sbc a
    and e
    ld [hl-], a
    ld c, b
    ld a, $56
    ld e, a
    rst $28
    xor $f7
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
    rst $28
    xor $5f
    ld e, a
    ld e, a
    ld d, c
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
    ld h, d
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
    ld h, d
    ld d, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $9f
    and e
    ld l, $42
    ld b, d
    ld c, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, d
    ld c, l
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
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld a, $62
    ld b, a
    ld c, h
    ld d, [hl]
    ld h, e
    rst $28
    xor $f6
    ld h, d
    ld d, h
    ld c, h
    ld c, e
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
    xor $50
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $40
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld b, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    rst $28
    xor $3e
    ld d, c
    ld d, c
    ld b, [hl]
    ld d, c
    ld d, d
    ld b, c
    ld b, d
    ld h, e
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
    ld c, l
    ld c, a
    ld c, h
    ccf
    ld a, $3f
    ld c, c
    ld d, [hl]
    rst $28
    xor $3f
    ld b, d
    ld b, b
    ld a, $52
    ld d, b
    ld b, d
    ld h, d
    or $fa
    rst $30
    rst $28
    xor $54
    ld c, h
    ld c, e
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
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $62
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
    ld h, d
    ld a, [$eff7]
    xor $45
    ld b, d
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld h, h
    rst $28
    xor $ff
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
    ld b, l
    ld b, d
    ld c, a
    ld c, h
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
    ld h, d
    ld a, [$eff7]
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $63
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld h, d
    ccf
    ld b, d
    ld d, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, b
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
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, b
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    rst $28
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    rst $38
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld b, d
    ld d, b
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
    xor $37
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld b, [hl]
    ld b, b
    ld d, c
    ld c, h
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $54
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld c, e
    ld h, a
    ld h, d
    ld a, $50
    ld c, b
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld b, l
    rst $28
    xor $3e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
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
    ld c, a
    ld c, h
    ld d, d
    ld d, b
    rst $28
    xor $4a
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, h
    ld a, $50
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld a, [$eff7]
    xor $50
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
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
    ld b, l
    ld a, $4d
    ld c, l
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, e
    ld a, $49
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
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
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    rst $28
    xor $50
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
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    rst $28
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
    ld d, h
    ld b, l
    ld b, d
    ld c, e
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
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
    xor $40
    ld a, $4a
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld h, e
    ld h, d
    inc l
    ld h, d
    ld a, [$eff7]
    xor $54
    ld c, h
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld b, e
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld c, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, e
    ld h, d
    ld [hl-], a
    ld d, d
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld c, h
    rst $28
    xor $f6
    ld h, e
    ld a, [$eff7]
    xor $9f
    and e
    scf
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
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $56
    ld d, d
    ld c, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld c, d
    ld b, d
    ld a, $51
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $40
    ld b, d
    ld c, c
    ld b, d
    ccf
    ld c, a
    ld a, $51
    ld b, d
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_04a_4b9d

    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld e, a
    ld e, a
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
    ld c, d
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$eff7]
    xor $9f
    and e
    jr z, jr_04a_4bc6

    ld d, c
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    ld c, d
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    rst $28
    xor $2a
    ld b, [hl]
    ld c, d
    ld c, d
    ld b, d
    ld h, d
    ld a, [$eff7]
    xor $42
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld d, c
    ld a, $46
    ld c, e
    ld c, d

jr_04a_4b9d:
    ld b, d
    ld c, e
    ld d, c
    ld h, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_04a_4bea

    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $5e
    rst $28
    xor $27
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, b
    ld c, e
    ld c, h
    ld d, h
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]

jr_04a_4bc6:
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld h, $3e
    ld c, c
    ld c, c
    ld h, h
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
    ld a, $49
    ld c, c
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $4b

jr_04a_4bea:
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $50
    ld b, d
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld h, $3e
    ld c, c
    ld c, c
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
    ld h, $3e
    ld c, c
    ld c, c
    rst $28
    xor $40
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, b
    ld d, c
    ld a, $4b
    ld d, c
    ld c, c
    ld d, [hl]
    ld a, [$eff7]
    xor $40
    ld a, $49
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld d, c
    ld b, l
    ld h, d
    ld a, $49
    ld c, c
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
    ld d, c
    ld h, d
    ld d, b
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld b, e
    ld d, d
    ld c, e
    ld h, e
    rst $28
    xor $36
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, e
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld e, a
    ld e, a
    ld e, a
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
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld a, $fa
    rst $30
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
    rst $28
    xor $26
    ld a, $49
    ld c, c
    ld h, h
    ld a, [$f0f7]
    ld [$a39f], a
    ld [hl-], a
    ld b, l
    ld h, e
    ld h, d
    inc a
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
    xor $46
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld h, d
    ld [hl], $45
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld a, $44
    ld b, [hl]
    ld b, b
    ld h, e
    rst $28
    xor $f7
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    rst $28
    xor $26
    ld a, $49
    ld c, c
    ld h, e
    ld a, [$eff7]
    xor $25
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
    ld h, h
    rst $28
    xor $31
    ld c, h
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    ld a, [$eff7]
    xor $3a
    ld b, l
    ld a, $51
    ld l, b
    ld h, d
    ld b, h
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld c, h
    ld c, e
    rst $28
    xor $30
    ld a, $50
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    or $64
    ld a, [$eff7]
    xor $9f
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, h
    ld h, d
    scf
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
    ld d, b
    ld a, $46
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld a, [$eff7]
    xor $41
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld c, l
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld d, b
    ld b, l
    ld c, h
    ld d, h
    ld h, h
    ld a, [$eff7]
    xor $9f
    and e
    ld e, a
    ld e, a
    ld e, a
    ld [hl-], a
    ld b, l
    ld h, d
    ld d, h
    ld b, d
    ld c, c
    ld c, c
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld h, d
    or $5f
    rst $28
    xor $30
    ld d, [hl]
    ld h, d
    ld a, $4d
    ld c, h
    ld c, c
    ld c, h
    ld b, h
    ld b, [hl]
    ld b, d
    ld d, b
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld c, b
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $4f
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, h
    ld a, [$eff7]
    xor $37
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
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld c, b
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld d, b
    ld d, d
    ld c, a
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, d
    ld b, c
    ld e, a
    ld a, [$eff7]
    xor $25
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld d, h
    ld a, $56
    ld h, d
    ld c, h
    ld b, e
    rst $28
    xor $3e
    ld c, l
    ld c, h
    ld c, c
    ld c, h
    ld b, h
    ld b, [hl]
    ld d, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
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
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld sp, hl
    nop
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld sp, hl
    nop
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $49
    ld c, h
    ld d, h
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
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
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, e
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
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
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
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $51
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, h
    ldh a, [$ea]
    sbc a
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
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
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
    ld b, b
    ld a, $4b
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, d
    ld c, c
    ld d, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld c, h
    ld c, l
    ld b, d
    ld h, d
    ld a, $62
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $3f
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
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    jr nc, jr_04a_50ce

    ld h, d
    jr z, @+$58

    ld b, d
    ld b, c
    ld b, d
    ld c, a
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    rst $28
    xor $41
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld d, b
    ld e, a
    ld h, d
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d

jr_04a_50ce:
    ld d, [hl]
    ld h, d
    jr z, jr_04a_5128

    ld b, d
    ld b, c
    ld b, d
    ld c, a
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    inc a
    ld b, d
    ld d, c
    ld b, [hl]
    ld h, h
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d

jr_04a_5128:
    inc a
    ld b, d
    ld d, c
    ld b, [hl]
    ld h, h
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld d, d
    ld d, c
    ld e, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld d, [hl]
    ld e, a
    rst $28
    xor $2b
    ld b, [hl]
    ld b, b
    ld e, a
    ld e, a
    ld e, a
    rst $30
    ldh a, [$ea]
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
    ld h, $3e
    ld d, c
    add hl, hl
    ld c, c
    ld d, [hl]
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld h, $3e
    ld d, c
    add hl, hl
    ld c, c
    ld d, [hl]
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld c, d
    ld b, [hl]
    ld c, e
    ld b, d
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
    ld c, c
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $49
    ld b, d
    ld d, e
    ld b, d
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
    ld e, a
    rst $28
    xor $fa
    rst $30
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
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3e
    ld c, e
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
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld a, $63
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, c
    ld b, l
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
    ld h, h
    ld a, [$eff7]
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
    rst $28
    xor $f0
    ld [$a39f], a
    ld [hl], $51
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld d, c
    ld b, d
    ld c, c
    ld c, c
    rst $28
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld a, $fa
    rst $30
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
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld c, l
    ld b, d
    ld h, d
    ld a, $62
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $3f
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
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld b, e
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
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $3e
    ld b, h
    ld a, $46
    ld c, e
    ld e, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
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
    cpl
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    jr nc, @+$40

    ld c, e
    rst $28
    xor $50
    ld a, $56
    ld d, b
    ld h, d
    inc h
    ld b, h
    daa
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $46
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld d, [hl]
    ld c, l
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
    xor $2f
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    jr nc, jr_04a_5414

    ld c, e
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
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld a, $4f
    ld b, d
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $2f
    ld b, [hl]
    ld d, a
    ld a, $4f
    ld b, c
    jr nc, jr_04a_5450

    ld c, e
    ld h, h

jr_04a_5414:
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
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
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld a, $48
    ld e, a
    ld a, [$eff7]
    xor $37
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
    rst $28
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld d, d

jr_04a_5450:
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld c, h
    ld c, e
    ld e, a
    ld e, a
    ld e, a
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, e
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
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
    ld d, c
    ld a, $48
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
    ld h, e
    rst $28
    xor $fa
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
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld [hl], $51
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, h
    ldh a, [$ea]
    sbc a
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
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
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
    dec h
    ld d, d
    ld d, c
    ld h, d
    inc l
    ld l, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $ef
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, a
    ld b, d
    ld d, b
    ld d, d
    ld c, c
    ld d, c
    ld d, b
    ld a, [$eff7]
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld e, a
    rst $28
    xor $32
    ld c, b
    ld a, $56
    ld h, h
    ldh a, [$ea]
    sbc a
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld c, c
    ld c, c
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
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld a, $51
    ld h, d
    ld c, c
    ld b, d
    ld a, $50
    ld d, c
    ld h, d
    ld b, l
    ld a, $49
    ld b, e
    ld a, [$eff7]
    xor $4a
    ld d, [hl]
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
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    jr nc, jr_04a_562d

    ld b, b
    ld c, b
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld c, h
    ld c, e
    rst $28
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
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $51
    ld b, [hl]
    ld c, d
    ld b, d
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
    ld h, d
    ld b, [hl]
    ld c, e
    rst $28
    xor $26
    ld h, d
    ld b, b
    ld c, c
    ld a, $50
    ld d, b
    ld e, a
    rst $30
    ldh a, [$ea]
    jr nc, @+$48

    ld b, b
    ld c, b
    and e

jr_04a_562d:
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    daa
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld h, e
    ld h, e
    ldh a, [$ea]
    jr nc, jr_04a_5695

    ld b, b
    ld c, b
    and e
    ld a, [hl-]
    ld b, l
    ld c, h
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
    ld c, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld a, [$eff7]
    xor $27
    ld b, d
    ld a, $41
    ld sp, $5146
    ld b, d
    ld h, h
    rst $28
    xor $f0
    ld [$4630], a
    ld b, b
    ld c, b
    and e
    inc a
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
    ld l, b
    ld h, d
    ld c, c
    ld b, d

jr_04a_5695:
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld a, [$eff7]
    xor $51
    ld c, h
    ld c, h
    ld h, d
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    jr nc, jr_04a_56fd

    ld b, b
    ld c, b
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
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
    ld d, c
    ld a, $48
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    jr nc, jr_04a_5738

    ld b, b
    ld c, b
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]

jr_04a_56fd:
    ld d, b
    rst $28
    xor $4c
    ld c, e
    ld b, d
    ld h, h
    ld h, d
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
    ld h, h
    ldh a, [$ea]
    jr nc, @+$48

    ld b, b
    ld c, b
    and e
    ld [hl], $51
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, h
    ldh a, [$ea]

jr_04a_5738:
    sbc a
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
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    inc l
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld a, [$eff7]
    xor $51
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
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
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $4d
    ld c, a
    ld c, h
    ld c, h
    ld b, e
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, h
    ld d, d
    ld c, a
    ld a, [$eff7]
    xor $43
    ld c, a
    ld b, [hl]
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld b, l
    ld b, [hl]
    ld c, l
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
    ld d, b
    ld b, d
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc sp
    ld c, c
    ld b, d
    ld a, $50
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $4a
    ld b, d
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
    ld a, $4b
    ld d, c
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    jr nc, jr_04a_58ad

    ld h, d
    dec [hl]
    ld a, $56
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, d
    ld c, c
    ld c, h
    ld d, e
    ld b, d
    ld d, b
    rst $28
    xor $3f
    ld b, [hl]
    ld c, a
    ld b, c
    ld d, b
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    dec [hl]
    ld a, $56
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, h
    ldh a, [$eb]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, l

jr_04a_58ad:
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    dec [hl]
    ld a, $56
    ccf
    ld d, d
    ld c, a
    ld c, e
    ld h, h
    rst $28
    xor $f0
    db $eb
    sbc a
    and e
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
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
    ld a, $62
    ld c, c
    ld c, h
    ld d, h
    ld a, [$eff7]
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    rst $28
    xor $fa
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
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $4b
    ld c, h
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
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
    ld a, $48
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld d, b
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
    xor $4c
    ld c, b
    ld a, $56
    ld h, h
    ldh a, [$eb]
    sbc a
    and e
    ld h, $3e
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, h
    ldh a, [$eb]
    sbc a
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
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    rst $28
    xor $9f
    and e
    ld h, $3e
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $46
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec l
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    ldh a, [$eb]
    sbc a
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, e
    rst $30
    ldh a, [$eb]
    sbc a
    and e
    inc l
    ld h, d
    ld b, l
    ld c, h
    ld c, l
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $3e
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
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
    ld e, a
    ld a, [$eff7]
    xor $9f
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc sp
    ld a, $56
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ld a, $62
    ld d, e
    ld b, [hl]
    ld d, b
    ld b, [hl]
    ld d, c
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
    ld d, h
    ld a, $4b
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    ld sp, hl
    nop
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    rst $28
    xor $f9
    nop
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld h, $3e
    ld c, e
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld a, $62
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld c, c
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld a, [$eff7]
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld c, e
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
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
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
    ld h, $3e
    ld c, e
    ld h, d
    ld d, h
    ld b, d
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
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
    ld b, b
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, [hl]
    ld c, d
    ld a, $44
    ld b, [hl]
    ld c, e
    ld b, d
    rst $28
    xor $54
    ld b, l
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld a, [$eff7]
    xor $46
    ld d, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
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
    ld a, $4f
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
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld a, [$eff7]
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
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
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld b, d
    ld c, e
    ld e, [hl]
    ld h, d
    ld c, c
    ld b, d
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    rst $28
    xor $3f
    ld b, d
    ld b, h
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $40
    ld b, d
    ld c, a
    ld b, d
    ld c, d
    ld c, h
    ld c, e
    ld d, [hl]
    ld e, a
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld c, l
    ld b, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld a, $ef
    xor $50
    ld d, c
    ld c, a
    ld c, h
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
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
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
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld b, d
    ld c, e
    ld b, c
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
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, e
    ld a, $4f
    ld c, d
    ld h, e
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld d, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    jr nc, jr_04a_5cd0

    ld d, c
    ld a, $3f
    ccf
    ld c, c
    ld b, d
    ld h, e
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
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
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld a, [$eff7]
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, d
    ld d, [hl]
    ld h, d
    jr nc, jr_04a_5d0d

    ld d, c
    ld a, $3f
    ccf
    ld c, c

jr_04a_5cd0:
    ld b, d
    ld h, h
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, @+$48

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld a, $40
    ld c, b
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
    ld d, h
    ld a, $4b
    ld c, e
    ld a, $fa
    rst $30
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    rst $28
    xor $f7
    ldh a, [$eb]
    jr nc, jr_04a_5d4f

    ld c, c
    ld a, $56
    ld c, h

jr_04a_5d0d:
    ld d, d
    and e
    dec h
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    rst $28
    xor $4a
    ld d, [hl]
    ld h, d
    ld [hl], $48
    ld b, d
    ld c, c
    ld b, d
    ld d, c
    ld c, h
    ld c, a
    ld h, e
    ldh a, [$eb]
    jr nc, jr_04a_5d71

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    ld a, [hl-]
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
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld a, [$eff7]
    xor $4d
    ld b, [hl]
    ld b, b

jr_04a_5d4f:
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld c, d
    ld d, [hl]
    rst $28
    xor $36
    ld c, b
    ld b, d
    ld c, c
    ld b, d
    ld d, c
    ld c, h
    ld c, a
    ld h, h
    ldh a, [$eb]
    jr nc, jr_04a_5dac

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc h
    ld h, d
    ld c, c
    ld c, h
    ld d, h

jr_04a_5d71:
    rst $28
    xor $49
    ld b, d
    ld d, e
    ld b, d
    ld c, c
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld a, [$eff7]
    xor $40
    ld a, $4b
    ld h, a
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    jr nc, jr_04a_5ddd

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld d, h
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d

jr_04a_5dac:
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
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    jr nc, jr_04a_5e1a

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc l
    ld d, b
    ld h, d

jr_04a_5ddd:
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
    ld c, h
    ld c, b
    ld a, $56
    ld h, h
    ldh a, [$eb]
    jr nc, jr_04a_5e3a

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc l
    ld h, [hl]
    ld c, c
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld a, [$eff7]
    xor $40
    ld b, d
    ld c, a
    ld b, d
    ld c, d

jr_04a_5e1a:
    ld c, h
    ld c, e
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, h
    ld c, b
    ld a, $56
    ld h, h
    rst $28
    xor $f0
    db $eb
    jr nc, @+$48

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc l
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    rst $28
    xor $48
    ld c, e

jr_04a_5e3a:
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, l
    ld a, $51
    ld h, d
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld c, h
    ld b, e
    ld a, [$eff7]
    xor $42
    ld b, h
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
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
    ld h, $3e
    ld c, e
    ld h, d
    inc l
    rst $28
    xor $4f
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld a, [$eff7]
    xor $2d
    ld c, h
    ld d, d
    ld c, a
    ld c, e
    ld a, $49
    ld h, h
    rst $28
    xor $f0
    db $eb
    jr nc, jr_04a_5ed8

    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    cpl
    ld b, d
    ld d, c
    ld l, b
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, e
    rst $30
    ldh a, [$eb]
    jr nc, jr_04a_5eef

    ld c, c
    ld a, $56
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
    xor $46
    ld d, c
    ld h, [hl]
    ld c, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
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
    xor $fa
    rst $30
    rst $28

jr_04a_5ed8:
    xor $30
    ld b, [hl]
    ld c, c
    ld a, $56
    ld c, h
    ld d, d
    and e
    inc l
    ld l, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $ef
    xor $50
    ld b, d
    ld c, e
    ld b, c

jr_04a_5eef:
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld b, h
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $51
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
    ld b, d
    ld c, d
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld c, l
    ld e, a
    rst $28
    xor $30
    ld a, $56
    ld h, d
    inc l
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
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    rst $28
    xor $26
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
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
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    ld h, h
    rst $28
    xor $f0
    ld [$10f9], a
    ld h, d
    dec sp
    ld h, d
    ld sp, hl
    nop
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, jr_04a_5fd5

    ld e, a
    ldh a, [$ea]
    sbc a
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
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $42
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
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d

jr_04a_5fd5:
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
    ld [bc], a
    nop
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
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
    ld d, b
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, d
    ld b, d
    ld h, h
    ldh a, [$ea]
    sbc a
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
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    inc l
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld d, d
    ld d, [hl]
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    rst $28
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld c, c
    ld c, c
    ld h, h
    ldh a, [$ea]
    ld sp, hl
    db $10
    ld h, d
    dec sp
    ld h, d
    ld sp, hl
    nop
    rst $28
    xor $46
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, @+$2c

    ld e, a
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
    ld c, h
    ld c, e
    ld c, c
    ld d, [hl]
    rst $28
    xor $45
    ld a, $53
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    ld a, [$eff7]
    xor $09
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld b, l
    ld a, $4b
    ld c, b
    ld d, b
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    ld h, e
    rst $28
    xor $f7
    ldh a, [$ea]
    sbc a
    and e
    add hl, sp
    ld a, $52
    ld c, c
    ld d, c
    ld e, a
    rst $28
    xor $30
    ld a, $56
    ld h, d
    inc l
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
    ld [hl], $4c
    ld c, d
    ld b, d
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
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    ld h, $4c
    ld c, d
    ld b, d
    ld h, d
    ld a, $44
    ld a, $46
    ld c, e
    rst $28
    xor $3e
    ld c, e
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
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, h
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
    ld h, h
    rst $28
    xor $f0
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, a
    ld h, d
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    rst $28
    xor $50
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld a, $4b
    ld d, [hl]
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    scf
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld a, $43
    ld b, d
    rst $28
    xor $45
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, d
    ld d, b
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    dec hl
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
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
    ld b, c
    ld b, d
    ld c, l
    ld c, h
    ld d, b
    ld b, [hl]
    ld d, c
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld sp, $514c
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
    ld [$a39f], a
    jr z, jr_04a_6259

    ld b, b
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld c, d
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld d, c
    rst $28
    xor $56
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
    ld a, [$eff7]
    xor $41
    ld b, d
    ld c, l
    ld c, h
    ld d, b
    ld b, [hl]
    ld d, c
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld c, h
    rst $28
    xor $09
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc
    ld a, [hl+]
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld a, $43
    ld b, d
    rst $28
    xor $45
    ld a, $4b
    ld b, c
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, d

jr_04a_6259:
    ld d, b
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld d, h
    ld c, h
    ld d, d
    ld c, c
    ld b, c
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $49
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, h
    ld c, h
    ld c, c
    ld b, c
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    rst $28
    xor $4c
    ld c, a
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, c
    ld c, a
    ld a, $54
    ld h, d
    ld b, h
    ld c, h
    ld c, c
    ld b, c
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $3e
    ld c, e
    ld d, [hl]
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld c, h
    ld c, h
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld b, e
    ld b, e
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld d, c
    ld c, h
    ld c, a
    ld b, d
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld a, $48
    ld b, d
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    rst $28
    xor $4a
    ld a, $4b
    ld d, [hl]
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
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, [hl]
    ld d, c
    ld b, l
    ld b, c
    ld c, a
    ld a, $54
    rst $28
    xor $45
    ld c, h
    ld d, h
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld h, h
    ldh a, [$ea]
    sbc a
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
    ld b, l
    ld a, $53
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc a
    ld c, h
    ld d, d
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, b
    ld a, $4f
    ld c, a
    ld d, [hl]
    rst $28
    xor $51
    ld b, l
    ld a, $51
    ld h, d
    ld c, d
    ld d, d
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld b, d
    ld d, [hl]
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    rst $28
    xor $3a
    ld b, l
    ld a, $41
    ld a, $56
    ld a, $44
    ld c, h
    ld c, e
    ld c, e
    ld a, $41
    ld c, h
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc h
    ld c, e
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    rst $28
    xor $42
    ld c, c
    ld d, b
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    cpl
    ld a, $51
    ld b, d
    ld c, a
    ld h, e
    ld h, d
    ld a, [hl-]
    ld b, d
    ld h, [hl]
    ld c, c
    rst $28
    xor $3f
    ld b, d
    ld h, d
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld a, $63
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    daa
    ld c, a
    ld c, h
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    rst $28
    xor $54
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    rst $28
    xor $4b
    ld c, h
    ld d, c
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $62
    ld b, l
    ld a, $53
    ld b, d
    ld a, [$eff7]
    xor $3e
    ld c, e
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
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld e, a
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    daa
    ld c, a
    ld c, h
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $51
    ld c, h
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    rst $28
    xor $4c
    ld c, e
    ld b, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld a, $62
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, c
    ld b, d
    ld a, [$eff7]
    xor $51
    ld c, h
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld h, d
    ld b, l
    ld c, h
    ld d, h
    ld h, d
    ld d, h
    ld b, d
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld b, c
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    rst $28
    xor $46
    ld d, c
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld b, c
    rst $28
    xor $f9
    nop
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc sp
    ld b, [hl]
    ld b, b
    ld c, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $54
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld e, [hl]
    ld h, d
    or $64
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld sp, $624c
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
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld e, a
    ld a, [$f0f7]
    db $eb
    inc sp
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
    ld h, a
    rst $28
    xor $51
    ld a, $48
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc a
    ld c, h
    ld d, d
    ld l, c
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld c, e
    ld a, $ef
    xor $4d
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    scf
    ld c, a
    ld a, $46
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    rst $28
    xor $54
    ld b, d
    ld c, c
    ld c, c
    ld e, [hl]
    ld h, d
    or $63
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, [hl]
    ld c, e
    ld b, h
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
    ld e, [hl]
    ld h, d
    or $64
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
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
    rst $28
    xor $3e
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec [hl]
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld c, l
    ld c, c
    ld a, $40
    ld b, d
    ld b, c
    rst $28
    xor $f9
    nop
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld h, $45
    ld b, d
    ld b, b
    ld c, b
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
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld c, e
    ld c, h
    ld c, e
    ld b, d
    rst $28
    xor $51
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld b, d
    ld b, b
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    ld h, e
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld h, $45
    ld b, d
    ld b, b
    ld c, b
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
    ld c, h
    ld c, e
    ld b, d
    ld e, [hl]
    ld h, d
    or $64
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld h, $45
    ld b, d
    ld b, b
    ld c, b
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
    ld c, h
    ld c, e
    ld b, d
    ld e, [hl]
    ld h, d
    or $64
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $42
    ld c, l
    ld a, $4f
    ld a, $51
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    dec hl
    ld b, d
    ld d, [hl]
    ld e, [hl]
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
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    ld a, [$f0f7]
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $42
    ld c, l
    ld a, $4f
    ld a, $51
    ld b, d
    rst $28
    xor $54
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld d, h
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld c, e
    ld b, d
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld b, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f0
    ld sp, hl
    nop
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $4f
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc h
    ld c, a
    ld b, d
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    rst $28
    xor $50
    ld d, d
    ld c, a
    ld b, d
    ld h, h
    ld h, d
    inc a
    ld c, h
    ld d, d
    ld h, [hl]
    ld c, c
    ld a, [$eff7]
    xor $49
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $f0
    ld sp, hl
    nop
    ld h, d
    ld d, h
    ld a, $50
    rst $28
    xor $4f
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld b, d
    ld b, c
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
    ld e, a
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld [hl], $42
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    rst $28
    xor $96
    inc sp
    inc l
    ld h, $2e
    ld h, d
    jr c, jr_04a_6896

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
    ld h, d
    ld d, h
    ld a, $4b
    ld c, e

jr_04a_6896:
    ld a, $ef
    xor $4a
    ld a, $48
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
    ld a, [$eff7]
    xor $56
    ld c, h
    ld d, d
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $43
    ld a, $4f
    ld c, d
    ld h, d
    ld b, h
    ld c, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, h
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc h
    ld c, c
    ld c, c
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
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld c, e
    ld d, c
    ld a, [$eff7]
    xor $46
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
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
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld c, l
    ld d, d
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
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld a, [$eff7]
    xor $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
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
    ld a, [$eff7]
    xor $33
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld a, $4b
    ld b, c
    ld h, d
    ld d, h
    ld c, h
    ld c, b
    ld b, d
    rst $28
    xor $52
    ld c, l
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
    ld a, [$eff7]
    xor $54
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    rst $28
    xor $fa
    rst $30
    ldh a, [$eb]
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    ld a, [hl-]
    ld a, $4b
    ld c, e
    ld a, $62
    ld d, h
    ld a, $48
    ld b, d
    rst $28
    xor $52
    ld c, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
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
    xor $f0
    db $eb
    inc sp
    ld d, d
    ld c, c
    ld b, [hl]
    ld c, h
    and e
    inc l
    ld h, d
    ld d, h
    ld c, h
    ld c, b
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    rst $28
    xor $51
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
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
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    inc l
    ld h, d
    ld b, c
    ld c, h
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
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
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld h, $4f
    ld b, d
    ld a, $51
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    rst $28
    xor $52
    ld c, c
    ld d, c
    ld b, [hl]
    ld c, d
    ld a, $51
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
    ld h, e
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
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    rst $28
    xor $43
    ld c, h
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld b, d
    ld b, c
    ld b, [hl]
    ld b, h
    ld c, a
    ld b, d
    ld b, d
    ld h, h
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld b, l
    ld b, [hl]
    ld b, b
    ld b, l
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld c, h
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
    scf
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
    rst $28
    xor $4b
    ld c, h
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
    ld c, c
    ld b, d
    ld b, e
    ld d, c
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    ld [hl], $4c
    ld c, a
    ld c, a
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld b, [hl]
    ld d, c
    ld l, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    rst $28
    xor $4c
    ld c, c
    ld b, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4a
    ld b, d
    ld h, d
    ld b, h
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld e, a
    rst $28
    xor $26
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld e, a
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld h, d
    ccf
    ld b, d

jr_04a_6b0c:
    ld d, c
    rst $28
    xor $f9
    jr nz, jr_04a_6b0c

    rst $30
    rst $28
    xor $54
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ccf
    ld b, d
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
    inc a
    ld c, h
    ld d, d
    ld l, h
    ld b, d
    ld h, d
    ld b, l
    ld a, $41
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    rst $28
    xor $4a
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, h
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    dec hl
    ld c, d
    ld c, d
    ld e, a
    ld h, d
    ld [hl], $42
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    rst $28
    xor $3e
    ld h, d
    ld c, e
    ld b, d
    ld d, h
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, h
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    ld h, $3e
    ld c, e
    ld h, d
    inc l
    ld h, d
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld c, a
    ld b, c
    rst $28
    xor $51
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, a
    ld c, h
    ld d, [hl]
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld d, c
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
    ld d, c
    ld e, a
    rst $30
    ldh a, [$ea]
    ld sp, hl
    nop
    ld h, d
    or [hl]
    ld h, d
    ld sp, hl
    db $10
    rst $28
    xor $41
    ld b, [hl]
    ld d, b
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld b, d
    ld b, c
    ld e, a
    rst $30
    ldh a, [$ea]
    sbc a
    and e
    ld a, [hl-]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    inc l
    ld d, c
    ld l, b
    ld h, d
    ld a, $62
    ld c, a
    ld a, $4f
    ld b, d
    rst $28
    xor $3f
    ld c, a
    ld b, d
    ld b, d
    ld b, c
    ld h, e
    ld a, [$f0f7]
    ld [$a39f], a
    inc l
    ld c, e
    ld d, b
    ld b, [hl]
    ld b, c
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld a, $ef
    xor $3f
    ld a, $3f
    ld d, [hl]
    ld h, d
    ld sp, hl
    jr nz, jr_04a_6c63

    ld a, [$eff7]
    xor $9f
    and e
    ld h, $4c
    ld d, b
    ld d, c
    ld d, b
    ld h, d
    ld sp, hl
    jr nc, jr_04a_6c39

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
    rst $38
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
