; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $04c", ROMX[$4000], BANK[$4c]

    db $4C ; Bank number

    ; Cross-bank dispatch table (360 entries)
    ; Called via: ld hl, $4CXX / rst $10
    dw LoadB4c_42d1                  ; Entry 0
    dw $42E3                          ; Entry 1
    dw $42EA                          ; Entry 2
    dw $42F1                          ; Entry 3
    dw $4019                          ; Entry 4 — mode 0 -> table $4019 (mode list $4009)
    dw $4215                          ; Entry 5 — mode 1 -> table $4215 (mode list $4009)
    dw $423B                          ; Entry 6 — mode 2 -> table $423B (mode list $4009)
    dw $4249                          ; Entry 7 — mode 3 -> table $4249 (mode list $4009)
    dw $425B                          ; Entry 8 — mode 4 -> table $425B (mode list $4009)
    dw $4263                          ; Entry 9 — mode 5 -> table $4263 (mode list $4009)
    dw $4299                          ; Entry 10 — mode 6 -> table $4299 (mode list $4009)
    dw $42CF                          ; Entry 11 — mode 7 -> table $42CF (mode list $4009)
    dw $4305                          ; Entry 12 — [table $4019]; battle_message #0 "{ED}Look out! [INS 00] monster!{F…"
    dw $431F                          ; Entry 13 — battle_message #1 "{ED}Uh-oh! A gang of [INS 00] mon…"
    dw $4340                          ; Entry 14 — battle_message #2 "{ED}Watch out! [INS 00] and{FC}{E…"
    dw $4366                          ; Entry 15 — battle_message #3 "{ED}But it hasn't spotted us yet!…"
    dw $4387                          ; Entry 16 — battle_message #4 "{ED}But they haven't spotted us y…"
    dw $43AB                          ; Entry 17 — battle_message #5 "{ED}But they haven't spotted us y…"
    dw $43CF                          ; Entry 18 — battle_message #6 "{ED}But we've caught it off-guard…"
    dw $43F1                          ; Entry 19 — battle_message #7 "{ED}But we've caught them off-gua…"
    dw $4415                          ; Entry 20 — battle_message #8 "But we've caught them off-guard!{…"
    dw $4438                          ; Entry 21 — battle_message #9 "Suddenly - [INS 00] attacks!{FC}{…"
    dw $4452                          ; Entry 22 — battle_message #10 "Suddenly, a gang of [INS 00]{FC}{…"
    dw $4482                          ; Entry 23 — battle_message #11 "Suddenly, a gang of monsters{FC}{…"
    dw $44AF                          ; Entry 24 — battle_message #12 "[INS 00] launches a surprise atta…"
    dw $44D1                          ; Entry 25 — battle_message #13 "Ambush! [INS 00] monsters attack!…"
    dw $44F0                          ; Entry 26 — battle_message #14 "Ambush! A gang of monsters attack…"
    dw $4517                          ; Entry 27 — battle_message #15 "[INS 00] is sleeping!{EC}"
    dw $4528                          ; Entry 28 — battle_message #16 "[INS 00] is confused!{EC}"
    dw $4539                          ; Entry 29 — battle_message #17 "[INS 00] becames a lump of iron!{…"
    dw $4555                          ; Entry 30 — battle_message #18 "[INS 00] is frozen solid!{EC}"
    dw $456A                          ; Entry 31 — battle_message #19 "{ED}[INS 00] is paralyzed!{EC}"
    dw $457D                          ; Entry 32 — battle_message #20 "{ED}[INS 00] can't resist dancing…"
    dw $4597                          ; Entry 33 — battle_message #21 "[INS 00] is shivering!{EC}"
    dw $45A9                          ; Entry 34 — battle_message #22 "[INS 00] can't get up yet!{EC}"
    dw $45BE                          ; Entry 35 — battle_message #23 "[INS 00] cowers in fear!{EC}"
    dw $45D2                          ; Entry 36 — battle_message #24 "[INS 00] is daydreaming!{EC}"
    dw $45E6                          ; Entry 37 — battle_message #25 "A curse is cast on [INS 00]!{FC}{…"
    dw $4611                          ; Entry 38 — battle_message #26 "A curse is cast on [INS 00]!{FC}{…"
    dw $463A                          ; Entry 39 — battle_message #27 "{ED}A curse is cast on [INS 00]!{…"
    dw $4666                          ; Entry 40 — battle_message #28 "{ED}A curse is cast on [INS 00]!{…"
    dw $4692                          ; Entry 41 — battle_message #29 "[INS 00] tries to use [INS 10]!{F…"
    dw $46BE                          ; Entry 42 — battle_message #30 "{ED}[INS 00] casts [INS 10]!{FC}{…"
    dw $46E9                          ; Entry 43 — battle_message #31 "{ED}[INS 00] casts [INS 10]!{FC}{…"
    dw $4711                          ; Entry 44 — battle_message #32 "[INS 00] tries to spit [INS 10]!{…"
    dw $4747                          ; Entry 45 — battle_message #33 "[INS 00] performs the{FC}{EC}{F2}…"
    dw $477D                          ; Entry 46 — battle_message #34 "[INS 00] attacks!{EC}"
    dw $478A                          ; Entry 47 — battle_message #35 "{ED}[INS 00] casts [INS 10]!{EC}"
    dw $4799                          ; Entry 48 — battle_message #36 "[INS 00] throws [INS 10]!{EC}"
    dw $47A8                          ; Entry 49 — battle_message #37 "[INS 00] spits [INS 10]!{EC}"
    dw $47B6                          ; Entry 50 — battle_message #38 "[INS 00] performs{FC}{EC}{F2}the …"
    dw $47CF                          ; Entry 51 — battle_message #39 "{ED}[INS 00] shoots [INS 10]!{EC}"
    dw $47DF                          ; Entry 52 — battle_message #40 "[INS 00] defends itself!{EC}"
    dw $47F3                          ; Entry 53 — battle_message #41 "[INS 00] tries to escape!{EC}"
    dw $4808                          ; Entry 54 — battle_message #42 "[INS 00] tries to escape!{EC}"
    dw $481D                          ; Entry 55 — battle_message #43 "{ED}[INS 00] jumps on [INS 20]!{E…"
    dw $482F                          ; Entry 56 — battle_message #44 "[INS 00] charges at [INS 20]!{EC}"
    dw $4842                          ; Entry 57 — battle_message #45 "{ED}[INS 00] attacks in desperati…"
    dw $485F                          ; Entry 58 — battle_message #46 "[INS 00] launches a suicide{FC}{E…"
    dw $4887                          ; Entry 59 — battle_message #47 "{ED}[INS 00] attacks [INS 20] in{…"
    dw $48A4                          ; Entry 60 — battle_message #48 "{ED}[INS 00] slashes [INS 20].{EC}"
    dw $48B5                          ; Entry 61 — battle_message #49 "{ED}[INS 00] is charging its{FC}{…"
    dw $48D6                          ; Entry 62 — battle_message #50 "[INS 00] flies high in the sky!{E…"
    dw $48F1                          ; Entry 63 — battle_message #51 "{ED}[INS 00] dives down with forc…"
    dw $490D                          ; Entry 64 — battle_message #52 "[INS 00] takes a deep breath!{EC}"
    dw $4926                          ; Entry 65 — battle_message #53 "{ED}[INS 00] prays for a miracle.…"
    dw $495E                          ; Entry 66 — battle_message #54 "[INS 00] calls for help!{EC}"
    dw $4972                          ; Entry 67 — battle_message #55 "[INS 00] yells loudly for help!{E…"
    dw $498D                          ; Entry 68 — battle_message #56 "{ED}[INS 00] calms itself and{FC}…"
    dw $49B0                          ; Entry 69 — battle_message #57 "[INS 00] slashes at tornado speed…"
    dw $49CE                          ; Entry 70 — battle_message #58 "[INS 00] yells and attacks!{EC}"
    dw $49E5                          ; Entry 71 — battle_message #59 "[INS 00] creates a vacuum wave!{E…"
    dw $4A00                          ; Entry 72 — battle_message #60 "[INS 00] calls down lightning!{EC}"
    dw $4A1A                          ; Entry 73 — battle_message #61 "[INS 00] throws a huge rock!{EC}"
    dw $4A32                          ; Entry 74 — battle_message #62 "[INS 00] summons horrific thunder…"
    dw $4A50                          ; Entry 75 — battle_message #63 "{ED}[INS 00] summons the BigBang!…"
    dw $4A6A                          ; Entry 76 — battle_message #64 "[INS 00] uses all magic powers!{F…"
    dw $4AA6                          ; Entry 77 — battle_message #65 "[INS 00] mumbles a curse!{EC}"
    dw $4ABB                          ; Entry 78 — battle_message #66 "[INS 00] summons up the SandStorm…"
    dw $4AD9                          ; Entry 79 — battle_message #67 "[INS 00] starts to dance!{EC}"
    dw $4AEE                          ; Entry 80 — battle_message #68 "{ED}[INS 00] gives [INS 20] a hug…"
    dw $4B03                          ; Entry 81 — battle_message #69 "[INS 00] licks [INS 20]'s face!{E…"
    dw $4B17                          ; Entry 82 — battle_message #70 "[INS 00] sweeps [INS 20]'s legs!{…"
    dw $4B2C                          ; Entry 83 — battle_message #71 "[INS 00] trips [INS 20]!{EC}"
    dw $4B3A                          ; Entry 84 — battle_message #72 "[INS 00] shouts a WarCry!{EC}"
    dw $4B4F                          ; Entry 85 — battle_message #73 "{ED}[INS 00] summons natural forc…"
    dw $4B6C                          ; Entry 86 — battle_message #74 "[INS 00] creates a tailwind!{EC}"
    dw $4B84                          ; Entry 87 — battle_message #75 "[INS 00] summons a strong wind!{E…"
    dw $4B9F                          ; Entry 88 — battle_message #76 "{ED}[INS 00] binds [INS 20]'s mou…"
    dw $4BB5                          ; Entry 89 — battle_message #77 "[INS 00] is meditating calmly!{FC…"
    dw $4BEB                          ; Entry 90 — battle_message #78 "{ED}[INS 00] starts to sing the{F…"
    dw $4C11                          ; Entry 91 — battle_message #79 "{ED}[INS 00] finishes singing{FC}…"
    dw $4C35                          ; Entry 92 — battle_message #80 "[INS 00] prepares to fight.{EC}"
    dw $4C4C                          ; Entry 93 — battle_message #81 "{ED}[INS 00] proctects{FC}{EC}{F2…"
    dw $4C63                          ; Entry 94 — battle_message #82 "{ED}[INS 00] prepares for enemy{F…"
    db $87                            ; Entry 95 low ($4C87)
