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

## S125 techniques — answering YES at the right frame, losing on purpose, the item menu

- **When does the YES / NO box open?** `$C83C` (the answer byte) becomes 1 (NO, the
  default) on the frame the choice box opens — measured: talk A at frame 0, `$C915`
  climbs 4 → 11 in 15 frames, `$C83C` 0 → 1 at frame 157. Poke `$C83C` = 0 before the
  talk, press A to advance boxes only while it is 0, and on 1: wait ~20 frames, `up`, A.
  Pressing on a timer answers NO whenever the text is slower than the timer.
- **Lose a battle on purpose:** set every party record's HP word (+$50) to 1 (MP +$54
  too, to see the heal) before a talk battle against a strong enemy (EID 213 Esterk),
  then tap A every 20 frames until `GAME_MODE` is 1 again on the destination map.
- **Use an item in the field:** A opens the field menu (INFO ITEM / SKIL OPTN; `right`
  needs a 40-frame settle before A or INFO opens), ITEM lists 5 per page (`right` turns
  pages), A → USE / DEL, A → "… throws a WarpWing!", A. A gate floor to use it on: the
  pedestal's own mailbox (`$C96D` = gate, `$C96E` = 1, `$C96C` = 1, `$C88F`++, ~1,200
  frames, keep `$CA39/$CA3A` high), then A until `$C8EB` bit 0 clears.
- **Invisible sprites after a warp:** compare `$C8EC` with an arrival that draws them
  (KEY_LESSONS S125).
- **Is a room laggy, and why? — frame phases.** Count `MainFieldLoop` ($01) entries per
  600 frames while walking (600 = no frame dropped). For the why, hook the loop's own
  points — entry, `jr_001_4e0b`, +4 (after the bank $04 VM), +8 (bank $06 entry 6), +11
  (`CheckScriptBeforeAction`), +15 (bank $06 entry 1, the NPC sprite draw),
  `jr_001_4e29` (the `ret`) — record `(frame, LY)` at each, cost = Δframe × 154 + ΔLY.
  Build variants of the room (no NPCs, n NPCs, no tile animations) and compare; to price
  one patched call, byte-patch it back to the original in a copy of the ROM (ROOM_DATA_FORMAT
  "What NPCs cost per frame").


## S126 techniques — did a menu give the room back? walking to an NPC, logging every line

- **Room restored after a menu?** Read VRAM bank 0 `$9000-$97FF` (the room sheet, slot =
  (addr − `$9000`)/16) and the VISIBLE part of the map (`$9800 + 32·row + col`, rows
  0-17, cols 0-19 at scroll 0) before the talk and after the script ends. Columns 20-31
  of the map are the menus' scratch and stay changed — not a fault. Slots that change
  without any menu are the room's tile animations (a hall copied from a room with
  vanilla animation `$23`: `$13-$16`, `$19-$1C`; new_rooms' water `$0C-$0E`), so judge
  the slots the menu writes (`$60-$7F`), not "any change".
- **Walk, don't warp, to an NPC:** tap a direction (hold 6, wait 24), wait for idle,
  check `PLAYER_TX/TY`; three tries per cell, then give up and report — a warp proves
  nothing about whether the player can reach the NPC. Face it with a 2-frame tap.
- **Every line a menu speaks:** hook ROM0 `TextBankDispatch` (HL = the text id; `[$4000]`
  = the calling bank, the return address on the stack) AND bank $60 `CustomTextDisplay`
  (id = `$0A00` + `$C822`·256 + `$C823`) — since S126 a service set's line arrives
  through the second hook only.
