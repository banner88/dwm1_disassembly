# Sidequest & Event Map — Game Knowledge ↔ Technical Implementation

> This document maps every sidequest, gate unlock, and progression event
> to its technical implementation (flags, step counters, engine variables,
> opcodes). Game knowledge from the FAQ/player guide; technical data from
> branch-following script analysis.
>
> **Status**: Initial mapping. Engine evaluation opcodes ($CA8D, $D8E1,
> $FF92 population) need per-opcode tracing (Phase D work).

---

## 1. Story Progression Overview

The game is primarily driven by **arena wins** and secondarily by
**mandatory gate bosses**. Two engine variables orchestrate this:

| Variable | Purpose |
|----------|---------|
| $D9E3 (Story progression counter) | Set by boss-defeat scripts (48→78), checked by room-entry scripts |
| Event flags $0030–$0037 ($D9A1) | Arena rank flags (G→S class), set by Arena Lobby script 0 |

### Arena-Driven Progression

| Arena Class | Flag | Checks | Unlocks |
|------------|-------|--------|---------|
| G class | $0030 | 19 | First gates (Beginning, Villager, Talisman), breeding NPCs |
| F class | $0031 | 25 | More gates, some NPC dialogue |
| E class | $0032 | 55 | Well Gate, Bazaar Gate requirements, Teto/Dob breeding |
| D class | $0033 | 29 | — |
| C class | $0034 | 17 | Teto (Eyeder) breeding |
| B class | $0035 | 57 | — |
| A class | $0036 | 24 | May (Rayburn) breeding, Restaurant NPC |
| S class | $0037 | 61 | Bazaar Edge Gate, MedalMan (Metaly) breeding |

### Mandatory Gate Interludes

| Event | Flag | Checks | When |
|-------|------|--------|------|
| Beat BattleRex (Gate of Anger) | $001D | 52 | After D class — arena locked until cleared |
| Beat Durran (Gate of Reflection) | $0025 | 59 | After S class — arena locked until cleared |
| Starry Night Tournament | $00F1 | 131 | After Durran — set by Castle scr0 ($0C:$46C4, unreached branch via $CAB9) |

Arena Lobby scripts 6/7/10/11 check these in priority order:
$00F1 → $0025 → $0037 → $001D, blocking arena access until mandatory
gates are cleared.

---

## 2. Gate Unlock Sidequests

### Bazaar Gate (map_type $02, screen 6 = $D93A)
- **Requirement**: G class ($0030) + forfeit a monster with a Fire-type skill
- **Script**: Bazaar script 7 — checks $0032(E), $004B, $004A, then `cond_branch [$FF92]==215/216/217`
- **Flags**: $004A = fire monster given, $004B = gate accessible, $0040 = related state
- **Step counter**: $D93A has 9 steps tracking BBQ→gate transformation
- **Engine variable**: `$FF92` = **hPlayerX low byte** (S68: bank $01/$04 field code writes it as the player X coordinate word $FF92/93; Y = $FF95/96) — the 215/216/217 branch is a *player-position* gate (which counter tile you stand at), not a species/skill result. [in-game confirm trivially: stand elsewhere]
- **Monster forfeited**: Yes (lost forever, e.g. Gremlin)

### Well Gate (map_type $18, screen 4 = $D960)
- **Requirement**: E class ($0032) + forfeit a monster with a Lightning-type skill
- **Script**: Well script 6/7 — checks $006A, $005E, $005D, $0032, $0031, then `cond_branch [$CA8D]==1`
- **Flags**: $005E = lightning check passed (engine-set, 4 checks), $006C = monster given, $006A = quest seen, $005D = quest started
- **Step counter**: $D960 = 1 (Well screen 4 changes to show gate)
- **Engine variable**: `$CA8D` = **party count** (canonicalizer-owned; S68 — every slot-param opcode bounds against it). `cond_branch [$CA8D]==1` = "party has exactly ONE monster" → the can't-forfeit-your-last-monster refusal path. The skill check itself is the engine-set flag ($005E here), not $CA8D.
- **Monster forfeited**: Yes

### Farm Gate (map_type $04)
- **Requirement**: Beat Gate of Anger ($001D)
- **Implementation**: Pure flag gate. Farm room-entry script checks $001D and advances step counters. No engine evaluation needed.
- **Flags**: $001D (BattleRex defeated)