Jump_04c_40c0:
    db $4C                            ; Entry 95 high
    dw $4CAC                          ; Entry 96 — battle_message #84 "{ED}[INS 00] prepares for enemy{F…"
    dw $4CD0                          ; Entry 97 — battle_message #85 "{ED}[INS 00] prepares to{FC}{EC}{…"
    dw $4CF4                          ; Entry 98 — battle_message #86 "[INS 00] opens its mouth to suck{…"
    dw $4D23                          ; Entry 99 — battle_message #87 "[INS 00] attacks wildly!{FC}{EC}{…"
    dw $4D4E                          ; Entry 100 — battle_message #88 "[INS 00] is scared!{EC}"
    dw $4D5D                          ; Entry 101 — battle_message #89 "{ED}[INS 00] dashes towards{FC}{E…"
    dw $4D94                          ; Entry 102 — battle_message #90 "[INS 00] is frozen in fear!{EC}"
    dw $4DAB                          ; Entry 103 — battle_message #91 "[INS 00]'s turn! But cannot move!…"
    dw $4DC7                          ; Entry 104 — battle_message #92 "[INS 00] starts dancing!{EC}"
    dw $4DDB                          ; Entry 105 — battle_message #93 "[INS 00] uses [INS 10]!{EC}"
    dw $4DE8                          ; Entry 106 — battle_message #94 "[INS 00] throws [INS 10] at{FC}{E…"
    dw $4E01                          ; Entry 107 — battle_message #95 "{ED}[INS 00] holds up SageStone.{…"
    dw $4E1A                          ; Entry 108 — battle_message #96 "{ED}[INS 00] sprinkles WorldDew!{…"
    dw $4E33                          ; Entry 109 — battle_message #97 "[INS 00] uses [INS 10]!{FC}{EC}{F…"
    dw $4E65                          ; Entry 110 — battle_message #98 "[INS 00] uses [INS 10]!{FC}{EC}{F…"
    dw $4E93                          ; Entry 111 — battle_message #99 "[INS 00] uses [INS 10]!{FC}{EC}{F…"
    dw $4EC8                          ; Entry 112 — battle_message #100 "[INS 00] uses [INS 10]!{FC}{EC}{F…"
    dw $4EF4                          ; Entry 113 — battle_message #101 "[INS 00] uses [INS 10]!{FC}{EC}{F…"
    dw $4F20                          ; Entry 114 — battle_message #102 "[INS 00] uses [INS 10]!{FC}{EC}{F…"
    dw $4F54                          ; Entry 115 — battle_message #103 "{ED}[INS 00] attacks{FC}{EC}{F2}w…"
    dw $4F76                          ; Entry 116 — battle_message #104 "{ED}[INS 00]'s fear boosts its gu…"
    dw $4F93                          ; Entry 117 — battle_message #105 "[INS 00] focuses its energy!{EC}"
    dw $4FAB                          ; Entry 118 — battle_message #106 "[INS 00] counters fiercely!{FC}{E…"
    dw $4FD3                          ; Entry 119 — battle_message #107 "A Celestial light covers [INS 00]…"
    dw $4FF1                          ; Entry 120 — battle_message #108 "[INS 00] grabs [INS 10] and{FC}{E…"
    dw $501A                          ; Entry 121 — battle_message #109 "[INS 00] shouts a battle cry!{EC}"
    dw $5033                          ; Entry 122 — battle_message #110 "[INS 00] easily dodges the attack…"
    dw $5051                          ; Entry 123 — battle_message #111 "A horrific thing is summoned!{EC}"
    dw $5070                          ; Entry 124 — battle_message #112 "A thick fog cozes from [INS 00]!{…"
    dw $508C                          ; Entry 125 — battle_message #113 "[INS 00] is now loaded with power…"
    dw $50AA                          ; Entry 126 — battle_message #114 "[INS 00] is out of MP!{EC}"
    dw $50BC                          ; Entry 127 — battle_message #115 "[Chance Chance Chance Chance...]{…"
    dw $50FE                          ; Entry 128 — battle_message #116 "A gigantic devil emerges!{FC}{EC}…"
    dw $512B                          ; Entry 129 — battle_message #117 "Cold winds strike [INS 20]!{EC}"
    dw $5142                          ; Entry 130 — battle_message #118 "[INS 00] recoveres MP!{EC}"
    dw $5154                          ; Entry 131 — battle_message #119 "Shooting Stars fall everywhere!{E…"
    dw $5175                          ; Entry 132 — battle_message #120 "[INS 00] easily dodges the attack…"
    dw $5193                          ; Entry 133 — battle_message #121 "A critical hit! {EC}"
    dw $51A5                          ; Entry 134 — battle_message #122 "A pitiful attack! {EC}"
    dw $51B9                          ; Entry 135 — battle_message #123 "A wall of light reflects the{FC}{…"
    dw $51E2                          ; Entry 136 — battle_message #124 "The spell is reflected by a{FC}{E…"
    dw $5212                          ; Entry 137 — battle_message #125 "{ED}The wind around [INS 00]{FC}{…"
    dw $523F                          ; Entry 138 — battle_message #126 "{ED}[INS 20] dodges the attack!{E…"
    dw $5257                          ; Entry 139 — battle_message #127 "[INS 20] cannot dodge in time!{EC}"
    dw $5271                          ; Entry 140 — battle_message #128 "{ED}[INS 00] protects{FC}{EC}{F2}…"
    dw $5287                          ; Entry 141 — battle_message #129 "[INS 00] absorbs the attack!{EC}"
    dw $529F                          ; Entry 142 — battle_message #130 "{ED}[INS 00] takes [INS 10] damag…"
    dw $52B9                          ; Entry 143 — battle_message #131 "{ED}[INS 00] receives{FC}{EC}{F2}…"
    dw $52D9                          ; Entry 144 — battle_message #132 "[INS 00]'s wound heals!{EC}"
    dw $52EB                          ; Entry 145 — battle_message #133 "[INS 00] receives a fatal{FC}{EC}…"
    dw $530A                          ; Entry 146 — battle_message #134 "{ED}[INS 00] loses [INS 10] defen…"
    dw $5321                          ; Entry 147 — battle_message #135 "[INS 00] loses [INS 10] defense!{…"
    dw $5337                          ; Entry 148 — battle_message #136 "[INS 00]'s spells are all suspend…"
    dw $5356                          ; Entry 149 — battle_message #137 "[INS 00]'s spells are all suspend…"
    dw $5375                          ; Entry 150 — battle_message #138 "[INS 00]'s MP is drained by [INS …"
    dw $538F                          ; Entry 151 — battle_message #139 "[INS 00]'s MP is drained by [INS …"
    dw $53A9                          ; Entry 152 — battle_message #140 "[INS 00] starts to glow faintly!{…"
    dw $53C5                          ; Entry 153 — battle_message #141 "[INS 00] sucks in [INS 10] MP!{EC}"
    dw $53D9                          ; Entry 154 — battle_message #142 "[INS 00] is confused!{EC}"
    dw $53EA                          ; Entry 155 — battle_message #143 "[INS 00] is confused!{EC}"
    dw $53FB                          ; Entry 156 — battle_message #144 "[INS 00]'s attack power is double…"
    dw $5419                          ; Entry 157 — battle_message #145 "{ED}[INS 00] changes into a big d…"
    dw $5439                          ; Entry 158 — battle_message #146 "{ED}[INS 00]'s defense goes up{FC…"
    dw $545A                          ; Entry 159 — battle_message #147 "[INS 00]'s gang become iron lumps…"
    dw $5477                          ; Entry 160 — battle_message #148 "[INS 00] turns into an iron lump!…"
    dw $5494                          ; Entry 161 — battle_message #149 "[INS 00]'s speed goes down by{FC}…"
    dw $54B4                          ; Entry 162 — battle_message #150 "[INS 00]'s speed drops by [INS 10…"
    dw $54CC                          ; Entry 163 — battle_message #151 "[INS 00]'s speed goes up by [INS …"
    dw $54E6                          ; Entry 164 — battle_message #152 "An illusion engulfs{FC}{EC}{F2}[I…"
    dw $5503                          ; Entry 165 — battle_message #153 "A wall of light rises before{FC}{…"
    dw $5529                          ; Entry 166 — battle_message #154 "A wall of light is created before…"
    dw $5554                          ; Entry 167 — battle_message #155 "A veil of light covers [INS 00]{F…"
    dw $5581                          ; Entry 168 — battle_message #156 "[INS 00] is no longer poisoned!{E…"
    dw $559C                          ; Entry 169 — battle_message #157 "[INS 00] is no longer paralyzed!{…"
    dw $55B8                          ; Entry 170 — battle_message #158 "[INS 00] is revived!{EC}"
    dw $55C8                          ; Entry 171 — battle_message #159 "[INS 00] is no longer cursed!{EC}"
    dw $55E1                          ; Entry 172 — battle_message #160 "[INS 20] turns into [INS 00]!{EC}"
    dw $55F4                          ; Entry 173 — battle_message #161 "Allies appear from nowhere!{EC}"
    dw $5611                          ; Entry 174 — battle_message #162 "[INS 00] gets sand in its eyes!{E…"
    dw $562C                          ; Entry 175 — battle_message #163 "[INS 00] is blinded!{EC}"
    dw $563C                          ; Entry 176 — battle_message #164 "[INS 00] is now vulnerable to{FC}…"
    dw $5667                          ; Entry 177 — battle_message #165 "[INS 00] lost [INS 10] MP!{EC}"
    dw $5677                          ; Entry 178 — battle_message #166 "[INS 00] is lured into{FC}{EC}{F2…"
    dw $5696                          ; Entry 179 — battle_message #167 "[INS 00] seems to be feeling{FC}{…"
    dw $56B8                          ; Entry 180 — battle_message #168 "[INS 00] gets goose bumps!{EC}"
    dw $56CE                          ; Entry 181 — battle_message #169 "[INS 00] gets goose bumps!{FC}{EC…"
    dw $56FE                          ; Entry 182 — battle_message #170 "[INS 00] freezes in shock!{EC}"
    dw $5714                          ; Entry 183 — battle_message #171 "[INS 00] stumbles!{EC}"
    dw $5722                          ; Entry 184 — battle_message #172 "The spell on [INS 00]{FC}{EC}{F2}…"
    dw $5742                          ; Entry 185 — battle_message #173 "[INS 00] returns to its true form…"
    dw $5760                          ; Entry 186 — battle_message #174 "[INS 00] is completely cured!{EC}"
    dw $5779                          ; Entry 187 — battle_message #175 "Wow! [INS 00] joined the battle!{…"
    dw $5795                          ; Entry 188 — battle_message #176 "{ED}[INS 00] hypnotic dance is{FC…"
    dw $57B9                          ; Entry 189 — battle_message #177 "{ED}[INS 00] hypnotic{FC}{EC}{F2}…"
    dw $57DC                          ; Entry 190 — battle_message #178 "[INS 00]'s mouth is bound shut!{E…"
    dw $57F6                          ; Entry 191 — battle_message #179 "[INS 00]'s mouth is bound shut!{E…"
    dw $5810                          ; Entry 192 — battle_message #180 "[INS 00] is not listening to you!…"
    dw $582D                          ; Entry 193 — battle_message #181 "[INS 00] is frozen!{EC}"
    dw $583C                          ; Entry 194 — battle_message #182 "Misses! [INS 00]!{FC}{EC}{F2}is u…"
    dw $585A                          ; Entry 195 — battle_message #183 "Missed [INS 00]! No damage!{EC}"
    dw $5871                          ; Entry 196 — battle_message #184 "Has no effect on [INS 00]!{EC}"
    dw $5887                          ; Entry 197 — battle_message #185 "But the enemy blocks the way!{EC}"
    dw $58A6                          ; Entry 198 — battle_message #186 "[INS 00]'s turns to iron and{FC}{…"
    dw $58D6                          ; Entry 199 — battle_message #187 "But nothing happens!{EC}"
    dw $58EC                          ; Entry 200 — battle_message #188 "[INS 00] doesn't fall asleep!{EC}"
    dw $5904                          ; Entry 201 — battle_message #189 "[INS 00] is already sleeping!{EC}"
    dw $591D                          ; Entry 202 — battle_message #190 "[INS 00] becomes more confused!{E…"
    dw $5938                          ; Entry 203 — battle_message #191 "[INS 00] isn't revived!{EC}"
    dw $5938                          ; Entry 204 — battle_message #192 "[INS 00] isn't revived!{EC}"
    dw $594A                          ; Entry 205 — battle_message #193 "But it doesn't reach [INS 00]!{EC}"
    dw $5963                          ; Entry 206 — battle_message #194 "But the call is not heard!{EC}"
    dw $597F                          ; Entry 207 — battle_message #195 "[INS 00] dodges the air attack!{E…"
    dw $599A                          ; Entry 208 — battle_message #196 "[INS 00] quickly covers its ears!…"
    dw $59B7                          ; Entry 209 — battle_message #197 "[INS 00] shakes off the sand!{EC}"
    dw $59D0                          ; Entry 210 — battle_message #198 "[INS 00] dodges with ease!{EC}"
    dw $59E6                          ; Entry 211 — battle_message #199 "[INS 00] dodges quickly!{EC}"
    dw $59FA                          ; Entry 212 — battle_message #200 "[INS 00] isn't lured in!{EC}"
    dw $5A0D                          ; Entry 213 — battle_message #201 "But [INS 00] dodges easily!{EC}"
    dw $5A24                          ; Entry 214 — battle_message #202 "{ED}[INS 00] isn't affected!{EC}"
    dw $5A38                          ; Entry 215 — battle_message #203 "But the prayer isn't heard!{EC}"
    dw $5A54                          ; Entry 216 — battle_message #204 "[INS 00] is sent to sleep!{EC}"
    dw $5A6A                          ; Entry 217 — battle_message #205 "[INS 00] falls asleep!{EC}"
    dw $5A7C                          ; Entry 218 — battle_message #206 "[INS 00] is poisoned!{EC}"
    dw $5A8D                          ; Entry 219 — battle_message #207 "[INS 00] is paralyzed!{EC}"
    dw $5A9F                          ; Entry 220 — battle_message #208 "[INS 00] is severely poisoned!{EC}"
    dw $5AB9                          ; Entry 221 — battle_message #209 "[INS 00] is cursed!{EC}"
    dw $5AC8                          ; Entry 222 — battle_message #210 "[INS 00] is frozen!{EC}"
    dw $5AD7                          ; Entry 223 — battle_message #211 "[INS 00] gets even!{EC}"
    dw $5AE6                          ; Entry 224 — battle_message #212 "[INS 00] can't get even!{EC}"
    dw $5AF9                          ; Entry 225 — battle_message #213 "[INS 00] counterattacks!{EC}"
    dw $5B0D                          ; Entry 226 — battle_message #214 "[INS 00] can't counterattack!{EC}"
    dw $5B25                          ; Entry 227 — battle_message #215 "[INS 00] blows back [INS 10]!{EC}"
    dw $5B38                          ; Entry 228 — battle_message #216 "[INS 00] disappears!{EC}"
    dw $5B48                          ; Entry 229 — battle_message #217 "The wind is stopped!{EC}"
    dw $5B5E                          ; Entry 230 — battle_message #218 "Allies have gone! {EC}"
    dw $5B72                          ; Entry 231 — battle_message #219 "[INS 00] wakes up!{EC}"
    dw $5B80                          ; Entry 232 — battle_message #220 "[INS 00] returns to normal!{EC}"
    dw $5B97                          ; Entry 233 — battle_message #221 "[INS 00]'s Ironize wears off!{EC}"
    dw $5BAF                          ; Entry 234 — battle_message #222 "The wall of light disappears!{EC}"
    dw $5BCE                          ; Entry 235 — battle_message #223 "The devil leaves, laughing!{EC}"
    dw $5BEB                          ; Entry 236 — battle_message #224 "The [INS 10] falls to pieces!{EC}"
    dw $5C04                          ; Entry 237 — battle_message #225 "Poisoned! {FC}{EC}{F2}[INS 00] lo…"
    dw $5C23                          ; Entry 238 — battle_message #226 "A strong poison takes [INS 10] HP…"
    dw $5C7B                          ; Entry 239 — battle_message #227 "[INS 00] collapses!{EC}"
    dw $5C8A                          ; Entry 240 — battle_message #228 "[INS 00] is knocked out!{EC}"
    dw $5C9E                          ; Entry 241 — battle_message #229 "[INS 00] is weak after the dance!…"
    dw $5CBB                          ; Entry 242 — battle_message #230 "[INS 00] disappears!{EC}"
    dw $5CCB                          ; Entry 243 — battle_message #231 "[INS 00] is out of HP and faints!…"
    dw $5CE8                          ; Entry 244 — battle_message #232 "[INS 00] is finished!{EC}"
    dw $5CF9                          ; Entry 245 — battle_message #233 "[INS 00] falls to pieces!{EC}"
    dw $5D0E                          ; Entry 246 — battle_message #234 "[INS 00] is out of HP and faints!…"
    dw $5D2B                          ; Entry 247 — battle_message #235 "The [INS 00] gang is wiped out!"
    dw $5D47                          ; Entry 248 — battle_message #236 "[HERO] knocks out [INS 00]!"
    dw $5D5A                          ; Entry 249 — battle_message #237 "[HERO] beats the [INS 00] gang!"
    dw $5D71                          ; Entry 250 — battle_message #238 "[HERO] knocks out the enemy!"
    dw $5D8B                          ; Entry 251 — battle_message #239 "The [INS 00] has fled!"
    dw $5D9E                          ; Entry 252 — battle_message #240 "The [INS 00] gang has fled!"
    dw $5DB6                          ; Entry 253 — battle_message #241 "All the monsters have fled!"
    dw $5DD4                          ; Entry 254 — battle_message #242 "Can't use this item in battle!"
    dw $5DF4                          ; Entry 255 — battle_message #243 "But there are no items that can b…"
    dw $5E2C                          ; Entry 256 — battle_message #244 "Can't use items in this battle!"
    dw $5E4D                          ; Entry 257 — battle_message #245 "Can't run from this battle!"
    dw $5E6A                          ; Entry 258 — battle_message #246 "{ED}Waiting for [INS 00] to choos…"
    dw $5E8D                          ; Entry 259 — battle_message #247 "[INS 00] casts [INS 10]!{FC}{EC}{…"
    dw $5EB2                          ; Entry 260 — battle_message #248 "[INS 00] spits [INS 10]!{FC}{EC}{…"
    dw $5ED7                          ; Entry 261 — battle_message #249 "[INS 00] dances [INS 10]!{FC}{EC}…"
    dw $5EFD                          ; Entry 262 — battle_message #250 "But cannot use [INS 00]!"
    dw $5F12                          ; Entry 263 — battle_message #251 "But cannot use this skill in this…"
    dw $5F41                          ; Entry 264 — battle_message #252 "Cannot give a command in this {F2…"
    dw $5F6C                          ; Entry 265 = msg id $FD: the vanilla empty string. [S155 r3] back from CustomMsg_E0_MagicBurn (S2d-S155 r2): the game renders $FD through this row after the poison tick ($E1, stock $db8a) — it showed "burns half its MP!" (BATTLE_SKILL_SYSTEM §13.1)
    dw $5F6D                          ; Entry 266 — [table $4215]; battle_effect #0 "{ED}[INS 00] gives [INS 10] to{FC…"
    dw $5F86                          ; Entry 267 — battle_effect #1 "[INS 00] gives [INS 10] to the{FC…"
    dw $5FA7                          ; Entry 268 — battle_effect #2 "{ED}[INS 00] gives [INS 10] to th…"
    dw $5FCA                          ; Entry 269 — battle_effect #3 "{ED}[INS 00] starts eating the tr…"
    dw $6002                          ; Entry 270 — battle_effect #4 "[INS 00] timidly eats the treat!{…"
    dw $6032                          ; Entry 271 — battle_effect #5 "The [INS 00] gang eats the treat!…"
    dw $6069                          ; Entry 272 — battle_effect #6 "The [INS 00] gang nibbles the tre…"
    dw $609E                          ; Entry 273 — battle_effect #7 "The monsters start eating{FC}{EC}…"
    dw $60F2                          ; Entry 274 — battle_effect #8 "The monsters nibble the treat!{FC…"
    dw $6127                          ; Entry 275 — battle_effect #9 "{ED}A veil of light covers [INS 0…"
    dw $6145                          ; Entry 276 — battle_effect #10 "{ED}A veil of light covers the{FC…"
    dw $6170                          ; Entry 277 — battle_effect #11 "A veil of light covers the{FC}{EC…"
    dw $619A                          ; Entry 278 — battle_effect #12 "[INS 00] tries to fly high!{FC}{E…"
    dw $61C8                          ; Entry 279 — battle_effect #13 "[INS 00] tries to call for help!{…"
    dw $61FB                          ; Entry 280 — battle_effect #14 "[INS 00] tries to attack after{FC…"
    dw $6243                          ; Entry 281 — battle_effect #15 "[INS 00] tries to a curse!{FC}{EC…"
    dw $6270                          ; Entry 282 — battle_effect #16 "[INS 00] tries to suck in{FC}{EC}…"
    dw $62AC                          ; Entry 283 — battle_effect #17 "[INS 00] tries to shut{FC}{EC}{F2…"
    dw $62E3                          ; Entry 284 — battle_effect #18 "{ED}[INS 00] tries to sing the{FC…"
    dw $631F                          ; Entry 285 — [table $423B]; battle_command #0 "No monsters that can give command…"
    dw $6345                          ; Entry 286 — battle_command #1 "[INS 00] doesn't have any skill t…"
    dw $6345                          ; Entry 287 — battle_command #2 "[INS 00] doesn't have any skill t…"
    dw $6375                          ; Entry 288 — battle_command #3 "But this skill cannot be used {F2…"
    dw $63A3                          ; Entry 289 — battle_command #4 "Not enough MP!"
    dw $63B5                          ; Entry 290 — battle_command #5 "Give up the battle?"
    dw $63C9                          ; Entry 291 — battle_command #6 "[INS 00]s gives up the battle!{EC}"
    dw $63E5                          ; Entry 292 — [table $4249]; battle_beasttail #0 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 293 — battle_beasttail #1 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 294 — battle_beasttail #2 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 295 — battle_beasttail #3 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 296 — battle_beasttail #4 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 297 — battle_beasttail #5 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 298 — battle_beasttail #6 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 299 — battle_beasttail #7 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 300 — battle_beasttail #8 "[HERO] takes out the BeastTail!{E…"
    dw $63E5                          ; Entry 301 — [table $425B]; battle_beasttail_result #0 "[HERO] takes out the BeastTail!{E…"
    dw $6401                          ; Entry 302 — battle_beasttail_result #1 "Points the BeastTail at the{FC}{E…"
    dw $6429                          ; Entry 303 — battle_beasttail_result #2 "[INS 00] has been your pal before…"
    dw $6447                          ; Entry 304 — battle_beasttail_result #3 "[INS 00] hasn't been your pal yet…"
    dw $6464                          ; Entry 305 — [table $4263]; credits_role #0 "{ED}EXECUTIVE DIRECTOR"
    dw $6478                          ; Entry 306 — credits_role #1 "{ED}SCENARIO & GAME DESIGN"
    dw $6490                          ; Entry 307 — credits_role #2 "{ED}CHARACTER & MONSTER DESIGN"
    dw $64AC                          ; Entry 308 — credits_role #3 "{ED}MUSIC COMPOSER"
    dw $64BC                          ; Entry 309 — credits_role #4 "{ED}TOSE STAFF"
    dw $64C8                          ; Entry 310 — credits_role #5 "{ED}PROGRAMMERS"
    dw $64D5                          ; Entry 311 — credits_role #6 "{ED}GRAPHIC DESIGNERS"
    dw $64E8                          ; Entry 312 — credits_role #7 "{ED}MUSIC COMPOSER ASSISTANTS"
    dw $6503                          ; Entry 313 — credits_role #8 "{ED}GAME DESIGN ASSISTANTS"
    dw $651B                          ; Entry 314 — credits_role #9 "{ED}EIDOS INTERACTIVE STAFF"
    dw $6534                          ; Entry 315 — credits_role #10 "{ED}LOCALIZATION"
    dw $6542                          ; Entry 316 — credits_role #11 "{ED}PRODUCERS"
    dw $654D                          ; Entry 317 — credits_role #12 "{ED}QA MANAGERS"
    dw $655A                          ; Entry 318 — credits_role #13 "{ED}MARKETING"
    dw $6565                          ; Entry 319 — credits_role #14 "{ED}MANUAL TRANSLATION"
    dw $6579                          ; Entry 320 — credits_role #15 "{ED}SPECIAL THANKS"
    dw $6589                          ; Entry 321 — credits_role #16 "{ED}ENIX STAFF"
    dw $6595                          ; Entry 322 — credits_role #17 "{ED}ARTWORK"
    dw $659E                          ; Entry 323 — credits_role #18 "{ED}TECHNICAL SUPPORT"
    dw $65B1                          ; Entry 324 — credits_role #19 "{ED}TESTERS"
    dw $65B1                          ; Entry 325 — credits_role #20 "{ED}TESTERS"
    dw $65BA                          ; Entry 326 — credits_role #21 "{ED}U.S.LIAISON"
    dw $65C7                          ; Entry 327 — credits_role #22 "{ED}ASSISTANT PRODUCER"
    dw $65DB                          ; Entry 328 — credits_role #23 "{ED}PRODUCERS"
    dw $65E6                          ; Entry 329 — credits_role #24 "{ED}EXECUTIVE PRODUCER"
    dw $65FA                          ; Entry 330 — credits_role #25 "{ED}PRESIDENT"
    dw $6605                          ; Entry 331 — credits_role #26 ""
    dw $6606                          ; Entry 332 — [table $4299]; credits_name #0 "{ED}YUJI HORII"
    dw $6614                          ; Entry 333 — credits_name #1 "{ED}ENIX TOSE YUJI HORII"
    dw $662D                          ; Entry 334 — credits_name #2 "{ED}AKIRA TORIYAMA"
    dw $663F                          ; Entry 335 — credits_name #3 "{ED}KOICHI SUGIYAMA"
    dw $6652                          ; Entry 336 — credits_name #4 "{ED}"
    dw $6654                          ; Entry 337 — credits_name #5 "{ED}GAO MATSUMOTO UMEZO HI!SPEED"
    dw $6675                          ; Entry 338 — credits_name #6 "{ED}WANTENYU YUKAPI OLD{9B}ONES T…"
    dw $669F                          ; Entry 339 — credits_name #7 "{ED}ASD{9B}BAT KAZUKI KIKUTANI"
    dw $66BA                          ; Entry 340 — credits_name #8 "{ED}JIN UNK HISANE"
    dw $66CC                          ; Entry 341 — credits_name #9 "{ED}"
    dw $66CE                          ; Entry 342 — credits_name #10 "{ED}JIM CURRY YOTA WADA"
    dw $66E4                          ; Entry 343 — credits_name #11 "{ED}FRANK HOM (U.S.) YOTA WADA (U…"
