# Event Flags — Complete Analysis (Branch-Following)

## Overview

NPC dialogue and story progression are driven by an event flag bitfield
starting at **$D99B** in WRAM.

```
byte_address = $D99B + (flag_index / 8)
bit_mask     = bitmask_table[flag_index & 7]  ; $80,$40,$20,$10,$08,$04,$02,$01
```

### ROM Functions
| Function | Address | Purpose |
|----------|---------|---------|
| SetEventFlag | $00:$26A0 | Set a flag bit |
| ClearEventFlag | $00:$26A6 | Clear a flag bit |
| TestEventFlag | $00:$26AE | Test a flag bit (Z=clear, NZ=set) |

There are only **3 call sites** to SetEventFlag in the entire ROM: the
script engine opcode $03 handler (bank $04:$579B), and two engine-code
sites in bank $12 ($4EE1 sets flag $0007; $6C78 sets **$0050 + [$D9E1]** —
S124 correction, code-read: the medal man's egg reward, [$D9E1] = eggs already
given 0-7, so $0050-$0057 in turn; it was described as "conditionally sets
$0057"). See "Engine-side flag setters and readers (S124)" below.
S118f: the `$4EE1` site is state 6 (`$4EBC`) of Pulio's farm menu (screen type 3): taking
a monster into an EMPTY party sets `$0007` ("Pulio: Train it well"); read only by the
Castle entry script.
All other flag setting goes through script opcode $03.
**Reader added S97:** custom-room STATE RULES (bank $60 entry 8
`CustomStateRules`, PROJECT_COMPILER §2.13) call `TestEventFlag` at every
custom (re)load — a rule may test ANY flag (vanilla story flags included);
named project flags come from the safe pool below (16 flags) — S117: plus the
2,048 extended flags `$1000`-`$17FF` ("Extended flags (S117)").

### Script Opcodes
| Opcode | Name | Purpose |
|--------|------|---------|
| $00 | if_flag_clear | Branch if flag is CLEAR |
| $01 | if_flag_set | Branch if flag is SET |
| $02 | clear_flag | Clear a flag |
| $03 | set_flag | Set a flag |

## Statistics (from branch-following analysis)

**S124 (the decoder with the handler arities, `editor2/core/cutscenes.Catalogue`, every
map type's script table — `editor2/core/flag_index.py` uses it):** 587 scripts, **1,674
flag operations, 332 distinct flags** ($0000-$02C1), **327 with a set**, 19 cleared
somewhere; check-only: `$0007`, `$0050`, `$0053` (set by the game's code, below),
`$00E5` and `$02C1` (set by no decoded script — not traced). The figures below are the
pre-S96 decoder's (dump_all_scripts.py, the old arity table — DOC_AUDIT S96).

- **1,675 total flag operations** across 732 scripts in banks $0C/$0D/$0E/$0F
- **328 unique flags** referenced ($0000–$02C1, WRAM $D99B–$D9F3)
- **298 flags** have at least one set_flag operation in decoded scripts
- **29 flags** are check-only (either in unreached branches or engine-set)
- **~500 free flag slots** available for custom use (with caveats below)

Previous linear analysis found only 92 flags with sets and 219 "check-only"
anomalies because it didn't follow script branches. The branch-following
decoder (dump_all_scripts.py) covers 93.5% of script code paths.

## Story Progression — How Flags Drive the Game

The game has two interlocking state systems:

**1. Event flags** ($D99B+ bitfield) — persistent boolean state, survives
save/load. Used by NPC scripts to decide dialogue and behavior.

**2. Step counters** ($D92A–$D99A) — per-screen byte values that select
which NPC/exit/tile configuration is active. Set by opcode $12 (WriteRAM).

**Primary story driver: Arena battles.** Winning each arena class sets
a rank flag ($0030–$0037) in Arena Lobby script 0. These 8 flags are
checked 297 times across the game to gate content (new rooms, NPCs,
dialogue, gates).

**Mandatory gate interludes.** At two points the arena becomes unavailable
and the player must clear a specific gate:
- After D class: must defeat BattleRex in Gate of Anger (sets flag $001D)
- After S class: must defeat Durran in Gate of Reflection (sets flag $0025)

Arena Lobby scripts 6/7/10/11 check these flags in priority order:
$00F1 → $0025 → $0037 → $001D, gating arena access accordingly.

**Post-game unlock.** Flag $00F1 (131 checks, the most-referenced flag)
is set by Castle script 0 at $0C:$46C4 (`FF03 00F1`, then `$D92B := 5` —
ROM bytes, S124). **S124 correction:** it is NOT an unreached branch — the S124
decoder (handler arities) reaches it; the pre-S96 decoder's arity table lost the
path. Per the S124 research read (code-read, not measured) the Castle's arrival
cascade plays it once `$00EE` (the ending seen) is set and `$00F1` clear, i.e.
AFTER the ending, not right after the Starry Night victory. After setting $00F1,
the script advances Castle ($D92B=5, $D92C=4) and GreatTree ($D92D=3,
$D933=2, $D934=2) to their post-game states.

**Boss defeat flow.** Each boss-defeat script does three things:
1. Sets D9E3 (the King's-speech code, $30-$4E / $C7 / $10 — S101 r3: GATE_GENERATION §7.7) to its value
2. Sets the boss room's step counter (D976–D995) to 1 (defeated state)
3. Sets the gate "Room of" step counter + Castle screen 1 ($D92B = 7)
4. Sets one or more event flags marking the gate as cleared

## Key Flags

| Flag | Byte.Bit | Checks | Set By | Purpose |
|------|----------|--------|--------|---------|
| $0002 | $D99B.1 | — | Castle scr0 (new-game intro) | Starter granted — gates the `add_monster enemy=$0001` (Slib) grant at `$0C:$42D6`; set immediately after so the starter is given exactly once (see MONSTER_DATA.md → Starter Monster) |
| $00F1 | $D9B9.6 | **131** | Castle scr0 $0C:$46C4 (S124: reached; after the ending) | Post-game unlock (Starry Night champion) |
| $0025 | $D99F.2 | 59 | Boss: Reflection scr0 | Defeat Durran — unlocks Starry Night |
| $0037 | $D9A1.0 | 59 | Arena Lobby scr0 | Beat S class arena |
| $0035 | $D9A1.2 | 56 | Arena Lobby scr0 | Beat B class arena |
| $0032 | $D9A1.5 | 53 | Arena Lobby scr0 | Beat E class arena |
| $001D | $D99E.2 | 52 | Boss: Anger scr8 | Defeat BattleRex (mandatory gate) |
| $0030–$0037 | $D9A1 | 297 total | Arena Lobby scr0 | All 8 arena ranks in one byte |

## Free Flag Slots (CORRECTED S57 — per-byte audit)

**Primary block: $0158–$02C0 (361 flag indices)** — WRAM $D9C6–$D9F3.

**⚠ The pre-S57 version of this section was WRONG.** Its "broader safe
ranges" came from script analysis only. A per-byte audit (grep of every
`$d9xx` literal across `disassembly/` + `patches/`, PLUS a full-text scan of
`extracted/all_scripts.json`) shows most of those bytes are live ENGINE named
variables and/or script-referenced, on top of the known WriteRAM collisions:

| WRAM byte | Flag indices | Evidence | Verdict |
|-----------|--------------|----------|---------|
| $D9C6–$D9C7 | $0158–$0167 | zero engine literals; **S124: $0158 IS script-referenced** — Arena Battle ($5D) script 0 tests + sets it ($0F:$6890 / $6898, Milayou's rematch: first words vs "Are you challenging me again?"; PyBoy S124: flag OFF → pos 857 and the flag reads ON after, ON → pos 862). The S57 scan read the pre-S96 all_scripts.json, which never reached that branch. $0159–$0167: no reference in the S124 decode | **$0159–$0167 SAFE**; $0158 the game's |
| $D9C8–$D9CA | $0168–$017F | clean, but **RETIRED S57** → `wPendingFarmExp` (CF2) | reserved |
| $D9CB | $0180–$0187 | WriteRAM collision (pre-S57 table) | poisoned |
| $D9CC | $0188–$018F | engine literals (2 files) | poisoned |
| $D9CD–$D9D6 | $0190–$01DF | Coliseum / gate-reset named vars | poisoned |
| $D9D7–$D9D8 | $01E0–$01EF | clean, but **RETIRED S73** → `wAnchorGate`/`wAnchorFloor` (skill $E4 Anchor persistent state; CF2 precedent) | reserved |
| $D9D9–$D9DE | $01F0–$021F | engine literals (6 files each) | poisoned |
| $D9DF–$D9E2 | $0220–$023F | engine literals and/or script refs | poisoned |
| $D9E3 | $0240–$0247 | the King's-speech selector for the next `$D92B = 7` castle arrival (S101 r3 ROM scan: read ONLY by the castle chain $0C:$4804 and one castle NPC at $0C:$5066; the priest path resets it to $FF) — the old name "story progression counter" overstated it | poisoned |
| $D9E4–$D9E5 | $0248–$0257 | script-referenced | poisoned |
| $D9E6 | $0258–$025F | breeding "rare breed" flag (never set, S113) | poisoned |
| $D9E7–$D9E8 | $0260–$026F | engine literals / script refs | poisoned |
| $D9E9 | $0270–$0277 | current step (multi-step) | poisoned |

**SRAM boundary**: Flags at byte $D9EA+ ($0278+) are outside the SRAM save
range and will NOT persist across save/load.

**Actual safe+persistent pool: $0159–$0167 = 15 flags** (S124: $0158 is the game's —
above; S73: $01E0–$01EF retired to `wAnchorGate`/`wAnchorFloor`) (not "~200").
`editor2/core/project.py FLAG_AUTO_RANGES` (where the editor numbers new flags) matches
this; `FLAG_SAFE_RANGES` still admits $0158 for named flags numbered before S124 (old
saves keep their meaning; a build warning and the Progression & Flags tab's Renumber
move them — PROJECT_COMPILER §2.7). **S128 r2:** no flag lands on $0158 by default any more —
the compiler's "auto" numbering moves one that would (the others keep their numbers), and
opening a project moves a pinned one with a note (PROJECT_COMPILER §2.41 "Flags"). Note the audit verdicts are conservative:
an "engine literal" byte might in principle be a benign read, but nothing is
allocated onto a byte that any code names directly.

**`wPendingFarmExp` appropriation (S57/CF2):** bytes $D9C8–$D9CA hold the
pending farm-exp accumulator (24-bit LE; fed by bank $50
`CF2FarmShareDivert`, drained by bank $73 entry 0). They were chosen exactly
BECAUSE they are clean, save-imaged (in-gate save rooms exist, so pending
must survive save+reload), and boot-cleared. Flag indices $0168–$017F must
never be allocated.

## Extended flags (S117 — built S117, PyBoy-verified, NOT yet user-tested)

The user needs "dozens if not hundreds of flags" for a custom campaign; the vanilla
bitfield has 16 safe persistent ones (above). Patched builds add **2,048 flags,
indices `$1000`-`$17FF`**, in `wExtFlags` (`$D140`-`$D23F`, 256 B carved from
wCustomPool — known_RAM_map), saved with the game.

- **One chokepoint.** `SetEventFlag` / `ClearEventFlag` / `TestEventFlag` all call ROM0
  `ComputeFlagAddress` ($26B3; BC = index → HL = byte, A = mask). Patched: a SAME-SIZE
  34-byte rewrite (12 B code + 22 nops) that far-calls **bank $73 entry 21 `FlagAddr`**
  (DE = index → HL = address, C = mask; BC / DE preserved for the caller): `$1000`-`$17FF`
  → `wExtFlags + (index − $1000) / 8`; every other index → the vanilla `$D99B + index /
  8` (unchanged, out-of-range indices included); mask `$80 >> (index & 7)` (MSB-first, as
  the vanilla mask table `$26D5`, which keeps its address — ROM0 `GetBitAndMask` reads it too).
  Scripts reach the new range with the ordinary opcodes $00-$03 (the index is a word).
- **Saved / loaded / cleared like the vanilla bitfield.** Bank $73 entry 5's main-save
  detector also runs `ExtFlagsCommit` (SRAM bank 3: magic `"X1"` at `$A000`, the 256 B at
  `$A010`); entry 6's main-load detector runs `ExtFlagsRestore` after its zero-fill of
  `$CC80`-`$D664` (copied back only when the magic is there — an old save loads with all
  extended flags clear). A new game zeroes them (`CF3NewGameClear` covers `$C8EA`-`$D9E9`).
  An unsaved flag is lost on reload exactly like a vanilla one. ARCHITECTURE "SRAM bank 3
  (S117)".
- **Measured S117:** the address of every flag index the game's scripts reference (1,934)
  is identical to the original; an SM83 stub sweep of 0-`$1FFF` = the formula above with
  BC / DE preserved; on the user's save a flag set in the new range survives save → power
  off → continue, an unsaved one rewinds, a new game clears it.
- **Editor pool** (`editor2/core/project.py FLAG_SAFE_RANGES`): `$0158`-`$0167` (16) +
  `$1000`-`$179F` (1,952) for named project flags; **`$17A0`-`$17FF` = the gates'
  own cleared flags** (`$17A0` + gate number — GATE_GENERATION §7.9). `flag_persistent()`
  treats the whole extended range as persistent.
- **New SetEventFlag caller (patched builds):** bank $76 entry 2 `GateBossWin` (the
  cleared mark of re-bossed / new gates, GATE_GENERATION §7.9).

## Engine-side flag setters and readers (S124, code-read)

Besides script ops `$00-$03` (bank $04, through ROM0 Set / Clear / TestEventFlag):

| Where | Does | Flags |
|-------|------|-------|
| bank $12 `$4EE1` (Pulio's farm menu, state 6) | SetEventFlag when a monster is taken into an EMPTY party | `$0007` |
| bank $12 `$6C4B-$6C78` (the medal man's egg reward) | SetEventFlag `$0050 + [$D9E1]`, then `[$D9E1]++`, `[$C905]++` | `$0050-$0057` (egg 1-8; [$D9E1] ≥ 8 sets nothing). S126: the reward count is `MEDAL_REWARD_COUNT` (`gamedata.medals`, 1-8 — these 8 flags are why 8 is the cap; PROJECT_COMPILER §2.39), the game's 4 by default |
| bank $09 `SaveFld9_6004` (the gate keeper's list, screen 13) | TestEventFlag on `GateListClearedFlags` `$09:$607E` — draws `GateListClearedByte` `$608E` (meaning not traced) for a cleared gate, `$E0` otherwise | the 16 main gates' cleared flags `$10 11 12 13 14 16 17 19 1D 1C 1A 1F 20 22 23 25` |
| bank $09 `SetFld9_604d` (the same list) | TestEventFlag on `GateListUnlockFlags` `$09:$609E`: a gate is listed when its flag is set | `$0000` (Beginning), then two gates per arena class G..A `$0030-$0036`, Reflection on S `$0037` |

All re-sectioned / commented in both trees (S124). Patched builds add the readers of
PROJECT_COMPILER §2.13 / §2.32 (state rules, NPC conditions, encounter variants, gate
rules) and bank $76 `GateBossWin` (a setter). The editor's flag index lists all of them
(`editor2/core/flag_index.py`, the Progression & Flags tab).

## Reserved for the Milly hook (S121)

`$179F` = the player is Milly (set by the hook's bedroom script at the dresser; bank $79
reads it for every player draw / field load) and `$179E` = her arrival scene has played.
Reserved: the editor's named pool is `$1000-$179D` (`FLAG_SAFE_RANGES`); scenes and NPC
conditions refer to them as `hook:milly` / `hook:milly_arrived` (listed in the flag
pickers while the hook is on). Byte `$D233` (`wExtFlags + $F3`), masks `$01` / `$02`.
Saved / cleared like every extended flag (PyBoy S121: CONTINUE on a save with `$179F` →
Milly).

## Analysis Tool

```bash
python3 tools/analyze_event_flags.py              # Full report
python3 tools/analyze_event_flags.py --json        # Export JSON
python3 tools/analyze_event_flags.py --free        # Free slots (with warnings)
python3 tools/analyze_event_flags.py --flag 0x00F1 # Single flag detail
```

The tool reads `extracted/all_scripts.json` (branch-following data from
`dump_all_scripts.py`) rather than scanning the ROM directly. Regenerate
`all_scripts.json` first if the script decoder has been updated.

---
*Analysis from 732 scripts via dump_all_scripts.py branch-following decoder.*
*29 check-only flags remain (6.5% unreached code paths + 2 engine-set).*
