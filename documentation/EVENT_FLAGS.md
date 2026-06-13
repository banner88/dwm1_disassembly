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

**Primary block: $0158-$02C0 (361 contiguous flags)** — WRAM $D9C6-$D9F3, completely unused.
After range: $02C2-$0327 (102 flags). Plus ~30 scattered single-bit gaps.
**Total: 463 free flags.**

## Analysis Tool

```bash
python3 tools/analyze_event_flags.py              # Full report
python3 tools/analyze_event_flags.py --json        # Export JSON
python3 tools/analyze_event_flags.py --free        # Free slots
python3 tools/analyze_event_flags.py --flag 0x00F1 # Single flag detail
```

---
*Generated via static analysis of all 518 NPC scripts across banks $0C/$0D/$0E/$0F.*
