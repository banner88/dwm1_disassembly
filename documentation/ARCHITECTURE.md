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
| $50 | BATTLE MODE manager (wGameMode==2; S68): $D9EC 18-phase battle machine (BattlePhaseTable $5F3A), nested $D9F4 sub-machine (11 states), BattleExitHandler $640A (win→script-resume / loss penalty) |
| $51 | Event sub-handlers, room transitions |
| $52 | Battle system: 115 named skill handlers, SkillFunctionTable at $4011, family checks, math helpers |
| $54 | Post-battle join logic ($55BB), EXP distribution, level-up processing |
| $56 | Text rendering engine, parallel text dispatch cascade |

## Top-level game mode (wGameMode $C88A) — S68

ROM0 runs two parallel dispatch tables on `$C88A`: `$00:$030F` = mode INIT
(called from the main loop at `$02B0` when `$C88E` mode-change latch fires),
`$00:$050F` = per-frame TICK. Sub-modes `$C88B-$C88D`; `$C8AD-$C8B0` saves
the 4-byte mode block for overlay modes. Mode rows (init entry / tick entry):

| Mode | Bank:entries | Role |
|------|--------------|------|
| 0 | $15:0 / $15:1 | Title / new-game / link menus |
| 1 | $01:0 / $01:1 | FIELD (script VM ticks here via bank $04) |
| 2 | $50:0 / $50:1 | BATTLE (BattleInit / per-frame driver) |
| 3 | $02:1 / $02:2 | bank $02 mode |
| 4 | $5F:0 / $5F:1 | map-script/cutscene engine |
| 5 | $5F:8 / $5F:9 | map-script/cutscene engine (2nd) |
| 6 | $18:0 / $18:1 | bank $18 mode (link teardown target) |
| 7 | $55:$0D / $55:$0E | overlay (START saves mode block to $C8AD) |
| 8 | $59:0 / $59:1 | bank $59 mode |
| 9 | $59:2 / $59:3 | bank $59 mode |
| 10 | $59:4 / $59:5 | bank $59 mode |
| 11 | $56:3 / — | bank $56 mode |
| 12 | $56:7 / — | bank $56 mode (SELECT+? saves mode block) |