FuncB4c_42b1:
    dw $6708                          ; Entry 344 — credits_name #12 "{ED}TONY BOURNE (U.K.) MIKE MCHAL…"
    dw $6730                          ; Entry 345 — credits_name #13 "{ED}SUSAN BOSHKOFF (U.S.) JIM CUR…"
    dw $6771                          ; Entry 346 — credits_name #14 "{ED}PHOSPHORS"
    dw $677C                          ; Entry 347 — credits_name #15 "{ED}EIDOS-JAPAN SATOSHI HONDA TAK…"
    dw $67BB                          ; Entry 348 — credits_name #16 "{ED}"
    dw $67BD                          ; Entry 349 — credits_name #17 "{ED}NAOKI OISHI"
    dw $67CC                          ; Entry 350 — credits_name #18 "{ED}TERUHIKO HANAWA KENJIRO KANO …"
    dw $680D                          ; Entry 351 — credits_name #19 "{ED}SEIICHI MORIUCHI KAN IKEDA TE…"
    dw $685C                          ; Entry 352 — credits_name #20 "MITO YAMAGISHI JIRO KIMURA MIWAKO…"
    dw $68A7                          ; Entry 353 — credits_name #21 "{ED}PAUL HANDELMAN"
    dw $68B9                          ; Entry 354 — credits_name #22 "{ED}JUN MIYAMOTO"
    dw $68C9                          ; Entry 355 — credits_name #23 "{ED}HITOSHI SUINOU KEIJI HONDA"
    dw $68E8                          ; Entry 356 — credits_name #24 "{ED}YUKINOBU CHIDA"
    dw $68FA                          ; Entry 357 — credits_name #25 "{ED}YASUHIRO FUKUSHIMA"
    dw $6910                          ; Entry 358 — credits_name #26 "{ED}{B5}2000 ARMOR PROJECT {B5}20…"
    dw $6944                          ; Entry 359 — [table $42CF]; credits_end #0 "{ED}…TOBECONTINUED"

LoadB4c_42d1:
; Bank $4c entry 0 = battle-MESSAGE renderer (S2c). Caller sets $c822=mode (0/1)
; and $c823=message id; this runs the shared text VM with config base $4009, which
; resolves the string via the mode-0 two-level table: subtable=[$4c:$4009+mode*2]
; (=$4019 for mode 0, the battle-message ptr table), string=[subtable+id*2]. The
; "effect-script selector" $dd70/71 is just a packed (hit id, miss id) pair fed here
; by bank $53 jr_053_5a6f. $ff id = "no message" (skip). See BATTLE_SKILL_SYSTEM.md S9.
    ; S2e: forked to the custom-message resolver (LoadB4c_Fork, in pool free
    ; space). Byte-neutral: jp (3) + 15 nop = the original 18-byte footprint, so
    ; the entries at $42e3/$42ea/$42f1 stay at their addresses. See LoadB4c_Fork.
    jp LoadB4c_Fork
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop


    ld de, $4009
    call RunTextHandler
    ret


    call LoadB4c_42d1
    call RequestScreenUpdate
    ret


    ld a, [$dd6d]
    add $d7
    ld [$c823], a
    xor a
    ld [$c822], a
    call LoadB4c_42d1
    xor a
    ld [$dd6d], a
    ret


    db $ed
    cpl
    ld c, h
    ld c, h
    ld c, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    pop af
    ld sp, hl
    nop
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$ed]
    jr c, jr_04c_4367

    sbc h
    ld c, h
    ld b, l
    ld h, e
    ld h, d
    inc h
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld sp, hl
    nop
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    db $fc
    db $10
    db $ec
    ldh a, [$ed]
    ld a, [hl-]
    ld a, $51
    ld b, b
    ld b, l
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    pop af
    ld sp, hl
    nop
    ld h, d
    ld a, $4b
    ld b, c
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$ed]

jr_04c_4367:
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld a, $50
    ld c, e
    ld h, a
    pop af
    ld d, b
    ld c, l
    ld c, h
    ld d, c
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$ed]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld c, e
    ld h, a
    pop af
    ld d, b
    ld c, l
    ld c, h
    ld d, c
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$ed]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld c, e
    ld h, a
    pop af
    ld d, b
    ld c, l
    ld c, h
    ld d, c
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ld d, d
    ld d, b
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$ed]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, d
    ld l, h
    ld b, d
    ld h, d
    ld b, b
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld b, [hl]
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    sbc h
    ld b, h
    ld d, d
    ld a, $4f
    ld b, c
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$ed]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, d
    ld l, h
    ld b, d
    ld h, d
    ld b, b
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    sbc h
    ld b, h
    ld d, d
    ld a, $4f
    ld b, c
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld d, h
    ld b, d
    ld l, h
    ld b, d
    ld h, d
    ld b, b
    ld a, $52
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld c, d
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    sbc h
    ld b, h
    ld d, d
    ld a, $4f
    ld b, c
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$36]
    ld d, d
    ld b, c
    ld b, c
    ld b, d
    ld c, e
    ld c, c
    ld d, [hl]
    ld h, d
    sbc h
    pop af
    ld sp, hl
    nop
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$36]
    ld d, d
    ld b, c
    ld b, c
    ld b, d
    ld c, e
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld a, $62
    ld b, h
    ld a, $4b
    ld b, h
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld sp, hl
    nop
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ldh a, [$36]
    ld d, d
    ld b, c
    ld b, c
    ld b, d
    ld c, e
    ld c, c
    ld d, [hl]
    ld e, [hl]
    ld h, d
    ld a, $62
    ld b, h
    ld a, $4b
    ld b, h
    pop af
    ld c, h
    ld b, e
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, c
    ld a, $52
    ld c, e
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    pop af
    ld a, $62
    ld d, b
    ld d, d
    ld c, a
    ld c, l
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [rNR50]
    ld c, d
    ccf
    ld d, d
    ld d, b
    ld b, l
    ld h, e
    ld h, d
    ld sp, hl
    nop
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [rNR50]
    ld c, d
    ccf
    ld d, d
    ld d, b
    ld b, l
    ld h, e
    ld h, d
    inc h
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld a, $4a
    ld b, d
    ld d, b
    pop af
    ld a, $62
    ld c, c
    ld d, d
    ld c, d
    ld c, l
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld b, [hl]
    ld c, a
    ld c, h
    ld c, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld d, a
    ld b, d
    ld c, e
    ld h, d
    ld d, b
    ld c, h
    ld c, c
    ld b, [hl]
    ld b, c
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    pop af
    ld c, a
    ld b, d
    ld d, b
    ld b, [hl]
    ld d, b
    ld d, c
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld b, l
    ld b, [hl]
    ld d, e
    ld b, d
    ld c, a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    pop af
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, c
    ld a, $56
    ld b, c
    ld c, a
    ld b, d
    ld a, $4a
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    pop af
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld h, e
    db $ec
    ldh a, [$ed]
    inc h
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    dec hl
    inc sp
    ld h, e
    db $ec
    ldh a, [$ed]
    inc h
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    jr nc, jr_04c_46c2

    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_46ed

    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d

jr_04c_46c2:
    ld b, b
    ld a, $50
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ccf
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d

jr_04c_46ed:
    ld b, b
    ld a, $50
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld d, h
    ld a, $50
    pop af
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    pop af
    ld d, b
    ld c, l
    ld b, [hl]
    ld d, c
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld b, l
    ld d, d
    ld d, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld c, l
    ld b, d
    ld c, a
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ccf
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld c, l
    ld b, d
    ld c, a
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld c, h
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, d
    ld d, b
    ld b, b
    ld a, $4d
    ld b, d
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, a
    ld d, d
    ld c, d
    ld c, l
    ld d, b
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld sp, hl
    jr nz, jr_04c_4890

    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld b, l
    ld a, $4f
    ld b, h
    ld b, d
    ld d, b
    pop af
    ld a, $51
    ld h, d
    ld sp, hl
    jr nz, jr_04c_48a3

    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, c
    ld b, d
    ld d, b
    ld c, l
    ld b, d
    ld c, a
    ld a, $51
    ld b, [hl]
    ld c, h
    ld c, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld c, c
    ld a, $52
    ld c, e
    ld b, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld d, b
    ld d, d
    ld b, [hl]
    ld b, b
    ld b, [hl]
    ld b, c
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld sp, hl
    jr nz, jr_04c_48e8

    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40

jr_04c_4890:
    ld c, b
    ld d, b
    pop af
    ld sp, hl
    jr nz, jr_04c_48f8

    ld b, [hl]
    ld c, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld c, a
    ld a, $44
    ld b, d
    ld h, e
    pop af
    db $ec

jr_04c_48a3:
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld c, c
    ld a, $50
    ld b, l
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    jr nz, @+$61

    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld b, l
    ld a, $4f
    ld b, h
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, e
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c

jr_04c_48e8:
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, b
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, e

jr_04c_48f8:
    ld b, d
    ld d, b
    pop af
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, b
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld d, b
    pop af
    ld a, $62
    ld b, c
    ld b, d
    ld b, d
    ld c, l
    ld h, d
    ccf
    ld c, a
    ld b, d
    ld a, $51
    ld b, l
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld c, l
    ld c, a
    ld a, $56
    ld d, b
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld a, $62
    ld c, d
    ld b, [hl]
    ld c, a
    ld a, $40
    ld c, c
    ld b, d
    ld e, a
    db $fc
    db $10
    db $ec
    ld a, [c]
    inc h
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    pop af
    ld d, b
    ld c, c
    ld b, [hl]
    ld b, b
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    jr nz, jr_04c_49bf

    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld d, b
    pop af
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, [hl]
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld c, c
    ld c, h
    ld d, d
    ld b, c
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, b
    ld a, $49
    ld c, d
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, d
    ld a, $4b
    ld b, c
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, e
    ld c, h
    ld b, b
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld c, c
    ld a, $50
    ld b, l
    ld b, d
    ld d, b
    pop af
    ld a, $51
    ld h, d
    ld d, c

jr_04c_49bf:
    ld c, h
    ld c, a
    ld c, e
    ld a, $41
    ld c, h
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, [hl]
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld a, $4b
    ld b, c
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    pop af
    ld a, $62
    ld d, e
    ld a, $40
    ld d, d
    ld d, d
    ld c, d
    ld h, d
    ld d, h
    ld a, $53
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld d, b
    pop af
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    pop af
    ld a, $62
    ld b, l
    ld d, d
    ld b, h
    ld b, d
    ld h, d
    ld c, a
    ld c, h
    ld b, b
    ld c, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld d, d
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    pop af
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, c
    ld b, l
    ld d, d
    ld c, e
    ld b, c
    ld b, d
    ld c, a
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld d, d
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld b, [hl]
    ld b, h
    dec h
    ld a, $4b
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld a, $49
    ld c, c
    ld h, d
    ld c, d
    ld a, $44
    ld b, [hl]
    ld b, b
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    inc h
    ld h, d
    ld b, l
    ld d, d
    ld b, h
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld c, a
    ld d, b
    ld d, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld c, d
    ld a, $44
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, d
    ld d, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    pop af
    ld a, $62
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld d, d
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    pop af
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld [hl], $3e
    ld c, e
    ld b, c
    ld [hl], $51
    ld c, h
    ld c, a
    ld c, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    jr nz, @+$64

    ld a, $62
    ld b, l
    ld d, d
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, b
    ld c, b
    ld d, b
    pop af
    ld sp, hl
    jr nz, jr_04c_4b77

    ld h, d
    ld b, e
    ld a, $40
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld d, h
    ld b, d
    ld b, d
    ld c, l
    ld d, b
    pop af
    ld sp, hl
    jr nz, jr_04c_4b8c

    ld h, d
    ld c, c
    ld b, d
    ld b, h
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld c, l
    ld d, b
    pop af
    ld sp, hl
    jr nz, jr_04c_4b9b

    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    pop af
    ld a, $62
    ld a, [hl-]
    ld a, $4f
    ld h, $4f
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld d, d
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    pop af
    ld c, e
    ld a, $51
    ld d, d
    ld c, a
    ld a, $49
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, b
    ld b, d
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    pop af

jr_04c_4b77:
    ld a, $62
    ld d, c
    ld a, $46
    ld c, c
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld d, d
    ld c, d
    ld c, d
    ld c, h

jr_04c_4b8c:
    ld c, e
    ld d, b
    pop af
    ld a, $62
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e

jr_04c_4b9b:
    ld b, c
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ccf
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    pop af
    ld sp, hl
    jr nz, jr_04c_4c14

    ld h, d
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, d
    ld b, d
    ld b, c
    ld b, [hl]
    ld d, c
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, b
    ld a, $49
    ld c, d
    ld c, c
    ld d, [hl]
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld l, b
    ld h, d
    ld d, b
    ld b, b
    ld a, $4f
    ld d, b
    pop af
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    cpl
    ld b, [hl]
    ld b, e
    ld b, d
    ld [hl], $4c
    ld c, e
    ld b, h
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop

jr_04c_4c14:
    pop af
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld d, b
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld b, [hl]
    ld c, e
    ld b, h
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, h
    ld c, e
    ld b, h
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld e, a
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld c, l
    ld c, a
    ld c, h
    ld b, b
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    jr nz, jr_04c_4cc3

    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld b, d
    ld c, e
    ld b, c
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld a, $4b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld e, a
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld d, b
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    db $fc

jr_04c_4cc3:
    db $10
    db $ec
    ld a, [c]
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld c, l
    ld c, a
    ld b, d
    ld c, l
    ld a, $4f
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, h
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, c
    ld b, c
    ld c, c
    ld d, [hl]
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld b, d
    ld c, c
    ld b, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld b, b
    ld a, $4f
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, c
    ld a, $50
    ld b, l
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld d, h
    ld a, $4f
    ld b, c
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    jr nz, jr_04c_4dd9

    pop af
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, b
    ld d, c
    ld d, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld h, d
    ld a, $4b
    ld b, c
    pop af
    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld d, a
    ld b, d
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld h, e
    pop af
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e

jr_04c_4dd9:
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld b, l
    ld c, a
    ld c, h
    ld d, h
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld a, $51
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    jr nz, jr_04c_4e61

    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, l
    ld c, h
    ld c, c
    ld b, c
    ld d, b
    pop af
    ld d, d
    ld c, l
    ld h, d
    ld [hl], $3e
    ld b, h
    ld b, d
    ld [hl], $51
    ld c, h
    ld c, e
    ld b, d
    ld e, a
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld c, l
    ld c, a
    ld b, [hl]
    ld c, e
    ld c, b
    ld c, c
    ld b, d
    ld d, b
    pop af
    ld a, [hl-]
    ld c, h
    ld c, a
    ld c, c
    ld b, c
    daa
    ld b, d
    ld d, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    scf
    ld b, l
    ld b, d
    ld h, d
    ccf
    ld c, h
    ld c, c
    ld d, c
    ld h, d
    ccf
    ld d, d
    ld c, a
    ld d, b
    ld d, c
    ld d, b
    pop af
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
    ld h, d
    ld d, b
    ld d, c
    ld a, $43

jr_04c_4e61:
    ld b, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    inc l
    ld d, c
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld d, b
    ld h, d
    ld a, $f1
    ld d, h
    ld b, l
    ld b, [hl]
    ld c, a
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, e
    ld a, $40
    ld d, d
    ld d, d
    ld c, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    inc h
    ld h, d
    ld c, d
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
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec hl
    ld c, h
    ld d, c
    ld h, d
    ld c, c
    ld a, $53
    ld a, $62
    ld b, e
    ld c, c
    ld c, h
    ld c, h
    ld b, c
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld c, a
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    inc h
    ld c, e
    ld h, d
    ld b, [hl]
    ld b, b
    ld d, [hl]
    ld h, d
    ccf
    ld c, c
    ld b, [hl]
    ld d, a
    ld d, a
    ld a, $4f
    ld b, c
    pop af
    ccf
    ld c, c
    ld a, $50
    ld d, c
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    inc h
    ld h, d
    ld b, e
    ld b, [hl]
    ld c, a
    ld b, d
    ccf
    ld a, $49
    ld c, c
    ld h, d
    ccf
    ld d, d
    ld c, a
    ld d, b
    ld d, c
    ld d, b
    pop af
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
    ld h, d
    ld d, b
    ld d, c
    ld a, $43
    ld b, e
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, e
    ld d, d
    ld c, c
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld b, b
    ld b, d
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld l, b
    ld h, d
    ld b, e
    ld b, d
    ld a, $4f
    pop af
    ccf
    ld c, h
    ld c, h
    ld d, b
    ld d, c
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, h
    ld d, d
    ld a, $4f
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, e
    ld c, h
    ld b, b
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, a
    ld b, h
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, e
    ld b, [hl]
    ld b, d
    ld c, a
    ld b, b
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    pop af
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld h, $42
    ld c, c
    ld b, d
    ld d, b
    ld d, c
    ld b, [hl]
    ld a, $49
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, h
    ld c, a
    ld a, $3f
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld a, $4b
    ld b, c
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld d, d
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld a, $50
    ld h, d
    ld a, $f1
    ld d, b
    ld b, l
    ld b, [hl]
    ld b, d
    ld c, c
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld d, d
    ld d, c
    ld d, b
    pop af
    ld a, $62
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, d
    ld b, b
    ld c, a
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    pop af
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld b, l
    ld c, h
    ld c, a
    ld c, a
    ld b, [hl]
    ld b, e
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld d, d
    ld c, d
    ld c, d
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld b, b
    ld c, b
    ld h, d
    ld b, e
    ld c, h
    ld b, h
    ld h, d
    ld b, b
    ld c, h
    ld d, a
    ld b, d
    ld d, b
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    pop af
    ld c, c
    ld c, h
    ld a, $41
    ld b, d
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    jr nc, jr_04c_50ec

    ld h, e
    db $ec
    ldh a, [$96]
    ld h, $45
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld h, $45
    ld a, $4b
    ld b, b
    ld b, d
    pop af
    ld h, $45
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld h, $45
    ld a, $4b
    ld b, b
    ld b, d
    ld e, a
    ld e, a
    ld e, a
    sub a
    db $fc
    db $10
    db $ec
    ld a, [c]
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, e
    ld c, h
    ld b, [hl]
    ld b, b
    ld b, d
    ld h, d
    ld b, d
    ld b, b

jr_04c_50ec:
    ld b, l
    ld c, h
    ld b, d
    ld d, b
    pop af
    ld a, $49
    ld c, c
    ld h, d
    ld a, $4f
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld b, h
    ld b, [hl]
    ld b, h
    ld a, $4b
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    pop af
    ld b, d
    ld c, d
    ld b, d
    ld c, a
    ld b, h
    ld b, d
    ld d, b
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    daa
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    pop af
    db $ec
    ldh a, [rNR52]
    ld c, h
    ld c, c
    ld b, c
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    ld d, b
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld b, [hl]
    ld c, b
    ld b, d
    pop af
    ld sp, hl
    jr nz, jr_04c_51a3

    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld b, d
    ld d, b
    ld h, d
    jr nc, jr_04c_5184

    ld h, e
    db $ec
    ldh a, [$36]
    ld b, l
    ld c, h
    ld c, h
    ld d, c
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld [hl], $51
    ld a, $4f
    ld d, b
    pop af
    ld b, e
    ld a, $49
    ld c, c
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld d, h
    ld b, l
    ld b, d
    ld c, a
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    pop af
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d

jr_04c_5184:
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld b, b
    ld c, a
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, b
    ld a, $49
    ld h, d
    ld b, l
    ld b, [hl]
    ld d, c
    ld h, e
    pop af

jr_04c_51a3:
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld c, l
    ld b, [hl]
    ld d, c
    ld b, [hl]
    ld b, e
    ld d, d
    ld c, c
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    pop af
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, h
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld c, a
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld h, e
    pop af
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, a
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld a, $fc
    db $10
    db $ec
    ld a, [c]
    ld d, h
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    scf
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld a, $4f
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    pop af
    ld sp, hl
    nop
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld c, a
    ld b, d
    ld b, e
    ld c, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    jr nz, @+$64

    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [$f9]
    jr nz, jr_04c_52bc

    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    pop af
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, d
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld c, l
    ld c, a
    ld c, h
    ld d, c
    ld b, d
    ld b, b
    ld d, c
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld a, $3f
    ld d, b
    ld c, h
    ld c, a
    ccf
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, c
    ld a, $48
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, d
    ld c, l
    ld d, c
    ld d, b
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop

jr_04c_52bc:
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    pop af
    ld c, l
    ld d, c
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    pop af
    ld d, h
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $49
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld c, a
    ld b, d
    ld b, b
    ld b, d
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    ld h, d
    ld a, $62
    ld b, e
    ld a, $51
    ld a, $49
    db $fc
    db $10
    db $ec
    ld a, [c]
    ccf
    ld c, c
    ld c, h
    ld d, h
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, b
    ld d, d
    ld d, b
    ld c, l
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    pop af
    ld a, $4f
    ld b, d
    ld h, d
    ld a, $49
    ld c, c
    ld h, d
    ld d, b
    ld d, d
    ld d, b
    ld c, l
    ld b, d
    ld c, e
    ld b, c
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    jr nc, jr_04c_53ae

    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, c
    ld c, a
    ld a, $46
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    jr nc, jr_04c_53c8

    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, c
    ld c, a
    ld a, $46
    ld c, e
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld d, c

jr_04c_53ae:
    ld a, $4f
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, h
    ld c, c
    ld c, h
    ld d, h
    ld h, d
    ld b, e
    ld a, $46
    ld c, e
    ld d, c
    ld c, c
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d

jr_04c_53c8:
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld sp, hl
    db $10
    ld h, d
    jr nc, jr_04c_5409

    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    pop af
    ld c, l
    ld c, h
    ld d, h

jr_04c_5409:
    ld b, d
    ld c, a
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, c
    ld c, h
    ld d, d
    ccf
    ld c, c
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, b
    ld b, l
    ld a, $4b
    ld b, h
    ld b, d
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ccf
    ld b, [hl]
    ld b, h
    ld h, d
    ld b, c
    ld c, a
    ld a, $44
    ld c, h
    ld c, e
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld l, b
    pop af
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    db $fc
    db $10
    db $ec
    ld a, [c]
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    pop af
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, a
    ld c, h
    ld c, e
    ld h, d
    ld c, c
    ld d, d
    ld c, d
    ld c, l
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld a, $4b
    ld h, d
    ld b, [hl]
    ld c, a
    ld c, h
    ld c, e
    ld h, d
    ld c, c
    ld d, d
    ld c, d
    ld c, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, c
    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld b, c
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ccf
    ld d, [hl]
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, c
    pop af
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld b, d
    ld b, c
    pop af
    ld b, h
    ld c, h
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ccf
    ld d, [hl]
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld c, e
    ld h, d
    ld b, [hl]
    ld c, c
    ld c, c
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, h
    ld c, e
    pop af
    ld b, d
    ld c, e
    ld b, h
    ld d, d
    ld c, c
    ld b, e
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, e
    pop af
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, h
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld c, a
    ld b, [hl]
    ld d, b
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, e
    pop af
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, h
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $51
    ld b, d
    ld b, c
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, e
    pop af
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, e
    ld b, d
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld sp, hl
    nop
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld a, $4b
    ld b, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    pop af
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    pop af
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    pop af
    ld c, c
    ld c, h
    ld c, e
    ld b, h
    ld b, d
    ld c, a
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    jr nz, jr_04c_5646

    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld c, c
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    pop af
    ld b, e
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
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    pop af
    ld d, b
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld d, [hl]
    ld b, d
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ccf
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, c
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, h
    pop af

jr_04c_5646:
    ld d, e
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
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld c, d
    ld a, $44
    ld b, [hl]
    ld b, b
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld d, b
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld d, c
    pop af
    ld sp, hl
    db $10
    ld h, d
    jr nc, jr_04c_56a7

    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, c

FuncB4c_567e:
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld d, c
    ld c, h
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, c
    ld a, $4b
    ld b, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld b, d
    ld b, d
    ld c, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld b, e
    ld b, d

jr_04c_56a7:
    ld b, d
    ld c, c
    ld b, [hl]
    ld c, e
    ld b, h
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, h
    ld c, h
    ld c, h
    ld b, c
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    pop af
    ld b, h
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld c, d
    ld c, l
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    pop af
    ld b, h
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ccf
    ld d, d
    ld c, d
    ld c, l
    ld d, b
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld l, b
    pop af
    ld b, c
    ld b, d
    ld b, e
    ld b, d
    ld c, e
    ld d, b
    ld b, d
    ld h, d
    ld b, c
    ld c, a
    ld c, h
    ld c, l
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld bc, $f0ec
    ld sp, hl
    nop
    pop af
    ld b, e
    ld c, a
    ld b, d
    ld b, d
    ld d, a
    ld b, d
    ld d, b
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, b
    ld b, l
    ld c, h
    ld b, b
    ld c, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld d, b
    ld d, c
    ld d, d
    ld c, d
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld h, e
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld c, l
    ld b, d
    ld c, c
    ld c, c
    ld h, d
    ld c, h
    ld c, e
    pop af
    ld sp, hl
    nop
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld c, a
    ld c, h
    ld c, b
    ld b, d
    ld c, e
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld c, a
    ld d, d
    ld b, d
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld c, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, b
    ld c, h
    ld c, d
    ld c, l
    ld c, c
    ld b, d
    ld d, c
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$3a]
    ld c, h
    ld d, h
    ld h, e
    ld h, d
    ld sp, hl
    nop
    pop af
    ld b, a
    ld c, h
    ld b, [hl]
    ld c, e
    ld b, d
    ld b, c
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
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld b, l
    ld d, [hl]
    ld c, l
    ld c, e
    ld c, h
    ld d, c
    ld b, [hl]
    ld b, b
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld c, l
    ld b, d
    ld b, c
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    pop af
    ld b, l
    ld d, [hl]
    ld c, l
    ld c, e
    ld c, h
    ld d, c
    ld b, [hl]
    ld b, b
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld d, a
    ld b, d
    ld c, e
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld b, l
    ld d, d
    ld d, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld c, h
    ld d, d
    ld c, e
    ld b, c
    ld h, d
    ld d, b
    ld b, l
    ld d, d
    ld d, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    pop af
    ld c, c
    ld b, [hl]
    ld d, b
    ld d, c
    ld b, d
    ld c, e
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, e
    ld c, a
    ld c, h
    ld d, a
    ld b, d
    ld c, e
    ld h, e
    db $ec
    ldh a, [$30]
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld d, b
    ld h, e
    pop af
    ld sp, hl
    nop
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, d
    ld c, e
    ld b, l
    ld a, $4f
    ld c, d
    ld b, d
    ld b, c
    ld h, e
    pop af
    db $ec
    ldh a, [$30]
    ld b, [hl]
    ld d, b
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld sp, hl
    nop
    ld h, e
    pop af
    ld sp, $624c
    ld b, c
    ld a, $4a
    ld a, $44
    ld b, d
    ld h, e
    db $ec
    ldh a, [$2b]
    ld a, $50
    ld h, d
    ld c, e
    ld c, h
    ld h, d
    ld b, d
    ld b, e
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    pop af
    ld c, h
    ld c, e
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    pop af
    ccf
    ld c, c
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $56
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    ld h, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, [hl]
    ld c, a
    ld c, h
    ld c, e
    ld h, d
    ld a, $4b
    ld b, c
    db $fc
    db $10
    db $ec
    ld a, [c]
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld d, e
    ld d, d
    ld c, c
    ld c, e
    ld b, d
    ld c, a
    ld a, $3f
    ld c, c
    ld b, d
    ld e, a
    db $ec
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
    pop af
    ld b, l
    ld a, $4d
    ld c, l
    ld b, d
    ld c, e
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    pop af
    ld b, e
    ld a, $49
    ld c, c
    ld h, d
    ld a, $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld a, $49
    ld c, a
    ld b, d
    ld a, $41
    ld d, [hl]
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
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ccf
    ld b, d
    ld b, b
    ld c, h
    ld c, d
    ld b, d
    ld d, b
    pop af
    ld c, d
    ld c, h
    ld c, a
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, e
    ld b, e
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld c, a
    ld b, d
    ld d, e
    ld b, [hl]
    ld d, e
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld b, [hl]
    ld d, c
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a
    pop af
    ld c, a
    ld b, d
    ld a, $40
    ld b, l
    ld h, d
    ld sp, hl
    nop
    ld h, e
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld a, $46
    ld c, a
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld d, [hl]
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld a, $4f
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld b, l
    ld a, $48
    ld b, d
    ld d, b
    pop af
    ld c, h
    ld b, e
    ld b, e
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, b
    ld a, $4b
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    pop af
    ld d, h
    ld b, [hl]
    ld d, c
    ld b, l
    ld h, d
    ld b, d
    ld a, $50
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    pop af
    ld c, [hl]
    ld d, d
    ld b, [hl]
    ld b, b
    ld c, b
    ld c, c
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    pop af
    ld c, c
    ld d, d
    ld c, a
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, e
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld sp, hl
    nop
    pop af
    ld b, c
    ld c, h
    ld b, c
    ld b, h
    ld b, d
    ld d, b
    ld h, d
    ld b, d
    ld a, $50
    ld b, [hl]
    ld c, c
    ld d, [hl]
    ld h, e
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    pop af
    ld a, $43
    ld b, e
    ld b, d
    ld b, b
    ld d, c
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, a
    ld a, $56
    ld b, d
    ld c, a
    pop af
    ld b, [hl]
    ld d, b
    ld c, e
    ld h, a
    ld h, d
    ld b, l
    ld b, d
    ld a, $4f
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld b, d
    ld c, e
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    ld h, d
    ld a, $50
    ld c, c
    ld b, d
    ld b, d
    ld c, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, l
    ld a, $4f
    ld a, $49
    ld d, [hl]
    ld d, a
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld b, d
    ld c, c
    ld d, [hl]
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld d, a
    ld b, d
    ld c, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, h
    ld b, d
    ld d, c
    ld d, b
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, b
    ld a, $4b
    ld h, a
    ld h, d
    ld b, h
    ld b, d
    ld d, c
    ld h, d
    ld b, d
    ld d, e
    ld b, d
    ld c, e
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $4b
    ld h, a
    pop af
    ld b, b
    ld c, h
    ld d, d
    ld c, e
    ld d, c
    ld b, d
    ld c, a
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ccf
    ld c, c
    ld c, h
    ld d, h
    ld d, b
    pop af
    ccf
    ld a, $40
    ld c, b
    ld h, d
    ld sp, hl
    db $10
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, c
    ld b, [hl]
    ld d, b
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    ld h, e
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, e
    ld b, c
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld d, b
    ld d, c
    ld c, h
    ld c, l
    ld c, l
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld c, c
    ld c, c
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, h
    ld c, h
    ld c, e
    ld b, d
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld d, h
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld d, d
    ld c, l
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld c, a
    ld b, d
    ld d, c
    ld d, d
    ld c, a
    ld c, e
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, e
    ld c, h
    ld c, a
    ld c, d
    ld a, $49
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld l, b
    pop af
    inc l
    ld c, a
    ld c, h
    ld c, e
    ld b, [hl]
    ld d, a
    ld b, d
    ld h, d
    ld d, h
    ld b, d
    ld a, $4f
    ld d, b
    ld h, d
    ld c, h
    ld b, e
    ld b, e
    ld h, e
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld d, h
    ld a, $49
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    pop af
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    ld h, d
    ld b, c
    ld b, [hl]
    ld d, b
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    ld h, e
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld b, d
    ld d, e
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, c
    ld b, d
    ld a, $53
    ld b, d
    ld d, b
    ld e, [hl]
    pop af
    ld c, c
    ld a, $52
    ld b, h
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    db $10
    pop af
    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, d
    ld b, b
    ld b, d
    ld d, b
    ld h, e
    db $ec
    ldh a, [$33]
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld b, d
    ld b, c
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld c, c
    ld c, h
    ld d, b
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    dec hl
    inc sp
    ld h, e
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, b
    ld d, c
    ld c, a
    ld c, h
    ld c, e
    ld b, h
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    pop af
    ld d, c
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld sp, hl
    db $10
    ld h, d
    dec hl
    inc sp
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    ld h, d
    ld sp, hl
    nop
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld l, b
    ld h, d
    dec hl
    inc sp
    pop af
    ld b, c
    ld b, d
    ld b, b
    ld c, a
    ld b, d
    ld a, $50
    ld b, d
    ld d, b
    ld h, d
    ccf
    ld d, [hl]
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld c, l
    ld c, h
    ld b, [hl]
    ld d, b
    ld c, h
    ld c, e
    ld h, e
    db $fc
    db $10
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, b
    ld c, h
    ld c, c
    ld c, c
    ld a, $4d
    ld d, b
    ld b, d
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld c, b
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
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, d
    ld a, $48
    pop af
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld b, c
    ld b, [hl]
    ld d, b
    ld a, $4d
    ld c, l
    ld b, d
    ld a, $4f
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    dec hl
    inc sp
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, e
    ld a, $46
    ld c, e
    ld d, c
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    pop af
    ld b, e
    ld b, [hl]
    ld c, e
    ld b, [hl]
    ld d, b
    ld b, l
    ld b, d
    ld b, c
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, e
    ld a, $49
    ld c, c
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, l
    ld b, [hl]
    ld b, d
    ld b, b
    ld b, d
    ld d, b
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, [hl]
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    pop af
    ld c, h
    ld b, e
    ld h, d
    dec hl
    inc sp
    ld h, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, e
    ld a, $46
    ld c, e
    ld d, c
    ld d, b
    ld h, e
    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    pop af
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, h
    ld b, [hl]
    ld c, l
    ld b, d
    ld b, c
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    ld h, e
    ld a, [$f0f7]
    or $62
    ld c, b
    ld c, e
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    pop af
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld sp, hl
    nop
    ld h, e
    ld a, [$f0f7]
    or $62
    ccf
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    ld h, e
    ld a, [$f0f7]
    or $62
    ld c, b
    ld c, e
    ld c, h
    ld b, b
    ld c, b
    ld d, b
    pop af
    ld c, h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    ld h, e
    ld a, [$f0f7]
    scf
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld b, l
    ld a, $50
    pop af
    ld b, e
    ld c, c
    ld b, d
    ld b, c
    ld h, e
    ld a, [$f0f7]
    scf
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    pop af
    ld b, l
    ld a, $50
    ld h, d
    ld b, e
    ld c, c
    ld b, d
    ld b, c
    ld h, e
    ld a, [$f0f7]
    inc h
    ld c, c
    ld c, c
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
    pop af
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld b, e
    ld c, c
    ld b, d
    ld b, c
    ld h, e
    ld a, [$f0f7]
    ld h, $3e
    ld c, e
    ld h, a
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    pop af
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    ld a, [$f0f7]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
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
    pop af
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld a, $51
    ld h, d
    ld b, b
    ld a, $4b
    ld h, d
    ccf
    ld b, d
    ld a, [$f2f7]
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    pop af
    ld a, [$f0f7]
    ld h, $3e
    ld c, e
    ld h, a
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld d, c
    ld b, d
    ld c, d
    ld d, b
    pop af
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    ld a, [$f0f7]
    ld h, $3e
    ld c, e
    ld h, a
    ld h, d
    ld c, a
    ld d, d
    ld c, e
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld c, d
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    ld a, [$f0f7]
    db $ed
    ld a, [hl-]
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
    ld sp, hl
    nop
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld b, l
    ld c, h
    ld c, h
    ld d, b
    ld b, d
    ld h, d
    ld a, $62
    ld c, d
    ld c, h
    ld d, e
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, b
    ld a, $50
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_5ee1

    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, b
    ld c, l
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_5f06

    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, c
    ld a, $4b
    ld b, b
    ld b, d
    ld d, b
    pop af

jr_04c_5ee1:
    ld sp, hl
    db $10
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_5f2c

    ld h, e
    pop af
    db $ec
    ldh a, [rNR51]
    ld d, d
    ld d, c
    ld h, d
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h

jr_04c_5f06:
    ld d, c
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    pop af
    ld sp, hl
    nop
    ld h, e
    ld a, [$f0f7]
    dec h
    ld d, d
    ld d, c
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
    pop af
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d

jr_04c_5f2c:
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$f2f7]
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    pop af
    ld a, [$f0f7]
    ld h, $3e
    ld c, e
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld a, $f1
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld a, [$f2f7]
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    pop af
    ld a, [$f0f7]
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld d, c
    ld c, h
    db $fc
    jr @-$12

    ld a, [c]
    ld sp, hl
    jr nz, jr_04c_5fe6

    pop af
    db $ec
    ldh a, [$f9]

jr_04c_5f87:
    nop
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    jr jr_04c_5f87

    ld a, [c]
    ld sp, hl
    jr nz, jr_04c_6001

    ld b, h
    ld a, $4b
    ld b, h
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl

jr_04c_5fa9:
    nop
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld sp, hl
    db $10
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    jr jr_04c_5fa9

    ld a, [c]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    pop af

jr_04c_5fd5:
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, e

jr_04c_5fe6:
    db $fc
    jr jr_04c_5fd5

    ld a, [c]
    db $ed
    ld sp, hl
    nop
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_04c_6063

    db $ec

jr_04c_6001:
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld b, [hl]
    ld c, d
    ld b, [hl]
    ld b, c
    ld c, c

jr_04c_600b:
    ld d, [hl]
    pop af
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    db $fc
    jr jr_04c_600b

    ld a, [c]
    ld sp, hl
    nop
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld d, b
    pop af
    ld a, $51
    ld h, d
    ld sp, hl
    jr nz, jr_04c_6093

    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld a, $4b

jr_04c_603c:
    ld b, h
    pop af
    ld b, d
    ld a, $51
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    db $fc
    jr jr_04c_603c

    ld a, [c]
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d

jr_04c_6063:
    pop af
    ld sp, hl
    jr nz, jr_04c_60ca

    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld sp, hl
    nop
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    pop af
    ld c, e

jr_04c_6076:
    ld b, [hl]
    ccf
    ccf
    ld c, c
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    db $fc
    jr jr_04c_6076

    ld a, [c]
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, a
    ld c, h

jr_04c_6093:
    ld d, h
    ld c, e
    ld h, d
    ld a, $51
    pop af
    ld sp, hl
    jr nz, jr_04c_60ff

    db $ec
    ldh a, [$37]
    ld b, l
    ld b, d
    ld h, d
    ld c, d
    ld c, h
    ld c, e
    ld d, b

jr_04c_60a6:
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    pop af
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    ld h, d
    ld b, d
    ld a, $51
    ld b, [hl]
    ld c, e
    ld b, h
    db $fc
    jr jr_04c_60a6

    ld a, [c]
    ld d, c
    ld b, l

jr_04c_60bd:
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, d
    ld b, l
    ld a, $4d
    ld c, l
    ld b, [hl]

jr_04c_60ca:
    ld c, c
    ld d, [hl]
    ld h, e
    pop af
    db $fc
    jr jr_04c_60bd

    ld a, [c]
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
    ld h, d
    ld d, b
    ld d, c
    ld a, $4f
    ld d, c
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld c, c
    ld b, [hl]
    ld c, b
    ld b, d
    ld h, d
    ld sp, hl
    jr nz, jr_04c_6153

    db $ec
    ldh a, [$37]
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
    pop af