- **Answer YES to a guide:** `up` before every A while talking (it is harmless in a text
  box and does not wrap in the choice box) until the map changes — no timer guessing
  (the user's save has slow text).
- **Finish whatever menu is open:** B every 100 frames until idle — alternating A and B
  walks back into the menu.
- **Every sprite vanishes during a talk (S126 r2)?** Count the visible OAM entries (Y 1-159,
  X 1-167) with the box open and read `$FFD3` (1 top / 2 bottom box) and `$FFD4` (the tile
  threshold: sprites over BG tiles ≥ it are skipped; `$80` normally). Diff HRAM
  (`$FF80-$FFFE`) before / after each menu — the farm left `$60`.

## S127 techniques — breeding, gate floors from a room, harness traps

- **Breed through a menu:** talk A, the question A (YES), the list A (the first
  selectable monster), then **A again** ("Are you okay with this monster?" waits for A on
  the user's slow text) and only then `down` + A for OK — a `down` sent while the line
  prints is lost and A opens INFO. "Start the breeding ceremony?" A; then A every 24
  frames until the map is the room again and `$D951` = `$F0` / `$F1` / `$F2` (log
  `(map, $D951)` changes: 4 → map $08 → 5 → `$F2`).
- **Naming screen:** START (jumps to END), then A.
- **Is the random breeder rolled?** `wBreedSlots` (`$D4F3` + 4k: state, pool, row) and
  `wBreedVals` (`$D503`: level, arena × 12, seen / 2, story points) right after the
  question — the row must equal the name in the box.
- **An every-gate room's chance:** from one floor-1 state, reload, wait 7k + 1 frames (the
  RNG advances with time), staircase-kick floor 2 (S100 recipe), count map = the room
  over 24 samples; from a hit kick floors 3-6 for once-per-dive.
- **Trap — harness warps that hang PyBoy:** `warp()` keeps the screen index of the room
  left; into map $09 (the Starry Shrine) or GreatTree screen 7 the game crashes or PyBoy
  stops returning from `tick()` — identical on a pre-S127 build (a worktree of HEAD).
  Reach those by walking through their doors from a place a warp reaches safely.
- **Trap — `rest()` in animated rooms:** the shrine's stars never let the screen rest;
  use fixed waits there.
- **Trap — a driver with fixed timing re-rolls the same mate (S127 r2).** The game's RNG
  (`GenerateRNG`, x' = 5x + $1357) advances every frame; a loop that leaves and re-enters
  with exactly the same frames can land on the same value mod the weights (four Yeti in a
  row). Vary the wait per visit (17 + 29k frames) before calling a roll "stuck".
- **The mate a breeder staged:** during the ceremony the master's monster is roster slot 21
  (`$CAC1 + 21 × $95`: +9 species, +`$4B` level, +`$50` HP).
- **Box placement (S127 r3):** read `$FFD3` (1 top / 2 bottom) and the box base
  `$C919/$C91A` (bottom = `[$C909] + $01A0`) after each box opens; drive the talk from a cell in
  the lower half too (the default flips at player y − scroll ≥ `$50`).

## S128 techniques — the arena

- **Arena desk walk:** from the lobby's screen 1 (14, 7) up 3 to (14, 4), face left, A (the
  desk is an examine spot across the counter). The class menu's selection state =
  `$C8EF` 4, `$C905` 3, `$C906` 2; the cursor = `$C8E3` (column) / `$C8E2 & $7F` (row); the
  marks `$C0D8`-`$C0DF` (`$90` open, `$AC` won, `$9C` locked).
- **Win / lose a match:** poke the enemy HP words `$DBAB` / `$DBAD` / `$DBAF` to 1 (win), or
  each party monster's HP (`$CAC1 + idx × $95 + $50`) to 1 (lose). `$D9CD` after the return:
  `$FE` won the class, `$FF` lost.
- **Text ids:** hook `TextBankDispatch` (`$00:$0AD9`, HL = id) and `CustomTextDisplay` (bank
  $60; id = `$0A00 + [$C822] × 256 + [$C823]`) — the run's whole dialogue in order.
- **Paint checks:** snapshot the arena room ~200 frames after each battle (mode 2 → 1) to see
  that the room's tiles survive the post-battle redraw.
- **Trap — four PyBoys reading one .sav at once:** one boot failed (a read race); start runs
  20 s apart.
- **Trap — an NPC driver that presses A after the last box re-talks the NPC:** press A only
  while the script flag (`$D8D7` bit 0) is set and a box (`$C8EB` bit 0) is up.

## S129 techniques — story checks, quests, music by flag

- **Read any flag the way the game does (a stub call):** write a tiny routine into free
  WRAM (`$DD40`: push all / `ld bc, flag` / `call TestEventFlag` / A := Z ? 0 : 1 / `ld
  [$DD60], a` / pop all / `jp <the old PC>`), point PC at it, tick 2 frames, read `$DD60`.
  Works for the virtual flags `$18xx` (the story checks) on the user's real save — a census
  of every check against the save's bag / gold / farm / party in one boot.
- **YES / NO answering:** watch `$C83C` (the answer byte the box writes) — set it to 0
  before A; when the box sets it to 1, wait 20 frames, press UP for YES, then A.
- **Song checks:** `wCurrPlayingBGM` `$C8B5` = the song that is playing (`$C8B7` = the
  request queue, `$FF` once consumed). A room's song by flag: warp in (or the quest's
  refresh) and read `$C8B5` after ~60 frames.
