# PyBoy Debugging — Claude runs the ROM (established S70)

**The single biggest capability upgrade since the compiler.** Claude's
sandbox can `pip install pyboy --break-system-packages` (v2.7.0 verified,
pypi is whitelisted) and run the built ROM headlessly with full memory
access, scripted input, savestates, screenshots, and code hooks. Every S70
bug was root-caused this way, two of Claude's own would-be-shipped bugs were
caught pre-delivery, and the full quest battle round-trip (offer → battle →
win → resume → flag → join) was proven without a user test cycle.

**Use it by default.** Any runtime claim ("this script runs at entry",
"this exit fires", "this counter drains at rate X") should be MEASURED, not
inferred from code reading. The harness is `tools/pyboy_harness.py`.

## What Claude can do with it

| Capability | How | S70 example |
|---|---|---|
| Read any RAM/HRAM per frame | `p.memory[addr]` | frame-traced the cutscene freeze to the exact stuck opcode word |
| Write RAM mid-run | `p.memory[addr]=v` | warp anywhere; poke flags/party/counters; poke-bisect a stall to one byte ($C88A) |
| Scripted input | `button_press/release` | drove menus, dialogs, a YES/NO choice, whole battles by A-mash |
| Savestates | `save_state/load_state` | repeatable experiments from the exact frame before a bug |
| Screenshots | `p.screen.image.save` | SAW the textbox render, the guardian walk, the gold palette |
| Code hooks | `p.hook_register(bank, addr, cb, ctx)` | proved "the text servicer NEVER runs in field mode" and "Entry 9 never runs while standing" — hits==0 is decisive |
| A/B ROM comparison | same harness, two ROMs | S70 vs S69 baseline: encounter drain identical → seed myth busted |
| Historical bisection | git worktree + build + harness | five pinned historical ROMs proved the slow exit was a day-one defect, not a regression |

## The warp hijack (skip the whole game)

Scripting the real intro is painful (naming screens). Instead: boot → menu →
bedroom intro (`to_bedroom`), then **write the exit-match handler's own
mailbox** ($C96D dest, $C96F-72 spawn pixels, $C96C=1, $C88F=1) after
killing any running script ($D8D7=0). This teleports to any room with the
real transition machinery. `warp(p, mapID, tile_x, tile_y)` does it.

## Real save files kill most traps (ask the user for a .sav!)

A SameBoy/BGB `.sav` is a raw SRAM dump; PyBoy auto-loads `<rom>.ram`, so
`boot_with_sav(rom, sav)` (harness) + CONTINUE boots a **legitimate** game
state: real party, real flags, real progress — no intro hijack, no
canonicalizer traps, no hand-built monsters. This is the highest-value
artifact the user can attach to a session; request one whenever the task
touches battles, saving, party state, or anything progression-gated.
SameBoy .state files are emulator-specific — NOT usable; only `.sav`.
Pre-S69 saves are 8 KB (the header now declares 32 KB) — the helper
zero-pads. Cart SRAM is also directly addressable for inspection:
`p.memory[bank, 0xA000+off]`.

## Traps learned the hard way (S70)

(Most of 1-2 are AVOIDED ENTIRELY with a real .sav — see above.)

1. **Franken-state artifacts.** The hijacked state skipped the intro, so
   globals a real save always has may be unset. Two S70 red herrings came
   from this: $C917 was $0000 (a completed real dialog leaves $FFFF), and a
   "post-battle stall" was actually an **aborted battle** caused by trap 2.
   Rule: before blaming the ROM, reproduce with the most realistic state you
   can, and A/B against the baseline ROM under the identical harness.
2. **The canonicalizer erases hand-made party state on transitions.**
   `ReadPartySlotInfo` ($01:$46F6) runs on the standard roster epilogues and
   recounts $CA8D from the slot flags. Poke party records AFTER the last
   warp, never before (`give_party_monster`). Pre-warp pokes produce
   half-valid parties → battles abort in ~200 frames and leave the game-mode
   byte $C88A stuck at 2 — which looks exactly like an engine bug.
3. **Event flags are MSB-first**: bit = `7 - (idx & 7)` within
   `$D99B + (idx>>3)`. Reading LSB-first reports set flags as unset.
4. **Keep the encounter counter poked high** ($CA39/3A) while walking in
   encounter rooms, or an empty/invalid-party battle will fire and wedge the
   run.
5. **Screenshots occasionally render blank to Claude's viewer** even when
   the PNG is valid. A ~2.2 KB PNG is a uniform (black) screen = real render
   failure; ~4.5 KB+ with view-failure = viewer flakiness, judge by RAM.
6. **Battle end ≠ teardown end.** Keep mashing A well past the battle-flag
   clear ($C850/$C8AA); EXP boxes and fades follow. Detect clean return by
   `$C88A == 1` + map restored.
7. **Don't chain warps hastily** — leftover transition state races the
   mailbox pokes. Boot fresh or settle generously between warps; one S70
   "regression" was purely this.
8. **PC/registers are not exposed** — only code hooks. Locate hook targets
   by byte-signature search over the ROM or from `game.sym`. Remember label
   name-addresses drift from built addresses in compacted banks (bank $0B
   is ~$77 below its historical names).

## Timing facts measured with it (engine truths)

- Field-mode script servicing = **1 tick / 8 frames**; dialog mode
  ($C915=$0B) services per frame. `delay 30` = 4 s in field, 0.5 s in dialog.
- Encounter counter drains **100 per step** (all ROMs back to S64).
- Vanilla door transition ≈ 19 frames match→change; the pre-S70v2 custom-room
  exit ceremony was ~385 frames; post-fix custom exits ≈ 18.
- Boot→bedroom ≈ 15 s wall-clock at speed 0; a full battle by A-mash ≈
  1000-5000 frames.

## Session-start bootstrap

```
pip install pyboy --break-system-packages
cd <repo> && python3 - <<'EOF'
import sys; sys.path.insert(0, '.')
from tools.pyboy_harness import *
p = boot('<built rom>'); to_bedroom(p); warp(p, 0x6B, 3, 14)
print(hex(p.memory[MAP_ID]))
EOF
```

## Hooks perturb input timing — the S80 "round-2 wedge" trap

**Symptom**: any `hook_register`, even with an empty callback and a cold
address, makes a rigged battle stall in round 2 (~f450-750) while the
identical no-hook run sails through 1500+ frames. Debug logs show no
breakpoint events during the stall; MBC writes continue (the game runs;
the battle waits).

**Mechanism**: PyBoy 2.7.0 installs hooks by patching opcode $DB and
singlesteps past each hit (remove → step → reinject, `core/mb.py`).
That singlestep shifts joypad/interrupt alignment by an instruction;
a sparse input cadence (the old 3-of-24 A-mash) then misses a menu
edge and the battle waits for input forever.

**Rules**:
- Use the dense 4-on/4-off cadence (`if i%8<4: press`) in ANY hooked
  run. Verified: 1500 frames, 6 hooks, 0.4 s.
- Never hook per-frame-polled addresses for long runs: each hit costs
  10-20 ms wall (breakpoint dance + GIL). $57:$7129 is polled every
  frame while the player menu waits — worst case.
- `p.memory` reads and `p.frame_count` are safe INSIDE hook callbacks
  (measured). Registers are readable via `pyboy.register_file`.
- Enable pyboy's own logs with `PyBoy(..., log_level='DEBUG')`;
  `logging.basicConfig` does NOT capture the Cython modules.
