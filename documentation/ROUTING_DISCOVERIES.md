# ROOM ROUTING DISCOVERIES — DWM1 ROM

## Core Mechanism

ALL room transitions that change map_type go through one code path:

1. Destination map_type is written to `$C96D` at `$0B:$45AB`
2. Gate flag (byte after map_type) written to `$C96E` at `$0B:$45AF`
3. `$C96D` copied to `$C968` (active map_type) at `$0B:$401E`
4. `$C96E` copied to `$C969` (in_gate flag) at `$0B:$4024`
5. Room loading at `$0B:$4088` reads spawn table at `$26DD + map_type × 8`

The data read by `$45AB` comes from Bank 0B ROM via `LD A, [HLI]`. HL points to a transition data block with format:

```
Byte 0: destination map_type
Byte 1: gate flag (0x00 = normal, 0x01 = entering gate)
Bytes 2-4+: spawn/position data (bytes 3-4 are the primary spawn coordinates)
```

**Entry size is approximately 7 bytes**, tightly packed with adjacent entries. DO NOT overwrite more than bytes 0, 3, and 4 when redirecting — overwriting bytes 5+ can corrupt adjacent entries.

## Five Code Paths for $C96D Writes

| PC | System | Patchable? | Used for |
|---|---|---|---|
| `$45AB` | ROM data via LDI | **YES** | Stairs, door entries, room exits |
| `$524B` | RAM at `$D7B9` | No | Double doors (Castle↔GreatTree, Vault) |
| `$52E8` | HRAM at `$FFA3` | No | Castle exterior door exit |
| `$52F3` | Computed return | No | Leaving Library/OldMan/Renamer/etc |
| `$46C1` | RAM at `$C960` | No | Gate floor transitions |
| `$5A16` | Register A/B | No | Vine shortcuts, farm holes |

Only `$45AB` transitions are directly patchable in ROM.

## Exit Data Format

The exit data table (pointed to by bytes 2-3 of step entries) contains:
- `0x90` entries: 5 bytes `[90 FF X Y dest_map_type]` — walk-on coordinate triggers
- `0x8F` entries: 5 bytes — arrival/spawn points (SKIPPED by exit checker)
- `0x82`/`0x80` entries: 5 bytes — skipped
- Non-bit-7 byte or `0xFF`: terminates the exit search

The `0x90` exit's byte 4 is the destination **map_type directly** (NOT a room_id). These also go through the $C96D mechanism.

## Screen Transitions vs Room Transitions

- **Screen scrolls** (walking between GreatTree screens 1-8): do NOT change map_type. No $C96D write. Handled by scroll/position system.
- **Jump points** (GreatTree jump-down ledges): also scroll-based, no map_type change.
- **White-screen transitions** (entering buildings, gates, etc.): change map_type via $C96D.

## Confirmed Patchable Entry Transitions

All at `$0B:$45AB`, verified via SameBoy `watch $C96D` + backstep.

