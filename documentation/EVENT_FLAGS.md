# Event Flags — Complete Static Analysis

## Overview

NPC dialogue is driven by an event flag bitfield starting at **$D99B** in WRAM.

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

### Script Opcodes
| Opcode | Name | Purpose |
|--------|------|---------|
| $00 | if_flag_clear | Branch if flag is CLEAR |
| $01 | if_flag_set | Branch if flag is SET |
| $02 | clear_flag | Clear a flag |
| $03 | set_flag | Set a flag |

## Complete Statistics

- **~1,164 total flag operations** (derived with the old 530-script count;
  re-run `tools/analyze_event_flags.py` to refresh — see DOC_AUDIT.md C) across 518 NPC scripts
- **311 unique flags** referenced ($0002-$02C1, WRAM $D99B-$D9F3)
- **219 flags** check-only in scripts (set by engine code)
- **463 free flag slots** for custom use

## Key Flags

| Flag | Byte.Bit | Checks | Purpose |
|------|----------|--------|---------|
| $00F1 | $D9B9.6 | **125** | Post-game unlock (most-checked flag) |
| $0025 | $D99F.2 | 60 | Defeat Durran / Starry Night |
| $0037 | $D9A1.0 | 59 | Beat S class arena |
| $0035 | $D9A1.2 | 56 | Beat B class arena |
| $001D | $D99E.2 | 50 | Defeat BattleRex (mandatory) |
| $0030-$0037 | $D9A1 | 297 total | All 8 arena ranks in one byte |

## Free Flag Slots

**Primary block: $0158-$02C0 (361 flag indices)** — WRAM $D9C6-$D9F3.

**⚠ COLLISION WARNING**: Several bytes in this range are written directly by
script opcode $12 (WriteRAM) as named variables. Allocating custom flags at
these indices will corrupt game state:

| Flag indices | WRAM byte | Variable | Effect if corrupted |
|-------------|-----------|----------|---------------------|
| $0180-$0187 | $D9CB | (unverified) | Unknown |
| $0190-$0197 | $D9CD | Current Coliseum Battle | Arena/gate battles break |
| $01A0-$01DF | $D9CF-$D9D6 | Gate room reset counters | Gate rooms stop resetting |
| $0240-$0247 | $D9E3 | Story progression counter | Story progression breaks |
| $0258-$025F | $D9E6 | Breeding mutation flag | Breeding mutations break |
| $0270-$0277 | $D9E9 | Current step (multi-step) | Room state system breaks |

**Safe contiguous block: $0158-$017F (40 flags guaranteed clean).**

Broader safe ranges within $0158-$02C0 (excluding collision zones above):
$0158-$017F, $0188-$018F, $0198-$019F, $01E0-$023F, $0248-$0257, $0260-$026F,
$0278-$02C0 (but $0278+ is **outside SRAM save range** — will not persist).

After range: $02C2-$0327 (102 flags). Plus ~30 scattered single-bit gaps.
**Total available: ~400+ flags, but editor must skip collision ranges above.**

## Analysis Tool

```bash
python3 tools/analyze_event_flags.py              # Full report
python3 tools/analyze_event_flags.py --json        # Export JSON
python3 tools/analyze_event_flags.py --free        # Free slots
python3 tools/analyze_event_flags.py --flag 0x00F1 # Single flag detail
```

---
*Generated via static analysis of all 518 NPC scripts across banks $0C/$0D/$0E/$0F.*