Battle entry/exit: request latch `wGameState.6` → bank `$13` `$C905`
transition machine (`$13:$73F5` = the ROM's only `res 6`) → mode 2;
`BattleExitHandler $50:$640A` → mode 1 + `$C8EA.7` (script resume). Role
names beyond banks 01/50/13 are best-effort; entries are ROM-verified.

## Empty ROM Banks (23 banks = 368KB in the VANILLA ROM)

`$60, $64, $67, $69-$77, $79-$7A, $7C, $7E-$7F`

> 8 of these are now patch-owned ($60,$64,$67,$69,$6A,$71,$72,$7E). The
> canonical current-allocation table lives in PROJECT_STATE.md "Bank allocation".

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
| $D9EC | Battle phase index (18 phases; bank $50 BattlePhaseTable; S68) |
| $D9F4 | Nested battle sub-machine index (0-10; battle-scoped, NOT the main game state — S68; label wEventStateMachineIndex is historical) |
| $DA00-$DA7F | Temp: enemy stats, monster info copy, breeding vars |

## SRAM Save Layout

SaveGameState (ROM0, bank_000.asm line 6577) copies game state to SRAM:

| WRAM source | SRAM dest | Size | Contents |
|-------------|-----------|------|----------|
| $FF8A | $A003 | 33 B | HRAM (timer) |
| $C8EA | $A024 | $1100 (4352 B) | Main game state (last byte: $D9E9) |
| $C300 | $BCC8 | $0200 | Tile layout buffer |
| $C200 | $BEC8 | $0100 | GBC attribute buffer |
| $CAC1 | $A1FB | 2980 B | Party (separate SavePartyToSRAM path — NOT a second copy: $A024 + ($CAC1−$C8EA) = $A1FB, i.e. a targeted partial update of the same save image) |
| (SRAM-resident, S60) | $A3BA | $0BE5 (17×$95) | **Farm slots 3-19 (CF3, S60)** — live IN the save image at $A1FB+s*$95; never WRAM-resident anymore (vanilla window $CC80-$D664 freed). GMDP forks slots ≥3 here; walkers hop the boundary via bank $73 entry 2. EAGER together with the whole roster image $A1C7-$AD9E, which the v2 checksum EXCLUDES (seed $4638 + $A002×$1C5 + $AD9F×$1261); the canonicalizer tail mirrors WRAM $CA8D-$CC7F→$A1C7-$A3B9. World state stays lazy. Boot verify self-heals vanilla-full and S60v1 stored checksums to v2. |
| (SRAM-resident) | $B124 | $0BA4 (20×$95) | **Farm SLEEP pool (S55)** — a second 20-slot monster array that lives ONLY in SRAM, never WRAM. Gated by $CA41 bit 7; read in place by bank $07 (EnableSRAM per access); initialized by the sleep action (bank $12). One-way archival. Fills the $B124-$BCC7 hole in this map exactly. |

Checksum: $A002-$BFFF → stored at $A000-$A001. Valid flag: $A002 (1 = save exists).

### SRAM banking as built S69 — 32 KB expansion via the RAMB PIN

**Status: BUILT S69, NOT yet user-tested.** The patched build declares 32 KB
SRAM (`HeaderRAMSize $0149 = $03`, banks 0-3) under a global **RAMB-pin
discipline**: RAMB is $00 at power-on (vanilla boot's three literal writes,
kept) and **no engine code ever changes it again** — the 19 ROM0
quadrant-convention writers (`… and $03 / ld [$4100],a` after every ROM-bank
switch: RST_18, the RST_28/30 return tail, `WriteBankSwitch4100` /
`WriteBankReg4100` / `TextSetBank` shared helpers, the tile/SGB/text
loaders, and all four audio-tick sites) are retargeted by one operand byte
each to `ld [$6100],a` — an MBC5-ignored address (vanilla itself writes
$6100 at boot; $6000-$7FFF is unmapped on MBC5). A/flags/timing identical,
so quadrant-1..3 callers that might observe the trampoline's Z flag see no
change. Every existing SRAM consumer (vanilla quadrant-0 save/sleep/trade
cluster, CF3's bank $73 entries, the CF3 walker dereferences in banks
$50/$51) therefore hits bank 0 — exactly the 8 KB cart's behavior — with
**zero changes to any consumer**.

**Why pin instead of per-entry RAMB=0 discipline (the S65 sketch):** the
vblank audio tick is RAMB-transparent *by quadrant convention, not by
value* — it saves the interrupted ROM bank (`ld a,[$4000]` / push af) and
on exit restores `RAMB := quadrant(interrupted bank)` (AudioPopSetDE).
So "establish RAMB=0 inside CF3's entry points" would NOT survive: any
vblank during a bank $73 farm scan would exit the ISR with RAMB=3. The
sound fixes were either di-bracketing every dereference window across 10+
banks, or removing the convention. The pin removes it; interrupts now
cannot move RAMB at all.

**Accessing banks 1-3 (the new +24 KB persistent headroom):** the ONLY
sanctioned path is `CF3SRAMBankedCopy` (bank $73 entry 9; mailbox
`wSRAMXferBank/Src/Dst/Len` at $DE8B-$DE91, patches/wram.asm). It copies
per byte inside `di` windows — RAMB≠0 exists only between di and the
restore-to-0 before ei, so the pin invariant (`RAMB==0` whenever IME is
on) holds at every interruptible point. Contract: call with interrupts
enabled; one side of the copy is the banked-SRAM side; SRAM↔SRAM
cross-bank is unsupported; SRAM is (re-)enabled and left enabled (CF3
policy); DE preserved, A/HL/BC per the usual rst $10 contract.
Byte-executed S69 (emitted-bytes interpreter): copies both directions,
bank isolation, len-0 no-op, DE preserved, zero invariant violations.

**Deliberately untouched RAMB writers:** boot's three `RAMB:=0` (they ARE
the pin's establishment); bank $40's `di`-bracketed 4×8 KB wipe (saves/
restores via the $FFA3 shadow, then `jp InitGameData` → boot re-zeros;
under 32 KB it now genuinely clears banks 1-3 when its $CBC6 gate fires —
its original engine-family intent); bank $20's streaming system
(`RAMB:=[$C68A]` with $FFA3 shadow) — $C68A has **no initializing writer**
in DWM1 (decrement-only, so provably 0 in any reachable execution), all
its exit paths write RAMB:=0, and under the pin its RAMB survives
interrupts *better* than under the convention. Residual, not a hazard.

**Old saves:** an 8 KB .sav loads padded (SameBoy honors the header).
**Bank 1 is now claimed (S69v2): the "R3" roster snapshot** — magic
$52,$33 at bank1 $A000-$A001, snapshot region $A1BF-$AD9E, written by the
explicit-save funnel and restored at load; it self-seeds on first load of
a pre-v3 save (see MONSTER_DATA "Persistence model (v3)"). Banks 2-3
remain uninitialized and unclaimed — any future consumer brings its own
format/magic. The CF3 checksum covers bank-0 regions only, unaffected.
**Pin invariant, stated precisely (S69v2):** RAMB==0 except inside
CF3-owned banked-access windows — entry 9's per-byte di brackets, and the
entry 5/6 snapshot hooks' ~200-cycle chunk windows, which need no di/ei
because the ISR graph neither reads SRAM nor writes RAMB (audited S69:
vblank audio has zero SRAM literals; LCDC is display-only; timer is reti;
serial is inactive in save/load contexts and pin-safe regardless). Entry 9
remains the conservative any-context primitive for future code.

**What remains open in E3** (see ROADMAP): (a2) new-game INIT data as an
authorable object; (b2) story-variable headroom schema on top of the new
banks (allocation map + init/versioning convention for banks 1-3).

#### The S65 audit that motivated the pin (historical, all instruction-verified)

Cartridge header: MBC5+RAM+BATTERY (`$0147=$1B`), RAM size `$0149=$02` =
**8 KB, one bank**. The map above occupies $A000-$BFC7; native persistent
headroom = the tail **$BFC8-$BFFF (56 B)**. A romhack can declare 32 KB
(`$0149→$03`, banks 1-3 = +24 KB persistent) — MBC5 supports it, SameBoy
honors the header, old 8 KB .sav files load padded — **but the engine is
NOT expansion-ready as-is**. S65 audit findings (all instruction-verified):

* **RST_18 sets RAMB on every `rst $10`**: the dispatcher tail
  (`ROM0 $0018`: `swap a / rra / and $03 / ld [$4100],a`) writes
  `RAMB := rom_bank>>5` — quadrant convention $00-$1F→0, $20-$3F→1,
  $40-$5F→2, $60-$7F→3. Dead store on the 8 KB cart (only bank 0 exists);
  LIVE bank switching at 32 KB.
* **`$FFA3` is the RAMB shadow**; disciplined multi-bank SRAM code exists
  in vanilla: bank $40 `jr_040_41a5` region `di`s, then wipes $A000×$2000
  across RAMB 0/1/2… with save/restore via $FFA3 — proof the engine family
  carries genuine 32 KB SRAM infrastructure (gated on `$CBC6`). bank $20
  has 4 more $FFA3-shadowed `[$4100]` writers. All other `$4000-$5FFF`
  "write" hits repo-wide are data-as-code junk.
* **Vanilla's live SRAM users all run from quadrant 0** (banks $00/$01/$07/
  $0A/$12/$15/$18 — save, sleep pool, trade, image copy), so RST_18 leaves
  them on RAMB 0 correctly. **CF3 runs from bank $73 → RAMB=3** under
  expansion: every farm access would hit the wrong bank.