- **Gate floors without the gate menu:** from a room, `$C96D` 0 / `$C96E` 1 / `$C96C` 1 /
  `$C88F` 1 (gate 0 floor 1) and keep the party's step guard (`$CA39/$CA3A` = `$7FFF`) while
  ticking ~1,400 frames; then `$C8B5` = the floors' song.
- **Trap — a step right after a warp / a refresh:** the first walk input after the room
  loads can be eaten (the stairs "did not work"); wait ~120 frames or step twice before
  calling an exit broken.
- **Trap — the user's own arrival cutscenes:** warping into the user's rooms plays their
  scenes (Cities_FOUNT: "I am a shopkeep!"); close the boxes with B until the script flag
  clears before driving an NPC.

## S130 techniques — the stub-call census, ten family rigs, hook traps

- **Stub-call census with the RNG pinned** (`tools/census_raising.py`). Boot to the title,
  write a tiny stub into free RAM — `di / ld hl,<entry> / rst $10 / ld a,$A5 / ld [MARK],a /
  jr $` — set `wRNG1/wRNG2` to a known state, point PC at the stub and tick until the
  MARKER byte reads $A5 (≤ 200 frames, else fail loudly with the PC and the record's key
  bytes). The model replays the same draws from the pinned state, so every call is one exact
  comparison (create / level-up / learn / breed / birth). A longer caller loop (the bank $51
  learn caller around `ld hl,$0605 / rst $10` and its `$FFD8-$FFDA` protocol) is hand-
  assembled the same way, ending in the same marker write. Two rules that made it work:
  - **Completion = the marker, never the PC**: at frame end the PC can be inside an
    interrupt handler.
  - **Leaving a routine mid-call restores SP**: the past-max-level apply path ends in a
    bank $51 battle-screen redraw that waits forever at the title; `TAIL_HOOK` (hook on
    `$51:$5C23`) sets SP back to the value saved when the stub started and jumps PC to the
    marker write. Without the SP restore the stack drifted into WRAM and `tick()` hung after
    hundreds of calls.
  - A **control** belongs in every census: the census also evaluates learning on the
    POST-gain stats and counts how often that would differ (921 level-ups) — proof the run
    can tell the two orders apart.
- **The family rigs** (`simulator/measure_f*.py`, all copies of the S85 loop rig): every event
  carries the full 8-slot board; new flags per rig are listed in TOOLS_AND_DATA "S130 rows".
  The reusable ones: per-round SCHEDULES (`--sched SLOT:skill@target,…` in F6/F7/F10;
  `--sched/--esched R:SK:T[:SLOT]` in F9), forced queues for any slot (`--q`, F5),
  init / round / per-frame pokes (`--set`, `--poke`, `--rpoke`, `--stp`, `--side`, `--ram`,
  `--db42`, `--aib`), RNG injection at a site (`--db42rng`, `--critrng`), species-row swaps
  (`--dc3c`), and `--db73 0` for the wild condition inside a rig battle.
- **Waypoints that carry the S130 decodes**: the crit stage `$53:$586A`, the post-calc stage
  `$53:$58FB`, the tension rolls `$58:$5A40/$5BA1`; act state 7 interception `$53:$5411`
  (SuckAll `$5458`, Cover `$54D6`, Dodge `$557A`, TailWind `$5594`, MagicBack `$55CA`); the
  BladeD counter at `$52:$7C47`; the multi-hit continuation dispatch `$52:$7041` and the bank
  $58 re-pick `$642C`; the dispel handler `$52:$4BA1`, its return `$52:$6CDD` and the bank
  $53 entry-11 sub-states `$60C9…$6252`; the apply `$52:$6D56`. Take a sweep VICTIM at
  `miss_in` / `miss_rng`, not at `target_fetch` (`$53:$520C` fires before the fetch loads it),
  and take an effect's post state at the end of its own machine (`UltraDownEnd_66bd`,
  `$52:$6D37`), not at the handler return.
- **Determinism**: a rig run with the same recipe, ROM and state reproduces the identical
  event stream (`measure_f4.py`: 158,794 events, same RNG trajectory) — a changed count means
  a changed rig or ROM.