jr_04c_60ff:
    ld c, e
    ld b, [hl]
    ccf
    ccf
    ld c, c
    ld b, d
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    ld d, c
    ld c, a
    ld b, d
    ld a, $51
    ld h, e
    db $fc
    jr jr_04c_60ff

    ld a, [c]
    scf
    ld b, l
    ld b, d
    ld d, [hl]
    ld h, d
    ld b, e
    ld c, a
    ld c, h
    ld d, h
    ld c, e
    ld h, d
    ld a, $51
    pop af
    ld sp, hl
    jr nz, jr_04c_6188

    db $ec
    ldh a, [$ed]
    inc h
    ld h, d
    ld d, e
    ld b, d
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld sp, hl
    nop
    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    inc h
    ld h, d
    ld d, e
    ld b, d
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h

jr_04c_6153:
    ld b, l
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    nop
    ld d, b
    ld h, d
    ld b, h
    ld a, $4b
    ld b, h
    ld h, e
    pop af
    db $ec
    ldh a, [rNR50]
    ld h, d
    ld d, e
    ld b, d
    ld b, [hl]
    ld c, c
    ld h, d
    ld c, h
    ld b, e
    ld h, d
    ld c, c
    ld b, [hl]
    ld b, h
    ld b, l
    ld d, c
    pop af
    ld b, b
    ld c, h
    ld d, e
    ld b, d
    ld c, a
    ld d, b
    ld h, d
    ld d, c

jr_04c_6188:
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld c, d
    ld c, h
    ld c, e
    ld d, b
    ld d, c
    ld b, d
    ld c, a
    ld d, b
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    pop af
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    ld h, d
    ld d, c
    ld c, h
    ld h, d
    ld b, e
    ld c, c
    ld d, [hl]
    ld h, d
    ld b, l
    ld b, [hl]
    ld b, h
    ld b, l
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_61f7

    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld b, b
    ld a, $49
    ld c, c
    ld h, d
    ld b, e
    ld c, h
    ld c, a
    ld h, d
    ld b, l
    ld b, d
    ld c, c
    ld c, l
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_622a

jr_04c_61f7:
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld a, $51
    ld d, c
    ld a, $40
    ld c, b
    ld h, d
    ld a, $43
    ld d, c
    ld b, d
    ld c, a
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, e
    ld c, h
    ld b, b
    ld d, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld b, [hl]
    ld d, c
    ld d, b
    pop af
    ld c, l
    ld c, h
    ld d, h
    ld b, d
    ld c, a
    ld h, e

jr_04c_622a:
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_6272

    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld a, $62
    ld b, b
    ld d, d
    ld c, a
    ld d, b
    ld b, d
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_629f

    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop

jr_04c_6272:
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld d, d
    ld b, b
    ld c, b
    ld h, d
    ld b, [hl]
    ld c, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, d
    ld d, e
    ld b, d
    ld c, a
    ld d, [hl]
    ld d, c
    ld b, l
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d

jr_04c_629f:
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_62db

    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, l
    ld d, d
    ld d, c
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld sp, hl
    db $10
    ld l, b
    pop af
    ld c, d
    ld c, h
    ld d, d
    ld d, c
    ld b, l
    ld h, e
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h

jr_04c_62db:
    ld b, l
    ld h, d
    jr nc, jr_04c_6312

    ld h, e
    pop af
    db $ec
    ldh a, [$ed]
    ld sp, hl
    nop
    ld h, d
    ld d, c
    ld c, a
    ld b, [hl]
    ld b, d
    ld d, b
    pop af
    ld d, c
    ld c, h
    ld h, d
    ld d, b
    ld b, [hl]
    ld c, e
    ld b, h
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    cpl
    ld b, [hl]
    ld b, e
    ld b, d
    ld [hl], $4c
    ld c, e
    ld b, h
    ld h, e
    pop af
    db $fc
    db $10
    db $ec
    ld a, [c]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld c, e
    ld c, h
    ld d, c
    ld h, d

jr_04c_6312:
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, jr_04c_634e

    ld h, e
    pop af
    db $ec
    ldh a, [$31]
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
    ld b, l
    ld a, $51
    pop af
    ld b, b
    ld a, $4b
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld b, b
    ld c, h
    ld c, d
    ld c, d
    ld a, $4b
    ld b, c
    ld d, b
    ld h, e
    ld a, [$f0f7]
    ld sp, hl
    nop
    ld h, d
    ld b, c
    ld c, h
    ld b, d
    ld d, b
    ld c, e
    ld h, a

jr_04c_634e:
    pop af
    ld b, l
    ld a, $53
    ld b, d
    ld h, d
    ld a, $4b
    ld d, [hl]
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    ld h, d
    ld d, c
    ld c, h
    ld a, [$f2f7]
    ld d, d
    ld d, b
    ld b, d
    ld h, d
    ld b, [hl]
    ld c, e
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    pop af
    ld a, [$f0f7]
    dec h
    ld d, d
    ld d, c
    ld h, d
    ld d, c
    ld b, l
    ld b, [hl]
    ld d, b
    ld h, d
    ld d, b
    ld c, b
    ld b, [hl]
    ld c, c
    ld c, c
    pop af
    ld b, b
    ld a, $4b
    ld c, e
    ld c, h
    ld d, c
    ld h, d
    ccf
    ld b, d
    ld h, d
    ld d, d
    ld d, b
    ld b, d
    ld b, c
    ld a, [$f2f7]
    ld b, [hl]
    ld c, e
    ld h, d
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, e
    pop af
    ld a, [$f0f7]
    ld sp, $514c
    ld h, d
    ld b, d
    ld c, e
    ld c, h
    ld d, d
    ld b, h
    ld b, l
    ld h, d
    jr nc, @+$35

    ld h, e
    pop af
    ld a, [$f0f7]
    ld a, [hl+]
    ld b, [hl]
    ld d, e
    ld b, d
    ld h, d
    ld d, d
    ld c, l
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    ccf
    ld a, $51
    ld d, c
    ld c, c
    ld b, d
    ld h, h
    ldh a, [$f9]
    nop
    ld d, b
    ld h, d
    ld b, h
    ld b, [hl]
    ld d, e
    ld b, d
    ld d, b
    pop af
    ld d, d
    ld c, l
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
    ld h, e
    db $ec
    ld a, [$f0f7]
    or $62
    ld d, c
    ld a, $48
    ld b, d
    ld d, b
    ld h, d
    ld c, h
    ld d, d
    ld d, c
    pop af
    ld d, c
    ld b, l
    ld b, d
    ld h, d
    dec h
    ld b, d
    ld a, $50
    ld d, c
    scf
    ld a, $46
    ld c, c
    ld h, e
    db $ec
    ldh a, [$33]
    ld c, h
    ld b, [hl]
    ld c, e
    ld d, c
    ld d, b
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    pop af
    dec h
    ld b, d
    ld a, $50
    ld d, c
    scf
    ld a, $46
    ld c, c
    ld h, d
    ld a, $51
    ld h, d
    ld d, c
    ld b, l
    ld b, d
    db $fc
    db $10
    db $ec
    ld a, [c]
    ld b, d
    ld c, e
    ld b, d
    ld c, d
    ld d, [hl]
    ld h, e
    pop af
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, l
    ld a, $50
    ld h, d
    ccf
    ld b, d
    ld b, d
    ld c, e
    pop af
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld h, d
    ccf
    ld b, d
    ld b, e
    ld c, h
    ld c, a
    ld b, d
    ld h, e
    db $ec
    ldh a, [$f9]
    nop
    ld h, d
    ld b, l
    ld a, $50
    ld c, e
    ld h, a
    pop af
    ccf
    ld b, d
    ld b, d
    ld c, e
    ld h, d
    ld d, [hl]
    ld c, h
    ld d, d
    ld c, a
    ld h, d
    ld c, l
    ld a, $49
    ld h, d
    ld d, [hl]
    ld b, d
    ld d, c
    ld h, e
    db $ec
    ldh a, [$ed]
    jr z, jr_04c_64a2

    jr z, @+$28

    jr c, jr_04c_64a2

    inc l
    add hl, sp
    jr z, jr_04c_64d1

    daa
    inc l
    dec [hl]
    jr z, jr_04c_649a

    scf
    ld [hl-], a
    dec [hl]
    ldh a, [$ed]
    ld [hl], $26
    jr z, @+$33

    inc h
    dec [hl]
    inc l
    ld [hl-], a
    pop af
    or [hl]
    ld h, d
    ld a, [hl+]
    inc h
    jr nc, @+$2a

    ld h, d
    daa
    jr z, jr_04c_64c2

    inc l
    ld a, [hl+]
    ld sp, $edf0
    ld h, $2b
    inc h
    dec [hl]
    inc h
    ld h, $37
    jr z, jr_04c_64cf

jr_04c_649a:
    pop af
    or [hl]
    ld h, d
    jr nc, jr_04c_64d1

    ld sp, $3736

jr_04c_64a2:
    jr z, jr_04c_64d9

    ld h, d
    daa
    jr z, jr_04c_64de

    inc l
    ld a, [hl+]
    ld sp, $edf0
    jr nc, @+$3a

    ld [hl], $2c
    ld h, $62
    ld h, $32
    jr nc, @+$35

    ld [hl-], a
    ld [hl], $28
    dec [hl]
    ldh a, [$ed]
    scf
    ld [hl-], a
    ld [hl], $28
    ld h, d

jr_04c_64c2:
    ld [hl], $37
    inc h
    add hl, hl
    add hl, hl
    ldh a, [$ed]
    inc sp
    dec [hl]
    ld [hl-], a
    ld a, [hl+]
    dec [hl]
    inc h

jr_04c_64cf:
    jr nc, @+$32

jr_04c_64d1:
    jr z, jr_04c_6508

    ld [hl], $f0
    db $ed
    ld a, [hl+]
    dec [hl]
    inc h

jr_04c_64d9:
    inc sp
    dec hl
    inc l
    ld h, $62

jr_04c_64de:
    daa
    jr z, jr_04c_6517

    inc l
    ld a, [hl+]
    ld sp, $3528
    ld [hl], $f0
    db $ed
    jr nc, jr_04c_6523

    ld [hl], $2c
    ld h, $62
    ld h, $32
    jr nc, jr_04c_6526

    ld [hl-], a
    ld [hl], $28
    dec [hl]
    pop af
    inc h
    ld [hl], $36
    inc l
    ld [hl], $37
    inc h
    ld sp, $3637
    ldh a, [$ed]
    ld a, [hl+]
    inc h
    jr nc, jr_04c_6530

jr_04c_6508:
    ld h, d
    daa
    jr z, @+$38

    inc l
    ld a, [hl+]
    ld sp, $24f1
    ld [hl], $36
    inc l
    ld [hl], $37
    inc h

jr_04c_6517:
    ld sp, $3637
    ldh a, [$ed]
    jr z, @+$2e

    daa

jr_04c_651f:
    ld [hl-], a
    ld [hl], $62
    inc l

jr_04c_6523:
    ld sp, $2837

jr_04c_6526:
    dec [hl]
    inc h
    ld h, $37
    inc l
    add hl, sp
    jr z, jr_04c_651f

    ld [hl], $37

jr_04c_6530:
    inc h
    add hl, hl
    add hl, hl
    ldh a, [$ed]
    cpl
    ld [hl-], a
    ld h, $24
    cpl
    inc l
    dec a
    inc h
    scf
    inc l
    ld [hl-], a
    ld sp, $edf0
    inc sp
    dec [hl]
    ld [hl-], a
    daa
    jr c, jr_04c_656f

    jr z, jr_04c_6580

    ld [hl], $f0
    db $ed
    inc [hl]
    inc h
    ld h, d
    jr nc, jr_04c_6577

    ld sp, $2a24
    jr z, jr_04c_658d

    ld [hl], $f0
    db $ed
    jr nc, jr_04c_6581

    dec [hl]
    ld l, $28
    scf
    inc l
    ld sp, $f02a
    db $ed
    jr nc, jr_04c_658c

    ld sp, $2438
    cpl
    pop af
    scf
    dec [hl]

jr_04c_656f:
    inc h
    ld sp, $2f36
    inc h
    scf
    inc l
    ld [hl-], a

jr_04c_6577:
    ld sp, $edf0
    ld [hl], $33
    jr z, @+$28

    inc l
    inc h

jr_04c_6580:
    cpl

jr_04c_6581:
    ld h, d
    scf
    dec hl
    inc h
    ld sp, $362e
    ldh a, [$ed]
    jr z, jr_04c_65bd

jr_04c_658c:
    inc l

jr_04c_658d:
    dec sp
    ld h, d
    ld [hl], $37
    inc h
    add hl, hl
    add hl, hl
    ldh a, [$ed]
    inc h
    dec [hl]
    scf
    ld a, [hl-]
    ld [hl-], a
    dec [hl]
    ld l, $f0
    db $ed
    scf
    jr z, jr_04c_65c8

    dec hl
    ld sp, $262c
    inc h
    cpl
    ld h, d
    ld [hl], $38
    inc sp
    inc sp
    ld [hl-], a
    dec [hl]
    scf
    ldh a, [$ed]
    scf
    jr z, jr_04c_65eb

    scf
    jr z, jr_04c_65ed

    ld [hl], $f0
    db $ed
    jr c, jr_04c_661c

jr_04c_65bd:
    ld [hl], $5f
    cpl
    inc l
    inc h
    inc l
    ld [hl], $32
    ld sp, $edf0

jr_04c_65c8:
    inc h
    ld [hl], $36
    inc l
    ld [hl], $37
    inc h
    ld sp, $f137
    inc sp
    dec [hl]
    ld [hl-], a
    daa
    jr c, @+$28

    jr z, jr_04c_660f

    ldh a, [$ed]
    inc sp
    dec [hl]
    ld [hl-], a
    daa
    jr c, jr_04c_6608

jr_04c_65e2:
    jr z, jr_04c_6619

    ld [hl], $f0
    db $ed
    jr z, jr_04c_6624

    jr z, jr_04c_6611

jr_04c_65eb:
    jr c, jr_04c_6624

jr_04c_65ed:
    inc l
    add hl, sp
    jr z, jr_04c_65e2

    inc sp
    dec [hl]
    ld [hl-], a
    daa
    jr c, jr_04c_661d

    jr z, jr_04c_662e

    ldh a, [$ed]
    inc sp
    dec [hl]
    jr z, jr_04c_6635

    inc l
    daa
    jr z, jr_04c_6634

    scf
    ldh a, [$f0]
    db $ed
    inc a

jr_04c_6608:
    jr c, jr_04c_6637

    inc l
    pop af
    ld h, d
    ld h, d
    dec hl

jr_04c_660f:
    ld [hl-], a
    dec [hl]

jr_04c_6611:
    inc l
    inc l
    ldh a, [$ed]
    jr z, jr_04c_6648

    inc l
    dec sp

jr_04c_6619:
    pop af
    pop af
    scf

jr_04c_661c:
    ld [hl-], a

jr_04c_661d:
    ld [hl], $28
    pop af
    pop af
    inc a
    jr c, jr_04c_6651

jr_04c_6624:
    inc l
    pop af
    ld h, d
    dec hl
    ld [hl-], a
    dec [hl]
    inc l
    inc l
    ldh a, [$ed]

jr_04c_662e:
    inc h
    ld l, $2c
    dec [hl]
    inc h
    pop af

jr_04c_6634:
    ld h, d

jr_04c_6635:
    ld h, d
    scf

jr_04c_6637:
    ld [hl-], a
    dec [hl]
    inc l
    inc a
    inc h
    jr nc, jr_04c_6662

    ldh a, [$ed]
    ld l, $32
    inc l
    ld h, $2b
    inc l
    pop af
    ld h, d

jr_04c_6648:
    ld h, d
    ld [hl], $38
    ld a, [hl+]
    inc l
    inc a
    inc h
    jr nc, @+$26

jr_04c_6651:
    ldh a, [$ed]
    ldh a, [$ed]
    ld a, [hl+]
    inc h
    ld [hl-], a
    pop af
    ld h, d
    ld h, d
    jr nc, jr_04c_6681

    scf
    ld [hl], $38
    jr nc, jr_04c_6694

jr_04c_6662:
    scf
    ld [hl-], a
    pop af
    jr c, jr_04c_6697

    jr z, jr_04c_66a6

    ld [hl-], a
    pop af
    pop af
    dec hl
    inc l
    ld h, e
    ld [hl], $33
    jr z, jr_04c_669b

    daa
    ldh a, [$ed]
    ld a, [hl-]
    inc h
    ld sp, $2837
    ld sp, $383c
    pop af
    pop af
    inc a

jr_04c_6681:
    jr c, jr_04c_66b1

    inc h
    inc sp
    inc l
    pop af
    pop af
    ld [hl-], a
    cpl
    daa
    sbc e
    ld [hl-], a
    ld sp, $3628
    pop af
    pop af
    scf
    inc h

jr_04c_6694:
    ld h, $26
    dec hl

jr_04c_6697:
    inc h
    ld sp, $f1f1

jr_04c_669b:
    ld [hl], $2c
    ld sp, $edf0
    inc h
    ld [hl], $27
    sbc e
    dec h
    inc h

jr_04c_66a6:
    scf
    pop af
    pop af
    ld l, $24
    dec a
    jr c, jr_04c_66dc

    inc l
    pop af
    ld h, d

jr_04c_66b1:
    ld l, $2c
    ld l, $38
    scf
    inc h
    ld sp, $f02c
    db $ed
    dec l
    inc l
    ld sp, $f1f1
    jr c, jr_04c_66f3

    ld l, $f1
    pop af
    dec hl
    inc l
    ld [hl], $24
    ld sp, $f028
    db $ed
    ldh a, [$ed]
    dec l
    inc l
    jr nc, jr_04c_6735

    ld h, $38
    dec [hl]
    dec [hl]
    inc a
    pop af
    pop af
    inc a
    ld [hl-], a

jr_04c_66dc:
    scf
    inc h
    ld h, d
    ld a, [hl-]

jr_04c_66e0:
    inc h
    daa
    inc h
    ldh a, [$ed]
    add hl, hl
    dec [hl]
    inc h
    ld sp, $622e
    dec hl
    ld [hl-], a
    jr nc, jr_04c_66e0

    ld h, d
    and b
    jr c, jr_04c_6752

jr_04c_66f3:
    ld [hl], $5f
    and c
    pop af
    inc a
    ld [hl-], a
    scf
    inc h
    ld h, d
    ld a, [hl-]
    inc h
    daa
    inc h
    pop af
    and b
    jr c, jr_04c_6763

    ld l, $5f
    and c
    ldh a, [$ed]
    scf
    ld [hl-], a
    ld sp, $623c
    dec h
    ld [hl-], a
    jr c, jr_04c_6747

    ld sp, $f128
    ld h, d
    and b
    jr c, jr_04c_6778

    ld l, $5f
    and c
    pop af
    jr nc, jr_04c_674b

    ld l, $28
    ld h, d
    jr nc, jr_04c_674a

    dec hl
    inc h
    cpl
    jr z, @-$0d

    and b
    jr c, @+$61

    ld [hl], $5f
    and c
    ldh a, [$ed]
    ld [hl], $38
    ld [hl], $24

