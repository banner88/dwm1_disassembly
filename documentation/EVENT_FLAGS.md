# Event Flags — Story Progression System

## Overview

NPC dialogue is driven by an event flag bitfield starting at **$D99B** in WRAM. Each flag is a single bit, indexed by a 16-bit flag number:

```
byte_address = $D99B + (flag_index / 8)
bit_mask     = bitmask_table[flag_index & 7]
               table: $80, $40, $20, $10, $08, $04, $02, $01
               (bit 7 first, bit 0 last)
```

### ROM Functions
| Function | Address | Purpose |
|----------|---------|---------|
| SetEventFlag | $00:$26A0 | Set a flag bit (OR mask into byte) |
| ClearEventFlag | $00:$26A6 | Clear a flag bit (AND inverted mask) |
| CheckEventFlag | $00:$26AE | Test a flag bit (Z = clear, NZ = set) |

### Script Commands
| Cmd | Name | Purpose |
|-----|------|---------|
| $00 | ConditionalBranchNZ | Branch if flag is CLEAR |
| $01 | ConditionalBranchZ | Branch if flag is SET |
| $02 | ClearEventFlag | Clear a flag |
| $03 | SetEventFlag | Set a flag |

Scripts check flags from **newest to oldest** (latest story event first). When a flag is SET, the branch is taken to show that event's dialogue. The first match wins.

## Major Story Flags (Verified via SameBoy)

### Arena Progression — $D9A1 (8 flags, one per rank)

| Flag | Bit | $D9A1 Value | Event | Scripts Checking |
|------|-----|-------------|-------|-----------------|
| $0030 | 7 | $80 | Beat G class | 10 |
| $0031 | 6 | $C0 | Beat F class | 15 |
| $0032 | 5 | $E0 | Beat E class | 42 |
| $0033 | 4 | $F0 | Beat D class | 16 |
| $0034 | 3 | $F8 | Beat C class | 11 |
| $0035 | 2 | $FC | Beat B class | 46 |
| $0036 | 1 | $FE | Beat A class | 16 |
| $0037 | 0 | $FF | Beat S class | 45 |

All 8 arena flags are in a single byte. NPCs check from $0037 (S class, latest) down to $0030 (G class, earliest).

### Gate Boss Defeats — $D99E

| Flag | Bit of $D99E | Event | Scripts Checking |
|------|-------------|-------|-----------------|
| $001C | bit 3 ($08) | Defeat FunkyBird | minor |
| $001A | bit 5 ($20) | Defeat SkyDragon | minor |
| $001D | bit 2 ($04) | Defeat BattleRex (anger gate) | 33 |
| $001F | bit 0 ($01) | Defeat Jamirus | minor |

Flag $001D (BattleRex) is a major story flag — it's the first mandatory gate boss and triggers GreatTree earthquake + new area unlock. The others are per-gate flags checked by fewer NPCs.

### Major Story Milestones

| Flag | Byte | Event | Scripts Checking |
|------|------|-------|-----------------|
| $0025 | $D99F bit 2 ($04) | Defeat Durran / Starry Night begins | 42 |
| $00F0 | $D9B9 bit 7 ($80) | Post-game start (return through dresser) | few |
| $00F1 | $D9B9 bit 6 ($40) | King's post-game speech / new gates open | 86 |

Flag $00F1 is the single most-checked flag in the entire game (86 scripts). It's always checked FIRST by NPCs, meaning it represents the latest major story state. Nearly every NPC has post-game dialogue gated behind this flag.

## Complete Story Timeline (earliest → latest)

```
$0030  Beat G class
$0031  Beat F class
$0032  Beat E class
$0033  Beat D class
$001D  Defeat BattleRex (anger gate) — mandatory between D and C class
$0034  Beat C class
$0035  Beat B class
$0036  Beat A class
$0037  Beat S class — GreatTree earthquake, more areas unlock
$0025  Defeat Durran (reflection gate) — Starry Night Tournament
$00F0  Post-game start (return through dresser)
$00F1  King's post-game speech — all post-game content unlocked
```

## Per-Gate Boss Flags (partial, remaining gates TBD)

| Flag | Byte | Gate Boss |
|------|------|-----------|
| $001A | $D99E | SkyDragon |
| $001C | $D99E | FunkyBird |
| $001D | $D99E | BattleRex |
| $001F | $D99E | Jamirus |

Additional gate boss flags likely exist in $D99E-$D99F range. Can be mapped by routing redirect testing.

## How NPC Dialogue Uses Flags

Example: Grey shirt man in GreatTree (script_id $0B, bank $0C at $5A73):

```
Script data:
  $FF01, $00F1, $5A87    Check flag $00F1 (post-game): if SET → text $05D7
  $FF01, $0025, $5A83    Check flag $0025 (Durran): if SET → text $0492
  $0159                   Default text (early game)
  $FFFF                   End

Branch targets:
  $5A83: $0492, $FFFF     Mid-game text, end
  $5A87: $05D7, $FFFF     Post-game text, end
```

The NPC shows 3 different dialogues depending on story progress:
- Before defeating Durran: text $0159
- After Durran but before post-game: text $0492
- Post-game: text $05D7

## Using Flags in Custom Scripts

To make a custom NPC respond differently based on story state:

```
; Check if player has beaten S class
$FF01        ; ConditionalBranchZ opcode
$0037        ; Flag $0037 (Beat S class)
[branch_addr] ; Address to jump to if flag IS set

; Default dialogue (hasn't beaten S class yet)
$0159        ; Some text ID
$FFFF        ; End

; At branch_addr: alternate dialogue
$0492        ; Different text ID
$FFFF        ; End
```

---
*Verified June 2026 via SameBoy watchpoints on $D9A1, $D99E, $D99F, $D9B9.*
*All flag sets confirmed through Call_000_26a0 (SetEventFlag) backtrace.*