- **Trap — a hook on `$52:$7C18` stalls PyBoy.** It is the instruction right after
  `call BattleRNG` in `BladeDCounter_7bec`; with it registered the battle crawled (~35
  frames/s), no hook fired repeatedly, `faulthandler` showed the time inside `p.tick`. Use
  `$7C47`. When a capture crawls, bisect the HOOK LIST first (`F6_NOHOOK=tag,…`,
  `F6_TRACE=1` in `measure_f6.py`); avoid hooking the return address of a call.
- **Trap — party slot 0 may not do what you forced.** Its obedience roll (Darkdrium on the
  user's save) replaces the commanded action, and a `$DD0B == 2` actor that is not first in
  the round re-decides at act. Cast the skill under test from slots 1/2 (e.g. SideStep from
  slot 1), or from more than one slot, and count the handler waypoints per skill and side.
- **Trap — polled hooks**: `$52:$6D56` re-enters every frame while the apply animation
  waits; keep the first hit per run inside the callback.
- **Trap — the queue is read at act time**: a forced queue must stop changing between the
  order build and the act phase (latch the round index at `$D9EC == 4`, count `round_start`
  waypoints, not `round_end`); and forced runs can never validate commit-time decisions.
- **Trap — pokes**: `$DB42` is rewritten after init (re-poke each command frame); board pokes
  only at `$D9EC` 4/5 (the engine passes `$D9EC = 6` between actors); re-arm pokes inside the
  round_start hook before its snapshot; a KO reloads the slot from its source, undoing pokes.
- **Trap — `pkill -f <pattern>` from the tool shell kills the shell itself** (its command line
  contains the pattern): kill by PID, or use a `[c]haracter-class` pattern.
- **Corpus hygiene**: write one JSON per rig battle and merge once (append-and-rewrite went
  quadratic past ~25 MB); drop unvalidated tags and gzip (`f4_events.json.gz` 198k events in
  3.6 MB).

## S132 techniques — measuring a story step, a party by records, the editor under a profiler

- **A story step played by the game's own scripts** (`tools/census_story_state.py`): start
  from the state your model says holds BEFORE the step (`Engine.start(recipe, repoke=False)`:
  flags / RAM poked before the warp only), then let the real scripts play it — an arena class:
  `$D9CD` = $FE, `$D9CE` = class, warp into the lobby's screen 1 (its entry script runs the
  victory cascade, then warps to the Castle); a gate: warp into the boss room, write what the
  boss script writes before its tail (`$D9E3`, `$D92B` = 7, the tail's cleared flag), arm the
  script AT the tail (the counter = the word offset from the script's start — also for tails
  the decode from pos 0 never reaches, the Medal Gate) and repeat for each tail (Demolition:
  warp back in between). Run until the field is idle for 240 frames, then compare.
- **Trap — the re-poke.** `Engine.start` re-poked the recipe's RAM after the load (right for
  a cutscene); it overwrote what the arriving room's entry script had just written (a whole
  arena cascade). `repoke=False` for any "what does the room do on arrival" measurement.
- **Trap — flags that are RAM.** Bits of `$D99B + n` past `$D9CA` are engine variables:
  `$D9CD` (`wColiseumBattle`) shows as "flags" $0190-$0197, `$D9E3` (the speech) as
  $0240-$0247. Diff flags in $0000-$017F (+ $0248-$0257) only.
- **A party from records** (`Engine.start(records=…)` / `put_party`): 149-byte records into
  slots 0-2 + count + list after the room loaded. Checked: walk to another room, enter a gate
  (`$C96D` 0 / `$C96E` 1 / `$C96C` 1 / `$C88F` 1, keep `$CA39/$CA3A` high), start a battle
  (`$CA39` 1 then walk), win with the enemy HP words `$DBAB/$DBAD/$DBAF` = 1 and A every 50
  frames: `$C88A` back to 1, the party unchanged, exp up.
- **The editor under cProfile, offscreen.** `QT_QPA_PLATFORM=offscreen`, open the user's
  project in `MainWindow`, find the live `RoomsTab` (the LAST one — `findChildren` also returns
  the start-up tab of the previous project), then time `canvas._begin_stroke` /
  `_stroke_cell` / `_end_stroke` + `app.processEvents()` and the space meter's
  `measure_banks` separately. Modal boxes block an offscreen run forever: replace
  `QMessageBox.warning / information / question` with a printer in such scripts.