### Arena Left Gate (map_type $07, screen 1 = $D94C)
- **Requirement**: Beat Anger ($001D) + beat Goopi in room east of Shrine stairs
- **Scripts**: Goopy Room 1 scripts 2/3/4 — engine checks $D9DF/$D9E0 (RPS state machine)
- **Flags**: $0083 = Goopi 1 defeated → step $D94C advances
- **Engine variables**: $D9DF = RPS round state (0=playing, 5=won), $D9E0 = current choice result (0/1/2 likely maps to Crab/Log/Slime)
- **RPS sequence**: Always Crab, Log, Crab, Slime, Crab

### Medal Gate (MedalMan room, map_type $16, = $D95E)
- **Requirement**: Give 13 TinyMedals to MedalMan, talk to Metally, re-enter room
- **Scripts**: MedalMan script 1/2 set flag $0038 (medal quest). Script 3 sets $011E, $005C
- **Flags**: $0038 = medal quest active, $011E = collection milestone, $005C = gate accessible(?), $0050/$0053 = check-only (engine-set medal thresholds)
- **Step counter**: $D95E has 6 steps (MedalMan room changes)
- **Medal rewards**: 13→ZapBird Egg, 18→Trumpeter Egg, 25→Spikerous Egg, 30→Metable Egg

### Library Gate (map_type $12, screen 4 = $D95C)
- **Requirement**: 100 unique Library entries + talk to lady behind desk
- **Script**: Library script 16 — `cond_branch [$D8E1]==0..11` (12 tiers of collection progress)
- **Flags**: $0042 = library access granted (checked by scripts 14/15), $011F = quest milestone, $0092/$0093 = progression
- **Step counter**: $D95C has 2 steps (gate visible/hidden)
- **Engine variable**: $D8E1 = collection evaluation result (set by opcode $34, CheckMonsterSpecies3)
- **Opcode $34** checks species data at $CAEA against specific values ($0F, $10, $45, $11, $5A) and writes result to $D8E1

### Arena Right Gate (map_type $07)
- **Requirement**: Beat Starry Night Tournament ($00F1) + beat Goopi 2 in RPS
- **Scripts**: Goopy Room 2 scripts 4/5/6 — same $D9DF/$D9E0 RPS state machine
- **Flags**: $010C = Goopi 2 defeated, $010B = related state
- **Step counter**: $D94C = 4/5 (Arena Right step)

### Bazaar Edge Gate (map_type $02, Bazaar lower-right)
- **Requirement**: Starry Night ($00F1) + bring monster with summoning skill (NOT forfeited)
- **Script**: Bazaar script 22/23 — checks $00F1, $009E, $0040, then `cond_branch [$CA8D]==1`
- **Flags**: $009E = summoning check passed, $00F5/$00F6 = quest stages, $0040 = related
- **Engine variable**: `$CA8D` = party count == 1 (same refusal gate as the Well; S68 — the summoning check is flag $009E, engine-set)
- **Monster NOT forfeited** (unlike Bazaar/Well gates)

### Old Man's Gate (map_type $0D)
- **Requirement**: Starry Night ($00F1) + read journal to end + talk to girl + SHOW GoldSlime to Old Man
- **Script**: Old Man Gate script 2 — checks $00F1, $0025, $0035, $001D, then multiple `cond_branch [$C83C]==1` (YES/NO sequence). Script 7 checks $0107, $0106, $00F3, $00F1
- **Flags**: $0107 = gate open, $0106 = GoldSlime shown(?), $0105 = journal read, $00F3 = post-game milestone
- **Engine variable**: Monster showing likely uses $FF92 or $CA8D for GoldSlime species check

---

## 3. Queen's Quest (map_type $1F)

Access: Beat Goopi 1 in RPS (Crab, Log, Crab, Slime, Crab) → path opens to Queen Room.

Queen Room script 2 has a massive 16-tier flag ladder ($0126–$0157).
Each tier uses 3 flags in a group:

| Flag pattern | Purpose |
|-------------|---------|
| flag N+0 | Quest available (set by script when tier is reached) |
| flag N+1 | Monster shown correctly (engine-set after evaluation) |
| flag N+2 | Reward given (set by script after give_item) |

The check-only flags ($0128, $012B, $012E, etc.) are the "monster shown"
confirmations — set by the engine after evaluating whether the player
showed the correct bred monster. The engine evaluation for each tier
uses the monster-check opcodes ($30/$32/$34/$38/$3F/$5F).

### Queen Reward Tiers (from FAQ)

