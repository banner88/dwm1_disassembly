# Text System — Complete Reference

## IMPORTANT CORRECTION
The dispatch table at `$01:$6119` is a **per-room VRAM visual update** system
(palette animation, tile swaps), NOT NPC dialogue. See [$6119 System](#6119-system) below.

## Character Encoding (charmap.asm)

| Range | Characters |
|-------|-----------|
| $00-$09 | 0-9 |
| $10-$19 | Monster type icons (slime, dragon, beast, bird, plant, bug, devil, zombie, material, ???) |
| $24-$3D | A-Z |
| $3E-$57 | a-z |
| $5C-$64 | ' → , . ; .. (space) ! ? |

## DTE (Dual-Tile Encoding) — $65-$7F

Single bytes expanding to common 2-character pairs:

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
| $E7 | **CHOICE** | **YES/NO box + continuation flags. NOT "END".** Sets $C83C, $C83A=$FF. Script checks result via opcode $15. |
| $E8 | PAUSE | Brief pause |
| $E9 | NUM | Insert number from variable |
| $EA | BOX | Text box init (2 param bytes: $9F $A3 = standard NPC box) |
| $EB | BOX2 | Alternate text box init (same params as $EA) |
| $EC | NAME | Insert NPC/character name |
| $ED | MONSTER | Insert monster name |
| $EE | NEWLINE | Line break — **MUST be preceded by $EF** or overwrites line 1 |
| $EF | PAGE | Advance rendering position. Use `$EF $EE` together for line breaks |
| $F0 | SECTION | End text section. Stops rendering (unless bit 4 of $C825 set) |
| $F6 | HERO | Insert player's name |
| $F7 | CLEAR | Clear text box contents |
| $F9 | CONTINUE | Set continuation flag (bit 4 $C825), update base pointer |
| $FA | WAIT | Wait for A button press |
| $FF | CHOICE2 | YES/NO box only, does NOT set continuation flags |

**Text strings terminate with `$F7 $F0` (CLEAR + SECTION), NOT `$E7`.**

### Standard NPC Text Format (verified)
```
$EA $9F $A3 line1_text $EF $EE line2_text $F7 $F0
```

### YES/NO Choice (two-part system, verified)
Text ends with `$EF $EE $E7 $F0`. Script then checks `$C83C` via opcode `$15`:
```
dw question_text_id       ; text ending in $E7 $F0
dw $FF15                  ; CheckAndBranch
dw $C83C                  ; 0=YES, 1=NO
dw $0001                  ; branch if NO
dw .no_target
dw yes_text_id            ; shown if YES
dw $FFFF
.no_target:
dw no_text_id             ; shown if NO
dw $FFFF
```

### Custom Text Routing ($0A00+)
IDs with high byte ≥ $0A intercepted in bank $04 TextQueueCheck before ROM0 cascade.
Routed to bank $60 entry 5. Two-level pointer table required (see below).

### Custom Text Pointer Table
`SaveBankAndSwitch` (ROM0 $0940) does two-level indexing:
`table[$C822*2]` → section, `section[$C823*2]` → text address.
Flat tables crash.

## NPC → Dialogue Pipeline

```
Player presses A near NPC
  → Bank $01 NPCTalkHandler ($55D7)
    → Bank $0B entry 5: find NPC at facing position, return script_id
      → $D8D4 ← script_id, $D8D3 ← wMapID
    → Bank $04 ScriptInit ($55EC)
      → ScriptDataRead dispatches to bank $0C/$0D/$0E/$0F based on $D8D3:
          <$06→$0C, <$20→$0D, <$40→$0E, ≥$40→$0F
          ≥$6B→$60 (CUSTOM ROOMS, added by bank $04 patch)
      → Triple-index lookup: map_type→script_id→BC command pairs
      → B≠$FF: BC is text ID → queued to $D8D9/$D8DA
      → B=$FF: C is script opcode (0-99) dispatched via rst $00
    → ROM0 TextDispatchCascade ($0AD9) routes text ID to handler bank
      → Text IDs ≥$0A00: intercepted by bank $04 patch → bank $60 entry 5
```

## Text Storage

Handler banks ($42-$4E) each contain:
1. Bank number byte at $4000
2. Jump table (5 entries, 10 bytes) at $4001
3. Text pointer table at $400B (2 bytes per entry, LE)
4. Text strings in remaining space

## Text ID → Bank Routing (ROM0 Cascade at $0AD9)

Exact ranges determined by CPU-simulating the cascade for all 2067 text IDs:

| ID Range | Count | Bank | Content |
|----------|-------|------|---------|
| $0000-$00E1 | 226 | $42 | Early game, intro, GreatTree |
| $00E2-$0197 | 182 | $43 | Arena, Castle mid-game |
| $0198-$0243 | 172 | $44 | Gate world, mid-game |
| $0244-$02FF | 188 | $45 | Late arena, story gates |
| $0300-$03C7 | 200 | $46 | Boss events, cutscenes |
| $03C8-$0473 | 172 | $47 | Advanced gates, NPCs |
| $0474-$0511 | 158 | $48 | Tournament, arena special |
| $0512-$05DF | 206 | $49 | Post-game, special events |
| $05E0-$07BF | 480 | $4A | Largest — mixed content |
| $07C0-$0867 | 168 | $4B | System messages, menus |
| $0868-$09FF | 408 | $4E | Battle text, monster info |

Total: **2067 text IDs**. All decoded in `extracted/text_id_map.json`.

## $6119 System (VRAM Visual Updates — NOT Text) {#6119-system}

Function at `$01:$60E7` runs per-frame during gameplay. Dispatches via `rst $00`
indexed by `wMapID` to the table at `$6119`. Each handler does room-specific visual work:
- Castle ($00): VRAM updates via $65E0
- GateHub2 ($08): Palette animation using $C8A6/$C8A7 as counter
- GoopyRooms ($19/$1A): VRAM tile swaps at $9320↔$93D0
- Most rooms: RET (no visual effects)

## Key RAM Variables

| Address | Purpose |
|---------|---------|
| $C822 | Text section/page index (level 1 of two-level pointer table) |
| $C823 | Text entry index within section (level 2) |
| $C824 | Text data bank number (for async bank switching) |
| $C825 | Rendering state: bit 0=active, bit 2=waiting input, bit 4=inserted text |
| $C82D/$C82E | Text data read position (current, auto-incremented) |
| $C831/$C832 | Text data base position (for $F0 reset when bit 4 set) |
| $C83A | Last special control code ($FF = YES/NO choice active) |
| $C83C | **YES/NO result: 0=YES, 1=NO** (checked by script opcode $15) |
| $D8D3 | wScriptMapType (set to wMapID directly by bank $01) |
| $D8D4 | wScriptNPCId (script_id from NPC entry byte 4) |
| $D8D5/$D8D6 | wScriptCounter (16-bit, indexes script data) |
| $D8D9/$D8DA | Queued text ID from script (set when B≠$FF) |

## Data Files

- `extracted/text_id_map.json` — 2067 text IDs → decoded English, exact bank/index
- `extracted/decoded_text.json` — 1374 text strings organized by handler bank