- **Trap — relative project paths.** A project opened as a relative path gives a relative
  `last_rom`; the playback process runs elsewhere ("No such file"). Play here absolutizes.

## S133 techniques — "does anything happen between A and B?", a 4 MB ROM, three traps

- **Hook pairs bracket a window.** To prove a buffer survives from an event to a later one,
  hook both ends AND every writer of the buffer, log `(name, frame)` with a frame counter
  you advance yourself, and compare snapshots taken at both ends. S133: bank $0B
  `jr_00b_45a8` (exit fire), bank $60 `CopyExitListToBuffer` (the only writer of
  `wCustomExitBuffer`), bank $73 `CF2WarpCommitDrain` (the commit) — zero copies between
  fire and commit, the 28 bytes identical (a custom door and a GreatTree redirect).
- **Script reads across a warp.** Hook bank $60 `CustomScriptRead` and log
  `(wScriptMapType $D8D3, wMapID, word counter $D8D5)`; with the commit hook in the same log,
  "which room's script was read after the commit" is a list filter.
- **A 4 MB ROM in PyBoy.** `p.memory[0x2100] = 0x80` then `p.memory[0x4000]` reads bank $80's
  first byte (restore the bank you found at `[$4000]` afterwards). A runtime far call needs a
  call site: S133 put `push hl / ld hl, $8000 / rst $10 / pop hl` at the top of bank $73
  `CF2WarpCommitDrain` in a SCRATCH tree and counted calls in a WRAM byte — never in the repo.
- **Trap: CONTINUE by A-mash leaves the field menu open** on a real `.sav` (the party HP/MP
  window is drawn over the room). Tap B a few times before warping.
- **Trap: an entry cutscene owns the room after a warp** (a custom room's `cutscenes` with
  the entry trigger): tap A until `$C8EB` bit 0 and `$D8D7` bit 0 are both clear before
  driving the player.