| Tier | Monster | Reward | Unlock requirement |
|------|---------|--------|--------------------|
| 1 | WingSlime | Sirloin | F class + breeding unlocked |
| 2 | KingSlime | INTseed | Medal Gate Boss |
| 3 | FloraJay | AGLseed | — |
| 4 | CurseLamp | DEFseed | — |
| 5 | Roboster | LifeAcorn | — |
| 6 | WildApe | ATKseed | — |
| 7 | HornBeet | MysticNut | — |
| 8 | Reaper | HorrorBK | — |
| 9 | Phoenix | CheaterBK | — |
| 10 | WhiteKing | ComedyBK | — |
| 11 | KingLeo | SmartBK | — |
| 12 | Trumpeter | BeNiceBK | — |
| 13 | Armorpion | QuestBK | — |
| 14 | Rosevine | LifeAcorn | — |
| 15 | GoldGolem | TinyMedal | — |
| 16 | Divinegon | TinyMedal | — |

**Warning**: Completing Divinegon tier prevents breeding with Milayou's Skeletor.

Script 3 (Queen's attendant) checks the same flags and gives hints.
Scripts 4/7 and 5/8 are paired NPCs that handle monster-show interactions
with Queen Room-specific flag patterns ($0063–$0067, $006D–$006E for
one set; $0086–$0088, $00A6–$00A8 for another).

---

## 4. Breeding NPCs (Window-Based Availability)

These NPCs offer their monster for breeding at specific story checkpoints.
Your monster is always the pedigree. Availability opens and closes with
story progression.

| NPC | Monster | Location | Opens | Closes | Key flags checked |
|-----|---------|----------|-------|--------|-------------------|
| Teto | IceMan (Kure) | Farm | E class | Anger cleared | $0032, $001D, $000D |
| Dob | CatFly (Fuga) | Farm | E class | Anger cleared | $0032, $001D |
| Mick | DeadNite (Lizd) | Farm | D class | D class arena done | — |
| Mick | LizardMan | Farm | E class | Anger cleared | Changes E class dialogue |
| May | Rayburn (Zee) | Farm | Anger | A class | $001D, $0036 |
| MedalMan | FangSlime (Moha) | Queen Room | Anger | S class | $001D, $0037 |
| Teto | Eyeder (Pach) | Farm | C/B class | A class | $0034/$0035 |
| Teto | Yeti | Farm | A class | Durran cleared | $0036, $0025 |
| MedalMan | Metaly | Farm | S class | Starry Night done | $0037, $00F1 |
| Milayou | Skeletor | Stable | Starry Night | Queen Divinegon done | $00F1, Stable scr16 |

Farm scripts involved: scr2 (Teto/Dob E-class window), scr17, scr21,
scr22, scr26, scr27 (S-class window with add_monster).
Stable script 16 (Milayou) checks ALL boss gate flags $0010–$002F to
determine exact story position.

---

## 5. Engine Evaluation Opcodes (DECODED)

The script engine has 4 skill/species-check opcodes. All share a common
structure: read 2 params (slot_index, branch_target), scan the selected
monster's data, branch if match found.

### Opcode $23 — CheckFireSkill (Bazaar Gate BBQ)
Scans 8 skill slots at offset $29 ($CAEA) in party monster data for:
| ID | Skill |
|----|-------|
| $00 | Blaze |
| $01 | Blazemore |
| $02 | Blazemost |
| $03 | Firebal |
| $04 | Firebane |
| $05 | Firebolt |
| $44 | FireSlash |
| $5C | FireAir |
| $5D | BlazeAir |
| $5E | Scorching |
| $5F | WhiteFire |

If match: writes slot index to $D8E1, copies species data to $C180, branches.
Used by: Bazaar scr22 (original Bazaar Gate fire monster check, 3 calls).

### Opcode $34 — CheckLightningSkill (Well Gate)
Same structure, checks for:
| ID | Skill |
|----|-------|
| $0F | Bolt |
| $10 | Zap |
| $11 | Thordain |
| $45 | BoltSlash |
| $5A | Lightning |

Used by: Well scr6/7 (Well Gate electric monster check, 6 calls total).

### Opcode $38 — CheckSummoningSkill (Bazaar Edge Gate)
Same structure, checks for:
| ID | Skill |
|----|-------|
| $84 | TatsuCall |
| $85 | DiagoCall |
| $86 | SamsiCall |
| $87 | BazooCall |

Used by: Bazaar scr23 (Bazaar Edge summoning check, 3 calls).
Note: these summoning skills map to boss species 216-219, explaining
why Bazaar scr7 checks $FF92 for values 215/216/217.

### Opcode $40 — CheckMonsterInStorage (Queen Room, Old Man Gate)
```
Params: species_id, branch_target
Loop all 20 storage slots ($CAC1, stride $95 = 149 bytes):
  Skip if slot[0] == 0 or 1 (empty/unavailable)
  If slot[+$09] == species_id → branch to target
Fall through if no match.
```
Slot offset +$09 = species byte (confirmed).

Used by:
- Queen Room scr2 (17 calls — one per reward tier)
- Old Man Gate scr7 (1 call — GoldSlime species ID = 19)

### Other monster opcodes used in scripts
| Opcode | Name | Used by | Purpose |
|--------|------|---------|---------|
| $27 | MonsterPartyOp2 | Arena Lobby, Castle | Party display setup (bank $01 entry 3/9) |
| $28 | CheckStorageFull | Farm, Restaurant, Stable | Branch if 20 monsters stored (pre-AddMonster guard) |
| $29 | AddMonster | Farm, Stable, Restaurant, Castle | Add monster by enemy stats ID |
| $2E | CheckStepVariable | Goopy Rooms, Arena Rooms | Read $D9DF/$D9E0 (RPS/arena state machine) |
| $31 | CheckPartyLevel | Library scr17 | Check $CA94 party level |
| $35 | ResetPartyOrder | Gate Priest | Reset party display order |
| $3F | CheckSpeciesInParty | Boss: Arena Left | Check $CACA for specific species |
| $45 | FullMonsterOp | Castle scr0 | Copy $CAB9→$CA8D, setup party display |
| $5F | CheckMultiSpecies | Farm scr29 | Check party species (multi-slot scan) |
| $60 | CheckInventoryItem | Starry Shrine | Check item at $CA40/$CB23 |
| $63 | MonsterSpecialOp | Castle scr0 | Bank $01 special operation |

### Unused monster opcodes (not in any decoded script path)
$18, $25, $2B, $30, $32, $55 — may exist in the 6.5% unreached script
paths or be dead code. $55 (MonsterGive) is notable as it might be the
"give monster without losing it" mechanism (vs $29 which adds to storage).

---

## 6. Remaining Unknowns

### Characterized this session (Santi)
GreatTree scr16 ($0080, $00AE, $00F2, $00F3, $00F4) = **Santi's progressive
dialogue**. Sprite 1 (small girl), screen 12 (bottom-left village near Starry
Shrine / Old Man Gate / Copycat House). Massive flag cascade with unique dialogue
every chapter. Late-game $FF92 species check for WingSnake(39)/Coatol(40)/
Orochi(41) is part of Old Man Gate quest flow. Walking cutscene = Santi leading
you to grandpa. GreatTree scr10 ($0080) also Santi-related.

### Flags still needing investigation (grouped)

**Arena internal state (27 flags)** — per-match/per-class tracking:
$000E, $000F, $003C, $0049, $004F, $0058, $0059, $005A, $005B, $007D,
$007E, $007F, $008A, $008B, $0091, $0095, $0096, $00A4, $00A5, $00B0,
$00B1, $00FD, $00FE, $00FF, $0100, $0119, $011C.
Arena Lobby scr0/6/7/10/11 and Arena Rooms scr23. Track match outcomes,
class registration, gate announcements. Low priority for editor (arena
system is engine-driven, not custom-scriptable yet).

**Castle cutscene progression (6 flags):**
$003A (Castle scr3 — early rewards, step $D92A changes + 2 items),
$003B (Castle scr4 — step $D92A changes + 2 items),
$003D (Boss Beginning scr1), $003E (Castle scr0 — gates room state),
$00AC (Castle scr13), $0118 (Castle scr10).
Likely: King interactions, minister scenes, GreatLog king visits.

**NPC dialogue progression (no tangible reward):**
$000A, $000B (GreatTree scr0/8), $009B, $009C (GreatTree scr3/7),
$00AD (GreatTree scr15), $0114 (GreatTree scr13) — GreatTree NPC states.
$005F, $0060 (Restaurant scr3) — Bartender rumor progression.
$0097 (Restaurant scr1) — Bartender dialogue state.
$0079, $007A (Bazaar scr9/10) — Bazaar NPC dialogue.
$009D (Bazaar scr14), $0112, $0115 (Bazaar scr4) — Bazaar NPC events.
$00A0, $00F8, $00FA (Gate Hub scr10/14/19) — gate door announcements.

**Sidequests with rewards (need full characterization):**
$0084, $0085, $0098, $011D (Restaurant scr4) — **May's breeding offers**
(3 stages, add_monster 314). Which flag = which stage TBD.
$004E (Stable scr14) — give_item. Likely early Pulio gift.
$0090 (Stable scr15) — give_item. Watabou/Warubou meat.
$0125 (Well scr8) — Well NPC post-quest dialogue.

**System flags (functional but not quest-related):**
$0000 (Intro Bedroom) — intro sequence marker.
$000C (Farm scr26) — breeding NPC precondition.
$0039, $010D (Monster School scr3/4) — school lecture states.
$0041, $0113, $0124 (Vault scr1/2) — Vault tutorial + usage.
$0043 (Secret Passage/GreatTree/Starry Shrine) — gates GreatTree room state.
$0046, $0104 (Egg Evaluator scr4/5) — egg evaluation events.
$00E3-$00E8 (Farm scr0/5/11/19/36) — Farm visual growth progression.
$007C (Farm scr17) — Farm NPC state.
$0109, $010A (Library scr13/14/15) — Library NPC progression.
$00A9, $00AA, $00AB (Boss Durran scr0) — Durran boss internal.

### Opcode $00/$01 name swap
Still unverified. If swapped, every cascading flag check reads as the
OPPOSITE condition. Does not affect flag set/clear behavior or branch-
following coverage, but affects human reading of script flow. Needs one
SameBoy test: set a known flag, trigger opcode $00, observe whether it
branches or falls through.

---

## Gaps for authoring a NEW campaign (Session 27)

Two of the campaign-authoring gaps live in this doc's domain. The full prioritized
list (E1–E6) is in ROADMAP "Phase E — Campaign-scale subsystems"; these two are the
story/arena keystones.

### Arena / gate-boss ROSTER format — DECODED S67 (ROADMAP E1) ✅ [arena path USER-VERIFIED S67 via SameBoy write-watchpoints: Class D registration wrote $DA02=$02 at $04:$5D8E with EIDs 251/252/253 ($E0+9*3+slot, exact formula match), regen fired at the bank $50 clone, and $DA09=$01 written by opcode $20 at $04:$5E69 from map $5D scr0 (DE=$61E4). Boss/coliseum trigger sites are ROM-byte-derived.]

**Owning section.** Machine-readable form: `extracted/arena_brackets.json`
(`tools/dump_arena_brackets.py`, self-checking ROM anchors). The system has FOUR
mechanisms; only the first two are "authored content", the rest are RNG.

**Battle-slot RAM (common to all):** enemy EIDs are 16-bit LE at
`$DA03/04`, `$DA05/06`, `$DA07/08`; **`$DA02` = enemy count − 1** (0/1/2);
`$DA09` = battle mode (0 = field-touch [bank `$06` `SetMapS_6ad7`], 1 =
scripted preset [$05/$20/$36], 2 = party-scaled random [$52], 3 = boss
[$5A/$5B]). *(Mode 1 + `$DA02` semantics USER-VERIFIED S67 on HW; modes
0/2/3 code-derived.)*

**1. ARENA — formula-addressed, no roster table exists.**
`ArenaBattleSetup` (script opcode `$1F`, `$04:$5D5B`; between-matches clone
`LoadArenaEnemyStats` `$50:$66D3ish/$6716-labelled`) computes
**`EID = $E0 + 9*wArenaGroup + 3*wColiseumBattle + slot`** (slot 0-2, 3 enemies).
So the arena rosters are **90 consecutive enemy-stats rows from EID 224**:
groups 0-7 = classes G F E D C B A S (3 matches × 3 monsters each), group 8 =
Starry Night (EIDs 296-304; final = MetalKing/Coatol/RainHawk L50), group 9 =
**King battle** — the formula result is overridden in code with EIDs
`$01E1-$01E3` (GoldSlime/Divinegon/Rosevine L70); group 9's formula rows
(EIDs 305-313, rival-species teams incl. Rayburn/Eyeder/DeadNite) are
unreachable cut data. `wArenaGroup` (`$D9CE`) is set by the bank `$09` lobby
class menu (`4*[$C8E3] + ([$C8E2]&$7F)`, availability bytes at `$C0D8`, entry
gold word table `$09:$5D23` = 0/10/50/100/500/1000/5000/10000 for G→S) — or
directly by Arena Lobby **scr6** (`write_ram $D9CE=8` + `$D999=1` for Starry
Night; `$D9CE=9` + `$D999=4` for the King), which then runs opcode `$1F` and
teleports to map `$5D` (Arena Battle). Map `$5D` scr0 stages the pre-fight
scene (master sprite from `ArenaMasterSpriteTable` `$04:$5E22`, 30×2
`[gfx_id, is_monster]`; dup `$50:$6778` without King rows) and launches with
opcode `$20`. Bank `$50` post-battle (`Jump_050_640a`, map `$5D` branch)
regenerates the next match's EIDs, handles loss (`wColiseumBattle=$FF`, warp
to lobby) and the Starry phase machine (`$D999` 0→1→2→3).

