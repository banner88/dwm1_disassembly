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
sites in bank $12 ($4EE1 sets flag $0007, $6C78 conditionally sets $0057).
All other flag setting goes through script opcode $03.

### Script Opcodes
| Opcode | Name | Purpose |
|--------|------|---------|
| $00 | if_flag_clear | Branch if flag is CLEAR |
| $01 | if_flag_set | Branch if flag is SET |
| $02 | clear_flag | Clear a flag |
| $03 | set_flag | Set a flag |

## Statistics (from branch-following analysis)

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
is set by Castle script 0 after the Starry Night Tournament victory. It's
in an unreached branch (at $0C:$46C4, guarded by engine variable $CAB9),
which is why the decoder reports it as "check-only." After setting $00F1,
the script advances Castle ($D92B=5, $D92C=4) and GreatTree ($D92D=3,
$D933=2, $D934=2) to their post-game states.

**Boss defeat flow.** Each boss-defeat script does three things:
1. Sets D9E3 (story progression counter) to its value (48→78)
2. Sets the boss room's step counter (D976–D995) to 1 (defeated state)
3. Sets the gate "Room of" step counter + Castle screen 1 ($D92B = 7)
4. Sets one or more event flags marking the gate as cleared

## Key Flags

| Flag | Byte.Bit | Checks | Set By | Purpose |
|------|----------|--------|--------|---------|
| $0002 | $D99B.1 | — | Castle scr0 (new-game intro) | Starter granted — gates the `add_monster enemy=$0001` (Slib) grant at `$0C:$42D6`; set immediately after so the starter is given exactly once (see MONSTER_DATA.md → Starter Monster) |
| $00F1 | $D9B9.6 | **131** | Castle scr0 (unreached) | Post-game unlock (Starry Night champion) |
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
| $D9C6–$D9C7 | $0158–$0167 | zero engine literals, zero script refs (S8-tested: flag $0158 persisted) | **SAFE** |
| $D9C8–$D9CA | $0168–$017F | clean, but **RETIRED S57** → `wPendingFarmExp` (CF2) | reserved |
| $D9CB | $0180–$0187 | WriteRAM collision (pre-S57 table) | poisoned |
| $D9CC | $0188–$018F | engine literals (2 files) | poisoned |
| $D9CD–$D9D6 | $0190–$01DF | Coliseum / gate-reset named vars | poisoned |
| $D9D7–$D9D8 | $01E0–$01EF | zero engine literals, zero script refs | **SAFE** |
| $D9D9–$D9DE | $01F0–$021F | engine literals (6 files each) | poisoned |
| $D9DF–$D9E2 | $0220–$023F | engine literals and/or script refs | poisoned |
| $D9E3 | $0240–$0247 | story progression counter | poisoned |
| $D9E4–$D9E5 | $0248–$0257 | script-referenced | poisoned |
| $D9E6 | $0258–$025F | breeding mutation flag | poisoned |
| $D9E7–$D9E8 | $0260–$026F | engine literals / script refs | poisoned |
| $D9E9 | $0270–$0277 | current step (multi-step) | poisoned |

**SRAM boundary**: Flags at byte $D9EA+ ($0278+) are outside the SRAM save
range and will NOT persist across save/load.

**Actual safe+persistent pool: $0158–$0167 and $01E0–$01EF = 32 flags**
(not "~200"). `editor2/core/project.py FLAG_SAFE_RANGES` matches this list
as of S57; keep the two in sync. Note the audit verdicts are conservative:
an "engine literal" byte might in principle be a benign read, but nothing is
allocated onto a byte that any code names directly.

**`wPendingFarmExp` appropriation (S57/CF2):** bytes $D9C8–$D9CA hold the
pending farm-exp accumulator (24-bit LE; fed by bank $50
`CF2FarmShareDivert`, drained by bank $73 entry 0). They were chosen exactly
BECAUSE they are clean, save-imaged (in-gate save rooms exist, so pending
must survive save+reload), and boot-cleared. Flag indices $0168–$017F must
never be allocated.

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
