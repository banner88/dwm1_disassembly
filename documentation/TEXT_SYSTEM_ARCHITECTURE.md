# DWM1 Text/Dialogue System — Complete Architecture

## CRITICAL CORRECTION
The dispatch table at $01:$6119 (previously identified as "NPC text dispatch") is actually
a **per-room VRAM visual update** system. It handles palette animation, tile swaps, and
graphical effects — NOT NPC dialogue. Rooms with RET handlers have no visual effects,
not "no text."

## Actual NPC Dialogue Architecture

### The 3-Layer Text Chain

```
Layer 1: Text ID Dispatch (bank $00 at $0AEA, mirrored in bank $56)
  Converts 16-bit text ID ($C822/$C823) to script handler bank via range cascade

Layer 2: Script Handler Banks ($42-$4E)
  Contain per-room script logic. Use script_id to choose which text string to load.
  Call into text data banks via rst $10.

Layer 3: Text Data Banks ($18, $1A, $1B, $1F, $21, $22, $3F)
  Contain raw encoded text strings. Each bank has 3+ entry points for
  different text operations (load, display, format).
```

### Complete Bank Mapping

| Script Handler | Text Data Bank | Rooms (verified) |
|---|---|---|
| $42 | $1A | Castle (early game), Intro |
| $43 | $1A | Castle (mid game) |
| $44 | $1B | GreatTree, Library |
| $45 | $1F | Gate rooms group 1 |
| $46 | $1B | Gate rooms group 2 |
| $47 | $21 | Arena Lobby, Well |
| $48 | $1F | Secret rooms |
| $49 | $18 | Starry Shrine |
| $4A | $22 | Stable, Arena Rooms |
| $4B | $3F | Bazaar, Farm |
| $4E → $4F | (chained) | Post-game content |

### Text ID Dispatch Cascade (bank $00, $0AEA)

The dispatch at $0AEA receives a 16-bit text ID in DE and cascades through
range checks to select the handler bank:

```
Text ID range     → Handler Bank
$0000-$00E1       → bank $42
$00E2-$0197       → bank $43
$0198-$0243       → bank $44
$0244-$02C7       → bank $45
$02C8-$03C7       → bank $46
$03C8+            → bank $47
$0500-$0511       → bank $48
$0512-$05DF       → bank $49
$05E0+            → bank $4A
$0600+            → bank $4A (different group)
$0700-$07BF       → bank $4A
$07C0+            → bank $4B
$0800-$0867       → bank $4B
$0868+            → bank $4E
$0900+            → bank $4E
```

Bank $56 has a parallel dispatch cascade that mirrors this logic.

### Key RAM Variables

| Address | Name | Purpose |
|---|---|---|
| $C822 | TextID_High | Text ID high byte (page/group selector) |
| $C823 | TextID_Low | Text ID low byte (index within group) |
| $C8A4 | InteractType | NPC interaction type (AND 3: 1=talk?) |
| $C8A6 | VRAMUpdateState | Per-room VRAM update state (NOT text!) |
| $D7D2+ | NPCBuffer | NPC RAM data (32 bytes per NPC) |

### The $6119 System (NOT Text — Visual Updates)

The function at $01:$60E7 runs per-frame during gameplay:
1. Checks various state flags ($C850, $C88F, wInGateworld, wGameState)
2. If all pass, dispatches via rst $00 indexed by wMapID (table at $6119)
3. Each handler does room-specific visual work:
   - Castle ($00): VRAM updates via $65E0
   - GateHub2 ($08): Palette animation using $C8A6/$C8A7 as counter
   - GoopyRooms ($19/$1A): VRAM tile swaps at $9320↔$93D0
   - Most rooms: RET (no visual effects)

### How Custom Dialogue Would Work

1. **Assign text IDs** for custom NPCs in an unused range (e.g., $0A00+)
2. **Add dispatch entry** in bank $00 ($0AEA cascade) for range $0A00+ → custom handler bank
3. **Add parallel entry** in bank $56's cascade
4. **Create script handler** in empty bank (e.g., $69): maps script_id to text strings
5. **Create text data** in empty bank (e.g., $6A): encoded text using game's codec
6. **Map NPC script_ids** to text IDs (needs understanding of the conversion mechanism)

### UNKNOWN: script_id → text ID conversion

How does the game convert an NPC's script_id (byte 4 of NPC entry, 0-255)
into the 16-bit text ID stored at $C822/$C823? This likely involves:
- The map_type (to select the base text ID range)
- The script_id (as an offset within the range)
- Possibly the step variable (for dialogue that changes with story progression)

**SameBoy investigation needed**: Breakpoint $0AEA, talk to an NPC, examine
$C822/$C823 to see the text ID. Then trace back to find what SET those values.

### NPC RAM Buffer ($D7D2)

Each NPC occupies 32 bytes at $D7D2 + (index × 32):
- Byte 0: NPC type/flags
- Bytes 1-4: position, sprite, script_id (from ROM data)
- Byte 5: Status flags (bit 0 = interacting)
- Remaining: movement state, animation, timers

Bank $04 handles NPC interaction state via Jump_004_42cd.
Bank $06 iterates NPCs for rendering.

---

*Discovered June 2026. Corrects previous misidentification of $6119 as text dispatch.*