**2. GATE BOSSES — script-side EID params, no boss-selection table.**
Every boss room script triggers its fight with **opcode `$5A trigger_battle3
<EID>`** (single enemy, mode 3) or **opcode `$05 TriggerBattle <EID>`**
(single enemy, mode 1). The `$14:$4893` redirect table (34 pairs incl. the
non-boss `4→486` intro-Dracky entry) only maps **fight EID → join EID** for
recruitment — it does NOT drive which boss appears; `boss_table.json`'s
per-gate framing is positional coincidence. Multi-enemy exceptions write the
slots directly (`write_ram2`): **Temptation** = Centasaur 151 + Servant 149 +
EvilArmor 152 (`$DA02=2`, opcode `$5B`); **Durran phase 1** = Servant L55
(EID 342) ×2 (`$DA02=1`, opcode `$20`). The Durran gate is a 3-fight chain in
scr0: Servants ×2 → **Adult Terry EID 343 (`$0F:$4D46`)** → **Durran EID 199
(`$0F:$4DB8`)**; post-game Terry rematch = EID 343 again (`$0F:$500E`).
Other `$05` users: Digster/Arena-Left (127, scr1), Bewilder decoys (341 ×4),
Anger decoys (349 ×7), Castle intro demo Slime (480, 2 HP), and a previously
undocumented **MadGopher L21 event battle (EID 255)** from Castle scr13 +
Farm scr26. Medal Gate has THREE boss variants (EIDs 156/153/155 in scr1/2/3).
Tatsu EID 344 (species 216) appears unused (cut). Full site census with
script attribution: `arena_brackets.json → gate_boss_triggers`.