* **The audio ISR dispatches into bank $74 every vblank while music plays**
  (`AudioMasterTableExt` row $9E) → RAMB flips to 3 mid-anything. Any SRAM
  access that isn't `di`-bracketed (CF3's hot paths are not; vanilla's
  save cluster is quiesced, the bank $40 wipe `di`s) can be torn.

**Consequently, expansion requires (E3 scope, one session):** RAMB=0
(re)establishment inside CF3's SRAM entry points (bank $73 entries 3/5/6/7/8
+ the GetMonsterDataPtr fork path) with interrupt discipline (di/ei bracket
or per-access set+access within uninterruptible windows), an accessor
convention for new banked state, and a boot RAMB=0 init audit (vanilla
already writes 0 at boot, bank_000 ~294-304). Do NOT flip `$0149` without
this — the failure mode is silent farm/save corruption.
**[SUPERSEDED S69 — do not build this sketch.** The per-entry approach is
insufficient: the ISR restores RAMB by quadrant recomputation of the
interrupted bank, clobbering any in-bank-$73 establishment, and the
$50/$51 walker dereferences were outside this sketch's surface. The built
design is the RAMB pin — see the as-built section above and DOC_AUDIT
S69.**]**

The main save range $C8EA-$D9E9 covers step counters ($D92A-$D99A), most event
flags ($D99B-$D9E9), inventory, gold, and the party records ($CAC1-$CC7F).
**The CF3-freed window $CC80-$D664 inside it is EXCLUDED from save AND
restore** (its SRAM image $A3BA-$AD9E is the live farm — CF3CopyToSRAM/
CF3CopyFromSRAM skip it both ways, bank $73 entries 5/6). S65 layout of the
window: `wCustomNPCBuffer` $CC80 / `wCustomExitBuffer` $CD00 / step-counter
region $CD80-$CFFF (compiler-owned, 640 B) / `wCustomPool` $D001-$D664
(transient reserve). Init guarantee: ClearAllWRAM (power-on) +
CF3NewGameClear (new game) + the S65 entry-6 tail-clear (after the
main-image restore copy) — gameplay always starts with the window zeroed.
**Flags at byte $D9EA+ (indices $0278+) are OUTSIDE the save range and will NOT
persist.** The custom scratch block at $DE74-$DE8A (wRoomRecScratch $DE7B,
wRoomEncFlag, Tame vars, wCustomRoomFlag, CF3 mailbox) is also outside the
save range — transient BY DESIGN (persistent room state = event flags +
entry scripts, user decision S55, reaffirmed S65).

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

**Safe pool for custom flags (S57 audit, current): 32 flags = $0158-$0167
(bytes $D9C6-$D9C7) + $01E0-$01EF (bytes $D9D7-$D9D8).** The old claim of a
40-flag contiguous block $0158-$017F was pre-CF2: wPendingFarmExp took
$D9C8-$D9CA (= flags $0168-$017F) in S57 (DOC_AUDIT S69). Broader reuse of
the $0158-$0277 range requires excluding the collision rows above AND the
CF2 accumulator. Structural headroom beyond 32 flags = SRAM banks 1-3
(E3 pin, above) once a storage schema exists.
