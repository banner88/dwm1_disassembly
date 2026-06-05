# DWM1 Hacking Discoveries — Complete ROM Map

All addresses verified through SameBoy debugging. Flat ROM offsets given for `edits.json` `raw_bytes`.

---

## Table of Contents

1. [Party Monster Data](#party-monster-data)
2. [Starter Monster](#starter-monster)
3. [Encounter System](#encounter-system)
4. [Boss System](#boss-system)
5. [Gate System](#gate-system)
6. [Event System Architecture](#event-system-architecture)
7. [Join Mechanism — SOLVED](#join-mechanism--solved)
8. [Key ROM Functions](#key-rom-functions)
9. [Key RAM Addresses](#key-ram-addresses)
10. [ROM Table Map](#rom-table-map)
11. [Bank Map](#bank-map)
12. [Debug Mode](#debug-mode)
13. [SameBoy Quick Reference](#sameboy-quick-reference)
14. [Open Questions](#open-questions)

---

## Party Monster Data

Each party monster record is **149 bytes ($95)**. Up to 20 monsters in storage, 3 active.

| Offset | RAM (Mon 1) | Size | Field |
|--------|-------------|------|-------|
| +$00 | $CAC0 | 1 | Unknown |
| +$01 | $CAC1 | 1 | Event counter / flag |
| +$02 | $CAC2 | 8 | Monster nickname (text-encoded, $F0 padded) |
| +$0A | $CACA | 1 | **Monster species ID** |
| +$4C | $CB0C | 1 | Level |
| +$4E | $CB0E | 3 | Experience |
| +$50 | $CB10 | 2 | Current HP |
| +$58 | $CB18 | 2 | ATK |
| +$5A | $CB1A | 2 | DEF |
| +$5C | $CB1C | 2 | AGL |

Monster N starts at `$CAC0 + N × $95`.

---

## Starter Monster

The starter uses **enemy_stats_id 1** from the enemy stats table.

| Flat ROM | Offset | Field | Default |
|----------|--------|-------|---------|
| 0x50C36 | +0 | Monster species ID | $08 (Slime) |
| 0x50C3A | +4 | Level | $01 |
| 0x50C3B | +5,6 | HP (LE) | $1E $00 (30) |
| 0x50C3D | +7,8 | MP (LE) | $00 $00 |
| 0x50C3F | +9,10 | ATK (LE) | $0A $00 (10) |
| 0x50C41 | +11,12 | DEF (LE) | $06 $00 (6) |
| 0x50C43 | +13,14 | AGL (LE) | $05 $00 (5) |
| 0x50C45 | +15,16 | INT (LE) | $01 $00 (1) |

---

## Encounter System

### Index Chain: Gate → Floor → Monster Pool

1. **Gate offset array** at $01:$6A22 (32 bytes) — `gate_index[gate]` = base pool offset
2. **Floor threshold pointers** at $01:$6A42 (32 × 2-byte LE ptrs)
3. **Pool blocks** at $01:$6AAE (32 × 26 bytes)

### 26-Byte Encounter Block Format

| Offset | Size | Field |
|--------|------|-------|
| 0 | 1 | Encounter rate parameter |
| 1 | 1 | Floor difficulty level |
| 2–9 | 8 | Secondary encounter data |
| 10–11 | 2 | Monster slot 1: enemy_stats_id (LE) |
| 12–13 | 2 | Monster slot 2: enemy_stats_id (LE) |
| 14–15 | 2 | Monster slot 3: enemy_stats_id (LE) |
| 16–17 | 2 | Monster slot 4: enemy_stats_id (LE, 0=empty) |
| 18–19 | 2 | Padding |
| 20 | 1 | Weight for slot 1 |
| 21 | 1 | Weight for slot 2 |
| 22 | 1 | Weight for slot 3 |
| 23 | 1 | Weight for slot 4 |
| 24–25 | 2 | Footer (always $00 $08) |

### Enemy Stats Table

At `$14:$4C1D`, **25 bytes per entry**, 487+ entries verified.

| Offset | Size | Field |
|--------|------|-------|
| 0 | 1 | Species ID |
| 1-3 | 3 | Unknown |
| 4 | 1 | Level |
| 5-6 | 2 | HP (LE) |
| 7-8 | 2 | MP (LE) |
| 9-10 | 2 | ATK (LE) |
| 11-12 | 2 | DEF (LE) |
| 13-14 | 2 | AGL (LE) |
| 15-16 | 2 | INT (LE) |
| 17-23 | 7 | Unknown |
| 24 | 1 | Delimiter ($FF) |

Flat offset for EID N: `0x50C1D + N × 25`

---

## Boss System

### Boss Table

At `$14:$4897`, **4 bytes per entry**, **33 entries** (gates 0–31 + 1 cut content entry).

| Byte | Field |
|------|-------|
| 0 | Fight EID (enemy_stats_id for the boss battle) |
| 1 | Always $00 |
| 2-3 | Join EID (16-bit LE, monster that joins party after defeat) |

Flat offset for gate G: `0x50897 + G × 4`
- Fight EID: `0x50897 + G × 4`
- Join EID: `0x50897 + G × 4 + 2`

**Verified boss fight EIDs** (via watchpointing $DA03):
- Gate 0: EID 11 (Healer), Gate 1: EID 31 (Dragon), Gate 2: EID 32 (Golem)
- Gate 3: EID 51 (MadCat), Gate 4: EID 53 (FaceTree)

**Boss table found** by brute-force searching ROM for known EIDs at regular stride (`tools/find_boss_table.py`).

### Boss Floor Array

At `$16:$70A6`, **8 bytes per gate**, 32 entries.

| Byte | Field |
|------|-------|
| 0 | Difficulty tier A |
| 1 | Difficulty tier B |
| 2 | Encounter pool base |
| 3 | **Floor count** |
| 4 | Boss room map_type ($30-$4F range) |
| 5-6 | Unknown (position/parameters) |
| 7 | Gate era flag ($01 = early gates 0–5, $02 = later gates) |

Flat offset: `0x5B0A6 + G × 8`

**Note:** Gate 31 (Old Man's Gate) has floor count = 99 in ROM data, but the game triggers the boss fight at floor 30 via event scripts. The GameShark code to access this gate ($C935 = $1F) bypasses the event trigger, resulting in "99 floors, no boss" as documented by TCRF.

### Boss Loading Code Flow

```
$6D66: CALL $71EF          ; dispatch to boss loader based on $D8D3 tier
$71EF: dispatches to banks $0C/$0D/$0E/$0F based on gate range
Returns boss EID in register C
$6D69: LD a, c
$6D6A: LD [$da03], a       ; write fight EID to battle enemy slot
```

---

## Gate System

### Gate ID → Gate Name Mapping (ROM-verified via boss species matching)

| ID | Gate Name | Boss | Floors |
|----|-----------|------|--------|
| 0 | Gate of Beginning | Healer | 5 |
| 1 | Gate of Villager | Dragon | 5 |
| 2 | Gate of Talisman | Golem | 6 |
| 3 | Gate of Memories | MadCat | 5 |
| 4 | Gate of Bewilder | FaceTree | 6 |
| 5 | Bazaar Gate | MadKnight | 9 |
| 6 | Gate of Peace | FangSlime | 8 |
| 7 | Gate of Bravery | BigEye | 9 |
| 8 | Well Gate | Gigantes | 12 |
| 9 | Gate of Strength | StoneMan | 11 |
| 10 | Gate of Anger | BattleRex | 11 |
| 11 | Farm Gate | Copycat | 12 |
| 12 | Gate of Joy | FunkyBird | 14 |
| 13 | Gate of Wisdom | SkyDragon | 15 |
| 14 | Arena - Left Gate | Digster | 16 |
| 15 | Gate of Happiness | Jamirus | 18 |
| 16 | Gate of Temptation | Servant | 20 |
| 17 | Medal Gate | KingSlime | 19 |
| 18 | Gate of Labyrinth | DarkHorn | 23 |
| 19 | Gate of Judgement | Akubar | 25 |
| 20 | Library Gate | Orochi | 25 |
| 21 | Gate of Reflection | Durran | 29 |
| 22 | Gate of Ambition | DracoLord | 30 |
| 23 | Gate of Demolition (Hargon) | Hargon | 29 |
| 24 | Gate of Demolition (Sidoh) | Sidoh | 27 |
| 25 | Gate of Mastermind | Baramos | 30 |
| 26 | Gate of Control | Zoma | 30 |
| 27 | Gate of Extinction | Pizzaro | 30 |
| 28 | Gate of Sleep | Esterk | 30 |
| 29 | Bazaar Edge Gate | Mirudraas | 27 |
| 30 | Arena - Right Gate | Mudou | 30 |
| 31 | Old Man's Gate | DeathMore | 99* |
| 32 | Cut Content | EID 221 | 0 |

*99 in ROM but game triggers boss at floor 30 via event scripts.

**Note:** Internal gate ID order differs from gameplay unlock order. Gate of Demolition uses TWO boss table entries (23=Hargon, 24=Sidoh) for its two sequential bosses. The GameShark code `011F35C9` sets $C935=31, accessing Old Man's Gate data but without proper event initialization.

---

## Event System Architecture

### Overview

The event system uses a **multi-layer dispatch** architecture:

```
Main Game Loop ($00:$03B6 → $046E → $053A)
  ↓ RST $10 dispatch
Bank $50 Function $01 (entry: $5E21) — per-frame event update
  ├── CALL $3001 — battle flag processing
  ├── CALL $6D78 — play timer ($CAB5-$CAB8)
  ├── Battle result display ($DA80=1 → table at $5E84 → $1577 renderer)
  ├── $5F2F: check $DB73 (gate, $FF=skip)
  │   ↓ if $DB73 ≠ $FF
  │   $5F36: RST $00 dispatch on $D9EC (15-entry table at $5F3A)
  │     ├── States $00-$09: pre/during battle events
  │     ├── State $0A: post-battle setup + experience calc
  │     ├── State $0B: level-up loop (single INC → $0C, double INC → $0D)
  │     ├── State $0C: level-up display per monster ($51:fn$0C, loops back to $0B)
  │     ├── State $0D: join dispatcher → $6405 → $51:fn$0E ($5C33)
  │     └── State $0E: post-join cleanup
  │
  │   After double INC ($0B→$0D):
  │     $6332: call $54:fn$07 ($55BB) — join/no-join decision
  │       ├── $DB85 == $07 → INC $D9EC to $0E (skip join)
  │       └── $DB85 ≠ $07 → RNG probability → join or skip
  │
  └── State $0D calls: $50:$6405 → $51:fn$0E ($5C33) — 30-state join sub-machine
```

### RST Dispatch Mechanisms

**RST $10** — Cross-bank function call:
- HL high byte = bank number, HL low byte = function index
- Each bank has a function pointer table at $4000 (byte 0 = bank ID, then 2-byte LE pointers)
- Example: `LD HL, $510E; RST $10` → bank $51, function $0E → $51:$5C33

**RST $00** — Table-driven dispatch (at $00:$0000):
```
POP HL          ; HL = table address (after RST $00 instruction)
ADD A           ; A = state × 2
ADD L / LD L    ; index into table
LD A, [HL+]     ; read handler low byte
LD H, [HL]      ; read handler high byte
LD L, A         ; HL = handler address → jump there
```

### Bank $50 Main Dispatcher

At `$50:$4017`:
```
LD a, [$d9f4]   ; read main event state
RST $00         ; dispatch through 11-entry table at $401B
```

**Main event state table** (11 entries, states 0-10):

| State | Handler | Purpose |
|-------|---------|---------|
| 0 | $4031 | |
| 1 | $40ED | |
| 2 | $4114 | |
| 3 | $41EE | |
| 4 | $4215 | |
| 5 | $425E | |
| 6 | $426E | |
| 7 | $4301 | |
| 8 | $43A7 | |
| 9 | $41E0 | |
| 10 | $59D6 | Script executor: loads ptr from $DB58, calls $56F1 (screen fade), sets $D9F4 from $DB5A |

### Bank $50 Function Table

| Fn | Addr | Purpose |
|----|------|---------|
| $00 | $5DC9 | |
| $01 | $5E21 | Per-frame event update (main entry) |
| $02 | $5E49 | |
| $03 | $6053 | |
| $04 | $7C4D | |
| $05 | $768E | |
| $06 | $79EB | |
| $07 | $59EB | |
| $08 | $5B58 | |

### Bank $51 Function Table

| Fn | Addr | Purpose |
|----|------|---------|
| $00 | $423E | |
| $01 | $43F4 | |
| $02 | $4A96 | |
| $03 | $4BE8 | |
| $04 | $4CB3 | |
| $05 | $4D16 | |
| $06 | $4E5E | |
| $07 | $4FAA | |
| $08 | $50F6 | |
| $09 | $524A | |
| $0A | $46AA | |
| $0B | $44A9 | |
| $0C | $5578 | |
| $0D | $5B31 | |
| **$0E** | **$5C33** | **Join handler (sub-state machine)** |
| $0F | $537A | |

### Sub-state Dispatcher at $50:$5712

Uses `$D9F5` (not $D9F4) for sub-state dispatch:
```
LD a, [$d9f5]
RST $00
[sub-state table at $5716]
```

Sub-state entries: $571E, $57A8, $5831, $583B

---

## Join Mechanism — SOLVED

### Overview

The join/no-join decision is made by `$54:fn$07` (`$54:$55BB`), called at the end of
the post-battle level-up processing loop. The decision depends on `$DB85` (per-enemy
joinability flag): value `$07` = "non-joinable," anything else = recruitable via
RNG probability. Story bosses (Healer, FaceTree, etc.) have `$DB85 = $00` and join
through the natural probability path. Non-story bosses have `$DB85 = $07`.

### Post-Battle State Machine ($D9EC)

The dispatch table at `$50:$5F3A` is gated by `$DB73` at `$50:$5F2F`:
```
5f2f: LD a, [$db73]    ; gate flag
5f32: CP $ff
5f34: JR z, $5f5e      ; $FF → skip entire dispatch
5f36: LD a, [$d9ec]    ; post-battle state
5f39: RST $00          ; dispatch via table at $5F3A
```

**15-entry dispatch table** at `$50:$5F3A`:

| State | Handler | Purpose |
|-------|---------|---------|
| $00 | $5F6D | |
| $01 | $5F93 | |
| $02 | $5FAE | |
| $03 | $5FC1 | |
| $04 | $6051 | |
| $05 | $606F | |
| $06 | $6079 | |
| $07 | $60B6 | Post-battle init dispatch |
| $08 | $60CB | |
| $09 | $6AAC | |
| $0A | $60ED | Post-battle setup: experience calc, party processing init |
| $0B | $62F0 | Level-up check loop: check each monster, route to $0C or $0D |
| $0C | $63C1 | Level-up display: calls $51:$5578 (fn$0C) per monster |
| $0D | $63D2 | Join dispatcher: if $DD61 ≠ $FF, load EID + call join handler |
| $0E | $640A | Post-join cleanup |

### Post-Battle Flow (Verified via watchpoints)

**Transition: Battle End → Post-Battle**
Bank `$52:$7773` sets `$D9EC = $0A` (called from `$52:$710E` via `$50:$60B9`, state $07).
Also copies `$DB55` to `$DD6B` at this point.

**State $0A ($60ED) — Post-Battle Setup**
```
60ed: wait for UI ($C825)
60f2: set $C89B-$C89D values
60fd: check $DB4E (== 2 → call $52:fn$01, set delay)
611d: CALL $774E, $79AE, $768E — setup functions
6126: check $C86C (special event flag — always 0 for both story and non-story bosses)
6139: CALL $5C40
613c: call $51:fn$02 ($4A96)
6140: check $DB55 (always 0 for both story and non-story bosses)
6150: check $DD23-$DD25 (experience data — non-zero for both boss types)
6159: CALL $61E2 — experience distribution to party
6192: INC $D9EC → advance to $0B
```

**Key finding:** `$DB55`, `$DB73`, and `$C86C` are NOT the join decision variables.
Both story bosses (Healer) and non-story bosses (BigEye) have identical values
for all three. Both take the same path through state $0A.

**State $0B ($62F0) — Level-Up Check Loop**

This state checks if any party/storage monsters need level-up processing:

```
62f0: wait for UI ($C825)
62f5: check party slot 1 ($CA8E) via $6383
62fb: JR nc, $630d     ; if needs processing → single INC
62fd: check party slot 2 ($CA8F)
6303: JR nc, $630d
6305: check party slot 3 ($CA90)
630b: JR c, $6316      ; if ALL done → check storage
630d: INC $D9EC         ; SINGLE INC: $0B → $0C (level-up display)
6311: LD [$D9F4], 0     ; reset join sub-state
6315: RET

6316: loop through all 20 storage slots via $6383
6326: LD hl, $d9ec
6329: INC [hl]          ; DOUBLE INC: $0B → $0C
632a: LD hl, $d9ec
632d: INC [hl]          ;             $0C → $0D (skip level-up, go to join)
632e: XOR a
632f: LD [$d9f4], a
6332: LD hl, $5407      ; call $54:fn$07 (join decision)
6335: RST $10
6336: RET
```

**$6383 — Monster Slot Eligibility Check:**
```
6383: CP $ff            ; empty slot?
6385: JR z, $63a2       ; → return carry (skip)
6387: store slot index to $CAC0
638a: check level at $CB0C + A × $95
6391: CP $63            ; level 99?
6393: JR z, $63a2       ; → return carry (skip)
6395: check event flag at $CAC1 + A × $95
639f: OR a              ; flag == 0?
63a0: JR nz, $63a4      ; non-zero → return NC (needs processing)
63a2: SCF               ; carry = "done/skip"
63a3: RET
63a4: call $13:fn$00    ; process level-up, return NC
```
Returns: carry = "already processed/skip," NC = "needs level-up processing."

**The Level-Up Loop:**

When a monster needs processing (NC → single INC to state $0C):
```
State $0C ($63C1): calls $51:fn$0C ($5578) — level-up display handler
$51:$5578 shows level-up text/animations, then sets $D9EC = $0B
→ Back to state $0B → check next monster → repeat
```
This loop repeats once per monster that leveled up (e.g., 3 times if 3 monsters leveled).
When all monsters are processed (all return carry), the double INC fires.

**State $0C ($63C1) — Level-Up Display Handler**
```
63c1: LD a, [$db55]    ; always 0 for bosses
63c4: OR a
63c5: JR nz, $63cc     ; if non-zero → set $D9EC=$0E (skip)
63c7: LD hl, $510c     ; call $51:fn$0C ($5578) — level-up display
63ca: RST $10
63cb: RET
63cc: LD a, $0e        ; skip path
63ce: LD [$d9ec], a
63d1: RET
```
`$51:$5578` is the level-up display handler (NOT the join handler as previously
theorized). It runs over multiple frames and sets `$D9EC = $0B` when done,
creating the per-monster loop.

**State $0D ($63D2) — Join Dispatcher**
```
63d2: LD a, [$d9f4]    ; check join sub-state
63d5: CP $24           ; == 36 (done)?
63d7: JR z, $63de      ; skip UI wait if done
63d9: wait for UI ($C825)
63de: LD a, [$dd61]    ; join enemy index
63e1: CP $ff           ; $FF = no enemy
63e3: JR nz, $63ea     ; if valid → load EID and join
63e5: INC $D9EC        ; no enemy → advance to $0E (skip)
63e9: RET
63ea: index into $DA03 using ($DD61 - 4) × 2
63f0: load enemy_stats_id to $DA12-$DA13
6401: call $14:fn$06 ($1406) — enemy stats loader
6405: call $51:fn$0E ($5C33) — 30-state join sub-machine
6409: RET
```
State $0D fires every frame while the join sub-machine runs. When the join
sub-machine completes (state 21 adds monster, then exits), `$51:$67A5` sets
`$D9EC = $0E`, ending the join sequence.

### Join Decision Function — $54:fn$07 ($55BB)

Called at `$50:$6335` after the double INC. Decides whether the defeated enemy joins.

```
55bb: CALL $12d0          ; PRNG
55be: LD a, [$dd61]       ; join enemy index (4 = enemy 1)
55c1: OR a
55c2: JR z, $5609         ; 0 → skip (no enemy set)

55c4: AND $03             ; mask to 0-3
55c6: LD hl, $db85        ; per-enemy joinability array
55c9-55ce: HL = $DB85 + ($DD61 & 3)
55cf: LD a, [hl]          ; load joinability flag
55d0: LD [$db4d], a       ; store copy to $DB4D
55d3: CP $07
55d5: JR z, $5609         ; ★ $07 = NON-JOINABLE → skip

55d7-55e3: load probability data from $DC3C + $DD61
55e4: CALL $267e          ; probability computation
55ea-55f8: setup and dispatch
5604: CALL $5683          ; ★ final RNG probability check
5607: JR c, $560d         ; carry = JOIN → RET (stay at $0D)

5609: LD hl, $d9ec        ; no join:
560c: INC [hl]            ; $D9EC++ → $0E (skip join)
560d: RET
```

**Three gates in $54:fn$07:**

1. `$55C2`: `$DD61 == 0` → skip (no enemy to join). **Functional, keep.**
2. `$55D5`: `[$DB85] == $07` → skip (non-joinable boss). **This is the boss gate.**
3. `$5607`: `$5683` probability check → skip if RNG fails. **This is the wild monster gate.**

### Verified Values

| Variable | Healer (joins) | BigEye (doesn't join) |
|----------|----------------|----------------------|
| $DB73 | $01 | $01 |
| $DB55 | $00 | $00 |
| $C86C | $00 | $00 |
| $DD61 | $04 | $04 |
| $DB85 | $00 | **$07** |
| $DB4D | $00 | **$07** |
| $DD23-25 | non-zero | $DC $05 $00 |

**$DB85 is the sole differentiator.** Both boss types have identical values for all
other state variables. `$DD61 = 4` (enemy 1 joins) is set for ALL bosses during
battle setup, confirming the join buffer ($D665) is populated for non-joining bosses.

### $D9EC Progression (watchpoint verified)

**Healer (story boss, $DB85=$00):**
```
$0A (bank $52 init) → $0B (state $0A INC) → $0C,$0D (double INC at $6326)
→ $54:fn$07 returns without incrementing ($5683 carry = natural join)
→ state $0D dispatches join handler → $0E (join complete, $51:$67A5)
```

**BigEye (non-story boss, $DB85=$07):**
```
$0A (bank $52 init) → $0B (state $0A INC)
→ $0C (single INC, monster 1 leveled) → $0B ($51:$5578 resets)
→ $0C (single INC, monster 2 leveled) → $0B ($51:$5578 resets)
→ $0C (single INC, monster 3 leveled) → $0B ($51:$5578 resets)
→ $0C,$0D (double INC, all done)
→ $54:fn$07 sees $DB85=$07 → INC $D9EC → $0E (skip join)
```

### Per-Gate Join Patch (IMPLEMENTED)

Custom routine in bank $54 free space that intercepts the join decision:

**Hook code (3 ROM locations):**
- `$54:$55D5` (flat `0x1515D5`): NOP the `$DB85 == 7` early exit (2 bytes: `00 00`)
- `$54:$5604` (flat `0x151604`): redirect CALL to custom routine (`CD C8 7F`)
- `$54:$7FC8` (flat `0x153FC8`): 24-byte custom routine

**Custom routine at `$54:$7FC8`:**
```
CALL $5683        ; original probability check (wild monsters)
RET C             ; natural join → return carry
LD a, [$DB4D]     ; boss flag (copy of $DB85)
XOR $07           ; Z if $DB4D == 7, ALWAYS clears carry
RET NZ            ; not a boss → return (no carry = normal skip)
LD a, [$C935]     ; current gate ID
LD hl, $7FE0      ; per-gate join table
ADD l
LD l, a           ; HL = $7FE0 + gate_id
LD a, [hl]        ; load flag (01 = force join, 00 = no)
OR a
RET Z             ; 0 → no join
SCF               ; non-zero → set carry (force join)
RET
```
Bytes: `CD 83 56 D8 FA 4D DB EE 07 C0 FA 35 C9 21 E0 7F 85 6F 7E B7 C8 37 C9`

**Per-gate table at `$54:$7FE0`** (flat `0x153FE0`): 32 bytes, one per gate (0-31).
`$01` = boss forced to join after defeat, `$00` = default behavior.

**Critical: `XOR $07` not `CP $07`.** `CP $07` sets carry when A < 7, causing
wild monsters ($DB4D = 0,1,2,3) to return carry through `RET NZ` → false joins.
`XOR` always clears carry, fixing the bug.

**Limitation:** Story bosses ($DB85 ≠ $07) join through the natural probability
path ($5683 returns carry), bypassing the gate table entirely. The table only
controls non-story bosses ($DB85 = $07). Preventing story bosses from joining
would require a "is this a boss fight?" indicator to distinguish them from
wild monsters, which hasn't been found yet.

---

## Key ROM Functions

| Bank:Addr | Flat | Purpose |
|-----------|------|---------|
| $00:$0000 | 0x0000 | RST $00: table-driven dispatch (A = index, table after RST) |
| $00:$0010 | 0x0010 | RST $10: cross-bank function call (HL = bank:fn_index) |
| $00:$12D0 | 0x12D0 | PRNG |
| $00:$1577 | 0x1577 | Screen/text renderer (DE = data ptr, HL = VRAM dest) |
| $00:$1AB9 | 0x1AB9 | Display byte write |
| $00:$1E1E | 0x1E1E | Math: division or scaling (used in exp/join calculations) |
| $00:$223B | 0x223B | Compute HL = base + A × stride (multiplication helper) |
| $00:$267E | 0x267E | Probability computation (used in join RNG) |
| $00:$3001 | 0x3001 | Battle flag processing (checks $DA80) |
| $01:$4088 | 0x4088 | Post-battle party validation (CALL $46F6) — universal |
| $01:$46F6 | 0x46F6 | Party slot validation (check/clear invalid slots) |
| $01:$4808 | 0x4808 | Write party size to $CA8D |
| $01:$6891 | 0x6891 | Encounter monster selection |
| $01:$6989 | 0x6989 | Weighted random pool picker |
| $14:$4849 | 0x50849 | Load enemy stats from table |
| $50:$4017 | — | Main event state dispatcher (RST $00, 11 entries via $D9F4) |
| $50:$5712 | — | Sub-state dispatcher ($D9F5) |
| $50:$56F1 | — | Screen fade effect |
| $50:$59D6 | — | State 10: script executor ($DB58 ptr, $DB5A next state) |
| $50:$5C40 | — | Post-battle setup helper (called from state $0A) |
| $50:$5E21 | — | Bank $50 fn$01: per-frame event update |
| $50:$5F2F | — | Post-battle dispatch gate: checks $DB73, dispatches on $D9EC |
| $50:$60ED | — | State $0A: post-battle setup + experience processing |
| $50:$61E2 | — | Experience distribution to party monsters |
| $50:$6197 | — | Experience calculation helper |
| $50:$62F0 | — | State $0B: level-up check loop (single vs double INC) |
| $50:$6383 | — | Monster slot eligibility check (level 99/empty/inactive → carry) |
| $50:$63C1 | — | State $0C: level-up display (calls $51:fn$0C) |
| $50:$63D2 | — | State $0D: join dispatcher (checks $DD61, calls join handler) |
| $50:$6405 | — | Join call: LD HL,$510E; RST $10 → $51:$5C33 |
| $50:$63E8 | — | Alias: same as $51:$63E8 when bank $50 active? |
| $50:$63F0 | — | Load battle EID + call join handler |
| $50:$6D78 | — | Play timer (increments $CAB5-$CAB8) |
| $51:$4A96 | — | Bank $51 fn$02: post-battle init (called from state $0A) |
| $51:$5578 | — | Bank $51 fn$0C: level-up display handler (multi-frame, resets $D9EC→$0B) |
| $51:$5C33 | — | Bank $51 fn$0E: join handler, 30-state sub-machine via $D9F4 |
| $51:$63E8 | — | Find free party slot (scan 20 slots) |
| $51:$67A5 | — | Join complete: sets $D9EC = $0E |
| $51:$6928 | — | Copy $D665 buffer to party slot (149 bytes) |
| $52:$710E | — | Post-battle transition dispatcher |
| $52:$7773 | — | Set $D9EC = $0A (post-battle init), copy $DB55→$DD6B |
| $54:$55BB | — | Bank $54 fn$07: join/no-join decision (checks $DB85, RNG probability) |
| $54:$5683 | — | Final RNG join probability check (returns carry = join) |
| $16:$6E14 | 0x5AE14 | Set steps until next encounter |
| $16:$6F5F | 0x5AF5F | Determine if encounter triggers |

---

## Key RAM Addresses

| Address | Size | Description |
|---------|------|-------------|
| $C825 | 1 | UI interaction busy flag (set during dialogs, menus) |
| $C850 | 1 | System busy flag |
| $C86C | 1 | Special event flag |
| $C899–$C89A | 2 | PRNG state |
| $C8A9 | 1 | Floor encounter rate parameter |
| $C8B5 | 1 | BGM offset |
| $C935 | 1 | Current gate ID |
| $C939 | 1 | Current floor |
| $C968 | 1 | Map type |
| $C969 | 1 | In-gate flag |
| $CA38 | 1 | Encounter pool index |
| $CA39–$CA3A | 2 | Steps until random encounter |
| $CA4B | 3 | Gold |
| $CA51 | 20 | Items |
| $CA8D | 1 | Party/monster count |
| $CA8E+ | var | Party slot indices (which storage slots are active) |
| $CAB5–$CAB8 | 4 | Play timer (frames/sec/min/hours) |
| $CAC0+ | 149×20 | Monster storage (20 slots × 149 bytes each) |
| $C0D8–$C0DB | 4 | Party slot assignment buffer |
| $D665 | 149 | Join monster data buffer |
| $D66E | 1 | Join buffer species byte (= $D665 offset 9 = record offset +$0A) |
| $D8D3 | 1 | Boss tier (determines which bank handles boss: <6→$0C, <32→$0D, <64→$0E, ≥64→$0F) |
| $D8D5–$D8D6 | 2 | Event counter (16-bit, incremented during boss setup) |
| $D9EC | 1 | Post-battle state (dispatched at $50:$5F3A, 15 states $00-$0E) |
| $D9F4 | 1 | Event state (main state for bank $50 dispatcher, sub-state for bank $51 join handler) |
| $D9F5 | 1 | Event sub-state (used by $50:$5712 dispatcher) |
| $DA03 | 1 | Battle enemy 1 stats ID |
| $DA05 | 1 | Battle enemy 2 stats ID ($FF = no enemy 2) |
| $DA07 | 1 | Battle enemy 3 stats ID |
| $DA12–$DA13 | 2 | Current enemy_stats_id being loaded |
| $DA14 | 1 | Target party slot index for join |
| $DA18 | 25 | Enemy stats work buffer |
| $DA33 | 1 | Post-battle delay counter (decremented in state $0A) |
| $DA78 | 1 | Script executor busy flag |
| $DA80 | 1 | Battle status (0=none, 1=just ended, 2=result processed) |
| $DA81 | 1 | Battle result code |
| $DB4D | 1 | Copy of $DB85 joinability flag (set at $54:$55D0) |
| $DB4E | 1 | Post-battle phase flag (checked in state $0A, $02 = special) |
| $DB55 | 1 | Post-battle flag (always $00 for bosses; checked in states $0A and $0C) |
| $DB58–$DB59 | 2 | Script/event data pointer |
| $DB5A | 1 | Next event state value |
| $DB73 | 1 | Post-battle dispatch gate ($FF = skip dispatch, non-$FF = process) |
| $DB83–$DB84 | 2 | Join probability parameters (loaded in $54:fn$07) |
| $DB85–$DB88 | 4 | Per-enemy joinability flags (indexed by $DD61 & 3; $07 = non-joinable) |
| $DB88 | 1 | Current battle context / gate boss index |
| $DC3C+ | var | Per-enemy join probability data (indexed by $DD61) |
| $DD23–$DD25 | 3 | Experience/reward data (non-zero triggers exp distribution) |
| $DD61 | 1 | Join enemy index ($04=enemy 1, $05=enemy 2, $06=enemy 3, $00/$FF=none) |
| $DD62 | 1 | Event processing flag |
| $DD6B | 1 | Copy of $DB55 (set by $52:$7773 during post-battle init) |

---

## ROM Table Map

| Table | Location | Bank:Addr | Size | Entries | Stride |
|-------|----------|-----------|------|---------|--------|
| Enemy Stats | 0x50C1D | $14:$4C1D | 12,175 | 487 | 25B |
| Boss Table | 0x50897 | $14:$4897 | 132 | 33 | 4B |
| Boss Floor Array | 0x5B0A6 | $16:$70A6 | 256 | 32 | 8B |
| Encounter Pools | 0x06AAE | $01:$6AAE | 3,328 | 128 | 26B |
| Gate Offsets | 0x06A22 | $01:$6A22 | 32 | 32 | 1B |
| Floor Thresholds | 0x06A42 | $01:$6A42 | 64 | 32 | 2B |
| Monster Names | — | $41:$4339 | — | 256 | 2B ptrs |
| Bank $50 Fn Table | — | $50:$4001 | ~20 | ~10 | 2B ptrs |
| Bank $51 Fn Table | — | $51:$4001 | ~32 | ~16 | 2B ptrs |
| Main Event States | — | $50:$401B | 22 | 11 | 2B ptrs |
| Post-Battle States | — | $50:$5F3A | 30 | 15 | 2B ptrs |
| Join Sub-States | — | $51:$5C37 | 60 | 30 | 2B ptrs |
| Battle Result Disp | — | $50:$5E84 | 20 | 10 | 2B ptrs |
| Bank $54 Fn Table | — | $54:$4001 | ~20 | ~10 | 2B ptrs |
| Per-Gate Join Table | 0x153FE0 | $54:$7FE0 | 32 | 32 | 1B (custom patch) |

---

## Bank Map

| Bank | Primary Purpose |
|------|----------------|
| $00 | System functions (RST handlers, PRNG, text, rendering, battle flags, math) |
| $01 | Encounter system, party management, gate data |
| $0C–$0F | Boss loading by tier (dispatched from $71EF) |
| $13 | Level-up processing (fn$00 called from $6383) |
| $14 | Enemy stats table, boss table |
| $16 | Boss floor array, encounter triggering |
| $41 | Monster name pointer table |
| $42 | Event/dialog support |
| $50 | Gate event scripts, main event dispatcher, post-battle state machine |
| $51 | Join handler, level-up display, party copy, sub-state machines |
| $52 | Post-battle transition (sets $D9EC, copies state flags) |
| $54 | Join decision logic ($DB85 check, RNG probability, per-gate table) |
| $58 | Battle system |

### Free Space Found

| Bank | Addr | Flat | Bytes | Content |
|------|------|------|-------|---------|
| $01 | $7FE0 | 0x07FE0 | 31 | $FF fill |
| $51 | $7B34 | 0x147B34 | 1,228 | $00 fill |
| $54 | $7FC0 | 0x153FC0 | 64 | $00 fill (24B used by join patch routine) |

---

## Debug Mode

Activated by changing byte `$017E` in ROM from $00 to $07. Provides:
- GOTO PROGRAM (mode selection)
- MONSTER viewer
- GAME EDIT (teleport to any map, ACREATE for dungeon testing)
- SOUND TEST
- BATTLE EDIT
- Message debugger (press Select from any debug menu, non-Japanese versions only)

GameShark: `01078AC8` | Game Genie: `071-7EF-E6A`

See TCRF page for full details: https://tcrf.net/Dragon_Warrior_Monsters

---

## SameBoy Quick Reference

```bash
# Execution control
interrupt                     # pause game
continue (or c)               # resume
step                          # one instruction into calls
next                          # one instruction over calls
backstep                      # rewind one instruction

# Inspection
registers                     # all registers
examine/N ADDR                # N bytes at address
examine/N BANK:ADDR           # banked read
disassemble/N ADDR            # N instructions at address
disassemble/N BANK:ADDR       # banked disassembly
backtrace                     # call stack

# Breakpoints & watchpoints
breakpoint ADDR               # break on execution
breakpoint BANK:ADDR          # banked breakpoint
watch/w ADDR                  # break on write
watch/w ADDR to ADDR2 inclusive  # range write watch
unwatch                       # clear all watchpoints
delete                        # clear all breakpoints
```

### Debugging Lessons Learned

1. **`watch/w` on state variables** (like $D9EC) is often too noisy — they're written
   every frame by the game loop. Use `breakpoint` on the code that READS the variable
   (the dispatch point) instead, or set watchpoints only after a specific event
   (interrupt → set watch → continue).
2. **Conditional breakpoints** (`if [$ADDR] == $XX`) are unreliable in SameBoy for
   some conditions. Prefer unconditional breakpoints and check values manually.
3. **`backtrace`** only shows CALL return addresses. JP/JR chains leave no stack trace.
   Use watchpoints on state variables to trace JP-based dispatch chains.
4. **Best pattern for tracing state machines:** `interrupt` at the right moment,
   set `watch/w` on the state variable, then `continue`. Check `registers` and
   `backtrace` at each fire. This reveals the complete state progression.

---

## Open Questions

### Resolved (this session)
- ✅ **Join decision point found:** `$54:fn$07` at `$54:$55BB`. Checks `$DB85` (joinability flag) and RNG probability via `$5683`.
- ✅ **Join condition identified:** `$DB85 = $07` means "non-joinable boss." All other values go through RNG probability.
- ✅ **$D665 buffer IS populated for non-joining bosses.** `$DD61 = 4` for ALL bosses, confirming the join buffer has valid data.
- ✅ **Per-gate join patch implemented.** 24-byte custom routine + 32-byte table in bank $54 free space.

### For "Always Join" Refinement
1. **Story boss control:** Story bosses ($DB85 ≠ $07) join through the natural probability path ($5683 returns carry). To prevent them from joining, need a "is this a boss fight?" indicator that distinguishes bosses from wild monsters. Candidates: $DB88 (boss index), checking $DA03 against boss table, or a flag set during boss room entry.
2. **What sets $DB85 to $07?** Finding the write point would reveal the boss-marking mechanism. A `watch/w $DB85` during boss battle setup would locate it.
3. **What sets $DD61 to $04?** Set during battle setup for all bosses. Finding the write point reveals how the game identifies which enemy should join.

### For Custom Maps/Events
4. **Event script format:** The state 10 handler at $59D6 loads script pointers from $DB58-$DB59. What format is the script data?
5. **Per-gate event data:** Where are the gate-specific event configurations stored? How does the system know which scripts to run for each gate?
6. **Map generation:** How does ACREATE generate dungeon layouts? What data drives floor layouts?

### Other
7. **Entry 32 (cut content):** Boss table entry 32 has EID 221/222 but no floor data. What species is EID 221?
8. **Hargon/Sidoh mechanism:** How does the game handle two bosses for one gate?
9. **Monster experience/EXP formula:** $DD23-$DD25 contain experience data. $61E2 distributes it. Full formula unknown.
10. **$DB4E values:** Checked in state $0A; value $02 triggers call to $52:fn$01. What does this represent?
11. **$C86C special event flag:** Always $00 for tested bosses despite being checked. When is it set? Likely for scripted story events (cutscenes, NPC interactions) rather than boss battles.
