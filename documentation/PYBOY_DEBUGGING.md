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

**Field menu in a hijacked state (S96 round 4):** A on nothing opens the
menu only when the party is non-empty (bank $06 `Jump_006_6247` checks
`[$ca8d]`) — call `give_party_monster(p)` after the last warp, then tap A;
`wGameState` ($C8EB) bit 1 = menu open. That is enough to test menu /
INFO pages and (with encounters enabled) a battle round trip.

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

## S99 techniques + one trap

- **Force a dispatch index from a hook.** `p.register_file.A = n` inside a
  `hook_register` callback on a `rst $00` changes which jump-table entry runs
  (measured: bank $01 $6118, the room-animation dispatch). One room can then
  host every handler — `tools/census_room_animation.py`.
- **VRAM by bank.** `p.memory[0, 0x9000:0x9800]` reads VRAM bank 0 regardless
  of the game's VBK; writes work the same way (the census seeds a pattern).
- **Measure over a pattern.** A handler that rolls / swaps blank tiles shows
  no change on the room's own art — fill the buffer with a unique pattern
  first (KEY_LESSONS S99).
- **Trap — A-spam after CONTINUE.** Tapping A 40 times on a real save left a
  menu open: nothing animated and walking did nothing, which looked like an
  engine failure. Tap A only until `$C88A == 1` and `wGameState` ($C8EB) is 0,
  then B until it stays 0 (the S92 rule, again).
- **A/B timing.** A patch that changes a routine's cycle count shifts
  multi-frame VRAM loads by a few bytes at frame edges — A/B from ONE
  savestate and require convergence (KEY_LESSONS S99), not frame equality.


## S100 techniques (gate floors, saves) + two traps

- **Continue a patched-format save.** The user's `.sav` is in the PATCHED
  format (checksum v3, F2 gate, R4 snapshot): the ORIGINAL ROM rejects it and
  starts a new game (map $2F). Boot a patched build; the menu recipe that
  reaches CONTINUE: `adv 400 / START / adv 120 / A / adv 120 / A / adv 200 / A`
  then tap A until `$C88A == 1` and `wGameState == 0`.
- **Trap — savestates do not travel between builds.** A state saved on build
  A and loaded into build B whose bank $73 shifted hangs at the next far call
  (stale return addresses): map $00, `wInGateworld` $80, nothing moves. Make a
  continue state PER ROM from the `.sav`.
- **Drive gate floors without walking mazes.** Staircase kick (what
  `Jump_00b_46a7` writes): `wGateID`, `wCurrentFloor = floor − 2` (entry 5
  increments), `$C96D = 0`, `$C96E = $80`, `$C96C = 1`, `$C88F++`, then ~700
  frames (keep `$CA39/$CA3A` high). Real gate entry (the pedestal exit's own
  bytes): `$C96D = gate`, `$C96E = 1` → the first-entry branch, floor 1. Hook
  `$16:$5C1C` (special) / `$5BBF` (maze) / `$5BE1` (boss) to log decisions.
- **Trap — kicking OUT of a special maze room** ($57-$59 keep their own state)
  can wedge the next floor (blank screen, kicks ignored). For statistics,
  reload one state per sample and vary the frames waited before the kick
  (the RNG advances with time); an A/B of two builds then compares
  decision-for-decision.
- **Save + reload inside a test.** Menu OPTN → JOURNAL: `A (80) / down / right
  / A (60) / down ×3 / A (90)`, then A for YES; hooks `$07:$6090` (refused) /
  `$07:$60A5` (allowed). `p.memory[0, 0xBFCA]` reads cart SRAM bank 0;
  `p.stop()` writes `<rom>.ram` — copy it as a new `.sav` and boot again.
- **YES/NO in talk scripts starts on NO** (`$C83C = 1`): press up before A.
- **S100 r3 — compare transitions as pictures, not frames.** Two builds whose
  far calls differ by a few cycles give raster/fade frames that differ in 1-2
  scanline bands (the LCD caught mid-update), same picture. Diff per frame,
  then check the bounding boxes before calling it a regression.
- **S100 r3 — check VRAM tile DATA, not only the tilemap.** A room drew as
  flat colour blocks while the tilemap matched the layout: the sheet sat 256 B
  low in `$9000-$97FF` (LZSS over-long copy). Compare `$9000 + 16*i` with the
  project sheet slot by slot.

## S102 techniques — frame-exact VRAM checks, cost per call, SameBoy cross-check