- **Trap: the first move after `warp()` can report two tiles** (GreatTree screen 8: warped
  to y 22; an `up` press — 20-frame hold, or two 4-frame taps — reported y 20, and the
  walk-on exit at y 21 never fired: `VanillaExitResolve` ran once, at 20. From y 20 one
  `down` step landed on 21 and fired at once). Log the position after each move and approach
  a walk-on exit from a tile you have SEEN the player stand on. Not investigated further
  (the warp's pixel spawn vs the tile grid is the suspect).

## S134 techniques — every bank switch, a JOURNAL save that works, Qt in this sandbox

- **Log every bank the game selects.** PyBoy 2 has `p.register_file` (A, F, B, C, …): hook
  every ROM0 `ld [$2100], a` (scan `$0000-$3FFF` for `EA 00 21` — 23 sites in both trees) and
  read `p.register_file.A` in the callback (the hook fires before the instruction). S134: a
  play-through on the user's save (rooms, doors, a redirect, the menu, a gate, a battle) =
  ~200,000 switches over 63 banks, highest `$7E` — on the 2 MB and the 4 MB build alike.
- **The save, corrected (supersedes S100's recipe where they differ):** stand on a tile
  FACING NOTHING (facing an NPC, A talks); A opens the field menu (INFO / ITEM / SKIL / OPTN;
  START only shows the party's levels); `down / right / A` = OPTN (TEXT SPD / CH ORDER / CH
  PLAN / JOURNAL); `down ×3 / A` = JOURNAL, "Record to the Journal?" with the cursor on YES →
  A → "Recorded in the Journal." Hook `SaveGameState` (`$00:$2128` in the user's S134 build)
  to know it ran; `p.stop()` writes `<rom>.ram` → boot it as the next `.sav`.
- **Qt tests in this sandbox:** PySide6 6.12's audio backend segfaults here (PipeWire, no
  client.conf) — run `test_app.py` / `test_canvas.py` with `QT_AUDIO_BACKEND=none
  QT_QPA_PLATFORM=offscreen`. test_app may still segfault AFTER printing `PASS` (Qt teardown);
  the result is the `PASS` line.

## S135 techniques — the game's picture vs the editor's over many rooms, a hang that is the game

- **Whole-demo picture check:** for every room × screen, warp to tile x = 10 k + 5 (screen k of
  a 3-wide room; `SCREEN_IDX` read back == k in all 12 census warps) or walk there, wait 30 frames, `p.screen.image` vs `ProjectRenderer.render_screen`,
  compared per 8×8 tile over rows 0-15 (the HUD is rows 16-17), skipping tiles any OAM entry
  touches (`tools/census_stream_banks.py` `bg_tiles` / `sprite_tiles`). Screens of one room: walk
  along a row the room keeps walkable (the demo paints a floor corridor) — `PLAYER_TX` 10 k + 2 is
  screen k.
- **A guide's YES on a ONE-box question:** S126's "`up` before every A" answered NO here (the
  choice opened between taps); S125's rule worked every time: poke `$C83C` = 0, A only while it is
  0, on 1 wait 20 frames, `up`, A.
- **PyBoy stops returning from `tick()` = maybe the game, not the harness.** A warp into a room's
  undefined screen hung (like the S127 trap), and so did WALKING into it — game mode `$FE` on the
  last frame seen. Walking reproduces = a game defect; then confirm the cause by patching the one
  table word in the generated `.asm` and walking again (S135: the render row — KEY_LESSONS S135).
  Run such probes with `timeout` and a log file (a hung probe holds the tool call until its limit).


## S136 techniques — a stub census of far-call forwarders, an A/B by warps, D-pad timing on a real save

- **Stub census of every forwarded read** (`tools/census_place_banks.py`): the S130 marker stub
  (`di / ld hl,$60xx / rst $10 / store C B E D L H / ld a,$A5 / ld [MARK],a / jr $` at `$DD40`) per
  input; the EXPECTED value comes from the same ROM through game.sym (a script's word = the word at
  its label + 2n in whatever bank the plan put it), so the census proves the routing, not the
  compiler's arithmetic. A talk script's length = up to the next label that is not one of its own
  branch labels (`<label>_…`). Entry 9 (op `$24`) runs from the stub too: point the counter at the
  `$FF24` word, then read the staged tiles at `$C300 + offset`. 20,000 calls ≈ 10 s.
- **A/B of two builds without driving input:** warp into every screen of every room (tile x = 10 k +
  5 within the room's screen grid) and log (a) every script word the engine reads — a hook on bank
  $04 `DispatchBank0F_Ext` + 4 (the `ret` after `rst $10`; BC = `register_file.B / .C`, PyBoy 2 has no
  `.BC` / `.H`, use `HL >> 8`), (b) every text id, (c) `wCustomNPCBuffer` / `wCustomExitBuffer` after
  the load; then compare with addresses mapped to labels (KEY_LESSONS S136). Robust where walking
  scripts are not: the user's rooms' NPCs wander, scenes reposition the player.
- **D-pad on the user's save: hold 8 frames.** A 4-frame tap was missed about half the time (the
  S123 `move1` used 4; the walk then "stuck" against nothing); a 2-frame `face` never turned the
  player. 8 frames moves exactly one tile; 6 frames turns in place against an NPC. Walk around an NPC
  that blocks the target's row by a sidestep (the S136 driver's `walk_to`).
- **NPC positions live:** slot n = `$D7D2 + 32n` (+0 type, +1 sprite, +2 x, +3 y, +4 script) — walk
  to (x, y + 1) and face up; an arrival scene may have moved the NPC from its list cell.
- **Was there a battle?** Sample `GAME_MODE` from a hook on the VBlank vector (`$00:$0040`) during the
  talk: `{1, 2}` = a battle ran.
- **Trap — a 10-frame "the box rests" rule fires mid-print on slow text** (the user's text speed):
  harmless when A is only pressed while the script flag (`$D8D7` bit 0) is set — pressing A after the
  script ended re-opens the talk (the S128 trap again).

## S137 techniques — a bank $17 walk by stub, real palette RAM, "did the colours come back?", two traps

- **Call bank $17 entries 0 / 1 from the S130 stub** (`ld hl, $1700` / `$1701`, `rst $10`): poke
  `wMapID`, `wScreenIndex`, the screen's counter and `wInGateworld` = 0, fill `$C200…` / `$C797…`
  with `$EE`, call, read back: entry 1 leaves the attr map at `$C200`, entry 0 the palette slots 0-3
  at `$C797` (after the forcing: colour 1 := slot 7's unless the colour-3 bit-15 marker is set). Do
  NOT poison slot 7 (`$C7CF-$C7D6`) — the forcing copies it. `tools/census_place_banks.py` S137.
- **Reach a ruled state by its flags, not its counter** (the rules run first and overwrite the
  counter): event flag `idx` = `$D99B + idx / 8` (< `$1000`) or `wExtFlags + (idx − $1000) / 8`, mask
  `$80 >> (idx & 7)`.
- **The real CGB BG palette RAM:** write `p.memory[0xFF68] = i` (BCPS, no auto-increment needed) and
  read `p.memory[0xFF69]` for i = 0-63 — compare it with `$C797` before / after a menu.
- **"Did the colours come back?"** Before / after the field menu (A facing nothing, B ×8), a talk
  battle (A, `up` when `$C83C` = 1, A until `GAME_MODE` went 2 and back to 1 with the script done) and
  a service screen (the librarian: A until `GAME_MODE` ≠ 1, B until idle): `$C797` slots 0-3, BCPD
  and the visible BG tiles not under a sprite must be identical (S137: 24 / 24 in halls of $60 / $81).
- **Trap — `<rom>.ram` is loaded by every boot of that ROM path.** `boot_with_sav` copies the save
  next to the ROM; a later `boot()` + `to_bedroom()` of the SAME path then CONTINUES that save. Delete
  `<rom>.ram` (or use another path) before a new-game run.
- **Trap — a save made in a room the build lacks hangs at CONTINUE** (bank $71's room record,
  KEY_LESSONS S137): for an A/B of the user's project, start a new game instead.
- **Trap (again, S130) — `pkill -f` / `pgrep -f` + `kill` from the tool shell match the shell's own
  command line** and kill it (exit 144). Find the PID with `ps aux | grep '[s]cript'` and kill that.
- **A room's own entry scene replays on every warp in** (the user's Cities_FOUNT shopkeeper): after
  a warp, wait until the script flag stays clear ~90 frames (pressing A every 20 frames while it
  runs), then face the NPC and talk.
- **Where is the text box? (S137 r2)** `$C83E/$C83F` = the open box's tile-map base (bottom box
  ≈ `$99C1` at scroll 0, top `$9821` + the scroll), `$FFD3` = 1 top / 2 bottom. A menu that "prints
  twice" is often the text engine scrolling a box at `$C83E` while the screen draws its own box
  elsewhere. Compare a contact sheet (a frame every 20) of the same line on the ORIGINAL ROM
  (new game: every library family is empty) — `lib3.py` method: boot, `to_bedroom`, warp map
  `$12` (4, 12), face up, A.

## S138 techniques — making a stale save, "was the room loaded?", songs by hook, the menu by timing

- **A save in a room another build lacks:** build a demo with the room, CONTINUE the user's
  `.sav`, `warp()` into the room, JOURNAL (below), `p.stop()` → `<rom>.ram` = the stale save; boot
  the OTHER build with it (`boot_with_sav`). The map id it stands in = byte `$24 + ($C968 − $C8EA)`
  of the file (SRAM `$A0A2`).
- **The JOURNAL by timing (the S134 recipe, made reliable):** A facing nothing, then wait **90
  frames** before the first D-pad press (the menu ignores input while it opens — at 40 frames
  `down` was lost and `right` opened ITEM); every D-pad press **hold 8, wait 30**; `down / right / A`
  = OPTN, `down ×3 / A` = JOURNAL, A on YES. Hook `SaveGameState` to know it ran.
- **"Was the room ever loaded?"** Hook bank $71 `CopyCustomRoomRecord` and log `wMapID` per call:
  after a CONTINUE that goes home, every call reads the hub's id — never the saved one.
- **Test a design by poking from a hook first:** a hook on the instruction where the patch will go
  (here bank $15 `$445B`, the `jr` after the CONTINUE load) can write the RAM the patch would write
  (the warp mailbox, `$C8EA`) — the answer before any code exists (KEY_LESSONS S138).
- **Which song plays:** hook ROM0 `SetBGM` and log `register_file.A` with `wMapID` and `GAME_MODE`
  (1 = the room's song, 2 = the battle's; the battle's end request is the room song again).
- **Talking without walking:** `warp(p, room, x, y)` onto the cell next to the NPC, wait for the
  script flag to stay clear, face it, talk — robust where NPCs wander and arrival cells differ.
- **Trap — mashing A after CONTINUE eats an arrival scene:** to SEE a hub room's arrival lines,
  stop pressing A once `GAME_MODE` is 1 in the hub and take a frame every ~25 (A only while a box
  is open).
