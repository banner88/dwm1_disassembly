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
- **Engine variable**: $FF92 holds species/evaluation result (values 215/216/217 — needs investigation; may be skill check, not species)
- **Monster forfeited**: Yes (lost forever, e.g. Gremlin)

### Well Gate (map_type $18, screen 4 = $D960)
- **Requirement**: E class ($0032) + forfeit a monster with a Lightning-type skill
- **Script**: Well script 6/7 — checks $006A, $005E, $005D, $0032, $0031, then `cond_branch [$CA8D]==1`
- **Flags**: $005E = lightning check passed (engine-set, 4 checks), $006C = monster given, $006A = quest seen, $005D = quest started
- **Step counter**: $D960 = 1 (Well screen 4 changes to show gate)
- **Engine variable**: $CA8D = 1 means "selected monster has required skill"
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
- **Engine variable**: $CA8D = 1 (has summoning skill)
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
*Compiled from branch-following script analysis + FAQ game knowledge.*
*Engine evaluation opcodes are the primary remaining work for editor support.*