- **Every frame, every animated slot.** For a room's own animations the
  check is: after each `tick()`, the 16 bytes at `$9000+16*slot` (VRAM bank
  0) must equal ONE of that slot's authored frames (built with
  `editor2/core/tileanim.groups`); record the step sequence and the gaps
  between changes (= the speed; longer gaps = the dispatch guards paused it,
  e.g. the status bar popping up). Leaving to a vanilla room and warping back
  must keep the count of bad frames at 0 (the sheet reloads; the next step
  heals).
- **Cost of a routine in scanlines.** Hook its entry and its exit (e.g.
  `$6C:$4003` and `CustomTileAnimate.done`), record `(frame, LY)` at both,
  cost = frame delta × 154 + LY delta. Hooking `PerRoomVRAMDispatch` and
  `IncrementVisualStep` ($01:$4EAA) gives the whole animation dispatch; a
  frame with no MainFieldLoop pass (no exit hook fired) = a dropped frame.
- **PyBoy blocks VRAM writes in mode 3 — GDMA included** (measured S102: a
  build with the HBlank wait removed showed 581 bad tile-frames). Still, for
  anything timing-critical cross-check in SameBoy:
  `tools/sameboy_anim_check.py --project P --map 6C --x 5 --y 6 --sav S`
  (SameBoy core + `tools/sameboy/dwmcheck.c`; setup in the tool's
  docstring). Same boot / CONTINUE / warp mailbox as `pyboy_harness`.
- **Negative control.** Before trusting a "0 mismatches", run the same check
  on a deliberately broken ROM (patch one `jr` to `nop nop`) and see it fail.
- **Trap — building SameBoy's core into your own harness**: compile it with
  the SAME defines as the core objects (`-std=gnu11 -D_GNU_SOURCE`, no
  `-DGB_DISABLE_DEBUGGER` unless the core had it) or `GB_gameboy_t`'s layout
  differs and it crashes in `GB_timing_sync` (SIGFPE); call
  `GB_set_turbo_mode(gb, true, true)`.

## S109 techniques — a stub call that resumes, driving the arena on a real save

- **Stub call + resume.** To run one routine inside a live game (e.g. the
  text engine, an arena loader) write at a free WRAM spot: `push af/bc/de/hl`,
  `ld a,[$4000] / push af` (the current bank's self-id — valid for the code
  banks and every custom bank, not `$20`/`$40`/vanilla-empty banks), optional
  `ld hl,<arg>`, `ld a,<bank> / ld [$2000],a / call <addr>`, `pop af /
  ld [$2000],a`, `pop hl/de/bc/af`, `jp <the PC you replaced>`; set PC to the
  stub and tick. The game carries on afterwards (a parked `jr $` with `di`
  freezes it — KEY_LESSONS S109).
- **Enter a room the way the game does.** A warp straight into the Arena
  Battle room ($5D) at an arbitrary pixel broke the room script; use the
  lobby transition's own arrival (px `0x78`, `0x58`) or walk in through the
  lobby (GreatTree (4,12), walk up → lobby sub-room 1; receptionist: up 3,
  left 1, A; YES = up then A).
- **Measure a team, not a screenshot.** After the room is built read the
  display list `$D7CA-$D7D1` ([draw id, is_monster] × 4) and `$DA02`; in
  battle the enemy slots (`$D7D2 + 32·i`); after each won match the next
  team must load (bank $50 `LoadArenaEnemyStats` with `wColiseumBattle` =
  the next match). Gold = `$CA4B-$CA4D` (24-bit) before/after the class menu
  gives the fee actually charged.

## S114 techniques — census of a choice + a draw, field battles in a loop, talks with YES/NO

- **Stub-call census of a chooser and a draw.** `tools/census_encounters.py` boots to the
  title screen and stub-calls bank $01 entry $0D (the list choice) and $0B (the battle
  draw) with wInGateworld / wMapID / wGateID / wCurrentFloor / event flags poked, wRNG1/2
  pinned before every draw; it reads wEncounterPoolIndex, wC8A9, `wEncListBuf` and
  $DA02-$DA08. Works on the ORIGINAL ROM too (it reads the list from the ROM there), so the
  same tool proves the vanilla model and a patched build.
- **Field battles in a loop.** Walk left-left-right-right in 18-frame holds; a battle has
  started when `wGameState` ($C8EB) bit 6 is set or `$C88A` leaves 1 — read $DA02-$DA08
  then (EncounterMonsterSelect wrote them). Mash A (4 on / 4 off) until `$C88A == 1`, the
  map is back and `wGameState == 0`; read the counter ($CA39/A) to see the re-seed. A strong
  enemy can outlast 9,000 frames of A — treat a timeout as "no result", not a stall.