jr_04c_6735:
    ld sp, $62f1
    dec h
    ld [hl-], a
    ld [hl], $2b
    ld l, $32
    add hl, hl
    add hl, hl
    pop af
    ld h, d
    and b
    jr c, jr_04c_67a4

    ld [hl], $5f

jr_04c_6747:
    and c
    pop af
    pop af

jr_04c_674a:
    dec l

jr_04c_674b:
    inc l
    jr nc, jr_04c_67b0

    ld h, $38
    dec [hl]
    dec [hl]

jr_04c_6752:
    inc a
    pop af
    and b
    jr c, @+$61

    ld [hl], $5f
    and c
    pop af
    pop af
    daa
    inc h
    add hl, sp
    inc l
    daa
    pop af
    ld h, d

jr_04c_6763:
    dec h
    jr c, jr_04c_679b

    scf
    ld [hl-], a
    ld sp, $a0f1
    jr c, @+$61

    ld l, $5f
    and c
    ldh a, [$ed]
    inc sp
    dec hl
    ld [hl-], a
    ld [hl], $33
    dec hl

jr_04c_6778:
    ld [hl-], a
    dec [hl]
    ld [hl], $f0
    db $ed
    jr z, jr_04c_67ab

    daa
    ld [hl-], a
    ld [hl], $9c
    dec l
    inc h
    inc sp
    inc h
    ld sp, $f1f1
    ld [hl], $24
    scf
    ld [hl-], a
    ld [hl], $2b
    inc l
    pop af
    ld h, d
    dec hl
    ld [hl-], a
    ld sp, $2427
    pop af
    scf
    inc h

jr_04c_679b:
    ld l, $24
    pop af
    ld h, d
    inc a
    inc h
    jr nc, jr_04c_67c7

    ld a, [hl+]

jr_04c_67a4:
    jr c, @+$28

    dec hl
    inc l
    pop af
    ld h, $35

jr_04c_67ab:
    inc a
    ld [hl], $37
    inc h
    cpl

jr_04c_67b0:
    pop af
    pop af
    daa
    inc a
    ld sp, $3024
    inc l
    ld h, $36
    ldh a, [$ed]
    ldh a, [$ed]
    ld sp, $3224
    ld l, $2c
    pop af
    ld h, d
    ld h, d
    ld [hl-], a

jr_04c_67c7:
    inc l
    ld [hl], $2b
    inc l
    ldh a, [$ed]
    scf
    jr z, jr_04c_6805

    jr c, jr_04c_67fd

    inc l
    ld l, $32
    pop af
    ld h, d
    ld h, d
    dec hl
    inc h
    ld sp, $3a24
    inc h
    pop af
    ld l, $28
    ld sp, $2c2d
    dec [hl]
    ld [hl-], a
    pop af
    ld h, d
    ld l, $24
    ld sp, $f132
    dec hl
    inc l
    dec [hl]
    ld [hl-], a
    ld [hl], $2b
    inc l
    pop af
    ld h, d
    ld [hl], $24
    scf
    ld [hl-], a
    pop af
    dec hl
    inc l

jr_04c_67fd:
    daa
    jr z, @+$30

    inc l
    pop af
    ld h, d
    ld h, d
    inc a

jr_04c_6805:
    ld [hl-], a
    ld sp, $3c28
    inc h
    jr nc, @+$26

    ldh a, [$ed]
    ld [hl], $28
    inc l
    inc l
    ld h, $2b
    inc l
    pop af
    ld h, d
    ld h, d
    jr nc, @+$34

    dec [hl]
    inc l
    jr c, jr_04c_6844

    dec hl
    inc l
    pop af
    ld l, $24
    ld sp, $62f1
    inc l
    ld l, $28
    daa
    inc h
    pop af
    scf
    jr z, jr_04c_6864

    jr c, jr_04c_686d

    ld [hl-], a
    pop af
    ld h, d
    ld [hl], $24
    ld l, $38
    jr nc, jr_04c_685e

    pop af
    inc a
    inc h
    ld [hl], $38
    ld [hl-], a
    pop af
    ld h, d
    ld h, d
    dec hl

jr_04c_6844:
    inc l
    dec [hl]
    ld [hl-], a
    inc l
    pop af
    ld l, $28
    ld sp, $2c9c
    ld h, $2b
    inc l
    pop af
    ld h, d
    jr nc, jr_04c_6881

    inc a
    inc h
    jr nc, @+$34

    scf
    ld [hl-], a
    ldh a, [$30]
    inc l

jr_04c_685e:
    scf
    ld [hl-], a
    pop af
    ld h, d
    ld h, d
    inc a

jr_04c_6864:
    inc h
    jr nc, @+$26

    ld a, [hl+]
    inc l
    ld [hl], $2b
    inc l
    pop af

jr_04c_686d:
    dec l
    inc l
    dec [hl]
    ld [hl-], a
    pop af
    ld h, d
    ld l, $2c
    jr nc, jr_04c_68af

    dec [hl]
    inc h
    pop af
    jr nc, jr_04c_68a8

    ld a, [hl-]
    inc h
    ld l, $32
    pop af

jr_04c_6881:
    ld h, d
    scf
    ld [hl-], a
    ld l, $38
    daa
    inc h
    pop af
    inc a
    jr c, jr_04c_68ba

    inc l
    pop af
    ld h, d
    ld h, d
    ld sp, $3524
    inc h
    pop af
    dec hl
    inc l
    dec [hl]
    ld [hl-], a
    ld l, $2c
    pop af
    ld h, d
    jr nc, jr_04c_68d7

    dec [hl]
    inc h
    ld l, $32
    ld [hl], $2b
    inc l
    ldh a, [$ed]

jr_04c_68a8:
    inc sp
    inc h
    jr c, jr_04c_68db

    pop af
    ld h, d
    ld h, d

jr_04c_68af:
    dec hl
    inc h
    ld sp, $2827
    cpl
    jr nc, jr_04c_68db

    ld sp, $edf0

jr_04c_68ba:
    dec l
    jr c, @+$33

    pop af
    ld h, d
    ld h, d
    jr nc, @+$2e

    inc a
    inc h
    jr nc, jr_04c_68f8

    scf
    ld [hl-], a
    ldh a, [$ed]
    dec hl
    inc l
    scf
    ld [hl-], a
    ld [hl], $2b
    inc l
    pop af
    ld h, d
    ld h, d
    ld [hl], $38
    inc l

jr_04c_68d7:
    ld sp, $3832
    pop af

jr_04c_68db:
    ld l, $28
    inc l
    dec l
    inc l
    pop af
    ld h, d
    dec hl

jr_04c_68e3:
    ld [hl-], a
    ld sp, $2427
    ldh a, [$ed]
    inc a
    jr c, @+$30

    inc l
    ld sp, $2532
    jr c, jr_04c_68e3

    ld h, d
    ld h, d
    ld h, $2b
    inc l
    daa

jr_04c_68f8:
    inc h
    ldh a, [$ed]
    inc a
    inc h
    ld [hl], $38
    dec hl
    inc l
    dec [hl]
    ld [hl-], a
    pop af
    ld h, d
    ld h, d
    add hl, hl
    jr c, jr_04c_6937

    jr c, jr_04c_6941

    dec hl
    inc l
    jr nc, jr_04c_6933

    ldh a, [$ed]
    or l
    ld [bc], a
    nop
    nop
    nop
    ld h, d
    inc h
    dec [hl]
    jr nc, @+$34

    dec [hl]
    ld h, d
    inc sp
    dec [hl]
    ld [hl-], a
    dec l
    jr z, jr_04c_6949

    scf
    pop af
    pop af
    or l
    ld [bc], a
    nop
    nop
    nop
    ld h, d
    dec h
    inc l
    dec [hl]
    daa
    ld h, d
    ld [hl], $37

jr_04c_6933:
    jr c, @+$29

    inc l
    ld [hl-], a

jr_04c_6937:
    pop af
    pop af
    or l
    ld [bc], a
    nop
    nop
    nop
    ld h, d
    jr z, @+$33

jr_04c_6941:
    inc l
    dec sp
    ldh a, [$ed]
    and h
    scf
    ld [hl-], a
    dec h

jr_04c_6949:
    jr z, jr_04c_6971

    ld [hl-], a
    ld sp, $2c37
    ld sp, $2838
    daa
    ldh a, [rIE]
    cp l
    dec b
    ld sp, hl
    add hl, bc
    ld sp, hl
    ld bc, $ff01
    rlca
    rra
    ccf
    ld a, a
    ld a, a
    inc bc
    rst $38
    add l
    ldh [$f8], a
    db $fc
    cp $fe
    inc bc
    rst $38
    ret nc

    db $10
    inc d
    jr jr_04c_6981

jr_04c_6971:
    jr jr_04c_6993

    or b
    or b
    ld a, b
    ld d, b
    ld e, b
    ld e, b
    ld c, h
    ld l, h
    add [hl]
    adc e
    ld hl, sp-$06
    rst $08
    sbc l

jr_04c_6981:
    ld hl, sp+$71
    ld l, e
    ld a, [c]
    pop af
    ei
    rst $38
    pop af
    db $eb

jr_04c_698a:
    rst $30
    rst $38
    rst $38
    xor e
    ld l, a
    rst $30
    ld a, a
    cp a
    ld [hl], e

jr_04c_6993:
    cp $fd
    cp $f9
    rst $30
    rst $28
    cp $d5
    ld a, c
    db $76
    add a
    add l
    ret nc

    sub d
    rst $38
    ld [hl], d
    ld l, d
    ld a, [c]
    add c
    add $e8
    ldh [$f9], a
    sub $78
    db $76
    ld hl, sp+$7a
    rrca
    ld a, l
    ld [$9789], sp
    inc c
    cp $79
    scf
    rrca
    ld c, $2d
    add l
    adc b
    ld [bc], a
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    sub h
    jp hl


    dec [hl]
    jp nz, VBlankInterrupt

    jr nz, @+$42

    and b
    ld c, d
    cp h
    ld e, d
    ld bc, Boot
    inc bc
    inc bc
    jp hl


    dec [hl]
    db $c2, $40, $04

    nop
    add h
    ld c, d
    cp h
    ld e, d
    ld bc, $0005
    sbc a
    ld bc, DispatchBank42Rst
    rra
    rra
    ld a, a
    rst $38
    nop
    nop
    add h
    adc h
    ret c

    ld hl, sp-$04
    rst $38
    rst $38
    push af
    xor $c9
    rst $00
    rst $08
    xor e
    ld [$efff], a
    ld [hl], e
    dec bc
    rst $38
    cp a
    di
    ei
    inc bc
    db $10
    inc b
    jr c, jr_04c_698a

    ld [hl], h
    jr nz, jr_04c_6a0c

jr_04c_6a0c:
    sub b
    ld bc, SpriteGBCSkipEntry2
    inc bc
    rrca
    rra
    rst $38
    ld a, a
    add b
    ldh [$f0], a
    db $fc
    sbc b
    ld e, b
    ld a, h
    ld e, [hl]
    ld [$9200], sp
    add b
    ret nz

    ld b, b
    add b
    ret nz

    ret nz

    ld h, b
    ret nz

    rlca
    inc bc
    dec b
    ld [bc], a
    ld bc, $0205
    inc bc
    rst $38
    rst $38
    inc bc
    ret nz

    adc e
    adc $c0
    ret z

    rst $38
    rst $38
    ld bc, $a101
    ld sp, $c111
    inc b
    rst $38
    sbc h
    rst $00
    ld a, l
    or a
    rst $28
    db $fd
    db $fd
    ei
    or $da
    xor $31
    rst $38
    or [hl]
    rst $08
    rst $08
    ld [$d4cf], a
    sbc $ff
    cp l
    ld a, c
    db $db
    rst $38
    di
    inc bc
    rst $38
    rst $38
    inc bc
    ld [hl], h
    dec b
    or d
    jr nz, jr_04c_6a65

jr_04c_6a65:
    adc a
    ccf
    rrca
    rrca
    rlca
    rrca
    rra
    ld de, $d400
    ld a, h
    ld d, h
    ldh a, [$f0]
    add b
    add b
    add hl, bc
    nop
    sub h
    and b
    ld d, b
    ld h, b
    ld h, b
    or b
    ld h, b
    ret nz

    add b
    dec b
    ld [bc], a
    ld bc, $0203
    rlca
    ld [bc], a
    dec b
    call $c0c0
    ret z

    inc bc
    ret nz

    add l
    rst $38
    and c
    ld sp, $4101
    inc bc
    ld bc, $ff85
    cp c
    ld e, a
    inc bc
    inc b
    inc b

jr_04c_6a9d:
    nop
    add l
    or $f0
    ldh [$c0], a
    add b
    ld d, e
    nop
    ret nz

    db $fd
    or l
    jp z, $50c0

    call z, FuncB4c_42b1
    ld c, e
    cp [hl]
    ld e, d
    ld de, $2e03
    add l
    adc h
    db $fd
    or l
    jp z, Jump_04c_40c0

    xor h
    pop hl
    and d
    ld c, e
    cp [hl]
    ld e, d
    ld de, DataLookup_2A01
    add a
    adc c
    ld d, h
    sub c
    add hl, bc
    adc e
    ld e, a
    sbc a
    ld a, a
    rst $38
    ld bc, $8c06
    sbc h
    reti


    ld_long a, $fffe
    rst $38
    adc d
    sub c
    xor c
    xor a
    xor a
    res 1, d
    rst $38
    ld de, $0b9f
    rst $38
    rst $38
    ei
    ei
    inc bc
    db $10
    inc b
    jr z, jr_04c_6a9d

    ld c, h
    rst $08
    push hl
    or h
    ld [$eeb7], a
    sub $ad
    rrca
    dec h
    ld e, e
    cpl
    dec d
    dec bc
    cpl
    dec d
    rst $38
    rst $28
    ld [hl], a
    ld [$ae57], a
    sub h
    dec c
    rst $38
    rst $28
    ld [hl], a
    xor [hl]
    ld d, l
    ld a, [hl+]
    add b
    nop
    dec c
    rra
    rrca
    dec bc
    rra
    rra
    rst $38
    ld a, a
    add a
    push hl
    ldh a, [$fe]
    sbc e
    ld e, d
    ld a, h
    ld e, a
    ld [$a000], sp
    ld [hl], a
    and l
    or b
    ld l, d
    daa
    ld l, $94
    xor l
    add hl, bc
    inc b
    ld [bc], a

jr_04c_6b2b:
    dec c
    ld d, $0a
    inc d
    dec c
    rst $38
    add b
    cp a
    cp b
    or a
    and c
    and b
    and b
    rst $38
    ld bc, $1dfd
    ld c, l
    push bc
    dec b
    dec b
    inc b
    rst $38

jr_04c_6b42:
    sbc h
    rst $00
    ld a, l
    or a
    rst $28
    db $fd
    db $fd
    ei
    or $da
    xor $31
    rst $38
    sbc $af
    xor a
    adc e
    xor a
    or h
    sbc [hl]
    rst $38
    cp l
    ld a, c
    db $db
    rst $38
    di
    inc de
    rst $38
    rst $38
    inc bc
    ld c, h
    dec b
    jp z, $d4b0

    or d
    add sp, -$2c
    ld [c], a
    call c, $82e5
    dec hl
    ld d, a
    add hl, hl
    rla
    dec l
    dec de
    and a
    sbc e
    ld d, h
    sub b
    ld c, h
    xor d
    ld d, l
    xor $df
    rst $38
    ld bc, $4c16
    cp d
    ld d, l
    xor $df
    rst $38
    cp a
    ld l, a
    ccf
    rla
    rrca
    ccf
    sub l
    adc c
    call nc, FuncB4c_567e
    or $fc
    cp b
    pop de
    ld [c], a
    ld [$b800], sp
    ld d, h
    and b
    jr jr_04c_6b2b

    ret nz

    sbc h
    and c
    ld l, d
    ld a, [hl+]
    dec [hl]
    ld c, $11
    dec d
    jr z, jr_04c_6b42

    adc c
    and b
    or d
    or l
    and d
    and b
    cp a
    add b
    rst $38
    dec d
    dec b
    adc l
    dec h
    dec b
    db $fd
    ld bc, $b9ff
    ld e, a
    and e
    ld [hl], h
    dec sp
    adc a
    sub h
    dec c
    rst $30
    push af
    rst $28
    adc $96
    ld a, h
    ret nc

    nop
    rst $38
    ld h, [hl]
    sbc c
    ld b, $81
    jr nz, @+$18

    add c
    ld c, d
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    add e
    inc e
    inc a
    inc a
    inc bc
    inc e
    sbc d
    ld a, $3e
    ld a, [hl]
    rst $38
    rst $20
    adc $3c
    ld a, e
    rst $38
    rst $38
    ld a, [hl]
    rst $38
    rst $00
    ccf
    ccf
    rst $00
    rst $38
    ld a, [hl]
    ld a, $7e
    ld a, [hl]
    cp $ee
    rst $38
    rst $38
    ld c, $03
    rst $38
    add l
    ld l, d
    xor $40
    ld a, e
    ld h, b
    inc bc
    rst $38
    add l
    xor d
    xor $00
    cp e
    nop
    inc bc
    rst $38
    sub l
    xor [hl]
    rst $28
    ld [bc], a
    cp d
    ld b, $00
    inc bc
    rrca
    inc e
    ld sp, $6232
    ld h, d
    nop
    ret nz

    ldh a, [$38]
    adc h
    ld c, h
    ld b, [hl]
    ld b, [hl]
    inc bc
    rst $38
    add l
    db $fc
    pop af
    ld a, [c]
    ld [c], a
    ld [c], a
    inc bc
    rst $38
    adc d
    ccf
    adc a
    ld c, a
    ld b, a
    ld b, a
    rst $38
    rst $38
    cp e
    ld d, l
    ld [hl+], a
    inc bc
    nop
    add l
    rlca
    rra
    ccf
    ld a, a
    ld a, a
    inc bc
    rst $38
    add l
    ldh [$f8], a
    db $fc
    cp $fe
    dec bc
    rst $38
    ld [$8200], sp
    rst $38
    rst $38
    dec b
    ret nz

    add e
    add b
    rst $38
    rst $38
    inc bc
    nop
    adc l
    rrca
    nop
    nop
    rst $38
    rst $38
    nop
    nop
    ld [$00f8], sp
    nop
    rst $38
    db $fd
    ld b, $01
    cp b
    ld l, [hl]
    ld b, b
    ld a, e
    ld h, b
    ld l, [hl]
    ld b, b
    ld a, e
    ld b, b
    xor $00
    cp e
    nop
    xor $00
    cp e
    nop
    xor $02
    cp d
    ld b, $ee
    ld [bc], a
    cp d
    ld b, $42
    ld b, d
    ld [hl+], a
    ld hl, $0c10
    inc bc
    nop
    ld b, d
    ld b, d
    ld b, h
    add h
    ld [$c030], sp
    nop
    jp nz, $e2c2

    pop hl
    ldh a, [$fc]
    rst $38
    rst $38
    ld b, e
    ld b, e
    ld b, a
    add a
    rrca
    ccf
    rst $38
    rst $38
    add hl, bc
    nop
    add c
    ld a, b
    dec b
    ld b, b
    sub c
    nop
    rst $38
    rst $28
    rst $38
    jr nz, @-$1e

    ld h, b
    ld b, b
    nop
    rst $38
    rst $18
    ld a, l
    ld bc, Boot
    nop
    nop
    add hl, bc
    rst $38
    inc b
    adc h
    add h
    rst $38
    ld b, b
    ld c, h
    rst $38
    inc b
    ld bc, $ffd5
    ld [bc], a
    ld [bc], a
    xor d
    nop
    add b
    nop
    add l
    rrca
    add a
    rrca
    xor d
    ld bc, Boot
    ld d, b
    pop hl
    ldh a, [$e1]
    nop
    nop
    db $10
    ld hl, $0703
    ld c, $1d
    nop
    nop
    add sp, -$30
    and b
    ld b, b
    add c
    ld [bc], a
    nop
    nop
    db $10
    ld hl, $8743
    ld c, $1d
    nop
    nop
    add sp, -$30
    and b
    ld b, b
    add b
    nop
    ld a, a
    xor a
    ld e, a
    jr nz, @+$12

    ld [$0204], sp
    nop
    add b
    ld b, b
    jr nz, @+$12

    ld [$0204], sp
    nop
    ld bc, $0402
    ld [$2010], sp
    ld b, b
    rst $38
    db $dd
    ld a, d
    inc b
    ld [$2010], sp
    ld b, b
    ld b, b
    ld e, [hl]
    dec b
    ld d, b
    add c
    ld b, b
    inc bc
    rst $38
    add l
    ld [$e0f0], a
    ldh a, [$e1]
    inc bc
    rst $38
    add c
    xor d
    inc bc
    nop
    add c
    ld d, l
    inc bc
    rst $38
    add a
    xor a
    rlca
    rrca
    rlca
    rrca
    ld c, h
    ld c, h
    dec b
    ld h, $83
    ccf
    ld [bc], a
    ld [bc], a
    dec b
    inc b
    sub [hl]
    db $fc
    add a
    rrca
    add a
    ld a, [bc]
    add b
    nop
    add b
    ld d, l
    ldh a, [$e1]
    ldh a, [$a1]
    nop
    ld bc, $5500
    ld a, [hl-]
    inc [hl]
    jr z, jr_04c_6d62

    jr nz, jr_04c_6d57

    nop
    sub [hl]
    inc b

