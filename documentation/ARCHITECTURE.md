# DWM1 ROM Architecture — Quick Reference

## Bank Map

| Bank | Role |
|------|------|
| $00 | ROM0 (always mapped): RST handlers, PRNG, math, text render, BGM, event flags |
| $01 | Encounters, party management, NPC talk handler, gate data |
| $03 | Link/serial, monster info table ($4461) |
| $04 | NPC script engine (100 opcodes) |
| $0B | Room system: loading, exits, NPCs, transitions, pointer table $4B43 |
| $0C-$0F | Script data banks: 518 NPC scripts across all map types ($0C=129, $0D=168, $0E=130, $0F=91). Identical code $4000-$41B9, data from $41BA. Master table indexed by absolute map_type. $0C=types<$06, $0D=$06-$1F, $0E=$20-$3F, $0F≥$40. Generator: `gen_script_banks.py` |
| $13 | Level-up processing, stat growth tables |
| $14 | Enemy stats table ($4C1D), boss redirect table ($4897) |
| $16 | Breeding system: special table ($4B30), family table ($4974) |
| $17 | Palette system |
| $41 | Name/text tables: monster names, skill names, family codes, items, personalities, game text (fully annotated) |
| $42-$4E | Text handler banks (text ID routing, text data) |
| $50 | Event state machine (11 states, post-battle states) |
| $51 | Event sub-handlers, room transitions |
| $52 | Battle system: 115 named skill handlers, SkillFunctionTable at $4011, family checks, math helpers |
| $54 | Post-battle join logic ($55BB), EXP distribution, level-up processing |
| $56 | Text rendering engine, parallel text dispatch cascade |

## Empty ROM Banks (23 banks = 368KB free)

`$60, $64, $67, $69-$77, $79-$7A, $7C, $7E-$7F`

## Free Space in Used Banks

| Bank | Address | Bytes | Notes |
|------|---------|-------|-------|
| $00 | $3FE8 | 24 | Confirmed safe (FF fill at bank end) |
| $01 | $7FD5 | 42 | FF fill $7FD5-$7FFE; $7FFF=$01 (NOT free) |
| $0B | — | ~2 | Essentially FULL |
| $51 | $7B34 | 1,228 | 00 fill — large, investigate safety |
| $54 | $7FC0 | 64 | 00 fill (24B used by join patch) |

## RST Dispatch Mechanisms

- `rst $00` — Jump table dispatch: A indexes into table immediately after RST
- `rst $08` — ROM0 call dispatch: calls function in bank $00
- `rst $10` — Cross-bank call: H=bank, L=entry index → switches bank and calls entry

## Key RAM Regions

| Range | Purpose |
|-------|---------|
| $C800-$C8FF | System state, UI, battle temp |
| $C900-$C9FF | Room/map state, screen index, floor, gate |
| $CA51-$CA64 | Inventory (20 item slots, empty=$00) |
| $CAC1-$D6B0 | Party/storage monsters (20 × $95 bytes) |
| $D7D2+ | NPC RAM buffer (32 bytes per NPC slot — verified: parser at $0B:477E advances with `add $20`) |
| $D8D0-$D8DF | Script engine state |
| $D92A-$D99A | Room step counters (113 addresses — one per screen; value selects which NPC/exit set loads; see ROOM_DATA_FORMAT.md "Room State System") |
| $D99B+ | Event flag bitfield |
| $D9F4 | Event state machine index |
| $DA00-$DA7F | Temp: enemy stats, monster info copy, breeding vars |

## SRAM Save Layout

SaveGameState (ROM0, bank_000.asm line 6577) copies game state to SRAM:

| WRAM source | SRAM dest | Size | Contents |
|-------------|-----------|------|----------|
| $FF8A | $A003 | 33 B | HRAM (timer) |
| $C8EA | $A024 | $1100 (4352 B) | Main game state (last byte: $D9E9) |
| $C300 | $BCC8 | $0200 | Tile layout buffer |
| $C200 | $BEC8 | $0100 | GBC attribute buffer |
| $CAC1 | $A1FB | 2980 B | Party (separate SavePartyToSRAM path) |

Checksum: $A002-$BFFF → stored at $A000-$A001. Valid flag: $A002 (1 = save exists).

The main save range $C8EA-$D9E9 covers step counters ($D92A-$D99A), most event
flags ($D99B-$D9E9), inventory, gold, and custom WRAM. **Flags at byte $D9EA+
(indices $0278+) are OUTSIDE the save range and will NOT persist.**

### Flag byte collisions

Several named RAM variables share bytes with the event flag bitfield. The editor
must skip these flag index ranges when allocating custom flags:

| RAM addr | Flag indices | Variable |
|----------|-------------|----------|
| $D9CB | $0180-$0187 | (unverified name) |
| $D9CD | $0190-$0197 | Current Coliseum Battle |
| $D9CF-$D9D6 | $01A0-$01DF | Gate room reset counters |
| $D9E3 | $0240-$0247 | Story progression counter |
| $D9E6 | $0258-$025F | Breeding mutation flag |
| $D9E9 | $0270-$0277 | Current step in multi-step screens |

**Safe contiguous block for custom flags: $0158-$017F (40 flags guaranteed clean).**
Broader safe range $0158-$0277 (288 flags) if collision ranges are excluded.
