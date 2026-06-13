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
| $00F1 | $D9B9.6 | **131** | Castle scr0 (unreached) | Post-game unlock (Starry Night champion) |
| $0025 | $D99F.2 | 59 | Boss: Reflection scr0 | Defeat Durran — unlocks Starry Night |
| $0037 | $D9A1.0 | 59 | Arena Lobby scr0 | Beat S class arena |
| $0035 | $D9A1.2 | 56 | Arena Lobby scr0 | Beat B class arena |
| $0032 | $D9A1.5 | 53 | Arena Lobby scr0 | Beat E class arena |
| $001D | $D99E.2 | 52 | Boss: Anger scr8 | Defeat BattleRex (mandatory gate) |
| $0030–$0037 | $D9A1 | 297 total | Arena Lobby scr0 | All 8 arena ranks in one byte |

## Free Flag Slots

**Primary block: $0158–$02C0 (361 flag indices)** — WRAM $D9C6–$D9F3.

**⚠ COLLISION WARNING**: Several bytes in this range are written directly by
script opcode $12 (WriteRAM) as named variables. Allocating custom flags at
these indices will corrupt game state:

| Flag indices | WRAM byte | Variable | Effect if corrupted |
|-------------|-----------|----------|---------------------|
| $0180–$0187 | $D9CB | (unverified) | Unknown |
| $0190–$019F | $D9CD–$D9CE | Coliseum battle / round | Arena battles break |
| $01A0–$01DF | $D9CF–$D9D6 | Gate room reset counters | Gate rooms stop resetting |
| $0240–$0247 | $D9E3 | Story progression counter | Story progression breaks |
| $0258–$025F | $D9E6 | Breeding mutation flag | Breeding mutations break |
| $0270–$0277 | $D9E9 | Current step (multi-step) | Room state system breaks |

**SRAM boundary**: Flags at byte $D9EA+ ($0278+) are outside the SRAM save
range and will NOT persist across save/load.

**Safe contiguous block: $0158–$017F (40 flags guaranteed clean).**

Broader safe ranges within $0158–$02C0 (excluding collision zones above):
$0158–$017F, $0188–$018F, $01E0–$023F, $0248–$0257, $0260–$026F.

After range: $02C2–$0327 (102 flags, but outside SRAM — won't persist).

**Total safe+persistent: ~200 flags. Editor must skip collision ranges.**

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
