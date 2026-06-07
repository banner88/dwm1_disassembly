# Text Encoding & Storage

## Character Encoding (charmap.asm)

| Range | Characters |
|-------|-----------|
| $00-$09 | 0-9 |
| $10-$19 | Monster type icons (slime, dragon, beast, bird, plant, bug, devil, zombie, material, ???) |
| $24-$3D | A-Z |
| $3E-$57 | a-z |
| $5C | ' (apostrophe) |
| $5D | → (right arrow) |
| $5E | , |
| $5F | . |
| $60 | ; |
| $61 | .. |
| $62 | (space) |
| $63 | ! |
| $64 | ? |

## DTE (Dual-Tile Encoding) — $65-$7F

Single bytes that expand to common 2-character pairs:

| Code | Pair | Code | Pair | Code | Pair |
|------|------|------|------|------|------|
| $65 | ll | $6E | he | $77 | ou |
| $66 | 'l | $6F | be | $78 | te |
| $67 | 't | $70 | or | $79 | nd |
| $68 | 's | $71 | an | $7A | to |
| $69 | 'r | $72 | in | $7B | it |
| $6A | 'm | $73 | er | $7C | es |
| $6B | n' | $74 | re | $7D | at |
| $6C | 'v | $75 | on | $7E | en |
| $6D | th | $76 | st | $7F | al |

## Control Codes ($E0+)

| Code | Name | Purpose |
|------|------|---------|
| $E7 | END | End of text string |
| $E8 | PAUSE | Brief pause |
| $E9 | NUM | Insert number from variable |
| $EA | BOX | Text box initialization (followed by 2 param bytes) |
| $EB | ITEM | Item/context text marker |
| $EC | NAME | Insert NPC/character name |
| $ED | MONSTER | Insert monster name |
| $EE | NEWLINE | Line break within text box |
| $EF | PAGE | New text page (clear box, continue) |
| $F0 | SECTION | Section separator (close box, open new) |
| $F6 | HERO | Insert player's name |
| $F7 | CLEAR | Clear text box contents |
| $FA | WAIT | Wait for button press |
| $FF | CHOICE | Yes/No choice prompt |

## Text Storage Format

Text data is stored in handler banks ($42-$4E). Each bank has:
1. Bank number byte at $4000
2. Jump table (5 entries, 10 bytes) at $4001
3. **Text pointer table** starting at $400B (2 bytes per entry)
4. Text strings in the remaining space

Each text pointer is a 2-byte little-endian address pointing to the text string within the same bank.

## Text String Format

```
[EA][param1][param2]  — Box initialization (position)
[character bytes]      — Text content (chars + DTE)
[EE]                   — Newline
[EF]                   — Page break
[FA]                   — Wait for button
[F7]                   — Clear box
[E7]                   — End of string
```

## Text ID → Bank Routing

Text IDs are 16-bit. The high byte selects the handler bank via the ROM0 cascade at $0AD9:

| High byte | Handler bank | Approximate text count |
|-----------|-------------|----------------------|
| $00 (low) | $42 | 112 |
| $00 (high)-$01 | $43 | 142 |
| $01-$02 | $44 | 97 |
| $02-$03 | $45 | 123 |
| $03-$04 | $46 | 143 |
| $04-$05 | $47 | 55 |
| $05-$06 | $48 | 107 |
| $06-$07 | $49 | 157 |
| $08-$09 | $4A | 288 |
| $09+ | $4B | 63 |
| special | $4E | 87 |

Total: 1374 decoded text strings.

## Decoded Text Data

All 1374 strings are decoded in `extracted/decoded_text.json`, organized by handler bank with pointer addresses and full text content.

---
*Decoded June 2026. DTE table derived from context analysis of decoded strings.*

## ROM0 Text Cascade — Precise Routing ($0AD9)

The cascade dispatches by text_id high byte via `rst $00` at $0ADC:

| ID Range | Count | Handler Bank | Notes |
|----------|-------|-------------|-------|
| $0000-$00E1 | 226 | $42 | Early game, intro, GreatTree basics |
| $00E2-$0197 | 182 | $43 | Arena, Castle mid-game |
| $0198-$0243 | 172 | $44 | Gate world, mid-game |
| $0244-$02FF | 188 | $45 | Late arena, story gates |
| $0300-$03C7 | 200 | $46 | Boss events, cutscenes |
| $03C8-$0473 | 172 | $47 | Advanced gates, NPCs |
| $0474-$0511 | 158 | $48 | Tournament, arena special |
| $0512-$05DF | 206 | $49 | Post-game, special events |
| $05E0-$07BF | 480 | $4A | Largest bank — mixed content |
| $07C0-$0867 | 168 | $4B | System messages, menus |
| $0868-$09FF | 408 | $4E | Battle text, monster info |

Total: **2067 text IDs** mapped and decoded in `extracted/text_id_map.json`.

The mapping was determined by CPU-simulating the ROM0 cascade at $0AD9
through all 10 handlers ($0AF1-$0C6A), tracking register state and
branch conditions for every possible text ID.

Each handler checks the low byte against its threshold. Below → dispatch to the primary bank. Above → subtract and cascade to next handler's bank. The jump table at $0ADD contains the 10 handler pointers.