- **YES/NO talks.** A on the NPC, advance the question's boxes, `up` (the cursor starts on
  NO), A, then exactly the answer's boxes; then wait for `wGameState` 0 and the script
  flag ($D8D7 bit 0) clear. An extra A re-opens the talk (KEY_LESSONS S114).
- **Gate entry and floor kicks (measured S114 on the user's save).** Real entry =
  `$C96D` = gate, `$C96E` = 1, `$C96C` = 1, `$C88F` = 1 (~700 frames) → floor 1. From a maze
  floor (wInGateworld 1) the staircase kick (`$C96D` 0, `$C96E` $80) did NOT increment
  wCurrentFloor: poke `floor - 1` for the floor you want (the S100 note "floor − 2" was
  measured from special rooms). **S115 re-measure (contradicts the line above as worded):**
  from a maze floor the kick DID add one — poke wCurrentFloor 1 → 2, poke 2 → 3 (0-based;
  game floors 3 and 4) — i.e. poke (the game's floor number − 2); see DOC_AUDIT S115. Settle ~120 frames and B away any box before poking a warp
  after a battle, or the mailbox is ignored.

## S115 techniques — a gate entered by walking, the accessor swept by stub calls, boss joins

- **Enter a gate the real way.** Put the entrance in a room you can warp into (the demo's
  custom room), warp next to it, walk onto it (`up` holds of 18 frames) and wait ~1,200
  frames: wGateID / wCurrentFloor / wLastFloor / wBossMapType and the row buffer
  (`wGateRowBuf`, $D138) tell what entry 5 read. Hook the accessor and the far entry
  (`hook_register(0x16, GateRowPtr)`, `(0x76, NewGateRowCopy)`) to count the calls.
- **Sweep an accessor over its whole index range.** At the title screen write `di / ld
  a,<bank> / ld [$2000],a / call <addr> / jr $` at $DD40, poke the index (wGateID), set
  PC = $DD40 and SP, tick 3 frames, read `register_file.HL` — gates 0-255 in seconds; a
  sentinel in the buffer ($EE) shows which indices copied.
- **After battles:** press B until `wGameState` ($C8EB) is 0 before walking — a lone B can
  leave the field menu open (the loop then sees "no battle"). A boss that joins a full
  party asks "Choose a monster back to farm": mash A with a `down` every ~25 presses to
  reach OK. Floor kicks from a maze floor: see the S115 re-measure above.


## S120 techniques — text boxes as pictures, voices by hook, talk battles, forcing a floor type

- **Capture each text box.** Compare only the box's rows between frames and leave out the
  blinking wait arrow (rows 137-142, x 80-87): a box is "resting" after ~24 identical
  frames; then snap and press A (a YES: `up`, then A). The field box is the bottom 5 tiles
  (y 104-143) — but when the player stands low on the screen the game opens it at the TOP.
  Rooms with animated tiles change the screen every few frames, so whole-screen equality
  never settles.
- **Which voice a text used.** Hook `PlaySoundEffect` (`$00:$1B2C`, from game.sym) and
  record `register_file.A` with the text pointer `$C82D`; attribute each blip to the
  bank $60 `CustomText_NN` label at or below the pointer (an insert prints from RAM —
  `$C0C8` / `$C180`).
- **Preview == game.** Render the editor's box (`talk_editor.render_box(…, scale=1)`) and
  compare its dark pixels (value < 60) with the game's box crop (0, 104, 160, 144): 0
  differences on 4 boxes S120 (the hero's name differs on purpose: the preview draws
  the new-game "TERRY" tiles).
- **Trap — the first warp after a CONTINUE base state can be ignored** (the mailbox is
  consumed, the map stays): repeat the warp until `wMapID` changes (`goto2` in the S120
  scratch helper; KEY_LESSONS S119 "wait for $C850").
- **Win a talk battle.** Wait for `$C88A` ≠ 1 with A taps 40 frames apart (multi-box
  texts come first), then ONE A every 50 frames (FIGHT is the default; a 4-on / 4-off
  mash ends up in the skill list). A joinable enemy with a full party asks "Choose a
  monster back to farm" — fight a project enemy with `joinability` 7 and 1 HP instead.
- **Force a gate's maze floor type.** Hook `$16:$5BD2` (right after the maze path's
  `SelectFloorType`) and set `register_file.A` = the type; enter gate 1 with the portal
  mailbox (`$C96D` = 1, `$C96E` = 1, `$C96C` = 1, `$C88F` = 1), keep `$CA39/$CA3A` high
  (a new game has no party) — `tools/census_gate_floor_types.py`.

## S122 techniques — a generator re-run in place, screens vs the model, a walk on the user's save

- **Re-run a routine in place (census of a generator).** `tools/census_maze.py floors`:
  hook the generator's ENTRY (`$16:$605B`) and its END (`$16:$63AE`); at the entry write the
  inputs (RNG `$C899/$C89A`, maze size `$C93D`, contents row, `$CAB4`, `$C92D`), at the end
  capture every output, then set `PC` back to the entry from the hook and write the next
  inputs. Thousands of floors run without a room change or a frame of gameplay between
  them; the frame budget per batch is `max(3000, 40·n)`. A hook that never fires for a
  case = the routine hung (the freeze probe uses exactly that).
- **Capture after the terminator.** Hook the instruction after the last write of the data
  you read (`$63AE`, the `ret` after `ld [hl], $FF`), not the one before it — the list was
  unterminated at `$63AC` (KEY_LESSONS S122).
- **A screen vs the editor's picture.** Warp / walk in, wait 30 frames, take
  `p.screen.image`, render the same screen with `ProjectRenderer.render_screen` and compare
  every 8×8 tile that no sprite covers (OAM `$FE00`: Y-16 / X-8, 8×16 objects) — 0 tiles
  differing = the preview is the game (`verify_theme.py`, the S122 demo walk).
- **Walk a demo end to end.** Movement = hold the D-pad 18 frames per tile (with the
  random-battle counter `$CA39/$CA3A` held at `$FF/$7F`), then 6 frames; walk to a tile by x
  then y and stop when `MAP_ID` leaves the expected set; talk = A, then A at every text box
  (`$C8EB` bit 0) until the box flag clears, saving a picture per box.
- **Stub-call a far routine from a hook.** Write `ld hl, $<bank><entry> / rst $10 / jp <PC>`
  into free WRAM (`$DD40`), set `PC` there, advance 3 frames, restore the bytes — used for
  the 20 GateBossWin calls (`wintail_check.py`) with random starting flags.
- **Trap: `pkill -f <pattern>` matches the shell running it** and kills the tool call; kill
  by PID instead.
## S123 techniques — single-tile moves, text boxes at rest, winning battles by script, colour by OAM

- **One tile per press.** Hold the D-pad a few frames, release, then wait until
  `PLAYER_TX/TY` changes (cap ~40 frames) — `move1`. Holding a fixed 18 frames overshoots
  after a slowdown (a coloured-NPC room, a scroll) and the walk drifts.
- **Edge doors need a second push.** A door on x = 9 / y = 7 fires only when the player
  pushes against the screen edge from the door cell: one more press in the same direction.
- **A text box at rest.** Snap when the box rows (crop y 104-136 minus the blinking
  ▼ arrow's cells) are unchanged for 8 frames; the arrow alone otherwise makes every frame
  "new". Then A.
- **Win a battle by script.** `GAME_MODE` 2 = battle; tap A every 50 frames (FIGHT → the
  default target); poke `$DB85` = 7 to suppress the "wants to join" prompt; B closes a
  menu opened by mistake; outside battle press A only while `$C8EB` bit 0 (a box) is set —
  A in the field opens the menu.
- **Is an NPC coloured?** Read the OAM (`$FE00`, 40 × 4 B): the pieces at the NPC's screen
  position carry the palette in attr bits 0-2 — compare with the palette it should have;
  scroll the screen and read again (the colours must follow the slot, not the position).
- **Cost of a per-frame hook:** measure it in the emulator against the same room and
  input with the feature off, never by counting cycles on paper — S123 colour path:
  ≈ 1.2 scanlines per NPC, ~1.2 % dropped frames in a 4-NPC room with 2 coloured NPCs,
  none seen in the user's rooms.
- **Read enemy ids as words** (KEY_LESSONS S123).
- **Which transition ran?** Log `$C905` (the transition ladder) and `$C8B8` (sound
  requests) per frame while walking onto the exit: a portal / fresh gate entry = states
  1-6 with sound `$52` (~350 frames), an in-gate floor change = `$10-$17` with sound
  `$55`. Walk onto the real cell — a warp injected from another room takes another path
  (KEY_LESSONS S123 r2).