jr_04c_6d57:
    ld [$2110], sp
    ld b, e
    add a
    nop
    nop
    ld a, [hl-]
    ld [hl], h
    add sp, -$30

jr_04c_6d62:
    and b
    ld b, b
    nop
    nop
    inc b
    ld [$2010], sp
    ld b, h
    adc h
    inc b
    nop
    adc c
    add b
    nop
    ldh [rP1], a
    cp b
    nop
    ld bc, $0400
    dec b
    nop
    add e
    add b
    nop
    ld b, b
    rlca
    nop
    adc b
    inc bc
    nop
    ld c, $00
    dec sp
    nop
    rst $38
    rst $38
    inc bc
    ret nz

    adc e
    adc $c0
    ret z

    ldh a, [$e1]
    ldh a, [$e1]
    ldh a, [$e1]
    ldh a, [$e1]
    inc b
    nop
    adc [hl]
    ld b, h
    nop
    cp e
    nop
    add a
    rrca
    add a
    rrca
    add a
    rrca
    add a
    rrca
    nop
    ld a, a
    ld b, $40
    add d
    nop
    cp $06
    nop
    ld [$0840], sp
    nop
    sub b
    inc bc
    rrca
    rra
    ccf
    ld a, a
    ld a, a
    rst $38
    rst $38
    ret nz

    ldh a, [$f8]
    db $fc
    cp $fe
    rst $38
    rst $38
    inc c
    nop
    and b
    ldh [$f8], a
    cp $ff
    db $fc
    di
    rst $28
    rst $18
    cp a
    cp a
    ld a, a
    ld a, a
    ccf
    rst $08
    rst $30
    ei
    db $fd
    db $fd
    cp $fe
    rst $38
    rst $38
    ld bc, $a101
    ld sp, $c111
    and c
    ld sp, $4101
    inc bc
    ld bc, $ff85
    call $c0c0
    ret z

    inc bc
    ret nz

    add [hl]
    rst $38
    ldh a, [$e0]
    ldh a, [$e0]
    push af
    inc bc
    rst $38
    add c
    xor d
    inc bc
    nop
    add c
    ld d, l
    inc bc
    rst $38
    add l
    add a
    rrca
    rlca
    rrca
    ld d, a
    inc bc
    rst $38
    add e
    inc b
    inc b
    inc h
    inc bc
    inc b
    jp c, MenuDispatchData

    ld [bc], a
    add hl, sp
    ld hl, $04c2
    add hl, de
    ld bc, $02ff
    add hl, sp
    pop bc
    inc bc
    add hl, sp
    ld bc, $7e83
    ld [bc], a
    ld [de], a
    ld [de], a
    ld [hl-], a

jr_04c_6e27:
    ld [hl+], a
    ld bc, $0ef3
    rst $38
    add b
    add b
    dec d
    sub c
    ccf
    add h
    rra
    rst $38
    nop
    nop
    ld d, l
    ld de, $44ff
    rst $38
    rst $38
    ld bc, $5001
    ld de, $45fc
    ld hl, sp-$01
    rst $38
    db $fc
    di
    xor $ed
    db $dd
    db $dd
    rst $38
    rst $38
    ccf
    rst $08
    rst $30
    rst $30
    ei
    ei
    nop
    inc bc
    inc c
    inc de
    ld l, $2d
    ld e, l
    ld e, l
    nop
    ret nz

    jr nc, jr_04c_6e27

    db $f4
    db $f4
    ld_long a, $fffa
    nop
    ld b, h
    xor d
    db $dd
    rst $38
    cp e
    ld d, l
    db $10
    rst $38
    ld [$0900], sp
    rst $38
    add c
    add b
    dec b
    cp a
    sub e
    ret nz

    rst $38
    nop
    rst $38
    ldh [$ef], a
    ldh [rIE], a
    nop
    rst $38
    nop
    rst $38
    rlca
    rst $30
    rlca
    rst $38
    nop
    rst $38
    inc bc
    dec b

jr_04c_6e8a:
    db $fd
    sbc c
    ld bc, $bf91
    add h
    sbc a
    sub c
    cp a
    add h
    cp a
    ld de, $44ff
    rst $38
    ld de, $44ff
    rst $38
    ld de, $45fd
    ld sp, hl
    ld de, $45fd
    ld sp, hl
    inc bc
    db $fd
    add c
    cp $0c
    rst $38
    or b
    ld a, l
    ld a, l
    dec a
    ld a, $1f
    rrca
    inc bc
    nop
    cp $fe
    db $fc

jr_04c_6eb7:
    db $fc
    ld hl, sp-$10
    ret nz

    nop
    nop
    ld d, h
    ld d, h
    nop
    nop
    ld d, h
    ld d, h
    nop
    ret c

    add b
    or b
    inc [hl]
    inc [hl]
    or h
    add h
    cp b
    rst $38
    sub b
    add b
    ld e, l
    sbc a
    rla
    jr nz, jr_04c_6f53

    rst $38
    ld hl, $ed81
    db $fc
    cp l
    inc b
    cp $09
    rst $38
    inc b
    or e
    add h
    rst $38
    ret nz

    db $d3
    rst $38
    inc b
    add e
    push af
    rst $38
    inc bc
    add a
    xor d
    nop
    sub l
    ccf
    sbc d
    jr nc, jr_04c_6e8a

    ld sp, $01aa
    ld d, h
    ld sp, hl
    xor h
    add hl, de
    inc c
    sbc c
    nop
    ld a, a
    ld h, a
    ld c, [hl]
    ld e, h
    ld a, b
    ld [hl], c

jr_04c_6f02:
    ld h, d
    nop
    rst $38
    inc d
    add hl, hl
    ld d, e
    and a
    ld c, [hl]
    sbc h
    nop
    rst $38
    rst $20
    adc $9c
    jr c, @+$73

    ld [c], a
    nop
    cp $16
    ld a, [hl+]
    ld d, d
    and [hl]
    ld c, [hl]
    sbc [hl]
    ld a, a
    db $10
    add b
    call $f3e7
    ld hl, sp-$04
    ld a, a
    ccf
    sbc a
    rst $08
    rst $20
    di
    ld sp, hl
    db $fc
    cp $fc
    ld sp, hl
    di
    rst $20
    rst $08
    sbc a
    ccf
    rst $38
    jr nz, jr_04c_6eb7

    db $e3
    rst $20
    adc a
    rra
    ccf
    dec l
    ld hl, $2d0d
    dec l
    inc l
    ld bc, $ff1b
    add b
    add b
    sub l
    adc a
    sbc d
    adc h
    sbc c
    rst $38
    nop
    nop
    ld d, l
    rst $38
    xor d
    nop
    ld d, l

jr_04c_6f53:
    rst $38
    ld bc, $5101
    ld sp, hl
    or c
    add hl, de
    ld sp, $d3d3
    dec b
    jp hl


    add e
    rst $38
    add a
    add a
    dec b
    rrca
    rst $38
    rst $38
    sbc c
    jr nc, jr_04c_6f02

    dec [hl]
    sbc a
    ld a, [hl+]
    add b
    ld d, l
    adc h
    add hl, de
    inc c
    ld e, c
    db $fc
    xor c
    nop
    ld d, l
    ld b, l
    ld c, d
    ld d, h
    ld l, c
    ld d, e
    ld h, a
    ld a, a
    nop
    add hl, sp
    ld [hl], e
    rst $20
    adc $9c
    jr c, @+$01

    nop
    push bc
    adc d
    inc d
    add hl, hl
    ld d, e
    and a
    rst $38
    nop
    ld a, [hl-]
    ld [hl], d
    and $ce
    sbc d
    ld [hl-], a
    cp $00
    rst $38
    rst $38
    ld a, a
    rst $38
    rra
    rst $38
    ld b, a
    rst $38
    ld a, [hl]
    cp a
    db $db
    db $ed
    rst $30
    ei
    db $fd
    cp $7e
    db $fd
    cp e
    rst $10
    rst $28
    rst $18
    cp a
    ld a, a
    rst $38
    rst $38
    db $fc
    rst $38
    pop af
    rst $38
    call nz, $ffff
    add b
    cp a
    cp b
    or a
    and c
    and b
    and b
    adc h
    sbc c
    adc h
    sbc c
    adc h
    sbc c
    adc h
    sbc c
    ld de, $aa44
    ld [hl], a
    xor e
    rst $38
    ld b, h
    rst $38
    sbc c
    ld sp, $3199
    sbc c
    ld sp, $3199
    nop
    nop
    dec de
    scf
    cpl
    ld l, $1d
    dec de
    nop
    nop
    cp b
    ld [hl], h
    ld [hl], h
    db $ec
    and d
    sbc h
    cp b
    dec l
    dec l
    dec de
    scf
    cpl
    ld l, $1d
    dec de
    ret c

jr_04c_6ff1:
    cp b
    xor b
    ld [hl], h
    ld [hl], h
    db $ec
    sbc h
    cp b
    db $fc

jr_04c_6ff9:
    ldh a, [$e0]
    ret nz

    add b
    add b
    nop
    nop
    ccf
    rrca
    rlca
    inc bc
    ld bc, $0001
    nop
    inc c
    rst $38
    call nz, $071f
    ld bc, $0300
    inc c
    db $10
    jr nz, jr_04c_7054

    ld b, b
    add b
    add b
    ret nz

    jr nc, @+$0a

    inc b
    ld [bc], a
    ld [bc], a
    ld bc, $ff01
    ld bc, $1dfd
    ld c, l
    push bc
    dec b
    dec b
    dec d
    dec b
    adc l
    dec h
    dec b
    db $fd
    ld bc, $a0ff
    or d
    or l
    and d
    and b
    cp a
    add b
    rst $38
    adc h
    sbc b
    adc l
    sbc a
    adc d
    add b
    add b
    rst $38
    xor d
    nop
    ld d, l
    rst $38
    xor d
    nop
    nop
    rst $38
    sbc c
    ld sp, $f159
    xor c
    ld bc, $ff01
    ld [bc], a
    nop
    nop
    nop
    nop

jr_04c_7054:
    nop
    nop
    nop
    nop
    add c
    ld a, [hl]
    inc bc
    cp $86
    ld h, [hl]
    cp $fe
    nop
    ld a, [hl]
    cp $05
    jr c, jr_04c_6ff1

    nop
    ld e, $3e
    ld a, [hl]
    xor $fe
    cp $ee
    nop
    inc a
    ld a, h
    inc bc
    jr c, jr_04c_6ff9

    inc a
    ld a, h
    nop
    inc a
    ld a, [hl]
    inc bc
    xor $96
    cp $7c
    nop
    ld h, d
    and $f6
    cp $fe
    xor $e6
    nop
    rst $38
    db $fc
    db $e3
    add b
    ldh [$e0], a
    add b
    ldh [rIE], a
    ld a, h
    db $e3
    dec b
    nop
    xor l
    rst $38
    ld a, l
    push hl
    ld bc, $0507
    ld bc, $4001
    ld h, c
    jr z, @+$18

    ld c, d
    inc b
    add l
    ld b, b
    ld hl, $0242
    ld a, [bc]
    inc b
    jr nc, @+$2e

    nop
    ld [$060c], sp
    inc bc
    add c
    ld b, e
    ld h, $1c
    db $10
    jr nc, jr_04c_7118

    ret nz

    add c
    ld [bc], a
    inc b
    ld [$100f], sp
    jr nz, jr_04c_7101

    ld b, c
    inc bc
    ld b, d
    add l
    ldh a, [rP1]
    nop
    db $10
    adc b
    inc bc
    ld [$4008], sp
    adc d
    ccf
    ld a, a
    ldh [$80], a
    ld b, b
    ccf
    ld [hl+], a
    ld hl, $ffff
    inc bc
    nop
    sbc e
    rst $38
    add d
    ld bc, $fefc
    rlca
    ld bc, $fc02
    adc b
    ld [$80ff], sp
    and b
    add e

jr_04c_70eb:
    add h
    adc b
    sub b
    sub b
    rst $38
    nop
    ld [$20c0], sp
    db $10
    inc c
    inc c
    inc b
    nop
    add c
    rst $38
    inc bc
    nop
    adc b
    ret nz

    and b
    add b

jr_04c_7101:
    ldh [$a0], a
    sub b
    adc $ff
    dec b
    nop
    sbc b
    ldh a, [$0e]
    rst $38
    inc bc
    ld bc, $0507
    rlca
    pop af
    rrca
    rst $38
    ld sp, $000b
    dec b

jr_04c_7118:
    add hl, bc
    ld [de], a
    ld bc, $4a00
    ld [hl+], a
    sub h
    jr @+$22

    inc bc
    nop
    sub b
    jr jr_04c_7156

    ld h, b
    ret nz

    ld bc, $0402
    ld [$2c18], sp
    ld b, [hl]
    add e
    add c
    ld b, b
    jr nz, jr_04c_7144

    inc b
    ld b, d
    add [hl]
    ld [hl+], a
    ld [hl+], a
    ld hl, $0821
    ld [$1006], sp
    ld [$b208], sp
    ld [hl+], a
    inc d

jr_04c_7144:
    jr jr_04c_7156

    jr jr_04c_7154

    ld a, [bc]
    add hl, bc
    add d
    ld b, h
    jr z, jr_04c_715e

    jr z, jr_04c_7194

    add d
    ld bc, $5088

jr_04c_7154:
    jr nc, jr_04c_7166

jr_04c_7156:
    jr nc, @+$62

    and b
    jr nz, jr_04c_70eb

    sub b
    adc b
    add h

jr_04c_715e:
    and e
    add e
    add b
    add b
    inc c
    inc c
    jr jr_04c_7196

jr_04c_7166:
    add sp, -$40
    nop
    nop
    rst $38
    rst $30
    ret nz

    ret nz

    add b
    add b
    and a
    rst $38
    rst $38
    rst $30
    inc b
    nop
    adc d
    rst $00
    rst $38
    rst $38
    rst $30
    ld bc, $0103
    ld bc, $ffc7
    inc bc
    jp $81a5


    pop bc
    pop bc
    jp $efc3


    rst $30
    ret c

    call z, $d0bc
    and a
    rst $38
    ccf
    or a
    and b

jr_04c_7194:
    ld h, b
    ld h, h

jr_04c_7196:
    inc c
    db $d3
    db $e3
    db $e3
    rst $20
    dec l
    dec de
    add hl, de
    ld bc, $ffc7
    jp $e3c3


    ld de, $6d39
    jp Jump_000_05c3


    ld de, $7f83
    jr nc, jr_04c_71af

jr_04c_71af:
    dec b
    jr nz, @-$7d

    cp $03
    nop
    add c
    rst $38
    ld b, $00
    adc e
    add c
    ld a, [hl]
    ld h, c
    ld a, [hl]
    add [hl]
    ld h, [hl]
    ld a, a
    add c
    add c
    ld a, [hl]
    sbc c
    inc b
    db $db
    adc e
    rst $20
    pop hl
    sbc $be
    ld h, [hl]
    ld h, [hl]
    ld a, [hl]
    ld h, [hl]
    sbc c
    jp $04bd


    db $db
    add h
    cp l
    jp $bdc3


    inc b
    ld h, [hl]
    rst $00
    cp l
    jp Jump_04c_7a9d


    ld a, d
    ld l, d
    ld l, d
    ld h, [hl]
    ld l, d
    sbc l
    rst $38
    add e
    add h
    rst $38
    sbc b
    add e
    rst $08
    sub [hl]
    rst $38
    add e
    inc b
    rra
    ld hl, sp-$1d
    adc a
    db $76
    rst $38
    add e
    dec b
    add hl, de
    rst $38
    push hl
    adc c
    ld [hl], c
    dec a
    sbc [hl]
    sub l
    ret


    or l
    db $d3
    ld [hl], b
    dec a
    ld d, [hl]
    dec l
    call AudioNoteOff
    ld b, a
    ld b, e
    ld c, l
    ld [$1b74], sp
    ld h, l
    sbc e
    ld b, [hl]
    dec l
    dec sp
    db $10
    ld l, $d1
    xor [hl]
    dec e
    ld a, [c]
    call nz, $f029
    rst $28
    ret c

    or a
    xor [hl]
    inc bc
    xor l
    add l
    rrca
    rst $30
    dec de
    db $ed
    ld [hl], l
    inc bc
    or l
    ld [$a8af], sp
    rst $38
    ret nz

    sbc a
    rst $38
    ret nz

    rst $38
    ret


    db $cc, $ff, $00
    rst $38
    rst $38
    nop
    rst $38
    add hl, sp
    ld a, h
    rst $38
    inc bc
    ld sp, hl
    rst $38
    inc bc
    rst $38
    inc sp
    ld [hl], e
    nop
    ld a, a
    ld e, h
    ld l, e
    ld [hl], h
    ld l, c
    ld d, d
    ld d, h
    nop
    cp $36
    jp c, $962e

    ld a, [bc]
    ld a, [bc]
    inc b
    rst $38
    call z, $ff00
    nop
    rst $38
    cp h
    add $c9
    add d
    ret c

    ldh a, [$8e]
    rst $38
    ld e, h
    ld h, $89
    ld h, d
    cp b
    ldh a, [$0e]
    rst $38
    ld e, e
    ld hl, $658f
    cp a
    pop af
    rrca
    rst $38
    adc [hl]
    sub b
    db $eb
    ld [$e1f6], a
    ld a, [c]
    ld sp, hl
    sub l
    sbc l
    add hl, hl
    jp Div16x16CheckHigh


    sbc a
    rra
    jr nc, jr_04c_72b9

    ld e, [hl]
    cp b
    ld [hl], l
    ld a, [bc]
    ld [hl], h
    ld l, c
    db $db
    and a
    ld e, e
    cp l
    xor [hl]
    ld d, c
    xor $f7
    xor l
    xor l
    or l
    or l
    push de
    push de
    sub $d6
    or l
    or l
    xor l
    xor l
    xor e
    xor e
    ld l, e
    ld l, e
    ld [$e8f5], sp
    call z, $e3e1
    rst $20
    db $e3
    di
    pop af
    ldh a, [$7c]
    add hl, sp
    sub e
    rst $00
    rst $00
    sub e