```
FLAT ADDRESS  BYTE  TRANSITION                          12-BYTE DATA
0x02CE08      03    Castle stairs DOWN → Gate Hub        03 00 01 02 05 07 05 04 00 05 07 05
0x02CE0F      04    Castle stairs UP → Farm              04 00 05 07 05 04 07 01 00 80 04 04
0x02CFC1      00    GreatTree scr1 → Castle (door)       00 00 05 04 07 05 04 00 00 05 05 07
0x02CFD0      16    GreatTree scr2 → MedalMan            16 00 00 03 07 ff 04 03 06 00 01 04
0x02CFD8      06    GreatTree scr3 → Arena (left tile)   06 00 01 04 07 05 03 06 00 01 05 07
0x02CFE8      12    GreatTree scr5 → Library             12 00 04 05 07 04 05 18 00 00 04 00
0x02CFEF      18    GreatTree scr5 → Well                18 00 00 04 00 ff 05 01 0f 00 00 05
0x02CFF7      0F    GreatTree scr6 → Vault               0f 00 00 05 07 09 03 02 00 00 00 03
0x02D006      09    GreatTree scr7 → Starry Shrine       09 00 04 04 06 05 01 0d 00 00 05 07
0x02D00D      0D    GreatTree scr7 → Old Man Gate Room   0d 00 00 05 07 04 04 10 00 00 04 07
0x02D014      10    GreatTree scr7 → Copycat House       10 00 00 04 07 ff 04 06 09 00 04 04
0x02D032      0C    GreatTree scr8 → Renamer             0c 00 00 02 07 ff 02 01 0c 00 00 02
0x02D492      03    Gate Hub → sub-level 2 (stairs)      03 00 04 07 05 07 02 26 00 00 08 07
0x02D524      23    Gate Hub → Room of Beginning         23 00 00 07 07 05 01 23 00 00 08 07
0x02D541      03    Gate Hub sub2 → sub1                 03 00 00 07 05 ff 07 05 03 00 00 07
0x02D82B      05    Farm → Stable                        05 00 02 06 04 ff 07 05 00 00 05 07
0x02D833      00    Farm → Castle (stairs)               00 00 05 07 05 ff ff 40 58 4e 58 5c
0x02D998      04    Stable → Farm (stairs)               04 00 04 06 04 ff a6 59 ae 59 b6 59
0x02DC2B      1D    Arena → Monster School               1d 00 00 05 07 ff ff 05 02 1f 00 00
0x02DC34      1F    Arena → Queen Room                   1f 00 00 05 02 ff 05 02 1f 00 00 05
0x02DC61      1E    Arena → Restaurant                   1e 00 00 05 07 ff 05 07 06 00 00 05
0x02E49E      07    Queen Room → Arena (leaving!)        07 00 01 05 02 ff a6 64 68 d9 03 2d
0x02E4D5      00    Room of Beginning → Gate (flag=01)   00 01 00 00 00 ff dd 64 69 d9 05 2d
0x02EACE      00    Boss Room gate → Castle (post-boss)  00 00 01 04 05 ff d6 6a 77 d9 10 26
```

## Confirmed Patchable Exit Transitions

All at `$0B:$45AB`, verified via SameBoy `breakpoint $0B:$45AB`.

```
FLAT ADDRESS  BYTE  ROOM EXIT → DESTINATION              12-BYTE DATA
0x02CE16      01    Castle → GreatTree                    01 00 80 04 04 05 07 01 00 80 05 04
0x02D2C5      01    Bazaar → GreatTree                    01 00 09 09 03 ff ff ff ff ff ff ff
0x02D51D      00    Gate Hub sub1 → Castle                00 00 05 02 05 04 01 23 00 00 07 07
0x02D541      03    Gate Hub sub2 → sub1                  03 00 00 07 05 ff 07 05 03 00 00 07
0x02D833      00    Farm → Castle                         00 00 05 07 05 ff ff 40 58 4e 58 5c
0x02D998      04    Stable → Farm                         04 00 04 06 04 ff a6 59 ae 59 b6 59
0x02DA1D      01    Arena → GreatTree scr3                01 00 84 05 03 ff 04 00 07 00 06 04
0x02DE62      01    Starry Shrine → GreatTree scr7        01 00 0c 04 06 ff ff ff 72 5e 7a 5e
0x02DEBA      01    Renamer → GreatTree                   01 00 8d 02 01 ff c2 5e 58 d9 01 30
0x02DF3D      01    Old Man Gate Room → GreatTree          01 00 8c 05 01 08 02 1e 01 00 00 00
0x02DF6B      01    Vault → GreatTree                     01 00 89 05 01 ff 73 5f 5a d9 05 30
0x02DFC6      01    Copycat House → GreatTree              01 00 8c 04 04 ff 04 07 01 00 8c 04
0x02E070      01    Library → GreatTree scr5               01 00 88 05 03 06 01 13 00 00 06 07
0x02E1CD      01    MedalMan → GreatTree                   01 00 81 03 02 ff 03 07 01 00 81 03
0x02E2AC      01    Well → GreatTree                       01 00 08 04 05 ff ff 02 06 08 01 00
0x02E3F0      07    Monster School → Arena                 07 00 80 05 01 ff f8 63 66 d9 1e 30
0x02E432      07    Restaurant → Arena                     07 00 82 05 01 ff 3a 64 67 d9 01 2d
0x02E4C7      03    Gate of Beginning Room → GateHub       03 00 81 04 01 08 07 03 00 81 05 01
0x02E525      03    Gate Room (Villager/Talisman) → GateHub 03 00 81 02 02 02 02 01 01 00 00 00
0x02E583      03    Gate Room (Memories/Bewilder) → GateHub 03 00 81 07 02 05 01 03 01 00 00 00
0x02E5E1      03    Gate Room (Peace/Bravery) → GateHub    03 00 80 07 02 03 03 06 01 00 00 00
0x02EACE      00    Boss Room → Castle                     00 00 01 04 05 ff d6 6a 77 d9 10 26
0x02E1CD      01    MedalMan → GreatTree                   01 00 81 03 02 ff 03 07 01 00 81 03

```