**3. IN-GATE COLISEUM (map `$52`) — RNG, level-banded, not authorable rosters.**
Opcode **`$5C ColiseumInitPrize`** (`$04:$6D93`; old label "HugeBattleSetup"
was wrong) generates the 3 foreign-master parties: 3 random EIDs each from a
window `base + rand(range)` keyed on **MAX** party level (bank `$16` twin
`SetBrd_5e38`, run at floor creation, keys on **AVERAGE** level). Bands
(below-level → base EID, range): 4→2×9, 10→13×18, 16→33×18, 22→57×18,
28→81×18, 34→105×18, 40→129×18, 46→157×18, else 181×18 — i.e. the wild-EID
space. Parties 2/3 staged at `$D9D1-$D9D6` / `$D9D9-$D9DE` (chained by
`SetBtl_67ae` `$50` as `wColiseumBattle` 0→1→2→3); prize item `$D9D0` rolled
from 16-byte tables `$04:$6F44` (<9 lifetime visits, counter `$D9CF`) /
`$6F54` (≥9).

**4. MIMIC + RANDOM-SCALED battles.** Opcode `$36 MimicBattleSetup`: word
table `$04:$63EF` (EIDs 317-324 = Mimic L1/5/10/20/30/38×3) indexed by
**`$CAB4` = arena-progress tier** — Arena Lobby scr0 writes `$CAB4 = class+1`
on every class victory, so chest Mimics scale with arena rank. Opcode
`$52 RandomScaledBattle`: word table `$04:$6A3C` (8 bases $0160-$01D0, tier =
(party level sum+1)/20 cap 7, EID = base + rand&$0F → EIDs 352-479).

