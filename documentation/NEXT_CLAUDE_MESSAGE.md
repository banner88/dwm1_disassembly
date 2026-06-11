# Message to Next Claude Instance

## Read These First
1. `documentation/KEY_LESSONS.md` — Hard-won debugging lessons. DO NOT skip.
2. `documentation/CROSSBANK_ROOMS.md` — Complete working cross-bank room system.
3. `documentation/SESSION_HANDOFF.md` — What's done, what's next.

## Project State
Dragon Warrior Monsters (GBC) disassembly with a **working cross-bank room system**. Custom rooms can live in bank $60+ instead of the full bank $0B. Proven with single-screen and multi-screen rooms.

## What's Working
- Cross-bank rooms with correct graphics, palette, collision, NPCs, exits
- Multi-screen rooms with scrolling between screens
- Custom rooms can link to each other (room $6B → room $6C)
- All existing game functionality preserved (no regressions)

## What's NOT Working Yet
- NPC scripts in custom rooms (bank $0F master table needs extension)
- Custom tilesets (must reuse existing room graphics)
- Custom text/dialogue
- Step progression in custom rooms

## Critical Rules
1. **NEVER run `make clean` or `git stash`**
2. **NEVER insert bytes into bank $01 or $17** — raw embedded pointers will break
3. **rst $10 clobbers register A** — use DE/HL returns or ROM0 calls
4. **Check KEY_LESSONS.md before making changes** — every mistake documented there was made at least once

## Modified Files
All in `disassembly/` directory:
- `bank_060.asm` — Custom room overflow bank (NEW)
- `bank_000.asm` — ROM0 helpers at $3FE8
- `bank_001.asm` — 4 same-size mapID patches
- `bank_00b.asm` — 6 intercept patches + exit redirect
- `bank_017.asm` — 2 same-size palette patches
- `wram.asm` — WRAM buffer definitions
- `game.asm` — Bank $60 include

## Repo
`https://github.com/banner88/dwm1_disassembly.git`
ROM: `data/DWM-original.gbc` (MD5: `b90957482011c8083a068781033715b7`)