## Non-Patchable Exit Transitions

These use computed return paths — the destination is determined by the room's own code, not by patchable ROM data:

- Shrine vine → Farm: `$5A16` code path (register-based)
- Castle ↔ GreatTree exterior double doors: `$524B`/`$52E8` (RAM-based)
- Stable → Vault rooms: `$524B` (RAM double-door system)

## Bidirectional Routing — Proven Working

**To redirect an entrance and fix the return path:**

1. **Patch the ENTRY byte** (byte 0 at the entry address) to the new destination map_type
2. **Patch entry spawn bytes 3-4** (offsets +3 and +4 from entry address) to match the destination's normal entry spawn — DO NOT change byte 5 or beyond
3. **Patch the DESTINATION's EXIT spawn bytes 3-4** (offsets +3 and +4 from exit address) to match where you want to return

**Example — Library entrance → Starry Shrine, Shrine exit → screen 5:**
```json
{
  "raw_bytes": {
    "0x02CFE8": "09",
    "0x02CFEB": "04",
    "0x02CFEC": "06",
    "0x02DE64": "88 05 03 06"
  }
}
```

**Confirmed working destinations** (from Library entrance testing):
Working: 0x01, 0x02, 0x03, 0x04, 0x07, 0x09, 0x12, 0x18, 0x53, 0x57-0x59
Breaking: 0x00, 0x05, 0x06, 0x0A, 0x0D, 0x10, 0x16, 0x23, 0x30+, 0x42, 0x52, 0x5D

## Double Door Entries

Double doors (e.g., Arena, Castle) have **separate entry addresses per tile**. The Arena left tile is at `0x02CFD8`, the right tile is likely at `0x02CFDF`. Both must be patched for a complete redirect.

## Room Loading Table at $26DD

Bank 0, address $26DD. 8 bytes per map_type:
- Bytes 0-1: tileset/graphics pointer
- Bytes 2-5: default spawn position → $FF9D-$FFA0

Code at `$0B:$4094` reads: `HL = $26DD + map_type × 8`
Gate variant at `$2A5D` used when `$C969 != 0`.

## Bank 0C Routing Table ($41BA) — NOT for Transitions

The table at `$0C:$41BA` with 6 master entries (Castle, GreatTree, Bazaar, Gate Hub, Farm, Stable) is for **room rendering/tile setup**, NOT for transition decisions. Patching it affects visuals and can trigger NPC dialogues, but does NOT redirect room transitions.

## SameBoy Debugging Commands

**Finding any transition's patchable byte:**
```
breakpoint $0B:$45AB
```
Then perform the transition. When breakpoint fires:
```
registers          → note HL value
examine/12 $XXXX   → where XXXX = HL - 1
continue
```

The byte at HL-1 is the patchable map_type byte.
Flat ROM address = 0x0B × 0x4000 + (HL-1 - 0x4000) = 0x2C000 + (HL-1 - 0x4000).

Use `tools/hl_calc.py` for automatic calculation:
```
uv run python -m tools.hl_calc [PC] [HL]
```