**Per-class VICTORY cascade (Arena Lobby scr0, runs on lobby return with
`wColiseumBattle=$FE`).** Branches on `wArenaGroup` = the class just won:
sets the rank flag + catch-up flags for any skipped lower ranks, writes
`$CAB4 = class+1`, and batch-writes world step counters. Per class: **G**:
flag $0030; steps $D92B=0 $D92F=2 $D931=1 $D93C=3 $D941=1. **F**: $0031;
$D92F=3 $D931=2 $D933=1 $D93C=4 $D952-4=1. **E**: $0032 (+catch-up $0031,
$0049); $D93B=1 $D942=1. **D**: $0031+$0032+$0033 (+$0119 if E unseen);
$D92B=0 $D92F=3 $D931=2 $D933=1 $D93B=2 $D93C=4 $D942=1 $D952-4=1. **C**:
$0034; $D93B=3. **B**: $0035 (+catch-up $0034); $D939=1 $D93D=1 $D945=1
$D946=1 $D947=2 $D963=1 $D964=1. **A**: $0036 (+catch-ups $0035/$0034);
$D93D=2. **S**: $0034-$0037 all (+$011C if A unseen); $D92B=0 $D936-8=2
$D939=2 $D93B=3 $D93D=3 $D945/6=1 $D947=2 $D963/4=1. Registration/announce
flags $0059/$005A/$007D/$00FD are set by scr0/scr6 (part of the "arena
internal state" 27-flag group in §6, still only partially characterized).

**AUTHORING SPEC (for project.json later):** an arena bracket = 90+3
enemy-stats rows (224-304 + 481-483): edit species/level/stats/skills
per row — position in the block IS the (class, match, slot) address; changing
bracket SHAPE (more matches/classes) means patching the `$1F`/`$50` formula
constants (multipliers 9/3, base $E0). A gate boss = the `$5A`/`$05` param in
its boss-room script + its enemy-stats row + the redirect pair (fight→join) +
optionally the `$14:$4C1D` join-version row. Coliseum/Mimic difficulty =
the band tables above (same-size edits).

**Residual (banked, minor):** (a) `$DA09` mode **1** + `$DA02` semantics are
USER-VERIFIED S67 on HW (arena path); modes 0/2/3 remain code-derived;
(b) the intro Dracky fight (EID 4, redirect 4→486) has no script-side
trigger — engine-forced during the intro (bank `$2D` per `$CAB9` note);
(c) matches 2/3 re-entry: HW showed the bank `$50` clone firing post-battle
as predicted; the full loop wasn't single-stepped but is consistent.

### Story progression ENGINE + AUTHORING SPEC — DECODED S68 (ROADMAP E2 RE half)

**Owning section.** Everything below is ROM-byte-verified statically (S68);
in-game/SameBoy confirmation points are marked. Bank `$50` battle-machine
annotation: `disassembly/bank_050.asm` header + `BattlePhaseTable` (S68).

**The engine guarantee that makes story authorable.** The game's top-level
mode is `wGameMode $C88A` (ROM0 dispatch: `$00:$030F` init / `$00:$050F`
per-frame; mode 1 = field bank `$01`, mode 2 = battle bank `$50`). A battle
trigger (wild `set 6,[wGameState]`, or a script battle opcode) is a request
LATCH consumed by the bank `$13` `$C905` transition machine ($13:$73F5 does
the ROM's only `res 6`, sets mode 2). The script VM's state (`$D8D5/6`
counter, `$D8D7` flags) lives in WRAM and is untouched by battle. On battle
end, `BattleExitHandler` (`$50:$640A`, battle phase `$0E`) restores mode 1
and sets bit 7 of `$C8EA` ("field live"); bank `$01`'s `ClearAnimationState`
skips its state reset whenever `$C8EA != 0`, so **the NPC script resumes at
the command after the battle opcode — on the WIN path only**:

- **WIN** (`$DB55==0`, set by bank `$52`'s end-of-round KO scan ~`$52:$7727`):
  exp/level/join phases `$0A-$0D` run, then exit; script resumes → the
  commands after `trigger_battle` (set_flag / write_ram / dialogue /
  teleport) ARE the "on-win" rewards. This is how every vanilla boss script
  works (Watabou dialogue → opcode `$0F` teleport to the throne room →
  castle step counters), and it is an engine guarantee, not a convention.
- **LOSS** (`$DB55==1`, all party KO'd ~`$52:$76E0`): no exp/join
  (`$DB55!=0` skips both in phase `$0A`); `BattleExitHandler` writes
  `$D92B=8` (Castle "rescued" step state), engine-warps to the Castle via
  the opcode-`$0F` cells (`$C96D-$C972`, `$C96C=1`), **halves 24-bit gold**
  `$CA4B-4D` (`$1E1E` a=2), and drops every inventory item whose info-record
  byte `+$0B` bit 2 is clear (**keep-on-defeat** items: TinyMedal, BeastTail,
  WarpStaff, ShinyHarp, BookMark — table `$03:$71DA`, 12 B/item, id×12;
  FAQ's keep-list verified + BookMark), clears `$C8EA` bit 7 and `$D8D7`
  → full fresh room entry, script gone. The boss re-arms from its step
  counters on revisit. (Arena map `$5D` / Coliseum `$52` / `$DA09==2` take
  special branches — see the E1 section above — and also clear `$D8D7`.)
- `$DB55` = 0 win / 1 loss / 2 undecided; XOR'd for the link peer at
  `$52:$774F` (`$C863.1`). `wBattlePostFlag`'s old "always 0 for bosses"
  comment was a win-path observation. On loss `$DB73=$FF` freezes the phase
  machine for the defeat jingle/fade (released at `BattlePhaseFreezeWait`).

**The condition vocabulary (what a quest can TEST).** `cond_branch`
(opcode `$15`) reads any RAM cell; the engine-maintained cells scripts use:
event flags (opcode `$03` check), step counters (`$D92A-$D99A`), `$C83C`
YES/NO answer, **`$CA8D` = party count**, **`$FF92`/`$FF95` = player X/Y**
(position gates), story bytes (`$D9E3` etc.), and **`$D8E1` = ScriptTemp**,
the result cell of the EVALUATOR OPCODE FAMILY (all bank `$04`, S68 census
of every `$D8E1` writer): `$23` (`+$6D`), `$30`, `$32` (species via slot →
`$CACA`-family field reads), `$34` (species-vs-list tiers; Library),
`$38`, `$59`, `$5F` (per-monster field reads, slot param bounded by
`$CA8D`), **`$51`** (counts SEEN library bits `$CA94`, 0-$EF → 12-tier
compare table `$04:$699D`), **`$55`** (counts non-empty item slots
`$CA51`×20), **`$56`** (24-bit gold ÷10 magnitude test). Opcode `$45`
(`$04:$67B1`) = restore party list from the 7-byte snapshot `$CAB9-$CABF`
(count + 3 party ids + 3 follower gfx) — the party-borrowing mechanism's
other half (the snapshot writer is engine/script-side; trace when needed).

**The action vocabulary (what a quest can DO).** Set/clear flags
(`$00/$01`), write step counters / any RAM (`$12`/write_ram), dialogue,
YES/NO (`$E7 $F0`+`$15` on `$C83C`), give item/monster/egg
(`$2A/$2C/$29/$28`), battles (`$05/$5A/$5B/$20/$1F/$36/$52`), teleport
(`$0F`), BGM (`$41`), NPC movement — ALL already proven in custom rooms.

**AUTHORING SPEC (E2 wiring; project.json).** Story progression for a
NEW-WORLD campaign needs zero new engine work: a `progression` schema layer
that *generates scripts* through the existing compiler. Proposed shape:
`progression.quests[]` = `{id, room, trigger (npc/step/entry), requires
[flag/step/evaluator conditions → generated cond_branch ladder], battle
{eid, opcode, join_redirect}, on_win [set_flag / write_step / teleport /
dialogue → generated post-battle command tail], on_refuse/alt branches}`.
The compiler emits: the room's entry/NPC script bodies (condition ladder +
battle opcode + on_win tail), flag allocations from the safe pool, and
step-counter writes — exactly the vanilla pattern, machine-generated.
**Recommendation (user Q, S68):** do NOT hand-edit vanilla story data;
author new spines in custom rooms via generated scripts and keep vanilla
intact as postgame (Layer A′). Arena-progress gating survives as-is: the
per-class victory cascade is Arena Lobby scr0 SCRIPT content (E1 section),
so a rewritten campaign re-authors that script and keeps the arena engine.
**Capacity caveat:** persistent custom state today = 32 safe flags (+ step
counters via the compiler pool are TRANSIENT — CF4); a campaign-sized spine
(≈20+ quests × several flags) wants either E3 (SRAM expansion) or reuse of
vanilla flag indices freed by the rewritten story — reuse requires the
EVENT_FLAGS engine-literal audit per index (S57 lesson).

**HW-pinned S68 (user SameBoy session):** (a) RESOLVED — `$C899/$C89A`
stay the LIVE, per-frame-advancing RNG pair during battle (two adjacent
examines differ), so `LoadBtl_5d29`'s `&$1F==$1F` checks are a
**1/32-per-side random battle-intro event roll** (player-side variant:
messages 3-8 via `$6AA0`, +1 phase skip, `$DB55=0`; enemy-side: messages
9-14, +2 phase skip, `$DB88=4`, `$DB55=1` — likely the sleep/surprise
intros; message text unchecked). `$DB55` doubles as that intro-event
marker until the bank `$52` KO scans overwrite it with the outcome.
(b) **FLEE ends at `$DB55=2` (neutral)** — resolver `$50:$5808` (via the
`$D9F5` sub-dispatch, backtrace `$6067→$5715`): jumps straight to phase
`$0A`, masks the exp targets `$DD1F-22 = $FF` → no exp/join AND no loss
penalty; edge: if `$DB73` is already armed the flee converts to loss (=1).
(c) **Caught monster = plain WIN** (`$52:$7729` writes 0 via the phase-7
turn-engine chain, backtrace-verified) → join runs through phase `$0D`.

**Residuals (banked, minor):** the `$CAB9` snapshot WRITER not yet traced;
`$C8ED` follower-suppression mask = cosmetic (boss win `$DA09==3` sets
`$0E`, bank `$01` keeps it only while `$D92B==7`); loss-path 20-slot item
loop uses bank `$03` entry 2 info fetch per item — verified from the
attribute table, not stepped; intro-event message text (3-14) unchecked.

---
*Compiled from branch-following script analysis + FAQ game knowledge.*
*Engine evaluation opcodes are the primary remaining work for editor support.*