jr_04c_72b9:
    add hl, sp
    ld a, h
    ld [hl], e
    daa
    add a
    rst $00
    rst $00
    add a
    rrca
    ld c, a
    ld d, h
    ld d, b
    ld l, b
    ld [hl], h
    ld e, e
    ld l, h
    ld a, a
    nop
    ld a, [bc]
    ld a, [bc]
    ld d, $2e
    sub $3a
    cp $00
    rst $38
    adc b
    cp e
    cp h
    cp $c3
    rst $20
    rst $38
    rst $38
    ld [$fcfb], sp
    ld a, $83
    rst $00
    rst $38
    rst $38
    add hl, bc
    ld sp, hl
    rst $38
    dec a
    add c
    rst $00
    rst $38
    and a
    xor a
    sbc e
    ld sp, hl
    cp c
    cp c
    or e
    or a
    rst $38
    sbc b
    or e
    cp b
    or $c3
    rst $20
    rst $38
    rst $38
    add sp, -$45
    call c, $8f5e
    db $d3
    db $e3
    rst $38
    dec l
    jp hl


    rst $30
    dec [hl]
    add c
    rst $00
    rst $38
    and a
    xor a
    ei
    add hl, de
    jp hl


    push de
    di
    or a
    dec b
    ld [$8083], a
    rst $08
    add b
    dec b
    ld d, a
    add a
    ld bc, $01fd
    rst $38
    nop
    rst $38
    nop
    inc b
    rst $38
    ld [bc], a
; [S111] $7326-$735D: 56 bytes of custom-skill battle lines (compiler region
; gd_custom_msg_a; MagicBurn's announce "burns half its MP!" when unedited).
; The label CustomMsg_E0_MagicBurn is always emitted (wherever MagicBurn's line
; lands). [S155 r3] Entry 265 above (the $4019 table's $FD row) named it from S2d
; to S155 r2 and was called "dead" — it is NOT: LoadB4c_Fork_stockfd renders a
; stock $FD through it (the poison tick's follow-up), so it is the vanilla $5F6C
; (empty) again.
; @BUILD_PROJECT BEGIN gd_custom_msg_a
CustomMsg_E0_MagicBurn::   ; (kept; S155 r3: the $4019[$FD] row is the vanilla $5F6C again)
CustomMsgLine_224:  ; "[['{name} burns half its MP!'], ['A huge burst of', 'magic energy!']]"
    db $F9, $00, $62, $3F, $52, $4F, $4B, $50, $62, $45, $3E, $49, $43, $62, $46, $51, $50, $62, $30, $33, $63, $FC, $10, $EC, $F2, $24, $62, $45, $52, $44, $42, $62, $3F, $52, $4F, $50, $51, $62, $4C, $43, $F1, $4A, $3E, $44, $46, $40, $62, $42, $4B, $42, $4F, $44, $56, $63, $EC, $F0
; @BUILD_PROJECT END gd_custom_msg_a
    ASSERT @ == $735e
; ============================================================================
; S2e CUSTOM-MESSAGE INFRASTRUCTURE  (reusable, scales to all custom skills)
; ----------------------------------------------------------------------------
; Battle-message renderer fork. Message id $FD is the "custom message" escape:
; when seen, the string is resolved from CustomMsgPtrTable indexed by the CURRENT
; skill id ($db8a - $DE), by feeding a PRIVATE mode-table base (CustomMsgModeTable)
; to the SAME unchanged two-level resolver (CallTextEngine -> $092f). This is the
; project's standard "gate on skill id >= $DE -> high-table" pattern (cf. bank_04d
; HighDetailTextFork). Stock ids (< $FD) are byte-identical to vanilla; a stock
; skill that ever emits $FD (skill id < $DE) also falls through to vanilla $4019[$FD].
; Adding a new custom skill = one CustomMsgPtrTable entry + one pooled string.
; ============================================================================
LoadB4c_Fork::
    ld a, [$c823]
    cp $ff
    ret z
    cp $fd
    jr z, LoadB4c_Fork_custom
    cp $b7                           ; [QUAKE v3] miss family: the engine routes
    jr z, LoadB4c_MaybeFlew          ;   a 0-damage hit to $B8 "Has no effect
    cp $b8                           ;   on {name}!" (measured) / $B7 "Missed" —
    jr z, LoadB4c_MaybeFlew          ;   for a flying quake target both become
                                     ;   the "flew above it!" line
LoadB4c_plain:
    ld de, $4009                     ; vanilla battle-message path (unchanged)
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    ret
LoadB4c_MaybeFlew:                   ; [QUAKE v4] a FLYING PARTY member keeps
    ld a, [$db8a]                    ; its per-target beat (damage forced to 0
    cp $e5                           ; by the handler) but its line becomes
    jr c, LoadB4c_plain              ; "But {name} flew above it!". ENEMY
    cp $e9                           ; flyers keep the vanilla "Has no effect
    jr nc, LoadB4c_plain             ; on {name}!" (user preference), which
    ld a, [$db89]                    ; also sidesteps the $db88 flakiness seen
    cp $04                           ; in real-menu casts — $db89 is the
    jr nc, LoadB4c_plain             ; target var the damage handler trusts.
    push hl
    ld hl, $db8b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    bit 4, [hl]
    pop hl
    jr z, LoadB4c_plain
    xor a
    ld [$c822], a                    ; mode 0
    ld [$c823], a                    ; string index 0
    ld de, QuakeFlewModeTable
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    ret
QuakeFlewModeTable:
    dw QuakeFlewPtrTable             ; [QUAKE v3] mode 0 -> the 1-entry table
QuakeFlewPtrTable:
    dw CustomMsg_QuakeFlew
LoadB4c_Fork_custom:
    ld a, [wCustomLine]              ; [S155] an S155 skill's extra line pending?
    or a                             ;   (its handler made the hit message $FD)
    jr nz, LoadB4c_CustomLine
.mourn:
    ld a, [wMournBoosted]            ; [MOURN S75] boost banner pending?
    or a
    jr nz, LoadB4c_MournBoost
    ld a, [wQuakeAllyMsg]            ; [QUAKE] crossover pending? then $FD means
    or a                             ;   the shared "seismic wave" ally line, not
    jr nz, LoadB4c_QuakeAllies       ;   the per-id announce (flag cleared by the
                                     ;   QuakeGate_delay renderer right after)
    ld a, [$db8a]                    ; current skill id
    cp $de
    jr c, LoadB4c_Fork_stockfd       ; not a custom skill -> vanilla $FD
    sub $de
    ld [$c823], a                    ; id = custom index (skill - $DE)
    xor a
    ld [$c822], a                    ; mode 0
    ld de, CustomMsgModeTable        ; private mode table -> CustomMsgPtrTable
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    ret
LoadB4c_Fork_stockfd:
    ld de, $4009
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    ret
LoadB4c_QuakeAllies:                 ; [QUAKE] fixed index 0 into the ally table
    xor a
    ld [$c822], a                    ; mode 0
    ld [$c823], a                    ; string index 0
    ld de, QuakeAlliesModeTable
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    ret

LoadB4c_MournBoost:                  ; [MOURN S75] render the boost banner and
    xor a                            ;   clear the flag (one-shot)
    ld [$c822], a                    ; mode 0
    ld [$c823], a                    ; index 0
    ld de, MournBoostModeTable       ; private mode table -> boost string
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    xor a
    ld [wMournBoosted], a            ; clear flag
    ret
MournBoostModeTable:
    dw MournBoostPtrTable            ; [MOURN S75] mode 0 -> the 1-entry boost table
MournBoostPtrTable:
    dw CustomMsg_MournBoost

; [S155] LoadB4c_CustomLine — render extra line A (1-based, CustomLinePtrs) of the
; skill that set it (wCustomLineSkill == $DB8A; another skill's $FD drops it and
; goes on as before). One-shot: wCustomLine := 0. The lines are battle text in
; the gd_custom_msgs region (CustomLine_*; $F9 $00 = the target, $F9 $10 = the
; number of the hit — the damage / the ATK lost; [S156] at this $FD render $F9 $20
; = the caster (the game's own fill, measured) and Plunder's $F9 $30 = the buff's
; name, put in $C1B0 by bank $72 StealName72). BATTLE_SKILL_SYSTEM §13.10 / §13.11.
LoadB4c_CustomLine:
    ld b, a
    xor a
    ld [wCustomLine], a
    ld a, [wCustomLineSkill]
    ld c, a
    ld a, [$db8a]
    cp c
    jr nz, LoadB4c_Fork_custom.mourn
    ld a, b
    dec a
    ld [$c823], a                    ; index
    xor a
    ld [$c822], a                    ; mode 0
    ld de, CustomLineModeTable
    call CallTextEngine
    ld a, $ff
    ld [$c823], a
    ret
CustomLineModeTable:
    dw CustomLinePtrs                ; [S155] mode 0 -> the extra lines
CustomLinePtrs:                      ; [S155] LINE_* (bank $72), from 1
    dw CustomLine_LoneWolf           ; 1 LoneWolf: the bonus applied
    dw CustomLine_Punish             ; 2 Punish: the target had buffs
    dw CustomLine_Finish             ; 3 Finish: more than x1
    dw CustomLine_Rupture            ; 4 Rupture: the ailments burst
    dw CustomLine_Rust               ; 5 Rust: the ATK lost
    dw CustomLine_Plunder            ; 6 [S156] Plunder: the buff stolen
    dw CustomLine_PlunderDEF         ; 7 [S156 r2] + the caster's DEF rise
    dw CustomLine_PlunderAGL         ; 8 [S156 r2] + the caster's AGL rise

CustomMsgModeTable:
    dw CustomMsgPtrTable             ; mode 0 -> the custom pointer table
QuakeAlliesModeTable:
    dw QuakeAlliesPtrTable           ; [QUAKE] mode 0 -> the 1-entry ally table
QuakeAlliesPtrTable:
    dw CustomMsg_QuakeAllies
; [S111] Compiler regions (editor2/core/custom_skills.py, PROJECT_COMPILER
; §2.27): CustomMsgPtrTable = one line per custom id $DE-$FE (index id-$DE;
; CustomMsg_dummy = an empty line), then the lines themselves + the three fixed
; extra lines the bank-$4C forks name (CustomMsg_QuakeAllies, _QuakeFlew,
; _MournBoost), first-fit into gd_custom_msg_a ($7326, MagicBurn's old slot)
; and gd_custom_msgs (up to $7A9D). The line bytes are battle text: $ED (a box
; opener), $F9 $00 = the subject's name (the caster in an announce, the target
; in a hit line), $F1 = next line, $FC $10 $EC $F2 = next page, $EC $F0 = end.
    ASSERT @ == $7458                ; [S155] editor2/core/custom_skills.py MSG_PTRS_AT ([S156] +2: CustomLine_Plunder; r2 +4: _PlunderDEF / _AGL; was $7452)
CustomMsgPtrTable:
; @BUILD_PROJECT BEGIN gd_custom_msg_ptrs
    dw CustomMsg_dummy         ; [$DE] Repel
    dw CustomMsg_dummy         ; [$DF] LoneWolf
    dw CustomMsgLine_224       ; [$E0] MagicBurn
    dw CustomMsgLine_225       ; [$E1] Tame
    dw CustomMsgLine_226       ; [$E2] TameMore
    dw CustomMsgLine_227       ; [$E3] TameMost
    dw CustomMsg_dummy         ; [$E4] Anchor
    dw CustomMsgLine_229       ; [$E5] Tremor
    dw CustomMsgLine_229       ; [$E6] Quake
    dw CustomMsgLine_229       ; [$E7] QuakeMore
    dw CustomMsgLine_229       ; [$E8] QuakeMost
    dw CustomMsgLine_233       ; [$E9] Mourn
    dw CustomMsg_dummy         ; [$EA] Plunder
    dw CustomMsg_dummy         ; [$EB] Punish
    dw CustomMsg_dummy         ; [$EC] Finish
    dw CustomMsg_dummy         ; [$ED] Rupture
    dw CustomMsg_dummy         ; [$EE] Blunt
    dw CustomMsg_dummy         ; [$EF] -
    dw CustomMsg_dummy         ; [$F0] -
    dw CustomMsg_dummy         ; [$F1] -
    dw CustomMsg_dummy         ; [$F2] -
    dw CustomMsg_dummy         ; [$F3] -
    dw CustomMsg_dummy         ; [$F4] -
    dw CustomMsg_dummy         ; [$F5] -
    dw CustomMsg_dummy         ; [$F6] -
    dw CustomMsg_dummy         ; [$F7] -
    dw CustomMsg_dummy         ; [$F8] -
    dw CustomMsg_dummy         ; [$F9] -
    dw CustomMsg_dummy         ; [$FA] -
    dw CustomMsg_dummy         ; [$FB] -
    dw CustomMsg_dummy         ; [$FC] -
    dw CustomMsg_dummy         ; [$FD] -
    dw CustomMsg_dummy         ; [$FE] -
; @BUILD_PROJECT END gd_custom_msg_ptrs
; @BUILD_PROJECT BEGIN gd_custom_msgs
CustomMsg_dummy:
    db $F0
CustomMsgLine_225:  ; "['{name} used Tame!']"
    db $ED, $F9, $00, $62, $52, $50, $42, $41, $62, $37, $3E, $4A, $42, $63, $EC, $F0
CustomMsgLine_226:  ; "['{name} used TameMore!']"
    db $ED, $F9, $00, $62, $52, $50, $42, $41, $62, $37, $3E, $4A, $42, $30, $4C, $4F, $42, $63, $EC, $F0
CustomMsgLine_227:  ; "['{name} used TameMost!']"
    db $ED, $F9, $00, $62, $52, $50, $42, $41, $62, $37, $3E, $4A, $42, $30, $4C, $50, $51, $63, $EC, $F0
CustomMsgLine_229:  ; "['{name} sets off', 'a quake!']"
    db $ED, $F9, $00, $62, $50, $42, $51, $50, $62, $4C, $43, $43, $F1, $3E, $62, $4E, $52, $3E, $48, $42, $63, $EC, $F0
CustomMsgLine_233:  ; "['{name} used Mourn!']"
    db $ED, $F9, $00, $62, $52, $50, $42, $41, $62, $30, $4C, $52, $4F, $4B, $63, $EC, $F0
CustomMsg_QuakeAllies:  ; "['Allies are caught', 'in a seismic wave!']"
    db $24, $49, $49, $46, $42, $50, $62, $3E, $4F, $42, $62, $40, $3E, $52, $44, $45, $51, $F1, $46, $4B, $62, $3E, $62, $50, $42, $46, $50, $4A, $46, $40, $62, $54, $3E, $53, $42, $63, $EC, $F0
CustomMsg_QuakeFlew:  ; "['But {name}', 'flew above it!']"
    db $ED, $25, $52, $51, $62, $F9, $00, $F1, $43, $49, $42, $54, $62, $3E, $3F, $4C, $53, $42, $62, $46, $51, $63, $EC, $F0
CustomMsg_MournBoost:  ; "['Fallen allies', 'lend power!']"
    db $29, $3E, $49, $49, $42, $4B, $62, $3E, $49, $49, $46, $42, $50, $F1, $49, $42, $4B, $41, $62, $4D, $4C, $54, $42, $4F, $63, $EC, $F0
CustomLine_LoneWolf:  ; "["A lone wolf's", 'fury!']"
    db $ED, $24, $62, $49, $4C, $4B, $42, $62, $54, $4C, $49, $43, $68, $F1, $43, $52, $4F, $56, $63, $EC, $F0
CustomLine_Plunder:  ; "[['{name} steals', "{target}'s"], ['{buff}!']]"
    db $ED, $F9, $20, $62, $50, $51, $42, $3E, $49, $50, $F1, $F9, $00, $68, $FC, $10, $EC, $F2, $F9, $30, $63, $EC, $F0
CustomLine_Punish:  ; "['It punishes the', "foe's buffs!"]"
    db $ED, $2C, $51, $62, $4D, $52, $4B, $46, $50, $45, $42, $50, $62, $51, $45, $42, $F1, $43, $4C, $42, $68, $62, $3F, $52, $43, $43, $50, $63, $EC, $F0
CustomLine_Finish:  ; "['It goes in for', 'the kill!']"
    db $ED, $2C, $51, $62, $44, $4C, $42, $50, $62, $46, $4B, $62, $43, $4C, $4F, $F1, $51, $45, $42, $62, $48, $46, $49, $49, $63, $EC, $F0
CustomLine_Rupture:  ; "['The ailments', 'burst!']"
    db $ED, $37, $45, $42, $62, $3E, $46, $49, $4A, $42, $4B, $51, $50, $F1, $3F, $52, $4F, $50, $51, $63, $EC, $F0
CustomLine_Rust:  ; "['{target} loses', '{amount} attack!']"
    db $ED, $F9, $00, $62, $49, $4C, $50, $42, $50, $F1, $F9, $10, $62, $3E, $51, $51, $3E, $40, $48, $63, $EC, $F0
CustomLine_PlunderDEF:  ; "[['{name} steals', "{target}'s"], ['{buff}!'], ["{name}'s defense", 'goes up by {amount}!']]"
    db $ED, $F9, $20, $62, $50, $51, $42, $3E, $49, $50, $F1, $F9, $00, $68, $FC, $10, $EC, $F2, $F9, $30, $63, $FC, $10, $EC, $F2, $F9, $20, $68, $62, $41, $42, $43, $42, $4B, $50, $42, $F1, $44, $4C, $42, $50, $62, $52, $4D, $62, $3F, $56, $62, $F9, $10, $63, $EC, $F0
CustomLine_PlunderAGL:  ; "[['{name} steals', "{target}'s"], ['{buff}!'], ["{name}'s speed", 'goes up by {amount}!']]"
    db $ED, $F9, $20, $62, $50, $51, $42, $3E, $49, $50, $F1, $F9, $00, $68, $FC, $10, $EC, $F2, $F9, $30, $63, $FC, $10, $EC, $F2, $F9, $20, $68, $62, $50, $4D, $42, $42, $41, $F1, $44, $4C, $42, $50, $62, $52, $4D, $62, $3F, $56, $62, $F9, $10, $63, $EC, $F0
; @BUILD_PROJECT END gd_custom_msgs
; --- end S2e custom-message infrastructure ---
    ds $7a9d - @, $00       ; the bank's free run (was a counted nop pad)
    ASSERT @ == $7a9d

Jump_04c_7a9d:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
