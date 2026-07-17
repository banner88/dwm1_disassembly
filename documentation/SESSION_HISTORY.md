# SESSION HISTORY — Cold Archive (do NOT read at session start)

> **Purpose.** This file is a verbatim archive of superseded PROJECT_STATE.md
> session blocks and of long narratives compressed out of ROADMAP.md. It exists
> so that consolidation never loses information — but it is **not session
> reading**. Every canonical fact in here already lives in the owning reference
> doc (BATTLE_SKILL_SYSTEM, MONSTER_DATA, GATE_GENERATION, BREEDING_SYSTEM,
> TEXT_SYSTEM, KEY_LESSONS, …); when this archive and a reference doc disagree,
> the reference doc wins. Use this file only for forensics ("when/why did X
> change") — the session index in PROJECT_STATE.md points here.
>
> **Aging rule (SESSION_PROTOCOL §3):** PROJECT_STATE.md keeps only the latest
> TWO session blocks verbose. When a new session block is written, the oldest
> retained block moves here VERBATIM (prepend to Part 1) and gets one index row
> in PROJECT_STATE. Nothing is ever summarized away — moved, not rewritten.

---

## Part 1 — Archived session blocks (verbatim, newest first: S57 → S11)

> Session 58 (2026-07-13 — **CF3 step 1: party-first sort. The invariant
> "party at slots 0-2 in list order, farm contiguous after" now holds after
> every canonicalize** — the CF1-flagged precondition for farm→SRAM.
> Owning section: MONSTER_DATA "CF3 step 1 as built".)
> **User decisions settled at session start (recorded in ROADMAP CF3):**
> (1) party-first SORT over index remapping; (2) freed-range save semantics
> = **EXPLOIT** (keep the vanilla block copy — the range persists across
> save/load; layout rule: transient scratch stays $DE74, relocated buffers
> take a corner, the bulk is the editor's persistent-state pool, usable
> only AFTER the walker redirects land).
> **Implementation (1 operand edit + 1 new bank entry):** canonicalizer
> tail `ld hl,$0106 / rst $10` at $01:$4808 retargeted **$0106→$7301**
> (2 operand bytes $4809-$480A; pattern `79 EA 8D CA 21 06 01 D7 C9` unique
> in ROM). Bank $73 entry 1 `CF3PartyFirstSort` (patches/bank_073.asm):
> selection sort over ≤3 party-list positions (entry state per vanilla:
> occupied contiguous, list compacted/unique ⇒ t=list[i]>i), 149-B record
> swap i↔t + fixups of every WRAM cell holding raw slot indices across a
> canonicalize — later party-list entries (==i→t), battle-position cache
> $DA15-$DA17 (exchange i↔t; vanilla compaction is provably no-op at the
> mid-battle join canonicalize, the sort is not), $CA40 breeding-offspring
> persist (exchange; vanilla compaction happens to preserve it, the sort
> would not). Deliberately NOT remapped: $CAC0 (vanilla "indices unstable
> across canonicalize" contract; positional uses exist), $DA14 (consumed
> pre-canonicalize, verified). $C0D8 map: no caller consumes it after
> return (20-line scan below all 22 sites). Then nest-calls the displaced
> $0106 (rst $10 stack-nests; depth 3).
> **Validation:** emitted bytes decoded (sm83dis) + byte-executed in a mini
> SM83 interp: identity, scattered party [4,0,2], displaced-member fixup
> [1,0], post-breeding $CA40 tracking, empty party, mid-battle-join shape
> (pre-join cache untouched) — 21/21. Patched-build byte-diff vs S57
> reference: header checksum + 2 operand bytes + bank $73 only. Compiler
> regression re-pinned `79dd32c5…` (patched), 18/18 `--rom` green.
> **Two doc errors fixed in place (DOC_AUDIT S58):** the canonicalizer tail
> $0106 is `ScanPartySlotTable` (+$29/+$31 sanitizer), NOT "follower art"
> (MONSTER_DATA CF1 + bank_001 comment block, both corrected, byte-perfect);
> canonicalizer call-site count re-verified with generator: 22 sites /
> **7** banks ($04 $0A $12 $15 $18 $50 $51), S56's "8 banks" off by one.
> **Semantic delta (user to veto in test):** farm-menu display order can
> change when the party changes (sort displaces farm records that sat
> below a party member) — cosmetic, order-only.
> **NEW OPEN (ROADMAP CF3 (a2)):** pre-sort saves load a vanilla-layout
> roster; the invariant only appears at the first canonicalize after load —
> force a canonicalize/sort on the load path BEFORE any walker redirect
> assumes slots 3-19 == farm. Harmless in the sort-only build.
> **v2 (2026-07-14) — phantom-monster incident + $CA40 fixup removal:**
> user's first v1 session showed phantom farm monsters (garbage species,
> 0 HP/MP, PAIRED junk names "0012/0095", levels 1→cap) — ONLY in the S57
> in-gate save; unreproducible from any clean save on S57 OR S58 builds
> (user ran full gate loops both ways). SHELVED with hypothesis (recorded as
> hypothesis, KEY_LESSONS S58): fossils of the pre-S55 slot-14/16 collision
> bug class in that save's lineage, surfaced by CF2's drain leveling any
> flag-$01 garbage into visibility (level spread = garbage exp; 0 HP =
> level-ups don't heal). User advised to archive the .sav as evidence, then
> release the phantoms in-game. The investigation DID surface a real v1
> defect: the sort's $CA40 exchange-fixup rewrites the farm drop/pick flow's
> live candidate register ($CA40 is dual-role — S56's "breeding persist" was
> one flow's view; farm UI writes it per selection at $0A:~$5CC4 and feeds
> it to unguarded flag-marking paths). REMOVED in v2; $DA15-17 fixup kept
> (verified battle-only, 2 refs). Drain's nested calls exonerated by
> reading: $13 entry 2 + $51:$5B31 are context-free record math off [$CAC0].
> Interp re-run vs v2 bytes 21/21; compiler re-pinned `d31c9300…` (patched)
> 18/18; PASS 4/4. Breeding window + stale-$C0D8 state-machine reads are
> WATCH ITEMS in the as-built section.
> **v2 RESOLUTION (2026-07-14):** phantom mystery SOLVED — user found the
> repro (enter/exit well custom room = +2 Drakslimes "0095", level 0, all
> zeros) and the byte trace confirmed the S55 accepted hazard's undocumented
> facet: room $6B S1 NPC table byte 3 ($03, the spawn Y) is copied to
> wCustomNPCBuffer+3 = $D37C = SLOT 15's IN-USE FLAG (slot 16's = $D411 =
> exit buffer byte 24); the next canonicalize normalizes the spray into a
> real farm record. The <=14 rule protects real monsters, NOT empty 15/16.
> The S57 gate save's 4 fossils = two rooms' visits + CF2 drain leveling.
> SORT EXONERATED (predicted to repro on S57). USER RULING: hazard
> re-accepted, no interim patch, CF3 relocation retires it (ROADMAP CF3 (d);
> hazard note sharpened in patches/wram.asm). v2 then USER-CONFIRMED: farm
> multi pick/drop, breeding (the $CA40 watch item passes), full gate run +
> boss, party shuffles, save/reset. Battle JOIN not explicitly exercised —
> carry as a residual test item.
> **NEXT:** user test of the S58 **v2** ROM (party swaps at the farm —
> multiple picks/drops in one visit, battle join, breeding, save/load,
> farm-menu order sanity) → then CF3 (a2) + the two redirected walker
> helpers (b), or A′1.
>
> (S57 + earlier blocks moved verbatim to SESSION_HISTORY.md Part 1 — see Session Index.)

---


> Session 57 (2026-07-13 — **CF2: per-battle exp re-bound to party; farm exp
> banked into a persistent accumulator, paid at the map-change commit.**)
> **Implementation (3 patch sites + 1 new bank; MONSTER_DATA "CF2 as built"
> is the owning section):** (1) `wPendingFarmExp` **$D9C8-$D9CA** (24-bit LE,
> clamp $98967F) — carved from the S8-verified clean event-flag block, INSIDE
> the save image ON PURPOSE: in-gate save rooms exist (FAQ), so pending must
> survive save+reload; boot-cleared, new-game-zeroed, pre-CF2 saves load as 0.
> Flag indices **$0168-$017F retired** from the allocator pool in exchange.
> (2) Bank $50 same-size 14-B window at the exp walker head ($61FA):
> `CF2FarmShareDivert` (67 B, tail nops) still runs the vanilla Div24x8To16
> but banks total/16 into pending and ZEROES the per-monster farm share HRAM
> $DB-$DD — the walker's farm branch and the post-battle all-20 level scan
> become farm-inert with zero loop edits. (3) Bank $0B same-size 6-B window at
> RoomEntry0's map-change commit ($4020): `ld hl,$7300 / rst $10` + 2 nop →
> NEW **bank $73** entry 0 `CF2WarpCommitDrain` does the displaced
> wWarpFlag→wInGateworld store, then, when the DESTINATION is non-gate
> (wWarpFlag=0) and pending≠0, pays each eligible farm monster (flag $01, not
> egg +$63, level≠99, level<cap) the full pending and levels it with the
> IDENTICAL silent vanilla pair the post-battle farm scan uses
> ($1300 threshold / $1302 gains / $510d apply — all context-free, only
> [$CAC0]; nested rst $10 = vanilla precedent, bank $50 does it). [$CAC0]
> saved/restored. **Semantic deltas (user to veto in test):** farm
> exp/levels land at the first non-gate transition, not per battle (invisible
> — farm UI is town-only, and vanilla farm level-ups are SILENT: the
> party-list pass gets the display state, the all-20 scan is the $1302+$510d
> pair with no message — code-verified); mid-run storage recruits get the
> FULL run's pending (slightly generous); drain also fires entering in-gate
> special rooms (wWarpFlag=0) — an early payout, semantically safe (vanilla
> paid farm mid-gate every battle).
> **Validation:** emitted bytes decoded at all 3 sites (sm83dis);
> divert+drain byte-executed in a mini SM83 interp (accumulate ×2, clamp at
> 9,999,999, multi-level drain, egg/99/cap/party/empty skips, gate-dest
> passthrough, zero-pending early-out — all pass). Compiler regression
> re-pinned: compat build == the S57 hand-staged patched build md5-equal
> (`6c41f0d8…`, **patched**), 18/18 `--rom` tests green; old reference
> `026970d3…` (patched) historical.
> **⚠ FLAG-POOL DEFECT found + fixed in passing:** EVENT_FLAGS' "broader safe
> ranges" (and `editor2/core/project.py FLAG_SAFE_RANGES`) were script-only
> analysis — per-byte audit vs engine literals + all_scripts.json shows
> $D9CC, $D9D9-$D9E2, $D9E4-$D9E5, $D9E7-$D9E8 are LIVE (engine named vars
> and/or script-referenced). Truly clean persistent flag bytes: **$D9C6-$D9C7
> + $D9D7-$D9D8** (32 flags after the CF2 retirement, not "~200").
> EVENT_FLAGS rewritten in place; FLAG_SAFE_RANGES now
> [(0x0158,0x0167),(0x01E0,0x01EF)]; DOC_AUDIT addendum + KEY_LESSONS S57.
> **USER-CONFIRMED 2026-07-13 (`DWM-S57-CF2-TEST.gbc`):** farm exp up at the
> farm UI after a multi-battle gate run; save in an in-gate save room →
> reload → exit gives the FULL run's exp (persistence proven); party
> level-ups/display unchanged; town walk clean. Semantic deltas above stand
> un-vetoed.
> **NEXT:** CF3 (order: party-first sort first; the open user decisions in
> ROADMAP CF3 must be settled before it starts) or A′1 (mapID ≥$80 audit).

> Session 56 (2026-07-11 — **CF1: the monster-array access map. Byte-neutral;
> deliverables = docs + tool + JSON + source comments only.**)
> **Membership model (the CF1 headline):** party is NOT positional — dual
> representation: per-record in-use flag +$00 (**$00 empty / $01 farm /
> $02 party**, tri-state, what battle trusts) + party order list **$CA8D**
> (count) / **$CA8E-$CA90** (slot indices, $FF empty; battle position cache
> $DA15-$DA17). Synced by the CANONICALIZER `ReadPartySlotInfo` ($01:$46F6,
> entry 5, **22 call sites / 8 banks** — every roster mutation's epilogue):
> flags normalized $01, listed slots re-marked $02, array COMPACTED
> (149-B record swaps toward slot 0; old→new map at $C0D8), list remapped,
> $CA8D recounted. Records MOVE between slots on every canonicalize.
> **Exp (walker $50:$61E2, ONE walk over all 20):** party member =
> total/eligible-count (KO +$4A bit7 excluded; ±1 rounding quirk), farm =
> **total/16 each**; skips eggs (+$63 flag), level 99, level≥cap; total in
> $DD23-25 (RAM-map row solved). Level-ups: party list first, then all-20
> scan `jr_050_6318`. **The party/farm forks are single-site** — CF2 is a
> retarget, not new plumbing.
> **New structures:** EGG flag = record +$63 (set by egg-receive
> $12:jr_012_6c0a + builder sub-cmd $5E); KO bit +$4A.7 (bulk-cleared by
> $01 entry 9); nickname = +$0C ×9 (old "+$14 name" row was its last byte);
> two $FF-terminated ID lists +$29 ×8 / +$31 ×25 (semantics unverified);
> **staging pseudo-slots $14/$15 @ $D665/$D6FA** (GetMonsterDataPtr masks
> $7F): breeding parents (copied+deleted pre-bank-$16; fields read at
> +$0BA4/+$0BA4+$95), link-trade transit (send $15:jr_015_5aa5; receive
> $18:~$4C50 with forced SRAM saves = anti-clone), bank $15 menu scratch.
> $CA40 = offspring first-empty slot persist; $CA42 ×9 = name text scratch.
> Roster mutation paths enumerated (gives $28/$29, egg, battle join
> $51:SetBtlS_63e8, breeding ×2 variants, release $12, trade ×2, sleep $12
> init + $07 scans, compaction) — table in MONSTER_DATA.
> **Deliverables:** MONSTER_DATA "Party/farm boundary semantics + monster-
> array access map" (owning section); `tools/map_monster_walkers.py` +
> `extracted/monster_walkers.json` (**all 44 $CAC0 writers** — the S55
> count's origin: 44 = the `ld [$cac0],a` sites — **+ 60 register/stride
> walkers classified**; self-checking: drift in writer set or labels
> aborts); known_RAM_map rows ($CA40/$CA41/$CA42/$CA8D/$CA8E/$CA91/$CAC0
> tri-state/staging/$DA14/$DA15/$DD23 + record fields); audit_wram curated
> staging entry (gaps 34→31, selftest re-pinned incl. $D78E extent);
> bank_054 header corrected (claimed "EXP distribution entries 0-6" — they
> are the skill-record accessors — and "$CA94 party/storage count" — it is
> the seen-bits array; DOC_AUDIT row added); discovery comments at 17 sites
> across 10 banks (build byte-perfect after).
> **⚠ CF3 design input:** arc premise "party stays hot in slots 0-2" is
> false in vanilla — CF3 needs a party-first sort in the canonicalizer or
> index remapping (user decision pending). The S55 "$15-special release"
> was actually trade/breeding staging.
> **NEXT:** CF2 (exp accumulator + chokepoint drain — fork sites now known)
> or A′1 (mapID ≥$80 audit). T2 / S2f / blink remain parked; `--apply`
> decision from S53 still open. **OPEN USER DECISIONS for CF3** (details
> ROADMAP CF3 S56 amendments): save-persistence semantics of the freed
> range $CBEB-$D664 (it is inside the save image + SavePartyToSRAM copy);
> party-first sort vs index remapping.


> Session 55 (2026-07-10 — WRAM relocation, reduced form; block below moved
> verbatim from PROJECT_STATE by S57 per the aging rule; it was retained
> there without its own header, appended to the S56-era notes):
> **MID-SESSION CRASH POST-MORTEM (user test of the first S55 ROM): hard
> crash on room entry + on scroll after loading an in-room save.** Root
> cause: the old block was initialized by ADDRESS ACCIDENT (inside both the
> boot clear — ClearAllWRAM stops at $DDFF — and the SRAM save image); $DE74
> is inside neither → power-on garbage counters (the S53 crash mechanism,
> resurrected) + wCustomRoomFlag no longer restored on load. Fixes (v2):
> ClearAllWRAM `$1E00`→`$1EE0` (boot zeroes $C000-$DEDF; same-size operand
> edit, single early-boot call site) and flag DERIVED := (wMapID ≥ $6B) every
> movement frame at CopyCustomRoomRecord head (bank $71 template re-pinned
> per §5; TEMPLATE_SIZE 0x71: 103→116). Load-in-room now shows step-0 content
> — expected under transient semantics, not a bug. Full lesson: KEY_LESSONS
> S55 ("vetted-unclaimed is NOT initialized" + "one variable per test ROM" —
> the first S55 ROM wrongly stacked the never-user-tested S53 master-table
> fix under the relocation; v2 delivers COMPAT first).
> **What moved (patches/wram.asm; all refs were label-based → zero patch-bank
> edits; template sha256 pins UNCHANGED):** step counters $D478→**$DE74**
> (compiler region, STEP_COUNTER_BASE + example-project reserved hole
> →0xDE78), wRoomRecScratch→**$DE7B**, wRoomEncFlag $DE83, wTameDelay $DE84,
> wTameBGSave $DE85, wCustomRoomFlag→**$DE88**; $DE89-$DEDD reserved (85 B).
> Regression md5 re-pinned (v2): S55v2 reference patched build
> **`026970d361f6afe03f28e29fa6e631f6`** (compat) / fixed master-table build
> **`fb6a96abd2b045c68234d74fcfcc76b5`** — historical, superseded: S53 pair
> `3a5a514c…`/`f81d4ad8…`; mid-S55 pair `cc62b5…`/`8878ef…` (crashed, no
> init/flag fixes). Test ROMs delivered: **`DWM-S55v2-compat-TEST-FIRST.gbc`**
> (S53-user-tested table config + relocation/fixes — the isolating build)
> and `DWM-S55v2-fixed-master-table.gbc` (adds the S53 table fix) — **both
> user-confirmed working, 2026-07-10**.
> **USER-CONFIRMED 2026-07-10** ("everything now works without issues", both
> S55v2 deliverables): well entry, egg-give exit + scroll-up, save-in-room →
> reload → scroll all work. This ALSO clears the S53 master-table fix's
> test debt (first user run of the fixed-table config). Standing expected
> behaviors: load-in-room shows step-0 content (transient counters); stored
> monsters #15-16 still corrupt on custom-room transitions (≤14 rule). **NPC/exit buffers stayed at $D379-$D477** (inside monster slots
> 14-15): ACCEPTED legacy hazard of the exploration overlay (user decision —
> saves there are disposable); **≤14-occupied rule stands** for custom rooms
> on the hand overlay.
> **Why reduced (S55 vetting — full detail KEY_LESSONS S55 + wram_usage.json
> regen, 51→34 gaps):** the S54 candidates were FALSE gaps — $C200-$C2FF =
> attr decompression staging (every stream declares declen 256), $C300-$C4FF
> = 512-B screen staging unit (bank $06 bulk copy $C500→$C300 ×$0200; both
> blocks SRAM-save-copied — ARCHITECTURE's save table was right, the S54 read
> of it was partial); $DD80-$DE2B = **AUDIO engine** (6 chan × 26 B +
> scalars; known_RAM_map's "INFERRED battle structs" corrected); stack tops
> $DFFF. $DE74-$DEDD was the only vetted block. **Retired alternative:** cap
> monster slots 20→18 (reclaim $D53B-$D664 298 B; $00 in-use pads defuse all
> 44 read-walkers; give scanner `label4_5c14` + full-check `label4_5f67`
> located) — viable but retired as throwaway-path surgery; do NOT re-derive.
> **New canonical discoveries:** farm SLEEP pool = second 20×$95 monster
> array, SRAM-only at $B124-$BCC7 ($CA41 bit7; bank $07 scans it in place —
> vanilla's own cold-storage precedent); SVBK census: five writes total in
> the ROM → **WRAM banks 3-7 = 16 KB virgin** (docs: known_RAM_map); debug
> mode (banks $55/$56/$59) owns ~10 exclusive WRAM bytes (exclusivity scan).
> **Architecture decisions (user, S55):** vanilla rooms KEPT as postgame →
> mapID ≥$80 audit in scope (custom room #22+), vanilla counter pool not
> harvestable; parallel architecture (overlay = exploration, structural fixes
> = compiler pipeline only); **Cold Farm arc** = editor-era WRAM strategy
> (farm→SRAM, party-only exp + accumulator drained at the castle gate-exit
> chokepoint — user-confirmed: all gate exits funnel there, Arena awards no
> exp; ~2.5 KB freed; exp level-scan loop found at bank $50 `jr_050_6318`).
> Full specs: ROADMAP Arc COLD FARM / Arc LAYER A′; EDITOR_DESIGN §1 S55
> amendments.
> (S55 NEXT superseded by S56 — see above.)


> Session 54 (2026-07-08 — **egg-give root cause: custom WRAM sits inside the
> monster array; audit_wram.py ships. Byte-neutral session** — no ROM delta,
> verifier PASS 4/4, clean build byte-perfect `1ca6579…`).
> S53 anomaly (a) CLOSED (user misread the gate; Pillar B works; the "hub exit
> data" suspect statically refuted — room $24 exits step-invariant). S53
> anomaly (b) **ROOT CAUSE (static, runtime probe pending)**: the party/storage
> monster array (party+farm+eggs, ONE 20-slot limit, user-confirmed) spans
> **$CAC1-$D664** via `GetMonsterDataPtr` indexed access — zero literal refs,
> so the Phase-0 grep audit falsely called $D378-$D477 "unclaimed", and ALL 14
> custom WRAM labels ($D378-$D48B: room flag, NPC/exit buffers, 7 step
> counters, wRoomRecScratch, wRoomEncFlag, Tame vars) sit inside monster slots
> 14-16 (third instance of this bug class after $D95E and $D9A0-2).
> Forward corruption (the user's crash): `$FF29` writes a 149-B record into the
> first empty slot; slot 16 lands the 27 resistance bytes on $D479-$D493 =
> bottom-screen step counter (garbage step-entry ptr → dead exit) +
> wRoomRecScratch (garbage tileset/collision record → scroll-up crash).
> Reverse corruption (silent, worse): `CopyCustomRoomRecord` rewrites scratch
> on EVERY room transition since S42; buffer copies spray slots 14-16 →
> stored monsters #15-17 corrupted by normal play, persisted by saving.
> **Interim play rule: keep the array ≤14 occupied around custom rooms; user
> should inspect stored monsters #15-17 for damaged stats/resistances.**
> Confirmation probe: **RUN AND CONFIRMED by user same session.** Recorded
> values for the fix session — before: $D478-$D47E = 00×7, scratch
> `0d 28 a0 00 00 01 30 00`, encFlag 01, $D488+ = 00. After the give:
> $da14=$10 (slot 16); $D478-$D47E = `c8 22 fa 8b c8 22 fa`;
> $D488-$D497 = `ea 8a c8 af ea 8b c8 21 8e c8 34 fa 42 c8 cb 5f`;
> scratch bytes unchanged (per-frame self-heal, see above). Slot 16 = first
> empty ⇒ the user's save has slots 0-15 OCCUPIED ⇒ **monsters #15-#16
> (slots 14-15) are being actively corrupted by every custom-room visit** —
> slot 15's in-use flag ($D37C) is NPC-buffer byte 3; user advised to inspect
> both. The given egg (slot 16) will itself be corrupted by future room
> transitions (scratch/Tame writes land at its +$6E..+$7A). Deliverables: `tools/audit_wram.py` (4 evidence sources;
> gaps reported UNVETTED, never "free"; `--selftest` pins this detection) +
> `extracted/wram_usage.json` (TOOLS_AND_DATA rows added). Relocation
> candidates from the gap list: $C20D-$C2C2 (182 B), $C42B-$C4C3 (153 B),
> $DE74-$DEDD (106 B) — each needs vetting (pointer-walk loops; SVBK bank-2
> windows exist in bank_051/052, so banked WRAM is NOT assumed free). Docs
> corrected in place: ROADMAP facts row (refuted claim + new Phase 0 item),
> known_RAM_map (array end $D664, not $D6B0; seen-bits $CA94-$CAB1 documented;
> collision warning), DOC_AUDIT addendum, KEY_LESSONS S54. Class-C finding:
> new species 224's library bit at $CAB0 is inside the vanilla-scanned extent
> (benign; counts toward the 100-monster library rewards).

---


> Last verified: 2026-07-07 (Session 53 — **Editor headless backend ships:
> `project.json` schema + `tools/build_project.py`; regression machine-verified
> byte-identical.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`.)
> **The compiler (`editor2/` package + `tools/build_project.py`) compiles a semantic
> `project.json` into the proven patch overlay.** It owns `bank_060.asm` +
> `bank_071.asm` whole-file (verbatim, sha256-pinned engine template heads +
> generated data) and three byte-neutral `@BUILD_PROJECT` regions
> (`bank_017.asm` ×2: `room_palettes_a`/`room_render_tables`; `wram.asm` ×1:
> `wram_step_counters` — markers added S53, neutrality proven by integrity PASS).
> Pipeline: content-validate → emit ×2 (determinism enforced) → bank-accounting
> BEFORE rgbasm (pinned template sizes: `$60`=283 B @`$411B`, `$71`=103 B
> @`$4067`, from the reference `game.sym`) → splice regions → stage/`make`/
> restore (PATCH_FILES lists parsed from verify_integrity.py — one source of
> truth) → `build/manifest.json` (+`game.sym`) mapping every text/script/
> step-counter/flag to `bank:addr` for the SameBoy debug loop. KEY_LESSONS
> rules are compiler VALIDATIONS (spawn script 0; screen_byte required, never
> guessed; text terminators + bare-`$EE`; 8×4 palettes + forced-idx1/idx3
> warnings; dense mapID/text tables; flag safe-pool allocator; wram region cap
> keeping `wRoomRecScratch`@`$D47F`). 18/18 tests
> (`editor2/tests/test_compiler.py --rom`).
> **Proof 1 — regression:** `editor2/example-project/project.json` re-expresses
> ALL user-confirmed content (6 rooms `$6B–$70`, 21 texts, 10 scripts, 4
> palettes, records/enc rows, 7 step counters — auto-allocation reproduces the
> hand addresses incl. the `$D47C` legacy hole via a `reserved` entry); the
> generated patched ROM md5 **`3a5a514c65b330e2788170c5d409b960`** equals the
> S53 reference patched build — byte-identical.
> **Proof 2 + defect fixed by construction (built S53, NOT yet user-tested):**
> the hand `CustomScriptMasterTable` had 3 entries but rooms reach index 5; on
> the SCROLL path a room past the table overshoots into following data —
> benign today ONLY because `$70` is single-screen (cannot scroll). Compiler
> default emits the full-width master table + shared `CustomScriptNoop`
> (+10 B); `build.compat.master_table_rooms` reproduces the legacy bytes
> (compile-time warning). Fixed patched ROM `f81d4ad84ee52f4c3342cc1f7e261e58`;
> measured delta vs reference = bank `$60` `$4010–$45B8` (+ the 2 header
> checksum bytes) ONLY; `$60` usage 1455→1465 B. Test ROM delivered
> (`DWM-S53-compiler-fixed-master-table.gbc`).
> **Script routing documented (resolves S11 "room-entry script unreliable at
> initial entry"; engine UNMODIFIED, grep-verified):** scroll/post-battle path
> (bank `$06` `$66e3`, patches/bank_006.asm ~4931) sets `wScriptMapType` = raw
> `wMapID` → `MapTypeDispatch` ≥`$40` → `DispatchBank0F_Ext` →
> `GateAwareDispatch` → `CustomScriptRead` — the path that reaches bank-`$60`
> scripts. Initial-entry path (bank `$01` `$4C3E`, ~line 2478) clamps via
> `MapIDClampForPalette` → post-S42 `$00` for ALL custom rooms → CASTLE scr0
> runs at initial entry (benign: flag/var-guarded; the "`$16` for custom
> rooms" comment at that site is stale). Full write-up: PROJECT_COMPILER.md §7.
> **Tool defect logged, NOT fixed:** `tools/compile_script.py` declares
> `set_bgm` (`$41`) = 2 params; the handler `$04:$669D` consumes ONE (the
> user-confirmed hand script uses one). Fix later together with
> decompile_script.py's independent PARAM_COUNTS + round-trip re-test
> (PROJECT_COMPILER.md §8).
> New reference doc (user-sanctioned, like GATE_GENERATION precedent):
> **PROJECT_COMPILER.md** — schema, pipeline, regions, template pinning,
> insertion recipes for future skills/music emitters, S53 findings.
> **User test result (S53, same day):** demo loop CONFIRMED on the fixed ROM —
> $6B render/NPCs/jerky, scroll, encounters, $6C dusk + teleports + step demo,
> $70 ember + encounters, save. TWO anomalies, BOTH classified NOT-S53 by
> byte evidence (identical in reference + fixed builds):
> (a) **Gate of Villager shows 4 vanilla floors** (Pillar B $6D absent) —
> bank_016 unchanged since the S41 commit; fork machine code verified byte-equal
> in BOTH built ROMs at $16:$5BA9→$7CB9. Fresh-entry contract is
> `wGateID := wMapID` (pedestal pseudo-id) at `$16:$5B67` when wInGateworld
> bit7 clear. **CLOSED S54 — user misread which gate; Pillar B $6D + descent
> music + Dran boss all work as designed.** The recorded suspect
> ("story-step-dependent hub exit data") was ALSO statically refuted in S54:
> room $24's four step variants carry byte-identical exits (pedestal (2,2) →
> dest 1 / gate_flag 1 in every step; steps only toggle the sprite-77 pedestal
> objects). Do not chase it again.
> (b) **SkyDragon-egg give ($6B bottom screen) then scroll up → crash** —
> unknown vintage per user. Not plausibly S53 (the fix's measured delta doesn't
> touch the path). **A/B CONFIRMED (user, S53): reproduces on the reference
> build too → PRE-EXISTING, not S53.** **ROOT CAUSE FOUND S54 (static; runtime
> probe pending)** — see the S54 block below: the custom WRAM block sits inside
> the party/storage monster array; the give's 149-byte record lands on the live
> room state. The earlier follower-loader suspect list is dead (the egg goes to
> storage, party untouched; family byte written correctly from the bank-$03
> info loader). **RUNTIME-CONFIRMED (user probe, same session): `$da14=$10` —
> the give picked slot 16 exactly as predicted; step counters clobbered
> ($D478=$c8 → scroll-up crash via garbage screen-0 step-entry ptr;
> $D479=$22 → dead bottom exit; $D488-$D497 garbage) while wRoomRecScratch
> read back UNCHANGED — it self-heals (the ROM0 collision-threshold reader
> re-populates it via bank $71 entry 0 per movement/frame), so the crash
> vector is the counters, not the scratch. Fix NOT built yet — next session.**
> Demo rooms are THROWAWAY per user (real romhack starts from a fresh
> project.json); both anomalies matter as MECHANISMS ($29 give, Pillar B),
> not as content.
> **NEXT (updated S54):** the WRAM relocation (ROADMAP Phase 0, full spec
> there) is now the gating item before ANY new custom state or bigger romhack
> content — it touches the compiler-owned wram region + pinned scratch, so it
> is its own session with the PROJECT_COMPILER §5 re-pin cascade. After that:
> `--apply` decision (compiler sign-off GIVEN S53), then Phase 2 follow-ons
> (Encounters #2, Layer A extraction, dialogue DTE, set_flag-by-name) — or
> resume S2f / T2 / the blink.
>

> Last verified: 2026-07-06 (Session 52 — **Tame Stage 2 ships: 3-tier skill-evolve chain,
> natural-learn fork, real MP costs.** Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`. **Tame $E1 / TameMore $E2 / TameMost $E3** are a working upgrade chain,
> level-up learn + upgrade-replace **user-confirmed in SameBoy** (v34: "levelled up
> perfectly, message correct"). New systems (all label-based, byte-neutral splices):
> (1) **learn-chain fork** — the natural-learn scanner (bank `$06` entry 5 `$4f9a`,
> caller `$51` level-up) loops ids `0..$D9`; `LearnLoopFork` (3-byte splice at `$5088`)
> continues the SAME loop over `CustomLearnReqTable` (`$E1..$E3`, vanilla 18-byte format,
> prereq chain = vanilla EVOLVE/replace path) in the `$7F1E` free run — `Jump_006_7f7f`
> and `db $06 @ $7FFF` offsets preserved. (2) **MP fork** — ALL THREE `$570C` readers
> (display `$56E8` / afford / deduct) route through `MPPtrFromId` → `CustomMPCostTable`
> (0/0/0/10/30/50 for `$DE..$E3`); record `+4` mirrors match. Custom ids no longer read
> garbage MP. (3) **announce fork** — the vanilla announce table's tail physically
> overlaps CODE at `$58:$58E8` (byte for id `$E2` IS an opcode), so `AnnounceIdxFork`
> (9-byte window at `jr_058_57e6`) reads `CustomAnnounceTable` for ids ≥`$E2`;
> `DataBtlFX_7959` offset preserved. (4) **crank reverted** — `SkillTame` meter add is
> now `TameMeterTable` dw 10/100/400 (= FeedMeat/PorkChop/Sirloin meat record powers,
> NOT "$000A = Beef Jerky" as previously documented — BeefJerky is +30; DOC_AUDIT S52).
> The "$0640 mirrors in bank_052" claim was FALSE — those are the vanilla meter CAP
> (present in the clean tree); the only crank was one line in bank_072. (5) **upgrade
> message page-split** — `MiscTextPtrTable[3]` repointed to `MiscText_03_Paged`
> ("[Mon]'s [Old]" / page / "becomes"+NL+"[New]!"), fixing the orphaned "!" (vanilla
> defect for 8+-char names). Built S52, NOT yet user-confirmed. (6) MP charging
> (10/30/50) + tier meter values: built S52, NOT yet user-tested. Harness wild-Slime
> (bank `$14`) KEPT per user (revert at editor time); natural-to-Slime slot DE-SCOPED
> by user (editor lays real data; the fork makes any species slot work). (7) **Enemy
> hit-blink mechanism SOLVED via HW captures but implementation DEFERRED** (user:
> "bank it"): the battle enemy is **BG-drawn** (NOT OBJ — §11.7's old OAM premise was
> wrong; three prior fix attempts targeted layers the enemy doesn't use). The blink =
> tilemap toggle, bank `$5f` entry 5, `$da83` phase → `$da84` sub-dispatch `$4b99`
> (blank `$4ba5` / enemy `$4bcb`, sources via `$50f4`+`$50ff`/`$5109`, VRAM-safe copy
> `$4e1f`, divider `$da34`, done-flag `$da82`). Full map: BATTLE_SKILL_SYSTEM §11.7.
> An interim whole-screen BGP flash was built, user-rejected (that's the PLAYER-hit
> visual), REVERTED — the S50 no-op OBP flicker was removed with it (hook is now
> sound-only during the delay; `wTameBGSave` reserved, unused).
> **NEXT:** S2f (field-cast skill) or more §13.4 skills, or the blink implementation
> (mechanism fully mapped — drive `$5f` entry 5's blink phase from `TameGateHook`
> via `$da82/$da83/$da84/$da34` state injection), or T2 text roll-out.
>


### Session 51 (archived from PROJECT_STATE by S53, verbatim)

> Last verified: 2026-07-02 (Session 51 — **Repo/doc consolidation audit + skill-table
> rename.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Doc-layer session:
> no functional ROM change.)
> **S51 — the status layer is restructured for context cost; contradictions fixed.**
> (1) **PROJECT_STATE compressed** (~1,071 → ~330 lines): session blocks S11–S48 moved
> verbatim to the new cold archive `SESSION_HISTORY.md`; a one-line Session Index (below)
> replaces them; resolved doc-defects moved there too. Aging rule added to
> SESSION_PROTOCOL §3 (keep latest 2 blocks; move the oldest on each new session).
> (2) **ROADMAP compressed** (~1,176 → ~490 lines): every [x] item reduced to
> evidence + owning-doc pointer; cut narratives preserved verbatim in SESSION_HISTORY
> Part 3. New boxes added: **Tame Stage 2 / skill evolve** (⚠️ the S50 TEST CRANK
> `$0640` is LIVE in `patches/bank_072.asm`+`bank_052.asm` — one Tame cast maxes the
> [S52 correction: FALSE re bank_052 — its two `$0640`s are the VANILLA meter cap,
> present in the clean tree; the only crank was one line in bank_072. Crank reverted S52.]
> meat meter; revert to `$000A` is part of that box), G3 schema fold (was prose-only),
> MP/learn-table `dw`/`db` re-section, §13.4 skill follow-ups, skills.json retirement,
> TOOLS_AND_DATA upkeep. (3) **Contradictions fixed in place:** empty-bank counts
> unified (canonical Bank Allocation table below); script-count bases reconciled
> (518 = bank $0C–$0F label census; 732 = (map_type, script) entries in
> all_scripts.json — map types share banks); ROADMAP flag counts updated to the
> branch-following numbers (328/298); SESSION_PROTOCOL stale `documentation/reference/`
> path fixed (layout stays FLAT — the old "target structure" is dropped, user decision);
> DATA_STRUCTURES related-docs table fixed (FIRST_5MIN_TRACE → ROUTING appendix;
> known_ROM_map.md removed); BREEDING_SYSTEM "NOT yet built" header fixed (B1–B7 built);
> TOOLS_AND_DATA refreshed (103 tools / 56 JSONs; ~13 tools + ~10 JSONs added to the
> manifest; header counts fixed); README patched-build cleanup line fixed (8 new-bank
> files, not just bank_060). (4) **Rename executed (was deferred S44):**
> `TilesetLookupTable` → **`SkillMPCostTable`** and `LoadFld_56e8` → **`GetSkillMPCost`**
> in `disassembly/bank_007.asm` + `patches/bank_007.asm` (labels/comments only; clean
> build byte-perfect; role confirmed live by S48's 3-reader map + S49 MagicBurn MP path).
> (5) **Same session, user-approved follow-on:** housekeeping deletions EXECUTED —
> actually deleted: `__pycache__/`, 8× `.DS_Store`, `breeding_extra_recipes.json`
> (all tracked at HEAD → git-recoverable; the recipes file was a B3 capacity TEST
> fixture, facts archived in SESSION_HISTORY). THREE queue rows were stale:
> `monsters.json`, `event_flags.json`, `edits.json` were already absent
> (untracked at HEAD — never in a fresh clone). `--emit-relocation` marked
> legacy/absence-tolerant. (6) **Both skill tables
> RE-SECTIONED to real data** in BOTH trees via the new
> `tools/resection_skill_tables.py` (probe-build method): `SkillMPCostTable` →
> 222×`dw` with per-skill name/MP comments; `SkillLearnReqTable` → 222×18B `db`
> with decoded stat/prereq comments; 4,293 fake-instruction lines → 676 real ones;
> two fake-decode artifact labels kept at exact offsets (`DispMapS_566b`,
> `label6_6034` — referenced from not-yet-re-sectioned bank-$06 regions). Clean
> build byte-perfect; verifier PASS 4/4. (7) Phase-D STALE BOXES verified + ticked:
> banks $03/$14/$16 were already labeled `db`. Toolchain incident, honestly
> recorded: S51 **violated the pre-existing four-doc "never `make clean`" rule**
> (README ×2, PROJECT_STATE Iron Rule 3, SESSION_PROTOCOL, KEY_LESSONS — the
> SECOND recorded violation; the KEY_LESSONS canonical entry now logs both) and
> initially misreported the rule as nonexistent until the user pushed back —
> grep the docs before making claims about the docs. Sibling hazard also hit:
> **broad `git checkout -- disassembly/`** reverts uncommitted label work.
> STRUCTURALLY FIXED: Makefile `clean` no longer
> deletes gfx, the `%.2bpp: %.png` trap rules are removed (17/18 committed .2bpp
> are NOT PNG-regenerable — measured), `disassembly/gfx/README.md` added.
> (8) `--check` caught a tool defect (the SkillLearnReqTable label line was
> emitted missing — a silent str.replace no-op in the tool build); label inserted
> in both trees + the `ld hl, $50e0` loader relabeled to `ld hl,
> SkillLearnReqTable` (byte-identical), tool fixed with an assert.
> **NEXT:** Tame Stage 2 (crank revert + 3 tiers + natural-to-Slime) as its own session,
> or S2f (field-cast skill), or T2 text roll-out. Housekeeping deletions (`__pycache__/`,
> 8× `.DS_Store`, Tier-L JSONs, `breeding_extra_recipes.json`) queued pending user OK.

---

### Session 50 (archived from PROJECT_STATE by S52, verbatim)

> Last verified: 2026-06-30 (Session 50 — **S2e: custom skill #2 (Tame) ships; the
> custom-message + presentation-timing infra generalizes.** Integrity PASS 4/4, clean build
> byte-perfect `1ca6579…`. **Tame (`$E1`)** — recruit (meat-meter) + anti-abuse damage
> (ATK/4), single-target — is user-confirmed in SameBoy: announce "used Tame!", heart
> animation, damage sound + "takes X damage" text correctly SEQUENCED after the heart, damage,
> and recruitment all correct. New infra this session: (1) **custom-message render fork** —
> `$FD` is now a general escape resolving a per-skill pool string by `[$db8a]-$DE`
> (`LoadB4c_Fork`), so bespoke text no longer needs a scarce free id (MagicBurn migrated onto
> it); (2) **presentation timing** — the effect state machine's per-id animation-wait gate
> (`$53:$5b07`) + a fixed frame delay (`wTameDelay`) sequences a note-then-hit skill, and the
> damage sound is moved off the note onto the text. Full RE: `BATTLE_SKILL_SYSTEM.md` §13.5 +
> §11.7; TEXT_SYSTEM.md (fork); KEY_LESSONS.md (Session 50). KNOWN DEFECT (deferred, minor
> cosmetic): the per-enemy-sprite blink is unsolved (not `wBGPalette`/whole-screen, not
> OBP-only — an OAM visibility toggle not yet found; §11.7). Meter is TEST-cranked (`$0640`);
> revert to `$000A` for Stage 2.
>
> [S49 context] Session 49 — **S2d: custom skill #1 ships end-to-end.**
> Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. **MagicBurn (`$E0`)** is a
> non-aliased custom skill, user-confirmed working in SameBoy: own record (½ current MP →
> all foes) + result text + **announcement** + **animation** + **hit-flash** + **cast
> sound**, all via clean dynamic indirection, zero per-aspect hacks. New this session:
> (1) **announce** — `AnnounceTemplateTable` (`$58:$5806`, lookup `$58` e6 `$57C5`, render
> `$50:$5A42`; `$FF`=silent) re-disassembled to a clean `db` table in patches with `$E0`'s
> slot filled; (2) **custom message pool** — the 256-id battle-message table is FULL (one
> free slot `$FD`), so bespoke text lives at `$4c:$7326` (`CustomMsg_E0_MagicBurn`, `$FD`
> repointed); (3) **presentation proxy** — `GetPresentId` in `$5f` free space (identity for
> stock ids, per-skill PROXY for custom ids via `CustomProxyTable`) forked into the 12 `$5f`
> reads of `$db8a` (byte-neutral); renderers `$5c/$5d/$5e` read the id zero times, so a custom
> skill borrows a real skill's whole anim script → no hang, flash + SFX restored (MagicBurn
> proxies Infernos `$09`). Full RE + per-skill recipe: **`BATTLE_SKILL_SYSTEM.md` §13**;
> TEXT_SYSTEM.md (pool); KEY_LESSONS.md (3 lessons). The standalone presentation-groundwork
> doc was folded into §13 and deleted.
> **NEXT:** Tame Stage 2 — revert meter crank `$0640`→`$000A`; 3 upgrade tiers (learn-chain
> fork, bank $06); make Tame natural to Slime (a `$03:$4461` slot). Then S2f (field-cast skill,
> e.g. teleport) / more custom skills via the §13.4 recipe. Optional polish: the per-enemy
> blink (§11.7).


> Prior (Session 48 — **S2d FOUNDATION: skill-id bucketing audit.**
> Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral (disassembly
> comments + tooling; no byte change, no ROM/patch). Built the missing prerequisite for
> the "proper" S2d that S45 deliberately skipped: a complete map of where the battle
> engine buckets the working skill id (`$db8a`, **254 reads / 9 banks**, 148 in enemy AI
> `$57`). **Result — the surface reduces to a small, verified fork set:** 204 reads are
> equality checks (max `$C5`, so a custom id `≥ $DE` matches none = auto-safe), the 15
> range gates are windowed ladders that fall through to defaults, and the exhaustive `$57`
> AI pass (all 148) finds **zero** sites mishandling a custom id (its high-id sub-dispatch
> is guarded by `cp $d9; ret nc`). **Keystone:** magnitude/targeting/MP-in-record/status/
> ai_weight all come from INDEXING the record table `$54:$4013` by the id (3 indexer sites
> `$5251/$5276/$529E`), which overshoots at `≥ $DE`; one record fork fixes all of them and
> the enemy AI (shared reader). HW-confirmed (SameBoy): `$52:$66D9` writes `$db4c=$db8a`
> (Scorching `$5E`); the `$54:$535F` divert is a MINOR path (didn't fire for Scorch/Zap/
> IceStorm); menu Flee ≠ skill `$DB`. **Keystone fork PROVEN byte-neutrally implementable:**
> the 3 sites are identical 5-byte windows (`21 13 40 09 09`), no interior jump-ins, bank
> `$54` has ~10550 free in-bank bytes; an RGBDS-assembled `call Fork`+nop+nop trampoline
> executes vanilla-identical for normal ids and indexes a high table for custom ids. Other
> forks: MP (3 readers `$07:$56E8/$5A98/$5B4E`, mirror `record+4`), sound (`$55:$4067`,
> `$FF`=silence), name (repoint), anim (none for a no-visual skill — `$58dd[$DE]=$0d`).
> Full RE: **`BATTLE_SKILL_SYSTEM.md` §12**; tool `tools/map_skill_id_buckets.py` →
> `extracted/skill_id_bucket_map.json` (self-checking).
> **NEXT:** S2d implementation — fork the 3 record sites + in-bank high tables, MP, sound,
> name; prove a non-aliased ally heal (own record/handler/name). Shovel-ready per §12.6.
>
> Prior (Session 47 — **S2c: effect-script format / animation
> dispatch RE.** Integrity PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral
> (discovery + tooling; no `disassembly/` or ROM change). Resolves the S46 OPEN item.
> **Finding (corrects the prior model):** bank `$4c` is **not** a novel effect-bytecode
> interpreter — it is the shared **text/message VM**. The `$dd70/71` "script pointer"
> is a **packed pair of 8-bit message ids**: low = the "effect happens" message
> (damage/status/heal), high = the "effect fails" message (miss/resist). The battle
> effect player (`bank_053 jr_053_5a6f`, a frame-stepped state machine) hands a small
> mode (0/1) + the chosen id byte to bank `$4c` e0 (`LoadB4c_42d1`), which runs
> `CallTextEngine`/`SaveBankAndSwitch` to resolve the string via the **mode-0 two-level
> table at `$4c:$4019`** (`subtable=[$4c:$4009+mode*2]`, `string=[subtable+id*2]`).
> Effect "scripts" are standard `$F0`-terminated text-VM strings (DTE + control codes;
> `$F9 <slot>` = insert name/number). The on-screen **visual** is a SEPARATE system keyed
> by **skill id**: bank `$5f` e6 (`$52F0`) → per-skill anim-index (`$5f:$58dd/$59c3/$5aa9`)
> → routine table `$5f:$58bd`; **sound** = bank `$55` e1 → SFX table `$55:$4070`. So
> Blaze/Firebal/IceBolt share selector `$b882` yet differ visually. **Accept met +
> validated:** Blaze decoded to bytes — hit `$4c:529f` "{mon}{name} takes {num} damage pts!",
> miss `$4c:5871` "Has no effect on {name}!"; and `--validate` cross-checks decoded messages
> against the categorized FAQ (`extracted/skill_faq.json`, user-provided) — **67/67**
> statically-resolved skills match, 0 contradictions (≈81 real skills incl. the `$b682`
> physical-attack default). **S2c-anim — RENDERER REVERSED + EMULATOR-VERIFIED (2026-06-28):**
> the `$dd68` consumer is a **metasprite/OAM engine** (same 4-byte `dy,dx,tile,attr` $80-term
> format as the follower system). Full chain SameBoy-verified: skill id → `$5f:$52F0` →
> side-select `$5f:$58dd/$59c3/$5aa9` → routine dispatch `$5f:$5441` → table `$5f:$58bd`
> (index `$0d`=`ret`=NO VISUAL) → `$dd68` → builders `$5c:$40fc`/`$5d:$4122`/`$5e:$413a`
> (de=`$4071`, `[$c7]`anim/`[$c8]`frame). **3 presentation layers:** sprite-anim,
> sound+flash (`$56ed/$57d5`→`$da81`), vertical screen-shake (`$5f:$4c0c`, SCY via
> `$da84`/`$bb`). Corrects two prior mislabels (`$c8a8`=input-lock not shake; `$c8b1`
> dormant). *Reusing* an animation on a new id = table edit; *authoring a novel* one = add
> metasprite frames + a `$4071`-table entry (now fully specified). See **§11**. Tool:
> `decode_battle_animations.py` → `extracted/battle_animations.json` (45 anims/~600 frames).
> **Tool:** `tools/decode_effect_messages.py` (`--selftest`, `--validate`) →
> `extracted/effect_messages.json` (222 skills → selector → hit/miss messages, full 203-id
> mode-0 corpus, Blaze byte dump; honest classification of `a:a` flag-params, RAM-ptr loads,
> and dynamic builders as non-static). Full RE: **`BATTLE_SKILL_SYSTEM.md` §9 + §11**.
> S47's "NEXT" was S2d's foundation, which S48 (above) then built.)
>
> Last verified: 2026-06-28 (Session 46 — **Phase F / S2-arc: skill PRESENTATION
> foundation decoded + record-table round-trip keystone + re-section.** Integrity
> PASS 4/4, clean build byte-perfect `1ca6579…`. Byte-neutral (discovery +
> annotation + tooling); no functional ROM. NOT yet user-tested — handoff for a
> fresh instance to continue.)
> **S46 — S2 was NOT done; it is an ARC.** S45 shipped a single-caster,
> Blaze-shaped alias POC (correct but narrow). Audited S45 byte-for-byte: built
> correctly, no false claims; the error was marking S2 "done". This session
> decoded the skill **presentation** layer that the alias hack worked around.
> **Core architecture proven:** handler (`$52:$4011`) = effect TYPE (shared:
> Blaze/Blazemore/Blazemost → one handler `$41CD`); the per-skill **record**
> (`$54`) = parameters. **(a) Record table fully decoded + round-tripped:**
> `$54:$4013` pointer entries (dispatch entries 9–230) = `$41CF + id*19`, 222 × 19B
> data at `$41CF`. `build_skill_tables.py` now re-emits the pointer table + data
> **byte-identical** (`--selftest` 5/5 PASS); the 4218-byte block is **re-sectioned
> to clean `db` records** in `bank_054.asm` (editable in source). Field map (FAQ-
> validated PROVEN: +0 effect_class, +1 effect_category, +2 target_mode, +3
> **ai_weight** (per-skill AI score summed by enemy AI `$57`), +4 mp_cost, +5
> status_id, +6 damage_class, +11/+13/+15/+17 power min/range party/enemy — 31/32
> FAQ damage-heal ranges exact). **(b) Item-effect/meat system (#3):** the 37
> item_effect skills (ids 176–212) are the in-battle items; shared handler
> `$52:$4625` (record-driven); meat items (194–198) special-case via `$52:$4014`
> → recruitment handler `$58:$591E`. **(c) Animation dispatch (#2):** handler picks
> a descriptor-setter (`$52:$5460–$54f8`) → `$dd6f` (bit7=has-effect) + `$dd70`
> script pointer (Blaze=`$b882`) → bank `$4c` effect engine + `$55` sprite anim;
> pointer space `$b6xx–$bcxx` (`$b682` default). **OPEN:** effect-script bytecode
> FORMAT + `$b000` backing not reversed = the animation-authoring sub-item.
> **Tools:** `gen_skill_records.py` (+battle_record 7th source), `build_skill_tables.py`
> (+record round-trip, `--emit record/recordptr`). Annotation comment/label-only in
> `bank_052/053/054/058.asm` (clean build stays `1ca6579…`). Full RE + field tables
> + confidence: **`BATTLE_SKILL_SYSTEM.md` §7–§10.** **NEXT for the new instance:**
> either (1) reverse the effect-script bytecode (animation authoring, bank `$4c`),
> or (2) the real authoring step — proper per-id custom-skill records (own record +
> handler + name) that REPLACE the S45 alias hack, enabling heal/Tame/Anchor shapes.
>
 Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`. Functional change (rename) **user-confirmed in SameBoy: skill 215
> displays "BugCut".**)
> **S44 — the skill subsystem is now data-complete for an editor.** Audited the
> reshaped S1 and found it was already partly done (bank `$52` `SkillFunctionTable`
> was re-sectioned with named handlers); the real work was the *data* tables.
> **Two undocumented tables fully decoded and FAQ-validated:**
> **(a) `SkillMPCostTable` `$07:$570C`** — 222 × u16 LE = MP cost to cast (`999`=ALL,
> ids 50/102). The disassembly **mislabels this region `TilesetLookupTable`**; the
> indexing fn `$56E8` is effectively `GetSkillMPCost` (its id-`$70`/Ahhh special case,
> gated on `[$cacc]&1`, picks Ahhh's male/female MP 1/2). Renamed **only in comments**
> pending SameBoy confirmation of the fn's callers. **(b) `SkillLearnReqTable`
> `$06:$50E0`** — 222 × 18B: `+0` level u8; `+1` hp `+3` mp `+5` atk `+7` def `+9` agl
> `+11` int (u16 LE); `+13..17` up to 5 prereq skill ids (`$FF`=none). Validated vs the
> FAQ incl. MegaMagic's 5 prereqs. **BugCut finding:** id 215 (ROM name "Sheldodge", a
> placeholder) is the **Bug-family cut** — proven 3 ways: family sub `$6349` tests family
> code `$05`=Bug; StubBird's enemy list uses 215; its learn reqs match the FAQ's "BugBlow"
> row exactly. Renamed to **"BugCut"** in `patches/bank_041.asm` (10-byte slot preserved;
> **user-confirmed in SameBoy**). **Real skill count is 222 (`$00–$DD`), not 256:** the
> 222 entries classify as **155 skill / 37 item_effect (`$B0–$D4`) / 30 internal**, by
> cross-referencing monster natural sets + enemy lists. Corrected the bank `$52` header
> (`$4211`→`$6CC7` dispatch, `256`→`222`, `140`→`115` handlers). **Tools (NEW):**
> `gen_skill_records.py` → `extracted/skill_records.json` (222 records: name, kind, mp,
> handler+shared group, learn block, prereqs, family code, monster/enemy usage; `_generator`
> key, all 6 source addrs); `build_skill_tables.py --selftest` proves the JSON re-emits the
> function/MP/learn tables **byte-identical** (444+444+3996 B, PASS). Annotation is
> comment-only in `disassembly/bank_006/007/052.asm` (clean build stays `1ca6579…`).
> Test ROMs: `DWM-BugCut-test.gbc` (full stack + rename), `DWM-BugCut-vanillaVillager.gbc`
> (villager fork reverted so wild Picky is catchable — throwaway; project keeps the gate mod).
> **Follow-ups:** confirm the `TilesetLookupTable`/`$56E8` role in SameBoy, then rename +
> re-section both tables to real `dw`/`db` blocks; retire the old 256-entry `skills.json`
> (still read by `gen_name_tables_db.py`). Next item: **authoring NEW skills** (data side is
> ready; novel effects need a new handler in a free bank = the ASM frontier).
>
> Last verified: 2026-06-26 (Session 43 — **disassembly gap audit + Arc-1/T1 text
> re-section keystone (bank `$47`).** Integrity PASS 4/4, clean build byte-perfect
> `1ca6579…`; T1 is byte-neutral so there is no test ROM — acceptance is the MD5.)
> **S43 — two things.** (1) **Disassembly audit** (user-requested): characterized what is
> entirely un-understood or misassembled. Three gaps were *understated* in docs and are now
> first-class: **(a) audio** — engine partly in bank `$08` (`LoadAudP`, the SGB path; switches
> to `$78`) + scattered `Aud_`/`SoundEffect` routines, barely annotated; song/SFX **data**
> in banks `$61 $62 $63 $65 $66 $68 $78 $7b $7d` (~9 banks/144 KB) misassembled as
> instructions, reached only as DATA (nothing executes them) — format unreversed; **(b) battle
> engine** — bank `$52` holds the labeled `SkillFunctionTable`/dispatch but the 140 skill-effect
> handlers + `Battle*` funcs (banks `$52-$5f`) are auto-labeled only; the **damage formula, turn
> order, and enemy AI selection** are untraced (the `ai_weights` are extracted as DATA but the
> consuming algorithm is unlocated); **(c) vanilla text `$42-$4B,$4E`** — fully tool-extractable
> but **misassembled as fake instructions in source** (~12k bogus lines/bank), so vanilla text
> isn't editable in place. (Phase E's E1/E2 confirmed as genuine, already-flagged gaps.) The full
> attack plan is mapped in **ROADMAP Phase F** (Arc 1 text, Arc 2 skills+AI, Arc 3 music) —
> session-sized items, keystone-first methodology, with S3/M1 flagged as real RE.
> (2) **Arc-1/T1 DONE (byte-perfect):** new `tools/resection_text_bank.py` converts a corpus
> bank's contiguous DTE string run into `TextStr_<bank>_<addr>:` + `db` blocks (one label per
> text id, decoded text in a comment), labels/comments only. Region is data-driven (first string
> addr from `text_id_map.json`; end = bank trailing-fill scan) and snapped to real line
> boundaries via a probe-build line→address map (same machinery as `resection_library_tables.py`)
> so no fake instruction is split; exact ROM bytes are emitted as `db`, so a wrong split fails
> the build instantly. **Bank `$47`: 69 strings, run `$4174-$5b74`, 5607 fake lines replaced;
> clean build stays `1ca6579…`, integrity PASS 4/4.** Idempotent, re-runnable from clean tree.
> Docs updated in place: TEXT_SYSTEM.md "Source re-section" (method + per-bank bounds table),
> ROADMAP Phase F (Arc plan, T1 ticked), TOOLS_AND_DATA (tool). Files: `disassembly/bank_047.asm`
> (re-sectioned — clean tree, zero byte impact), `tools/resection_text_bank.py` (NEW).
> `APPLY_THESE_CHANGES.md` regenerated.
>
> Last verified: 2026-06-26 (Session 42 — **Phase 2 keystone: table-driven custom-room
> dispatch COMPLETE & user-confirmed in SameBoy.** Integrity PASS 4/4, clean build `1ca6579…`;
> test ROM `DWM-S42-custom-room-keystone-v3.gbc`, **user-confirmed: 3-room walk loop with
> visible staircase exits, amber `$70` renders past the old ceiling with working encounters +
> exit, green `$6D` gate rotation → boss still works.**)
> **S42 — the editor-backend keystone (EDITOR_DESIGN §2) is built.** All remaining hardcoded
> per-room intercepts are now table-driven, and the old `$6B-$6F` room ceiling is lifted to
> editor scale. **Architecture:** dispatch *logic + data* live in the previously-empty bank
> **`$71`** (reached via `rst $10`), so every in-bank edit is a **byte-neutral** stub — no
> scarce/fragmented ROM0 or bank-`$0B` free space consumed, and no risk to dense code/audio
> banks. (1) **Encounters #1 folded in:** `RoomEncTable` (bank `$71`, 3 B/room
> `[enabled,gate,floor]`, indexed `mapID−$6B`) via `CustomEncResolve` (bank `$71` e1) replaces
> the hardcoded `cp $6B` whitelist in `$0B`; `$6B` keeps gate-0/floor-1 exactly. (2) **`$26DD`
> ceiling lifted:** `Custom26DDTable` (bank `$71`, 8 B/room, indexed `mapID−$70`) via
> `CopyCustomRoomRecord` (bank `$71` e0) far-copies the tileset/dims/threshold record into
> `wRoomRecScratch` ($D47F). All three consumers (both `$0B` GFX loaders + the ROM0 collision
> threshold reader) read scratch; for `mapID<$70` the routine replicates the original
> `$26DD/$2A5D` index byte-for-byte (vanilla + `$6B-$6F` unchanged). Threshold site preserves
> `C` with `push bc`/`pop bc` around `rst $10`. This sidesteps the in-ROM0 `$70`↔`$2A5D`
> gate-table collision. (3) **Render tables** (`CustomRoomPalPtr`/`CustomRoomAttr`, `$17`)
> relocated to the bank tail + widened to 6 entries (`$6B-$70`; `$6E/$6F` vanilla-fallback).
> (4) **`MapIDClampForPalette`** (ROM0) made **uniform** (`$00` for all custom rooms) — already
> O(1); removed the dead `$6B→$16` special case. (5) **Room data** (`CustomSourceMapTable`/
> `CustomRoomPtrTable`, `$60`) widened to 6. **Proof:** room **`$70`** (amber) added *past* the
> ceiling by table rows alone; walkable loop `$6B→$6C→$70→$6B` with **staircase** exit markers
> (`$3C-$3F` placed on the exit metatiles via `tools/build_gate_room.py`); `$6D` (green) left
> as the gate-rotation-only proof. `$6B/$6C/$6D` behavior preserved. Files: `patches/bank_071`
> (NEW), `bank_000` (clamp + threshold site), `bank_00b` (2 GFX sites + encounter hook),
> `bank_017` (render tables relocated/widened + `$6D`/`$70` palettes), `bank_060` (tables + `$70`
> room + chained exits), `bank_064` (regenerated: exit staircases), `wram`
> (`wCustomStep_Room70_S0 $D47E`, `wRoomRecScratch $D47F`, `wRoomEncFlag $D487`), `game.asm`
> (`bank_071` include), `tools/build_gate_room.py`, `tools/verify_integrity.py`
> (`PATCH_NEW_FILES += bank_071`). Docs updated in place: EDITOR_DESIGN §2 (as-built),
> ROADMAP (Phase 2 keystone + Encounters #1 ticked, Pillar A ceiling-lift note), KEY_LESSONS
> (S42). `APPLY_THESE_CHANGES.md` regenerated for git.
>
> Last verified: 2026-06-26 (Session 41 — **Phase 2C: custom gate room INSERTION half ("Pillar B")
> complete & user-confirmed in SameBoy.** Integrity PASS 4/4, clean build `1ca6579…`; test ROM
> `DWM-gate-rotation-v3.gbc`, **user-confirmed: room appears every gate-1 floor, descends to boss,
> with whoosh + continuous BGM.**)
> **S41 — custom room `$6D` inserted into the Gate of Villager (gate 1) rotation, descending
> floor-to-floor.** This is the *insertion* half that Pillar A (S40, table-driven render) set up.
> (1) **Insertion via a byte-neutral fork**, NOT the planned `rst $00` slot: the 6-byte gate-0
> exclusion at `$16:$5BA9` (`ld a,[wGateID]/or a/jr z,jr_016_5bbf` — reads **`wGateID $C935`**,
> correcting an earlier `wCurrentFloor` cite) is replaced in place by `call GateDecisionFork`+3 nop.
> The fork (`$16:$7CB9`, end-of-bank padding) routes by `wGateID`: gate 0 → vanilla maze, gate 1 →
> `CustomGate1Setup` (`wMapID=$6D`, mirror of `$50` handler `$5D0D`), gates 2–31 → untouched RNG
> gating. A `pop hl` discards the call's return addr so gate 0/1 unwind to entry-5's caller (not back
> into the RNG path). (2) **Descent** via a `gate_flag=$80` exit on the room's PIT tile (mirror of
> special rooms `$50/$51`) → re-enters entry-5 floor setup, increments `wCurrentFloor`, re-runs the
> fork → `$6D` again until the boss floor. (3) **Descent-transition feel fixed.** Both the slow
> dissolve and the per-descent BGM restart trace to **one cause**: the custom room runs with
> `wInGateworld=0`, so the engine treats each descent as a *fresh hub→gate entry*. Making it a real
> in-gate floor (`wInGateworld=$01` during display) **freezes the game** — that flag gates every
> gate/maze branch and the un-intercepted ones read absent maze state. Fix is **transient**: set
> `wInGateworld=$01` **only during the transition window** (`CustomDescentInGate` @ `$0B`
> `jr_00b_466b`/`$45F9`, byte-neutral; resets to 0 before redraw via the fork) → whoosh + BGM
> continuous, render/descent unchanged. Dedicated room `$6D` keeps the `$6B`/`$6C` demos intact.
> Files: `patches/bank_016` (fork + setup), `bank_000` (`$26DD[$6D]` 1-screen gate record),
> `bank_017` (`CustomRoomPalPtr/Attr[2]` borrow `$6B`), `wram` (`wCustomStep_Room6D_S0 $D47D`),
> `bank_060` (`$6D` room data + descent exit), `bank_00b` (`CustomDescentInGate`). Docs updated in
> place: GATE_GENERATION §7.5 (+§6 `rst $00` table corrected: idx0=`$5C42`, idx2=`$5CCB`), ROADMAP
> (Phase 2C both halves ticked), KEY_LESSONS (S41: pop/jp fork control-flow; `wInGateworld=0` ⇒
> fresh-gate-entry transition; transient-flag-during-transition technique). `APPLY_THESE_CHANGES.md`
> regenerated for git.
>
> Last verified: 2026-06-25 (Session 39 — **Phase 2C: custom gate room (rendering half) +
> room-palette derivation fully solved & tooled.** Integrity PASS 4/4, clean build `1ca6579…`;
> gate-room test ROM `DWM-gate-room-v5.gbc` MD5 `2a008235…`, **user-confirmed in SameBoy**.)
> **S39 — two landed pieces.** (1) **Custom Room `$6B` now wears the Gate-of-Beginning maze
> tileset** (gfx-ID `$280D` = bank `$28` step `$0D`, floortype `$D`): a sandy island with an
> ocean-wall border (incl. top), 2×2 **tree** (`$34-$37`/pal3) and **dune** (`$38-$3B`/pal0)
> metatiles, and pit holes — all real gate tiles with the real gate floor palette (`$17:$629D`).
> Authored in new `tools/build_gate_room.py` → `patches/bank_064.asm`; gfx-ID/threshold in
> `bank_000.asm`; `CustomPaletteColors_6B` (slots 0–3 ONLY — widening clobbers system slots →
> monster-colour corruption) in `bank_017.asm`. Palette assigned **per position** (trees need
> pal3 yet share the `$30` collision-threshold side with ocean/floor). This is the *rendering*
> half of "custom room into the gate rotation"; the `rst $00` *insertion* half is still open.
> (2) **Room-palette derivation from ROM** (`tools/derive_room_palette.py`): a room's real BG
> colours are only indices 0 and 2 of slots 0–3 (from `$17:$476F`[mapID] normal / `$17:$51F5`
> [floortype] gate, scanning past empty screens); the engine **forces idx1=`$6bff`, idx3=`$0000`**
> in every BG palette; slots 4–7 are a shared system set; object palettes are one global block at
> `$17:$5615`. Validated **30/30** SameBoy dumps + the gate floor; refuses cleanly when a room has
> no resolvable pointer. Docs updated in place: GATE_GENERATION §7.1–7.3 + palette tables,
> TOOLS_AND_DATA (both tools), ROADMAP (Phase 2C rendering half ticked), KEY_LESSONS (S39: forced
> colours / screen-scan / decimal-label / metatile-palette lessons).
>
> Last verified: 2026-06-25 (Session 38 — **Phase D new-species data-table SEAMS annotated +
> Phase N lineage parent-name "?????" FIXED.** Integrity PASS 4/4, clean build `1ca6579…`;
> lineage test ROM `DWM-lineage-fix-v1.gbc` MD5 `2a09d94f…`, **user-confirmed in SameBoy**.)
> **S38 — two pieces, both landed.** (1) **Data-table fork SEAMS** now self-documenting at their
> clean anchors (labels/comments only, build byte-perfect; the S33 pass did the DISPLAY seams, this
> finishes the data-table set): `bank_003 label443f`/`SaveMon_4446` (single info indexer; id≥224 →
> bank `$6A` fork; also reached as `$03` entry 1 by breeding's `$0301` parent-family load),
> `bank_014 LoadEnemyStats` (16-bit EID → NO fork) + new label `EnemyStatsTrailingFree` @ `$7EAD`
> (append region; EIDs 487–517 are unusable CODE, first grid-aligned slot is EID 518 `$7EB3`),
> `bank_001 EncounterPool_000` (empty slot = in-place insertion point, Iron-Rule-2 safe),
> `bank_016 label16_485c` (entry-1 recipe lookup overshoots 222-entry `FamilyRecipeTable` →
> `FamilyRecipeResolve` display fork) + the `$0301` parent→family seam (new species resolves a real
> family as a breeding parent via the forked info loader). (2) **Lineage parent-name fix (N5 sub-item
> closed):** the library/encyclopedia lineage line-1 showed "?????    ?????" for Gorbunok. Verified the
> path from clean source (entry 2 `call SetB4d_43b9` → `HighDetailTextFork` → `HighModeTable4D` for
> id≥224), then wired `HighModeTable4D` mode-0 → new `HighMode0Ptrs` → `GorbunokRecipeLine`
> (`patches/bank_04d.asm`). Also **corrected a latent format bug** in the S32-staged string: real recipe
> lines use TWO 9-char fields (e.g. slot 200 "Servant  GreatDrak"), so rebuilt as `"Snaily   BattleRex"`
> (names sym-verified vs `MonsterNamePtrTable $41:$4339`). id≥224-gated → ids 0–223 byte-identical.
> Built-ROM check: `[mode0base+224*2] → GorbunokRecipeLine` → "Snaily   BattleRex". Docs updated in
> place: ROADMAP (Phase D seams ticked, N5 lineage sub-item done), MONSTER_DATA (overshoot registry
> lineage row → DONE, data-table seam annotations recorded).
>
> Last verified: 2026-06-24 (Session 36 — **Starter + force-join verification (audit of legacy
> editor knowledge).** Integrity PASS 4/4, clean build `1ca6579…`.)
> **S36 — starter mechanism PROVEN end-to-end and editor claim confirmed.** Starter = enemy-stats
> **EID 1** (`$14:$4C36`); granted by Castle intro `add_monster enemy=$0001` at `$0C:$42D6`, gated by
> flag `$0002` (fires once at new game), built via `LoadEnemyStats(EID 1)` → `label14_40b4`. Confirmed
> in-game (EID 1 → SkyDragon Lv25 swap). Stats transfer as base then take an 80–100% creation roll
> (`SaveEnem_4821`). Annotated the previously-raw-`db` grant block in `bank_00c.asm`
> (`Bank0C_ScriptAddr_4270:`, labels/comments only, byte-perfect). **Force-join hack verified** (hooks
> `$54:$55D5` NOP + `$54:$5604`→`$7FC8` resolver + `$7FE0` table all correct; logic sound) but **NOT
> ported** — brittle on `wGateID` (`$C935`) overload (arena/bank_055 zeroes it; gate-entry/bank_016 sets
> it to `wMapID`, not the editor's 0–31 ordering), table range, and tier-7 lacking a `join_eid` redirect.
> Crossbank left untouched per directive. Docs updated: MONSTER_DATA.md (Starter Monster, stat creation
> roll, force-join verification), EVENT_FLAGS.md (flag `$0002`).
> Last verified: 2026-06-24 (Session 35 — **Milestone G2: new-species BATTLE sprite + battle
> palette baked into `patches/`; user-confirmed OK.** Integrity PASS 4/4, clean build `1ca6579…`,
> patched build verified.)
> **S35 — battle-art half is now permanent too.** id 224 (blue-dragon proof art) now shows its real
> custom sprite IN BATTLE (royal-blue body / white belly / black outline), matching the G1 follower.
> What landed in `patches/`: the dragon battle pose packed as a **2nd overflow entry** in `bank_07e.asm`
> (`Battle_sp224` @ gid **`$7E01`**; the follower stays `$7E00`, byte-identical — the pointer table just
> grew to 2 entries); `bank_000.asm` repoints `MonsterBattleGfxTable[224]` at `$00:$2d5f` `$320f`→`$7e01`
> — a **same-size 2-byte edit, NO fork**, because the species-indexed battle gfx table `$2b9f` has a real
> (padding) slot for id 224 (contrast the follower tables, which overshoot and needed id-indexed forks);
> `bank_017.asm` forks the battle-palette reader `label17_41d0` byte-neutral (`call HighBattlePal` + 5 `nop`)
> to a resolver in the bank `$17` filler tail (`$6cea`) — id≥224 → custom palette `67 4d ff 6b ff 7f 00 00`,
> else vanilla `$62fd+species*8` (its slot `$69fd` overshoots into `PaletteColorData`). Tool
> `tools/bake_follower_overflow.py` extended with `--battle-art/--battle-spec` (emits both streams, prints
> the battle gfx-ID + palette); new spec `examples/follower_swap/gorbunok_battle.json`. No verify_integrity
> PATCH-list change (`bank_000/017` already in PATCH_FILES, `bank_07e` in PATCH_NEW_FILES). See
> KEY_LESSONS + MONSTER_DATA "NEW species battle sprite".
> **S34 — follower-art fork is now permanent + editor-shaped.** id 224 (blue-dragon proof art)
> walks the overworld / shows in menu+library with real custom art, built from the canonical
> `make` path. What landed in `patches/`: new overflow bank `bank_07e.asm` (blue-dragon 256B
> layout-0 payload, gid `$7E00`); all **8 follower-art gfx-ID copies** forked to a per-bank
> **id-indexed `NewFollowerGfxTableNN`** (`dw $7E00` at slot 0; resolver computes
> `table + (species-224)*2`, so adding species 225 = append a `dw` + rebuild — content-sized,
> grows on rebuild); `bank_011.asm` writes the layout level-1 slot `$413f = dw $4184` and forks
> the attr read (`HramUnk11_406e` → `NewAttrHandler @ $11:$792d`, id-indexed `NewFollowerAttrTable`);
> overworld clamp narrowed `cp $e0`→`cp $e1` so 224 passes (225–255 still clamp). New patch files:
> `bank_011/059/07e.asm`; new tool `tools/bake_follower_overflow.py` (emits the art bank).
> **Two orientation bugs found + fixed PROPERLY (root cause, not band-aid), both the same lesson —
> sanitise the base attr surgically:** (1) art is stored **un-flipped** (the `--flip-y` band-aid was
> removed from both tools); (2) the clean-attr mask is **`$B8` not `$98`** — `$98` also cleared the
> engine's bit5 X-flip, breaking the LEFT facing. See KEY_LESSONS + MONSTER_DATA. **G2 (battle sprite +
> battle palette for id 224) is now DONE (S35, above).** NOT yet done (next): `new_species.json` schema
> fold (G3).**

> **S33 — name/text/lineage/follower display fork seams now self-documenting at the clean anchors.**
> 11 files touched (`bank_000/001/006/007/009/00b/012/016/018/041/059`), comments+labels only.
> Covered: bank `$41` `$4007` mode→table config list, the corrective `FamilyCodePtrTable` block
> (it's the SPECIES-indexed 2-letter default-nick table, mode 7 — NOT a family table; label kept
> for ref-stability, flagged legacy), `Func_Bank41_GetText/GetPutText`; ROM0 `SaveBankAndSwitch
> $092F`/`TextHandler_0940 $0940` two-level `[mode][id]` lookup + per-mode-count overshoot hazard +
> `LoadModeBaseRedirect $00F0` fork cross-ref; bank `$12` lineage chain (`LoadItem_6456`→`$4d` entry
> 2 modes 0/1, `LoadItem_65a8`→recipe `$1601`→parent icons, `CmpItem_65cb`→`ItemSlotPtrTable`); the
> **8 follower gfx-ID copies** one-line-commented at their add-base sites (`$01/$06/$07/$09/$0b/$12/
> $18/$59`, all operands sym-confirmed to the tool's bases); + one optional cross-ref at bank `$16`
> `$0301` parent-family load. **Two corrections baked into source + MONSTER_DATA:** ItemNamePtrTable
> is **mode 8** of the `$4007` list (NOT mode 11 = `$49CD` MiscTextPtrTable); `$4739` overshoots at
> **id≥215** (fork covers **id≥224**; 215–223 phantom). Decisions (per user): keep the label + strong
> corrective comment (no rename), bank `$16` breeding-determination internals deferred to a
> breeding-mechanics pass. Docs updated in place: ROADMAP (Phase-D seam box → partial, display seams
> done, data-table seams `bank_003/014/001-encounter` + breeding internals still pending),
> MONSTER_DATA (overshoot registry + 8-copy add-base table + the two corrections). Changed source
> files are clean-disassembly only; no patches/tools/extracted touched.
>
> Last verified: 2026-06-22 (Session 30 — **Phase N audit + two reproducibility defects
> fixed; user-playtested OK**. Gorbunok (id 224) caught in Gate of Beginning, lists under
> Slime family, visualizable in library; custom rooms + encounters still good. Integrity
> PASS 4/4, clean build `1ca6579…`, test ROM `DWM-newspecies-repro-v1.gbc` MD5 `c17c2840…`.)
> **S30 — Phase N keystone verified; library + encounter made TOOL-OWNED (reproducible).**
> Forensic re-audit of the "add new monsters part 2" commits: clean disassembly net-zero
> change (the d84a43f/c4af28b comment add+remove cancel; nothing lost), N2 info-fork +
> N3 enemy-stats verified byte-correct (info table pinned at `$4461`, ids 0–220 byte-
> identical bar the 2 B6 reassigns; EID 518 @ `$14:$7EB3`). Two latent defects found and
> fixed, both "patch works but not reproducible from its tool": **(1)** the library Gorbunok
> entry + the unseen-marker move `$E0`→`$FE` (needed because `$E0` is now a real species)
> were hand-edited — `build_library_table.py` now reads `new_species.json` and owns all
> three marker sites (`ld [hl],$fe` + 2× `cp $fe`), count-validated, `--selftest` still
> proves vanilla parity. **(2)** the wild-encounter insertion (pool 0 slot 3 = EID 518) was
> hand-edited — `build_new_species.py` now emits it as a same-size in-place `EncounterPoolData`
> edit (validates the target slot was empty in vanilla first; Iron-Rule-2 safe). NOTE: an
> earlier audit claim that the encounter was "not applied" was MY error (searched the pool
> for species id `$E0` instead of EID `518`); the encounter was correct, only un-reproducible.
> Docs updated in place: BREEDING_SYSTEM (walker marker `$FE`), MONSTER_DATA (overshoot
> registry: encounters are a pool edit not a fork, follower 3/8 partial, library tool-owned),
> ROADMAP (N2/N3 ticked, N4/N5 partial, + a Phase-D follow-up to annotate the fork seams in
> clean disassembly). Changed files: `tools/build_library_table.py`, `tools/build_new_species.py`,
> `patches/bank_012.asm`, `patches/bank_001.asm`, `extracted/library_grouping.json` (+ docs).
>
> Last verified: 2026-06-22 (Session 29 — **encyclopedia DETAIL page FREEZE fixed**;
> Gorbunok (id 224) detail now opens clean, integrity PASS 4/4, ROM
> `DWM-Gorbunok-stage1ac-v16.gbc` MD5 `4d3d0d59…`. User-playtested: no freeze, no
> glitches; entry mirrors Dracky.)
> **S29 — detail-page freeze root-caused and fixed; recipe overshoot fixed.**
> Root cause: monster detail text uses a **mode×species double indirection** in
> `SaveBankAndSwitch` (`$00:$092F`) — source = `[ [$4007 + mode*2] + id*2 ]`. The
> line-2 **description** table (`$4D:$420B`) is only **215 entries** and ends at
> routine code, so id 224 read `[$43CB]=$0609` (ROM0 code) and the text VM rendered
> code as glyphs forever → `WaitScreenUpdateDone` spin. Fixed by a byte-neutral fork
> of `SetB4d_43b9` → `HighDetailTextFork` (custom mode-table; id≥224 line-2 →
> `$60BC`, Dracky's description as placeholder). Separately, the breeding-recipe
> lookup `label16_485c` indexed the **222-entry** `FamilyRecipeTable` unchecked
> (id 224 → bogus parents); forked via `FamilyRecipeResolve` → `$FF,$FF` (no recipe,
> correct for wild-only). New patch file `patches/bank_04d.asm` (registered in
> `PATCH_FILES`). The "material icon"/"stale Healer info" were render-abort artifacts
> and cleared with the freeze. New docs: `TEXT_SYSTEM.md`,
> `MONSTER_DATA.md` (Species ID geography) (species-indexed-table overshoot checklist); mechanism in
> `TEXT_SYSTEM.md`; recipe/new-breeding path in `BREEDING_SYSTEM.md`; lessons in
> `KEY_LESSONS.md`. **Deferred:** custom Gorbunok sprite/art and a custom (non-Dracky)
> description string. Vanilla 0–220 byte-identical; clean build still `1ca6579`.
>
> Last verified: 2026-06-21 (Session 28 — Phase N kickoff: add-NEW-species scoping/RE.
> No bytes changed, vanilla ROM untouched, integrity PASS 4/4. Pure RE + data tool —
> nothing to playtest yet; N2 is the first ROM.)
> **S28 — "add new monsters on top of the 221" scoped + slot map delivered.**
> User goal: brand-new species (not reskins). Species id is a single byte → hard 256
> ceiling; ids 215–219 are special (215 `TERRY?` one-off enemy; 216–219 Tatsu/Diago/
> Samsi/Bazoo = summon-skill byproducts, user-confirmed), 220–223 empty/phantom, so the
> **first free id is 224 (`$E0`), budget 32 (224–255)**. Architecture chosen: **high-table
> + single forked loader, vanilla 0–220 byte-identical** — each per-species table has ONE
> arithmetic indexer to fork (`if id < 224 → vanilla, else → free-bank high-table`).
> Verified single indexers: monster info `$03:SaveMon_4446` (×43; all 16 consumers read
> the `$DA33` copy), enemy stats `$14:LoadEnemyStats` (×25, **16-bit EID** → no 256 wall on
> the battle side). The ceiling is NOT one clean gate: ~40 `cp $dd`/`cp $de` hits are
> false positives (interrupt boilerplate + misassembled data); only 4 real top-range
> special-case gates (`$5f/$57/$58/$52`) need the N6 "treats ≥224 as normal" check.
> Deliverable: `tools/map_species_slots.py` + `extracted/species_slot_map.json` (256-slot
> map, self-aborts on drift). Plan: ROADMAP "Phase N" (N1 done; N2 info-table fork is the
> keystone next session); mechanics: MONSTER_DATA "Species ID geography".
>
> Last verified: 2026-06-21 (Session 27 — Phase D re-section: bank `$12` library/family
> data **COMPLETE**. Labels-only, byte-perfect — clean build still `1ca6579…`, integrity
> PASS 4/4. No behavioral change, nothing to playtest.)
> **S27 — bank `$12` window-layout run finished (whole bank now editor-addressable).**
> Extended `tools/resection_library_tables.py` to convert the **two remaining contiguous gaps**
> in the menu window-draw layout run: `$724e..$759a` (10 layouts) and `$75c0..$7b42` (13 layouts).
> Combined with S26, the entire contiguous run **`$710c..$7b9b` = 29 layouts** now reads as named
> `db`/`dw` (`LibWinLayout_<addr>`), all 13 remaining `ld de,$imm` reference sites labelized (44
> total across S26+S27). The 380-B `$79c6` full-screen library view (an 18×20 layout using a
> *different* window-border tileset, `$01 $02..$03`/`$04`/`$05`) is converted — its mgbdis fake `jr`
> labels (`$7a05`…`$7aca`) and their `jr` sources were all inside the data range and vanished
> together (no dangling refs). The 21 `ld hl,$XXXX; rst $10` far-call descriptors (`$5605`/`$6100`/
> `$6101`) correctly LEFT raw. New data deliverable `extracted/library_layouts.json` (29 layouts
> decoded to rows; `--dump-json`). Tool is now per-table idempotent and re-runnable from the clean
> tree (verified: clean-tree run reproduces byte-perfect build + identical 29-label set). Format +
> per-layout table: DATA_STRUCTURES "Library / family-tab menu data (bank `$12`)"; ROADMAP Phase D
> bank-`$12` item ticked complete. This closes the bank-`$12` re-section; the remaining Phase D work
> is the stale-box verify-ticks (`$03`/`$14`/`$16`) and editor-driven banks (`$01`/`$50`/`$51`).
> Also recorded (Session 27) a **"new campaign" gap analysis** — the campaign-scale subsystems
> beyond editor v1 (arena/gate-boss roster format, story-progression authoring + bank-`$50`,
> new-game init/save headroom, gate-network, intro/ending, text capacity) — in ROADMAP "Phase E",
> with the two story/arena keystones detailed in SIDEQUEST_MAP "Gaps for authoring a NEW campaign".
> The keystone RE gap is **E1 (arena/gate-boss roster format)** — the natural next Phase-D/E session.
>

> Last verified: 2026-06-21 (Session 26 — Phase D re-section: bank `$12` library/family
> data tables converted to labeled `db`/`dw`. Labels-only, byte-perfect — clean build still
> `1ca6579…`, integrity PASS 4/4. No behavioral change, nothing to playtest.)
> **S26 — bank `$12` library/family data tables re-sectioned (editor-addressable).**
> `tools/resection_library_tables.py` converts the misassembled library-menu data tables in
> `bank_012.asm` to named `db`/`dw` (labels/comments only, zero byte impact): `LibraryFamilyTabBounds`
> (`$6294`, 11 B family id-range bounds — the S18 case, "THE ONLY id-range family assumption in the
> ROM"), `LibTabColPos_564a`/`_5a8e` (tab-column cursor positions, `$ffff`-terminated, read by
> `FuncItem_43e2`), and `LibWinLayout_710c`/`_71aa`/`_71f4`/`_759a`/`_7b42`/`_7b6c` (menu window-draw
> layout streams: dest-position word + tile bytes, `$d8`=newline, `$d9`=terminator, via
> `ReadPtrFromDE` + draw loop `$40c3`). 31 raw-pointer reference sites labelized. `$5605` correctly
> LEFT — it's a far-call descriptor (`ld hl,$5605; rst $10` → bank `$56` entry `$05`), NOT `$12` data;
> the `$79c6` region conservatively skipped (mgbdis put `jr` labels in it; it is reached via `ld de`
> so likely a convertible layout — flagged for the bank-`$12` follow-up). The tool maps source
> line→address via a zero-byte probe-build read from the linker `.sym` (avoids the S22 opcode-size-
> summing trap) and is re-runnable from the clean tree. Format + addresses: DATA_STRUCTURES
> "Library / family-tab menu data (bank `$12`)"; remaining bank-`$12` tables + skip-list folded into
> ROADMAP Phase D "Re-section misassembled data tables". Supports the B8/B9 library/family work
> (the 11th-family tab + bounds are now named/editable rather than re-derived from raw bytes).
>
> Last verified: 2026-06-21 (Session 25 — GFX-4 DONE: monster→follower-layout auto-map +
> custom-art import + full multi-context consistency. Healer→Dragon clone and Dracky→custom
> blue-dragon both user-confirmed "everything is correct" in SameBoy, consistent across overworld
> + menu + library.)
> **GFX-4 DONE — monster → follower-layout map, custom-art import, all-context consistency.**
> (1) The level-1 layout dispatch tables are LOCATED at FIXED addresses **`$10:$407f` (species
> 0–127) / `$11:$407f` (species 128+)**, 128 `dw` each, indexed by species directly (`$ffc7 =
> species+$10`, routed `$10–$8F`→bank `$10`, `≥$90`→bank `$11` via bank-`$04` entry 2). A per-species
> **attr/palette table at `$10:$417f` (128 entries) / `$11:$412d` (87 entries)** (ORed into `$ffca`, low 3 bits = OBJ palette). **Two
> pre-GFX-4 doc errors corrected:** `[$caca]` is the SPECIES (party struct +$09), NOT a "sprite-class"
> byte; and bank `$05` is the ObjTest viewer path, NOT the follower path (S24 anchored to `$05`
> addresses — harmless because dedup ignored bank, but wrong). Both Healer (sp9, sharing) and DarkDrium
> (sp214, non-sharing) reproduced byte-for-byte through `$10`/`$11`. (2) `tools/extract_monster_follower_layouts.py`
> + `extracted/monster_follower_layouts.json` (every species → layout id + addresses + sharing); it
> REGENERATES & REPLACES `follower_layouts.json` with the COMPLETE **155 layouts** (old 118 dropped
> the 3-entry small/blob layouts the brute-force scan rejected). `--selftest` PASS (215/215
> collectible map; anchors verified). (3) **The follower-art gfx-ID table has EIGHT copies**
> (`$01 $06 $07 $09 $0b $12`-library `$18`-menu `$59`); a consistent swap must repoint all 8 (layout
> `$407f` + attr `$10:$417f`/`$11:$412d` are single/shared). GFX-3 repointed only `$01` → that's why swapped monsters
> kept old art in menus. (4) `tools/build_follower_reassign.py` — reassignment primitive: clone
> layout+art+attr from a same-bank monster, OR import custom 16-tile art (placed cross-bank via the
> GFX-2/3 overflow allocator, all-8-copies repointed) + set layout (default layout 0 `$10:$4e33`) +
> OBJ palette. Layout 0 packing: tiles 0–3=DOWN-a, 4–7=SIDE-a, 8–11=SIDE-b, 12–15=UP-a (down_B/up_B
> auto-mirror; LEFT = right X-flip). Clean build still `1ca6579…`; integrity PASS 4/4. Reassignments
> are reproducible EXAMPLES, not baked into the canonical ROM. **Reassignment is a level-1 repoint,
> NOT a `[$caca]`/species edit** (supersedes the GFX-3 plan's "same-size `[$caca]` edit"). Method:
> KEY_LESSONS "Session 25"; mechanics: MONSTER_DATA "Monster → layout dispatch".
>
> Last verified: 2026-06-21 (Session 24 — GFX-3 DONE: walking/follower sprite swap +
> follower metasprite engine fully reverse-engineered + 118-layout library extracted.
> Blue dragon → DarkDrium follower user-confirmed "absolutely perfect" all 4 directions.)
> **GFX-3 DONE — follower (walking-sprite) swap, end to end.**
> (1) `ScreenTransDataTable` @ `$01:$49DF` re-sectioned from mgbdis fake-instructions to a
> labeled `dw` block (`tools/resection_follower_gfx_table.py`; 231 entries indexed
> `species+$10`, + `FollowerFamilyGfxTable` 10 families @ `$4BAD`; build still `1ca6579…`,
> zero external refs into range). `build_sprite_swap.py --kind follower --payload F.bin`
> repoints the dw entry and DMAs a self-contained 16-tile (256 B) literal-encoded stream.
> (2) **Follower render = metasprite engine** — `SaveScr_40cd` @ `$04:$40cd` (GBC variant of
> ROM0 `$0d91`). A two-level pointer table (sprite-type `$ffc7` → frame/direction `$ffc8`)
> selects a metasprite list: 4-byte entries **(dy, dx, tile_offset, attr)**, `$80`-terminated.
> Final OAM tile = `tile_offset + [$ffc9]` (follower tile base `$20`/`$30`/`$40` per party
> slot 0/1/2); final OAM attr = `[$ffca] XOR attr` (X-flip = bit5 `$20`). `$ffc7 = [$ca91]`
> (= `GetActiveMonsterStatus` return: `$01` if bit7 of `[$cb0b]`, else `[$caca]+$10`).
> (3) **OBJ transparency rule (critical):** colour index 0 is HARDWARE-transparent for OBJ
> sprites (the battle path used a BG backdrop = index 1 — opposite). Follower empty/background
> pixels MUST map to idx0. 8 global OBJ palettes (4×RGB555) at `$17:$5615`.
> (4) **Per-monster layouts — there is NO single universal arrangement.** The tile→direction
> mapping is one of **118 distinct layouts** (`tools/extract_follower_layouts.py` →
> `extracted/follower_layouts.json`). **76 are non-sharing** (disjoint down/up/side tile sets
> → ANY distinct art renders perfectly; cover 202 sprite types) and **42 are sharing**
> (up/side reuse tiles — fine for radially-symmetric blobs, breaks directional art; 58 types).
> This resolved the multi-attempt mystery: a symmetric blob masks layout errors (the clam
> "worked" by luck); a directional dragon exposes them. Healer = a sharing layout, DarkDrium =
> a non-sharing one (both measured, both matched the extracted data exactly).
> (5) Tooling: interactive `tools/follower_frame_picker.html` (drag 6 boxes over a sprite
> sheet, live per-direction engine-accurate preview, export coords/payload). **Numbered-tile
> calibration method** (each VRAM tile renders its own hex index 0–F + a flip-foot →
> read the layout directly off-screen, no decoding) — `--palette` override forces black digit
> / red foot for legibility against terrain.
> USER-CONFIRMED in SameBoy: blue dragon (DWM2 art) → DarkDrium follower, all 4 directions
> correct, by matching the art to DarkDrium's non-sharing layout.
> **FOLLOW-UP — GFX-4 flagged (ROADMAP):** monster→layout auto-map. The type→layout level-1
> dispatch tables (banks `$05`/`$10`/`$11`, routed by `$ffc7` magnitude: `<$10` bank `$04`,
> `$10–$8F` bank `$10`, `≥$90` bank `$11`) and the per-monster sprite-class byte (`[$caca]`)
> are not yet located/extracted; the full engine structure IS known, so it's a clean pickup.
>
> Last verified: 2026-06-20 (Session 23 — GFX-2 DONE: cross-bank sprite backbone +
> monster battle palette SOLVED + recolour; clam→Dracky purple + full integration
> user-confirmed in SameBoy.)
> **GFX-2 DONE — cross-bank sprite swap backbone + monster palette recolour.**
> (1) `dwm/sprite_bank.py` — cross-bank OVERFLOW allocator: places encoded streams in
> the reserved sprite banks (`$7E–$7F`, then `$7C/$7A/$79`; EDITOR_DESIGN §8) with a
> `$4001` pointer table, and `tools/build_sprite_swap.py` (rewritten) repoints the
> species→gfx-ID entry — works for ANY of 221 monsters regardless of which bank their
> art lives in (resolver reads `$<bank>:$4001+index*2`, NO bank gating; verified). This
> is the bulk-DWM2-import enabler (the old tool was battle-only, bank `$36` only,
> ~40/221). `--relocate` = lossless cross-bank copy (proof: Slime relocated renders
> identically, user-confirmed). (2) **Monster battle palette SOLVED** (was the GFX-2
> "semi-speculative" gap): the enemy renders as BG tiles on **BG palette slot 4**; the
> per-species colours live in **`MonsterBattlePalettes` @ `$17:$62FD`** (mgbdis-misnamed
> `RoomAttrDataBlocks`), 8 B/species `[c0, c1=$6bff backdrop, c2, c3=$0000 black]`,
> loaded by bank `$17` **entry 6** (`$1706`: `$c81e`=species×8+base, `$c81f`=slot).
> Found via SameBoy BG-slot-4 dump (Dracky `007b 6bff 2a97 0000`) + ROM grep; annotated
> in `bank_017.asm` (label `MonsterBattlePalettes` + loader doc, byte-perfect). Recolour
> = same-size 8-byte edit of one species' entry (Iron-Rule-2 safe; per-species, no
> bleed) via `build_sprite_swap.py --palette`. (3) Data: `tools/extract_monster_palettes.py`
> + `extracted/monster_palettes.json` (all 221); `extracted/monster_sprites.json`
> REGENERATED (all 221 — the shipped copy was a 3-monster subset, a data defect now
> fixed). USER-CONFIRMED in SameBoy: DWM2 clam→Dracky battle + correct purple palette;
> and a full integration ROM (clam + Dracky→Spirit family + custom room with random
> encounters + breeding/library all coexisting, no glitches). The swap touches only
> bank `$7e` (art) + 2 B in `$00` (repoint) + 1 entry in `$17` (palette) — orthogonal to
> breeding/library/custom-rooms/Spirit-family. Integrity PASS 4/4. NEXT: GFX-3 (follower
> /walking swap) — rides this backbone via `$01:$49DF` (needs re-section first) + its own
> palette table + the family-shared `$4bad` block. Method: KEY_LESSONS "Session 23";
> mechanics: MONSTER_DATA "Monster battle palette system".
>
> Last verified: 2026-06-20 (Session 22 — GFX-1: graphics system annotated +
> sprite codec/extraction/swap tooling; Dracky→Anteater swap user-confirmed in
> SameBoy as a mostly-red Anteater, i.e. correct shape in Dracky's palette.)
> **GFX-1 DONE — editor graphics asset layer + correct disassembly.** Three
> foundations landed: (1) the battle gfx-ID table `$00:$2B9F` was misassembled
> (fake instructions, 23 hallucinated labels cross-referenced from other banks);
> re-sectioned into a real labeled block `MonsterBattleGfxTable` via
> `tools/resection_battle_gfx_table.py` — anchored between real symbol-map label
> boundaries, exact ROM bytes emitted, all 23 cross-refs preserved, build still
> `1ca6579…`. (2) `dwm/sprite_codec.py` — the SINGLE LZ codec for tiles+sprites
> (decode byte-exact = game + existing tile decompressor; encode valid/compact;
> tile↔image); `decode(encode(x))==x` verified on all 442 monster streams.
> Deliberately NOT byte-identical re-encode of vanilla (no editor value). (3)
> `tools/extract_monster_sprites.py` + `extracted/monster_sprites.json` — all 221
> monsters' battle+follower sprites → manifest (count-parameterised, no 221 wall).
> `tools/build_sprite_swap.py` generalised to species-agnostic (PNG/payload/probe →
> encode → place → repoint); builds valid ROM. INTEGRITY PASS. KNOWN: all 221
> battle streams use shared-VRAM-pool back-refs → new art must encode self-contained
> (`--literal`) or reconstruct pool; swap tool's free-space placement currently
> knows bank `$36` only (cross-bank allocator = editor-backend follow-up). PALETTE
> LEAD for GFX-2 (user VRAM data): battle uses ONE shared OBJ palette slot (4); the
> per-species COLOURS are loaded into it at battle-init via `FuncFld_6942`/
> `SetGBCPalette` (bank `$07`, note `ld h,$04`). So recolour = edit the per-species
> colour table, NOT a slot assignment. Full mechanics in MONSTER_DATA.md "Monster
> sprite graphics system"; lesson in KEY_LESSONS "Session 22". Next: GFX-2 (palette
> recolour) or GFX-3 (follower swap, rides the codec).
>
> Last verified: 2026-06-19 (Session 21 — Monster battle-sprite swap POC:
> Dracky sp.78 → DWM2 "clam", proven rendering in SameBoy; in Dracky's native
> palette pending recolour.)
> **Monster sprite graphics system reverse-engineered + swap proven.** Every
> graphic = gfx-ID `(bank<<8)|index` → resolver `DecompressTileLayout` `$00:$1627`
> → per-bank pointer table `$<bank>:$4001+index*2` → LZ stream (3-byte header,
> back-refs into a SHARED VRAM tile pool). Battle path VERIFIED: `SetFld_466d`
> (bank `$07`) → table `$00:$2B9F`[species*2] → VRAM `$8B00`; Dracky = gfx-ID
> `$3627` (bank `$36`, 36 tiles). Swap method: self-contained literal stream (no
> runmark byte) repointed in bank `$36` free space — `tools/build_sprite_swap.py`,
> `patches/bank_036.asm`. Build stays `1ca6579…`; INTEGRITY PASS. Full mechanics
> in MONSTER_DATA.md "Monster sprite graphics system"; next jobs queued as ROADMAP
> **GFX-1** (annotate tile system), **GFX-2** (palette + recolour, semi-speculative),
> **GFX-3** (follower swap). Palette is a separate subsystem (bank `$17`, not yet pinned).
>
> Last verified: 2026-06-19 (Spirit B9 — family-10 VRAM corruption FIXED + icon
> finalized; user-confirmed in SameBoy. Built ON TOP of the gate-entry-freeze fix.)
> **B9 — 11th family "Spirit": VRAM corruption FIXED; icon shipped.** Catching a
> family-10 (Spirit) monster (Dracky sp.78 / DarkDrium sp.214) → party → map corrupted
> ALL of VRAM. Root cause: `bank_01:$49C0` indexes a **10-entry family-indexed GFX
> pointer table at `01:$4BAD`**; family=10 reads OOB → garbage source + garbage copy
> length → runaway copy over all VRAM (SameBoy watchpoint: BC=$2196 runaway, source
> $55fc, into $9864). Fix: 8-byte `ClampFamIdx::` in ROM0 end-of-bank padding (replaced
> 8 `rst $38` filler at $3BCB: `call ReadActiveMonsterByte / cp $0a / ret c / dec a /
> ret`, family≥10→9); `patches/bank_001.asm` routes ONLY the `$4BAD` lookup ($49C0)
> through it as a same-size `call` (Iron-Rule-2 OK, zero shift). The nearby `$499D`
> lookup is SPECIES-indexed into the 215-entry follower table `$49DF` (NOT family) —
> clamping it broke all follower sprites, so it is left alone. **Icon:** the Spirit
> whip (user-selected "option 5") ships on font byte **$19 (`$4F:$41A0`)**, overwriting
> the vanilla ??? glyph (??? + Spirit share it) — NOT the S20-planned free slot $1A
> (`$41B0`), which the menu blanks at runtime (not fill-immune). `extracted/family_icons.json`
> + `tools/build_family_icon.py --selftest` reconciled to the $19 art (icon rederivable
> from tracked data, no PNG). This whole feature sits ON TOP of the committed gate-entry-
> freeze fix: `ClampFamIdx` and `CustomGFXMapID` coexist in ROM0. Clean build still
> `1ca6579…`; integrity PASS. User-confirmed: no corruption, correct followers, library
> grouping good, family attribution correct. Method: KEY_LESSONS "Spirit B9 Lessons".
> **Doc correction:** any S20 text below stating the Spirit icon is on $1A is superseded
> by the $19 placement recorded here.
>

> Last verified: 2026-06-18 (Session 20: family-icon trace (B8/B9 "name" path) +
> Spirit icon insert. NOTE: the S20 "$1A slot / pending sign-off" claims below are
> SUPERSEDED by the 2026-06-19 block above — Spirit icon ships on $19, B9 confirmed.)
> **B8/B9 family-icon path TRACED + Spirit icon half-built (S20).** The long-blocked
> "family-NAME render path" is solved: the family identity is an **ICON font tile**,
> not a string. 10 icons live at `$4F:$4110-$41A0`, addressed by **text bytes
> `$10-$19`** via `ComputeTileDataAddr` (`$00`: `addr = $4010 + byte*16`); the
> monster-detail screen prints `<$F0><icon $1x>"family"` (bank `$4D`) and the
> library tab strip blits the same tiles. `FamilyTextPtrTable` (`$04:$60F4`) is
> confirmed a red herring (per-family monster **dialogue**, opcode `$2D`). User
> confirmed the medium ("symbols, not text") and the icon order (by visual, glyph
> order `$10-$19`: slime, dragon, paw, feather, tree, insect, hammer/axe, black face,
> red face, "?"). The free slot for an 11th icon is **byte `$1A` → `$4F:$41B0`**
> (blank filler; charmap "20-23 are blank"). **Spirit icon inserted** as a same-size
> 16-byte 2bpp tile there (`patches/bank_04f.asm`, user "Fire Whip Spirit" art, zero
> shift; bank `$4F` otherwise byte-identical to vanilla). Tool
> `tools/build_family_icon.py` + data `extracted/family_icons.json` (Variant A = head
> on palette index 0 → yellow head if the menu palette allows; Variant B = head on
> index 2 fallback; `--selftest` proves the JSON grid == the patch bytes). Disassembly
> annotated (comments only, byte-perfect `1ca6579…`): `bank_04f.asm` family-icon block
> + free-slot map. Verifier PASS 4/4 (`bank_04f.asm` added to the patch set). Test ROM
> `ab59c842…`; clean build still `1ca6579…`. **STILL OPEN (rest of B9):** the "yellow
> head" is a SameBoy palette question (menu BG pal via `LoadGBCPalettes`→`rst $10`
> `$17:$03`); wiring Spirit as family 11 (the `$4D` detail line, tab-strip 11th cell
> `LoadItem_4241` `b=5,c=10`, the `$FA` family-code wildcard, `NUM_FAMILIES`→11,
> reshuffle) is not done. The icon isn't referenced by any family yet → view via
> SameBoy VRAM viewer until wired. Method: KEY_LESSONS "Session 20 — Family icons";
> reference: BREEDING_SYSTEM "Family icons (B8/B9)".
>

> **B7 — production library grouping (SameBoy-confirmed).** The S18 dynamic-library
> POC (runtime per-species far-load scan, ~221 loads/tab → lag + scratch RAM) is
> REPLACED by a build-time precomputed **family→members** table. `tools/build_library_table.py`
> emits the table into bank `$12` trailing free space (`$7B9B+`) and rewrites
> `SetItem_6242` zero-shift (`jp LibScanByFamily`; 82-byte body → `jp`+79 `nop`); the
> walker reads the table directly — **zero far-loads, zero scratch RAM**, and restores
> the vanilla blank-slot-for-undiscovered semantics the POC had dropped (`$E0` unseen /
> id seen; `$C8E9`=member count, `$C8E8`=seen count). Format: pointer table + length-
> prefixed member lists (additive for an 11th family). Family assignment sourced from
> the vanilla family byte (`$03:$4461+$00`, raw 0..9) + `breeding_family_reassign.json`
> (the SAME spec `bank_003`/B6 consumes — library and family bytes stay in lock-step).
> Build-time self-checks: `--selftest` proves no-reassign grouping == vanilla bounds
> table exactly (ids 0..214 → parity); each family ≤ buffer cap (32); ids ≤ 255;
> free-space fit. **COLLECTIBLE vs SPECIAL clarified (user, do not re-derive from
> "looks empty"):** ids 0..214 are collectible (library-listed); ids 215..220 are REAL
> but non-collectible combat-only entities — 215 `TERRY?` (Durran story enemy), 216–219
> the four summon-skill tiers (Tatsu/Diago/Samsi/Bazoo), 220 reserved/blank — enumerated
> and PROTECTED (excluded, never a reassignment target). **Extension-aware (no hardcoded
> 221):** species id is 1 byte → 256 ceiling; `COLLECTIBLE_MAX`(→255) and `NUM_FAMILIES`
> (→11, B9) are the only knobs. **User decision (S19): Spirit will be ADDED as an 11th
> family (B9), then families reshuffled** — not a 10-family rename. Data deliverable
> `extracted/library_grouping.json`. Test ROM `065943f6…`; canonical clean build still
> `1ca6579…`. Method: KEY_LESSONS "Session 19 — Breeding B7".
>
> Last verified: 2026-06-18 (Session 18: breeding B6 — family reassignment +
> dynamic-library proof-of-concept, user-confirmed in SameBoy.)
> **B6 — family reassignment (SameBoy-confirmed) + dynamic-library POC.** Monsters
> can be moved between ANY families (incl. in/out of ??? / Boss=9) via same-size
> family-byte edits at `$03:$4461+$00`. `tools/build_family_reassign.py` (spec
> `extracted/breeding_family_reassign.json`, `from` validated == vanilla) emits
> `patches/bank_003.asm` (exact-line db edits, zero shift). **Reader gate CLEARED:**
> family-byte readers outside breeding are display/struct-copy only (banks
> `$01/$04/$07/$09/$14`); none gate scout/recruit/AI/resistance on family==9 —
> eligibility is the enemy-stats joinability byte (`$14 +$3`) + boss table
> (`$14:$4897`). **Three family representations** (BREEDING_SYSTEM "B6"): breeding =
> live byte; status/menus = struct `+$0A` stamped at creation (snapshot — correct
> for a fresh hack); library = id-range via `SetItem_6242`/`$12:$6294` (the ONLY
> id-range family assumption in the ROM). **Dynamic library = PROOF OF CONCEPT**
> (`patches/bank_012.asm`, `tools/build_dynamic_library.py`): `SetItem_6242`
> redirected (zero-shift) to a family-byte scan in bank `$12` free space; 8
> reassigned monsters group correctly in SameBoy. POC only — lags ~221 far-loads/
> render (bearable), no RAM claim beyond one scratch byte. **Production plan (B7):
> editor emits a precomputed family→members table at build time; do NOT optimize the
> runtime POC.** Rename (B8) + 11th family (B9) split out in ROADMAP. Disassembly
> annotated (comments only, byte-perfect `1ca6579…`): `SetItem_6242`, the family-byte
> reader trace at bank `$03 label443f`. Patched test ROMs only; canonical clean build
> still `1ca6579…`. Method: KEY_LESSONS "Session 18 — Breeding B6".
>
> Last verified: 2026-06-18 (Session 17: breeding B5 — full special-table
> authoring DONE, user-confirmed in SameBoy.)
> **B5 — full special-table authoring (SameBoy-confirmed).** `build_breeding.py
> --emit-special` now OWNS the whole SPECIAL recipe table as authored data and emits
> it to bank `$69`. The base is the 825 vanilla entries decoded from the **ROM**;
> `extracted/breeding_special.json` supplies in-place `overrides` (edit any base
> entry — addressed by `{"index":N}` or by `{"match":{p1,p2}}` = first base entry that
> fires for that cross; absent fields inherit the base) and `appends` (new entries
> past 824, the B3 mechanism). A **whole-table first-match-wins shadow validator**
> replaces B3's append-only check: build-failing ERRORS on a shadowed append or a
> shadowed override; WARNINGS on an edit newly preceding a later different-result
> entry and on an override that changes a result species **other entries still
> produce** (so "edit a cross" ≠ "remove a monster"). **Single source of truth:**
> bank `$16`'s special table stays byte-identical to the ROM forever (already
> runtime-dead via the B2 `rst $10` redirect), so nothing in the shift-sensitive bank
> moves and there is one authored source + one emit target. Self-checks: emitted ==
> authored bytes + `$FF`; every non-overridden base entry == vanilla; each override
> present at its index; capacity ≤ 1650. User-confirmed in SameBoy: MadCat×BattleRex →
> DracoLord (in-place edit of entry 187, was Yeti; DracoLord id 200 used explicitly —
> two species share the name), Darkdrium×BattleRex → Armorpion (unshadowed append),
> Anteater×BattleRex → GoldSlime both orders (S12 carried forward as overrides at dead
> entries 693/803). Patched ROM `c95f62ce…`; canonical clean build still `1ca6579…`.
> **B5 supersedes the B3 `--emit-relocation` + `breeding_extra_recipes.json` path** as
> the canonical bank `$69` emitter (the old index-825 DracoLord append is replaced by
> the cleaner entry-187 edit; DracoLord still reachable, no capability lost). Method +
> rules: KEY_LESSONS "Session 17 — Breeding B5" and BREEDING_SYSTEM "Planned". The
> actual recipe REWRITE (Spirit-as-breedable, new results) is authored by hand in the
> editor UI later — B5 is the machinery, not the content.
>
> **B4 — family-defaults rewrite (SameBoy-confirmed).** The FAMILY recipe table
> (`$16:$4974`, positional: offspring species == slot index) can now be authored
> in place via `tools/build_breeding.py --emit-family`, sourced from
> `extracted/breeding_family_defaults.json` (a `result→{p1,p2}` override list). The
> tool starts from the vanilla family decode, applies only the overrides, validates
> positional 1:1 (one cross per result species) + 444-byte zero-shift + shadow classes
> (special-table family-code shadow and duplicate family matchers), and rewrites only
> the `FamilyRecipeTable` db block in `patches/bank_016.asm`. Authored proof set is a
> zero-collateral permutation of the three Dragon-mate matchers plus one NEW recipe at a
> previously-empty separator slot: Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj,
> Beast×Dragon→Wyvern, Dragon×Dragon→GreatDrak (slot 37). Whole-ROM impact: **5 bytes**
> in bank `$16` + header/global checksum (focused diff vs the B3 ROM; B3 baseline rebuilt
> as the recorded `f1cd94b1…`). User-confirmed in SameBoy: FunkyBird×BattleRex→DrakSlime,
> Snaily×BattleRex→Almiraj, Dragon×Dragon→GreatDrak (patched ROM `caa597d1…`; canonical
> clean build still `1ca6579…`). Beast×Dragon→Wyvern is in the table but correctly
> shadowed for MadCat by SPECIAL entry 187 (MadCat×BattleRex→Yeti) — special > family
> precedence, not a bug. Untouched cross BattleRex×Healer→DragonKid (vanilla family slot
> 20) unchanged. Confirmed mechanics (grepped, do not re-trust): family scan does
> exact-species-immediate / family-code-last-wins with a two-pass (parent2 specific, then
> as family); `$FA` "AnyFamily" wildcard is scanner-supported but used ZERO times in vanilla
> data. Method + rules: KEY_LESSONS "Session 16 — Breeding B4" and BREEDING_SYSTEM "Planned".
>
> **B3 — special-recipe capacity extension (SameBoy-confirmed).** The relocated
> bank `$69` special table (B2) now grows past the 825 vanilla entries: its
> scanner walks to the `$FF` terminator with no hardcoded count, so
> `build_breeding.py` appends recipes from `extracted/breeding_extra_recipes.json`
> after the 825 base entries and re-terminates. Capacity ceiling `SPECIAL_CAPACITY_MAX
> = 1650` (2× vanilla); bank `$69` (16 KB) fits it with headroom. Proof recipe at
> index 825: **BattleRex(Pedigree) × MadCat(Mate) → DracoLord** — chosen because
> it is UNSHADOWED by all 825 base entries (the forward order MadCat×BattleRex is
> the vanilla → Yeti recipe at index 187, so it would win first); user-confirmed
> DracoLord in SameBoy (patched ROM `f1cd94b1…`; canonical clean build still
> `1ca6579…`). Tool self-checks: base 825 == patched bank_016 table, S12 recipe
> intact, appended bytes placed + `$FF`-terminated, and an emit-time SHADOW CHECK
> that FAILS the build on a dead (already-matched) appended recipe. Focused diff:
> 4 bank-`$69` bytes + header checksum, nothing else. Method + rule: KEY_LESSONS
> "Session 15 — Breeding B3" and BREEDING_SYSTEM "Planned: Overhaul & Extension".
> Forward plan signposted there + ROADMAP Phase 2B (B4/B5/B6) after a ??? mechanic
> audit (see below).
>
> Session 14: bank $0B repointing — breeding-cutscene glitch FIXED.
> **Bank $0B dynamic-repointing completed.** The breeding-cutscene parent-sprite
> glitch (wrong monster, correct palette) and a parallel gate-table glitch were
> caused by three un-labelized raw pointer refs into bank $0B's shift region
> (`$4974` sprite table; `$42c8`/`$4308` gate table with raw `dw` entries). Labelized
> in the disassembly first (clean build still `1ca6579…`), then ported to
> `patches/bank_00b.asm` — where the sprite ref was additionally found **mislabeled**
> to `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`), and
> repointed. User-confirmed in SameBoy: breeding cutscene clean; custom rooms
> `$6B`/`$6C` + custom→custom transitions working (patched ROM `b43a04fe…`; canonical
> clean build still `1ca6579…`). No trampolines — pure dynamic repointing. Custom
> banks are 100% label-based (repointable by construction). Remaining hardcoded
> repointing refs: `$08:$7751`, `$32:$5A5F` (latent — banks not patched). Method
> + rule: KEY_LESSONS "Session 14 — Bank $0B repointing" and SESSION_PROTOCOL §4.
>
> Session 13: breeding B1 + B2 DONE.
> **B2 — special-table relocation harness (SameBoy-confirmed).** The special
> scan moved from bank $16 to free bank `$69`, called via `rst $10`
> (`ld hl,$6900`); the 30-byte scan at $16:$46F2–$470F replaced in-place with
> `ld hl,$6900`+`rst $10`+26-byte NOP pad (zero shift), falling into the
> unchanged plus-clamp at $4710. `patches/bank_069.asm` (faithful scanner port
> + special table) is generated by `build_breeding.py --emit-relocation`,
> sourcing the table from the **patched** `bank_016.asm` so existing custom
> recipes survive. Verifier PASS 4/4; full-ROM diff: bank $16 changed only in
> the 30-byte window. User-confirmed: Anteater×BattleRex→GoldSlime both orders,
> vanilla crosses unchanged, saving OK (patched ROM 868f9276…, patched-build
> artifact only — canonical clean build is still 1ca6579…). Open follow-up:
> breeding-cutscene parent sprites glitch — NOT from B2 (graphics path; B2 only
> writes result RAM), suspected pre-existing earlier-patch regression; logged in
> ROADMAP with a bisect plan. **RESOLVED in Session 14** — see top entry (it was an
> incomplete bank $0B labelization, not a breeding-path regression).
> **B1 — breeding round-trip encoder (keystone).** `tools/build_breeding.py --selftest` decodes BOTH vanilla tables
> and re-emits them byte-identical to the ROM (special $4B30 4126 B incl $FF;
> family $4974 444 B incl $0000); db-text emission re-parses to the same bytes;
> disassembly db == ROM (--check-disasm). Decode independently reconciles with
> hand-authored breeding_complete.json (825/825 special, 197/197 family slots, 0
> diffs). Data deliverable extracted/breeding_tables.json (Tier A, _generator).
> Pure tooling — no ROM change; clean build still 1ca6579…; verifier PASS 4/4.
> Unblocks B2-B6. NOTE: B1 is a tool+data keystone, not a content patch — nothing
> to playtest; acceptance is fully machine-checkable.
> Prior — Session 12: custom breeding PROVEN — special-recipe
> override Anteater × BattleRex → GoldSlime via same-size, in-place edit of two
> provably-dead table entries; confirmed in-game in SameBoy. Tool
> `patch_breeding_recipe.py` + `patches/bank_016.asm` (bank $16 added to the
> verifier patch set). Romhack-scale breeding overhaul + extension specced
> (BREEDING_SYSTEM "Planned: Overhaul & Extension" + ROADMAP Phase 2B): defaults
> rewritten in place, special table relocated to free bank $69 via rst $10 and
> extended to 1×–2× (~1650). Family table is positional (result = slot index) —
> documented. The keystone round-trip encoder B1 is now built (above).
> Prior — Session 11: random encounters PROVEN in a custom
> non-gate room (Strategy A) — whitelist mapID in $0B:Jump_00b_4674 + pin
> wGateID/wCurrentFloor in ASM + arm wEncounterCounter from the room-entry
> script. Pool fully controllable via gate/floor; win+flee return clean.)

---

## Part 2 — Resolved documentation defects (moved from PROJECT_STATE, 2026-07-02)

All items below are RESOLVED; kept verbatim for forensics. Open defects live in
PROJECT_STATE.md "Open defects".

- ~~Two contradictory MD5s across docs~~ → fixed; verifier now polices this.
- README inventory range `$CA21–$CA50` was wrong; **correct: `wInventory` =
  `$CA51`, 20 slots** (ARCHITECTURE.md + patches/wram.asm agree, verified in
  GiveItem handler).
- ~~`extracted/map_table.json` interact/exit labels swapped~~ → fixed;
  `dump_map_table.py` rewritten with verified semantics + $FFFF hole-
  skipping bug also fixed (was dropping a third of rooms).
- NEXT_CLAUDE_MESSAGE.md and SESSION1_ARCHIVE.md are superseded — delete
  (replaced by this file + SESSION_PROTOCOL.md + ROADMAP.md).
- ~~Data layer: tool-behind-data and frozen-source JSONs~~ → ALL RESOLVED.
  `dump_enemy_stats.py` reconciled (full 25-byte decode, 487/487 match);
  new generators written for `skills.json`, `text_id_map.json`,
  `all_scripts.json`; `map_table.json`/`exit_table.json`/
  `room_connections.json` regenerated with fixed decoders; remaining
  JSONs reclassified (hand-authored reference or stable analysis, not
  frozen-source). See TOOLS_AND_DATA.md for the complete audit.
  `monsters.json`, `event_flags.json`, `edits.json` are legacy (deletable).
- KEY_LESSONS.md claims "Bank $0B is safe for insertions" — true for the
  *patched* tree, but this is exactly the loophole that caused the
  byte-perfect drift. Insertions in $0B are allowed **in patches/ only**.
- ~~ROADMAP "NPC show/hide" pointed at opcodes $48/$49 and claimed the
  mechanism was "untraced"~~ → Fixed. The mechanism is the **step
  system** (multiple step entries per screen, counter at $D92A–$D99A
  set by opcode $12). Opcodes $48/$49 are runtime movement-based
  show/hide for cutscenes. Full documentation added to
  ROOM_DATA_FORMAT.md "Room State System", ARCHITECTURE.md RAM map,
  known_RAM_map.md, and CUSTOM_CUTSCENES.md.
- ~~Decompiler opcode names had systematic errors~~ → Fixed. Handler
  code verified against ROM bytes for all critical opcodes. Key fixes:
  $29 was "give_item" (actually AddMonster), $2A was "check_level"
  (actually GiveItem — PROVEN in v23), $41 was "save_map_return"
  (actually SetBGM). Compiler had same errors — "give_item" compiled
  to $29 (AddMonster) instead of $2A (GiveItem). All three tools
  reconciled: decompile_script.py, compile_script.py,
  dump_all_scripts.py. all_scripts.json regenerated.
- ~~Opcodes $00 and $01 names may be swapped~~ → **Confirmed correct
  (no swap).** Verified from assembly: $00 handler does `jp nz, skip`
  after `TestEventFlag`, so it branches when flag is CLEAR =
  "if_flag_clear". $01 handler does `jp z, skip`, so it branches when
  flag is SET = "if_flag_set". `TestEventFlag` returns Z=clear, NZ=set
  via `and [hl]`. Definitively resolved from code; no SameBoy test needed.
- ~~Room $6C step counter addresses $D9A0-$D9A2 collided with event flags~~
  → **Fixed.** $D9A0 = byte 5 of wEventFlags (boss defeat flags $0028-
  $002F: DracoLord, Zoma, Baramos, Pizzaro, Esterk, etc.), $D9A1 = byte 6
  (story flags $0030-$0037 with up to 62 uses each), $D9A2 = byte 7
  (MedalMan, Castle flags $0038-$003F). Writing step counter values there
  would clobber critical game state. Never triggered in practice because
  CustomPtrChase ignored step counters. Fixed by moving all custom step
  counters to $D478-$D47B (verified-unused WRAM gap). Room $6B's $D95E
  (shared with MedalMan original) also moved to $D478.
- ~~Room $6B NPCs blocked exit to Room $6C~~ → **Fixed (v25).** Egg giver
  at (3,3) and BGM changer at (1,4) removed; a prior session had moved
  them into positions that blocked the walkable path to the (3,1) exit
  without updating docs. Item giver at (2,2) retained.
- ~~dump_all_scripts.py decoded linearly, missing ~45% of WriteRAM ops
  at branch targets~~ → Fixed. Work-queue follows 9 branch opcodes.
  810/866 unique WriteRAM ops found (93.5%); 56 in alternate dispatch
  paths remain. $D9E3 story progression counter documented.
- ~~14 separate room-name dictionaries across tools (30–97 entries each,
  all different)~~ → Fixed. Created `dwm/map_names.py` as single source
  of truth (97 entries from editor/editor.py). All 14 tools now import
  from it. Regenerated JSONs use canonical names.
- ~~`analyze_event_flags.py` scanned scripts linearly, missing 70% of
  set_flag operations behind branches~~ → Fixed. Tool now reads
  `all_scripts.json` (branch-following data). Result: 298 flags with
  sets (was 92); check-only anomalies dropped from 219 to 29.
  `event_flags_complete.json` and `EVENT_FLAGS.md` regenerated.
  The 29 remaining are in the 6.5% unreached script paths or engine-set
  (flag $00F1 confirmed in unreached Castle script 0 branch at $0C:$46C4).
  Story progression fully mapped: arena-driven with mandatory Anger/
  Durran gate interludes.
- ~~Bank $04 inline comment at $59D2 labeled opcode $0E as
  "SetMapTransition"~~ → Fixed. $0E is **BranchByScreen** (branches
  if `wScreenIndex == param`). The real map transition is opcode
  **$0F** at $5A02 (MapTransitionFull: writes gate_id → $C96D, flag
  → $C96E, spawn XY, sets wIsPlayerChangingMaps). ROADMAP also
  corrected ($0E → $0F).
- ~~KEY_LESSONS claimed ROM palette pointers had "bit 15 set" as encoding
  marker~~ → **Corrected (Session 9).** Zero step-0 palette pointers have
  bit 15 set (verified all 107 entries). The actual issue: ROM palette bytes
  at `pal_ptr` are in an engine-internal format for ALL rooms, not just some.
  The game engine always transforms them at runtime. Editor tileset PNGs now
  use `room_palettes.json` (runtime-dumped data) via `regenerate_tileset_pngs.py`.

---

## Part 3 — Archived ROADMAP detail (verbatim narratives from completed items)

Cut from ROADMAP.md on 2026-07-02 (S51 consolidation). Each completed item now
carries a short evidence+pointer stub in ROADMAP; the full original narrative
is preserved here, grouped by item.

### Archived PROJECT_STATE dashboard rows (verbatim, replaced by compressed rows 2026-07-02)

| Add NEW monster species (ids 224–255) | 🟡 working POC (S30): id 224 Gorbunok playable | ROADMAP "Phase N"; mechanics MONSTER_DATA "Species ID geography". N1 scope ✅, N2 info-fork ✅ (`build_new_species.py`→`bank_06a`, `SaveMon_4446` zero-shift, vanilla 0–220 byte-identical), N3 enemy-stats ✅ (16-bit EID → no fork, EID 518 @ `$14:$7EB3`) + wild encounter ✅ (pool 0 slot 3, same-size `EncounterPoolData` edit in `bank_001`), name ✅ ("Gorbunok"), library ✅ (`build_library_table.py --new-species`, unseen-marker `$E0`→`$FE`). All tool-owned/reproducible. **S32 (user-tested):** N5 breeding DONE — Snaily×BattleRex→Gorbunok (special append, `build_breeding.py` admits new-species results), parent-path free via Slime family, recipe icons via `FamilyRecipeResolve`. Hatch crash (bank `$0b` follower overshoot, pinned in SameBoy) fixed (`FollowerArtResolve0b`). Default-nickname+narration "SkyBell" overshoot fixed → "Gorb" first-4 via `LoadModeBaseRedirect` ($00F0 ROM0 padding) → new-species short-name at `$41:$7FF9`. N4 follower ART integrated via `build_new_species_follower.py` (real W.png art, gid `$7e00`, all 8 contexts) — **baked into `patches/` (G1, S34).** **S35 (user-confirmed):** G2 battle sprite DONE — `MonsterBattleGfxTable[224]` `$320f`→`$7e01` (same-size repoint, real slot, no fork), dragon battle pose = 2nd overflow entry `$7e01`, palette reader `label17_41d0` forked to `HighBattlePal` (custom blue palette). **S38 (user-confirmed):** lineage parent-name DONE — line-1 mode-0 wired (`HighModeTable4D`→`HighMode0Ptrs`→`GorbunokRecipeLine` "Snaily   BattleRex", `patches/bank_04d.asm`), so the library/encyclopedia lineage no longer shows "?????". **Open:** `new_species.json` schema fold (G3) — now the only remaining new-species item. |
| Custom rooms (mapID ≥ $6B), multi-screen, exits | ✅ working | patches/bank_060.asm + intercepts. Multi-screen scrolling proven (v28): vertical 2-screen Room $6B (screens 0+4). Room dimensions in $26DD bytes 2-5 control walkable area. **S39: Room $6B can render the gate maze tileset** (gfx-ID `$280D`) with the gate floor palette — sandy island, tree/dune/pit metatiles; `tools/build_gate_room.py` → `bank_064.asm`. (GATE_GENERATION.md §7.2–7.3.) **S40 (Pillar A, user-confirmed in-game): custom-room RENDER is now fully table-driven by `mapID-$6B`** — no hardcoded `cp $6B` render intercepts remain. Two bank-`$17` tables (`CustomRoomPalPtr` = `dw` per room, `CustomRoomAttr` = `db bank,base_entry` per room) drive palette + attr; `CustomGFXMapID` widened `cp $6C`→`cp $70` so each of `$6B-$6F` indexes its **own** `$26DD` tileset/threshold record. Proven by a **second custom room `$6C`**: same gate-island layout/tileset/attr as `$6B`, distinct **moonlit-night palette**, entirely from the tables, zero new render code. System scales to ~140 rooms (`$6B-$FF` minus reserved; `$70+` needs a `$26DD` intercept — Pillar B follow-up). See GATE_GENERATION.md §7.4 + KEY_LESSONS S40. |

| Custom breeding recipes (special table) | ✅ working (same-size edit + capacity extension) | v31/S12: special-recipe override (Anteater×BattleRex→GoldSlime) via two provably-dead entries; in-game confirmed. Tool `patch_breeding_recipe.py`, `patches/bank_016.asm`. Family table is positional (result=slot index). **S13: round-trip encoder B1 built** (`tools/build_breeding.py`, `extracted/breeding_tables.json`) — both vanilla tables decode/re-emit byte-identical. **S13: B2 relocation** (special scan → free bank `$69` via `rst $10`). **S15: B3 capacity 1×–2×** — `build_breeding.py` appends recipes from `extracted/breeding_extra_recipes.json` past index 824 (cap 1650); BattleRex×MadCat→DracoLord confirmed in-game. **S16: B4 family-defaults rewrite** — `build_breeding.py --emit-family` authors the positional family table in place from `extracted/breeding_family_defaults.json`; Bird/Slime/Beast×Dragon + new Dragon×Dragon→GreatDrak confirmed in-game (5 bytes, zero-collateral). **S17: B5 full special-table authoring** — `build_breeding.py --emit-special` owns the WHOLE special table as authored data (825 ROM base + in-place `overrides` by index/parents + `appends`) from `extracted/breeding_special.json`, with a whole-table first-match-wins shadow validator; bank `$16` stays vanilla (single source = JSON → bank `$69`). Confirmed in-game: MadCat×BattleRex→DracoLord (entry-187 in-place edit), Darkdrium×BattleRex→Armorpion (append), S12 GoldSlime preserved. Supersedes the B3 `--emit-relocation` path. **S18: B6 family reassignment** — `build_family_reassign.py` moves monsters between ANY families (incl. ???/Boss=9) via same-size family-byte edits (`patches/bank_003.asm`); reader gate cleared (display/copy only, eligibility is joinability+boss table, not family). **S18: dynamic-library POC** — `build_dynamic_library.py` redirects `SetItem_6242` ($12) to a family-byte scan so the library groups by reassigned family (`patches/bank_012.asm`); user-confirmed, POC only (lags). **S19: B7 production library grouping (DONE, replaces the POC)** — `build_library_table.py` emits a build-time precomputed family→members table into bank `$12` free space + a zero-shift `SetItem_6242` walker; **zero far-loads, zero scratch RAM**, vanilla blank-slot semantics restored; generic-N (`NUM_FAMILIES`) + 256-id-ceiling extension-aware; special entries 215–220 protected; `extracted/library_grouping.json` data deliverable; user-confirmed in SameBoy (zero lag). Production library now done; 11th family (B9) data side unblocked. Rename (B8) folded into B9 per user decision. |

| Custom battle skill EFFECTS (net-new ids) | 🟢 Skill #1 LIVE end-to-end (S49, user-confirmed in SameBoy); system generalizes next (S2e) | **S2 is an ARC, not done.** (1) **Alias framework (S45, POC):** net-new ids ($DE Scorch, $DF Smite) on starter EID 1, templatized to Blaze at the action-queue commit; real id stashed in `$db86`; custom effect via `FarSkillFork` (bank `$72`) → `CustomSkillTable52` (`$52:$7FED`); names via `SkillNamePtrTable`. Single-caster, Blaze-shaped only. (2) **Presentation foundation (S46):** the skill RECORD table (`$54:$4013`→`$41CF`, 222×19B) decoded + round-tripped byte-identical + re-sectioned to `db`; field map FAQ-validated (power/targeting/MP/status/ai_weight); item-effect+meat system (`$52:$4625`, meat→`$58:$591E`); animation dispatch (descriptor-setters `$52:$5460–$54f8` → `$dd6f`/`$dd70` → bank `$4c`/`$55`). Handler=effect TYPE (shared), record=per-skill params. **Full RE + field tables + confidence + known limitations: `BATTLE_SKILL_SYSTEM.md` (read §⚠️ + §7–§11 before extending).** (3) **Animation renderer (S2c-anim, 2026-06-28, emulator-verified):** the 3 presentation layers (sprite-anim metasprite engine, sound+flash, vertical shake) fully mapped — see §11. (4) **De-aliasing FOUNDATION (S48, byte-neutral):** complete skill-id bucketing map (`$db8a`, 254 reads/9 banks) → the surface reduces to a verified fork set; **keystone = the record-table indexer `$54:$4013` (3 sites `$5251/$5276/$529E`), forking it fixes magnitude/targeting/MP/status/ai_weight + the enemy AI**; HW-confirmed via `$52:$66D9`; the `$535F` divert is a minor path; keystone fork PROVEN byte-neutrally implementable (5-byte `call Fork` trampoline, in-bank tables). Tool `tools/map_skill_id_buckets.py` → `extracted/skill_id_bucket_map.json`; full RE **§12**. (5) **Skill #1 SHIPPED (S2d, S49):** MagicBurn (`$E0`) non-aliased & complete — record+handler+name+announce+animation+flash+SFX, all via clean indirection (announce table `$58:$5806`; custom message pool `$4c:$7326`; `GetPresentId` presentation proxy in `$5f`). The `$5f`-cleanup anim blocker is **resolved**. Full system + how-to-add-a-skill recipe: **`BATTLE_SKILL_SYSTEM.md` §13**. **OPEN:** S2e custom skill #2 (prove a non-damage/heal shape generalizes); minor follow-ups in §13.4 (custom-id skill-name insert; 2nd bespoke-message render path). |


| System | Blocker |
|--------|---------|
| Random encounters in custom rooms | ✅ PROVEN (Strategy A, Session 11). Mechanism: encounters are gated per-step by a mapID whitelist in `$0B:Jump_00b_4674` (NOT by `wInGateworld`); whitelisting a custom mapID enables them. The battle pool is `GateBasePoolIndex[wGateID]+floor` resolved at battle time, so a non-gate room must pin `wGateID`/`wCurrentFloor` (done in ASM every step) and arm `wEncounterCounter` (room-entry script, since vanilla skips seeding when `wInGateworld=0`). Win+flee return clean; saving still works (no gate mode). **Remaining (editor):** #1 per-room on/off + gate/floor table, #2 custom pools — both specced in CROSSBANK_ROOMS.md, not yet generalized. |
| Custom tile GRAPHICS | Palette attributes fixed (v28). Multi-tileset mashup pipeline working end-to-end (Session 7): editor exports JSON → `build_combined_tileset.py` → ROM patches → playable room with tiles from 4 source tilesets (80 tiles). K-means palette grouping replaced with exact-color matching (10 groups for NORDEN). Game engine forces BG palette color index 1 to shared value ($6BFF) at runtime — build tool swaps EXT palette indices 0↔1 to work around this. Castle VRAM animation at tile indices 77-78 avoided by inserting blanks. Editor has live palette slot counter (X/8) with export validation. **Session 9**: editor tileset PNGs regenerated with runtime-correct palettes via `regenerate_tileset_pngs.py` (all 86 tilesets, using `room_palettes.json`). Force-preview toggle shows colour index 1 marker tint. `--build` flag validated end-to-end (editor export → patched ROM → clean restore). **Session 10**: multi-screen ROM patches working — per-screen layout+attr in bank $64, screen-aware CustomAttrCheck in bank $17, room height in $26DD table. **Remaining**: editor multi-screen UI (screen selector, per-screen canvas, exit/NPC placement); `build_combined_tileset.py` multi-screen export. |
| Custom music | Sound engine unexplored |
| Save-data audit | ✅ Completed Session 8. SRAM save layout fully traced and documented in ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 are in save range. Flag byte collisions mapped. Flag $0158 tested in SameBoy: set via NPC script, persisted through save+reload. |



### Archived ROADMAP narratives — Phases 1 / 2B / 2C (cut 2026-07-02)

### Phase1: NPC show/hide

- [x] **NPC show/hide by flag** — mechanism IS the step system
      (ROOM_DATA_FORMAT.md "Room State System"): multiple step entries
      per screen with different NPC lists, step counter set by opcode
      $12 (WriteRAM $D9xx). **Implemented and confirmed in-game (v25)**:
      CustomPtrChase now reads RAM step counter and indexes by ×6
      (was always returning step 0). Room $6C screen 0 has 2 step
      entries — Gatekeeper NPC at step 0 (advances counter via opcode
      $12) replaced by Guard NPC at step 1. Verified: NPC changes on
      re-entry after WriteRAM sets counter. Step counter addresses
      moved from event-flag collision zone ($D9A0-$D9A2 = flags
      $0028-$003F) to safe range $D478-$D47B. Note: $D478+ not in
      SRAM save range — step progress resets on power cycle; for
      persistence, use event flags + room-entry flag checks.
      *Accept*: NPC appears only after custom flag/step is set; verified
      after room re-entry. ✅


### Phase1: monster/egg give

- [x] **Monster/egg give** — opcode $29 (AddMonster) **confirmed working**.
      Takes 1 param (enemy_stats_id). Opcode $28 (CheckStorageFull)
      branches when all 20 slots full. Egg give proven with SkyDragon
      (EID 350, same as Farm event) — egg appears at farm, hatches
      correctly (minor cosmetic glitch on hatch). Direct monster give
      (EID 1) creates a withdrawable monster but species/stats don't
      fully initialize without `$FF04 $000F` preamble. Egg path is
      the practical choice for custom content.
      AddMonsterWrapper needed in bank $04 padding (bare `ret` →
      wrapper + `jp ScriptExecContinue`, same fix as GiveItem $2A).


### Phase1: tile layouts

- [x] **Custom tile LAYOUTS** (compressor done): place compressed layouts
      in a free bank, point step_entry byte 1 at it.
      **Done.** `tools/tile_layout_compiler.py` compiles 20×16 visible
      tile grid → 32×16 padded → LZSS compressed → ASM db statements.
      Bank $64 holds custom layout data with pointer table at $4001.
      Room $6B step entry uses `db 0,$64`. Tileset switching via
      MapIDClampForPalette in ROM0 (currently $04=Farm). User-designed
      layout confirmed in-game. Standalone HTML editor with 170 rooms
      and 85 tilesets delivered (towards_editor/). Spawn position for
      Room $6B is in Exit_GreatTree_s8 (bank_00b.asm), currently (7,6).
      *Accept*: custom room renders a layout that exists nowhere in the
      original ROM. ✅ Confirmed in-game.
      **Known issue (FIXED v28)**: palette attributes were per-position,
      causing color mismatches. Fixed by CustomAttrCheck intercept in
      bank $17 free space ($6C75): for Room $6B, bypasses vanilla attr
      lookup and decompresses custom nibble-packed attr data from bank
      $64 entry 1. Attr data generated by `tools/generate_attr_map.py`
      which builds tile→palette maps from ROM for any of the 85 tilesets.
      Collision threshold table at ROM0 $26E3 uses ×8 stride (not ×1).
      Multi-tileset HTML editor delivered (towards_editor/) with
      walkability overlay, variable-size stamps, marker management,
      tileset names, and full source-mapping export.


### Phase1: tile graphics

- [x] **Custom tile GRAPHICS**: palette attribute intercept DONE (v28).
      Single-tileset rooms fully working (tileset switch + correct palettes).
      **Multi-tileset mashup: WORKING (Session 7, refined Session 8).** Full pipeline:
      editor → JSON export → `build_combined_tileset.py` → ASM patches → ROM.
      **Session 8 critical discoveries and fixes:**
      - **4 palette groups max** (not 8). BG slots 4-7 reserved by game engine
        for monster display (4/5/6) and menu text (7). Verified: all 85 DWM1
        tilesets use max group 3. CustomPalCheck changed B=$08→$04.
      - **Gate detection in banks $06/$07**: mapID≥$50 whitelists treated custom
        rooms as gate-like (blocked saving, wrong menu state). Fixed with
        same-size `ld a,[wMapID]`→`call MapIDClampForPalette` patches.
      - **Ghost NPC**: spawn point script_id=$01 was talkable. Fixed to $00.
      - **Build automation**: `--build OUTPUT.gbc` flag added to
        `build_combined_tileset.py` (patches palette+threshold, builds ROM,
        restores tree). **Validated Session 9** — end-to-end pass with
        3-tileset test export (MedalMan+NORDEN+Farm).
      - **Editor**: PalGrp toggle shows palette group per tile (P0-P3 custom,
        S4-S9 system). Counter shows X/4. Export warns if >4.
      *Accept*: custom room shows tiles cherry-picked from 2+ source tilesets. ✅
      **Session 9 fixes:**
      - Editor tileset PNGs regenerated with runtime-correct palettes from
        `room_palettes.json` via new `regenerate_tileset_pngs.py` tool (86
        tilesets, all verified). ROM step-entry palette data is encoded (not
        raw RGB15) — was causing wrong colours for Starry Shrine and others.
      - Force-preview toggle ("Frc" button) added: swaps between runtime view
        ($6BFF at colour index 1) and marker-tint view (light cyan at index 1).
      - KEY_LESSONS corrected: "bit 15 set" palette claim was wrong — actual
        issue is that ROM palette bytes are always transformed at runtime.


### Phase1: random encounters

- [x] **Random encounters in custom rooms** — ✅ PROVEN (Strategy A,
      Session 11; runtime-verified in SameBoy). The blocker assumption was
      wrong: encounters are NOT gated by `wInGateworld`. They are gated
      per-step by a hardcoded mapID whitelist in `$0B:Jump_00b_4674`
      (`$53`,`$54-$56`,`$57-$59`,`$61-$64`); non-whitelisted normal rooms
      `ret` before the encounter step. **Recipe:** (1) add the custom mapID
      to that whitelist → enables battles; (2) the pool is
      `GateBasePoolIndex[wGateID]+floor` resolved at battle time, so a
      non-gate room must pin `wGateID`/`wCurrentFloor` (done every step in
      ASM — they're read only when a battle fires) and (3) arm
      `wEncounterCounter` from the room-entry script (vanilla skips seeding
      when `wInGateworld=0`). Trigger chain: counter underflow → `rst $10`
      bank $01 entry $0b (`EncounterMonsterSelect`) → `set 6,[wGameState]`.
      *Verified*: Room $6B, gate 0/floor 1 → pool 0 (Slime/Anteater/Dracky);
      `$C935=00 $C939=01 $CA38=00`; win+flee return intact, saving works.
      Full docs: DATA_STRUCTURES "Encounter Runtime Flow", CROSSBANK_ROOMS
      "Random Encounters in Custom Rooms", KEY_LESSONS Session 11.
      **Remaining → moved to Phase 2 (editor):** #1 per-room on/off + gate/floor
      table; #2 fully custom monster pools in a free bank. Both specced in
      CROSSBANK_ROOMS.md.


### Phase2C: gate rotation

- [x] **Custom room into the gate rotation** — TWO halves (BOTH done; Pillar A render S40, Pillar B insertion S41):
   - [x] **Rendering half (S39 + S40 generalisation).** Room `$6B` renders the
         Gate-of-Beginning maze tileset (gfx-ID `$280D`, bank `$28` step `$0D`) with
         the real gate floor palette — sandy island with ocean-wall border, 2×2
         tree/dune/pit metatiles, per-position attr palette. Authored in
         `tools/build_gate_room.py` → `patches/bank_064.asm` (+ `bank_000.asm`
         gfx-ID/threshold, `bank_017.asm` `CustomPaletteColors_6B`, slots 0–3 only).
         **S40 (Pillar A, user-confirmed):** render is now fully **table-driven by
         `mapID-$6B`** — `CustomRoomPalPtr`/`CustomRoomAttr` tables (bank `$17`) +
         per-room `$26DD` records via `CustomGFXMapID` widened to `cp $70`; no
         hardcoded `cp $6B` render code remains. Proven by a 2nd room `$6C` (same
         island, distinct moonlit palette, zero new code). `$6B` byte-identical
         regression verified; verifier PASS. (GATE_GENERATION.md §7.1–7.4.)
         **S42 generalisation:** the old `$6B-$6F` `$26DD`-record ceiling is lifted —
         `$70+` rooms read their record from `Custom26DDTable` (bank `$71`, far-copied
         to `wRoomRecScratch`). See EDITOR_DESIGN.md §2 (keystone, as-built) + Phase 2.
   - [x] **Insertion half (= "Pillar B", S41, user-confirmed in SameBoy).** Custom room
         `$6D` inserted into **gate 1 (Gate of Villager)**, descending floor-to-floor with the
         correct in-gate transition feel. Mechanism chosen was **not** the `rst $00` slot below
         but a cleaner **byte-neutral fork at the gate-branch decision**: the 6-byte gate-0
         exclusion at `$16:$5BA9` (`ld a,[wGateID]/or a/jr z,jr_016_5bbf` — it reads
         **`wGateID $C935`**, the earlier `wCurrentFloor` cite was wrong) is replaced in place
         by `call GateDecisionFork`+3 nops; the fork routes gate 0 → vanilla maze, gate 1 →
         `CustomGate1Setup` (`wMapID=$6D`), all others → untouched RNG gating. Descent uses a
         `gate_flag=$80` exit (mirror of special rooms `$50/$51`). The descent **transition feel**
         (whoosh + continuous BGM, not the hub→gate dissolve + BGM restart) is fixed by a transient
         `wInGateworld=$01` set **only during the transition** (`CustomDescentInGate` @ `$0B`
         `jr_00b_466b`); display-time `wInGateworld` must stay `0` or the room engine's gate/maze
         branches freeze the game. Test ROM `DWM-gate-rotation-v3.gbc`. (GATE_GENERATION.md §7.5.)
         *Alternative/general mechanism still valid for many-room rotations:* point a `rst $00`
         dispatch slot (`$16:$5C32` table, ROM-verified idx0=`$5C42`) at a custom-id handler and
         open its `FloorTypeSelectionTable2` weight. POC forces `$6D` every non-boss floor;
         occasional placement = gate the fork branch behind the RNG roll / a weight table.


### Phase2C: palette derivation

- [x] **Room-palette derivation from ROM (S39).** `tools/derive_room_palette.py`
      reproduces any room's runtime BG palette: colours 0/2 from the room/gate
      palette pointer (`$17:$476F` normal / `$17:$51F5` gate), engine-forced
      idx1=`$6bff`/idx3=`$0000`, screen-scan, clean refusal when unresolvable.
      Validated 30/30 SameBoy dumps + the gate floor. (GATE_GENERATION.md §7.1.)


### B1

- [x] **B1 — Round-trip encoder (keystone).** `tools/build_breeding.py` decodes
      + re-emits BOTH vanilla tables. *Accept:* `$4974`+`$4B30` byte-identical to
      ROM; clean build still `1ca6579…`; verifier PASS. (Decoder half done S12.)
      **DONE (Session 13):** `tools/build_breeding.py --selftest` proves both
      tables round-trip byte-identical to the ROM slices (special $4B30 4126 B
      incl $FF; family $4974 444 B incl $0000), the `db`-text emission re-parses
      to the same bytes, and the disassembly `db` bytes equal the ROM
      (`--check-disasm`). Decode independently reconciles with the hand-authored
      `breeding_complete.json` (825/825 special, 197/197 family slots, 0 diffs).
      Data deliverable: `extracted/breeding_tables.json` (Tier A, `_generator`
      stamped). Verifier PASS 4/4; clean build unchanged. Family encoding
      confirmed positional (result species == slot index; 197 recipes + 24
      separators + 1 terminator = 222 pairs).


### B2

- [x] **B2 — Relocation harness.** Bank `$69` scanner + special table mirrored
      there; bank $16 redirected via `rst $10`; vanilla tables left in place.
      *Accept:* breeding identical to vanilla (regression) in SameBoy; saving OK.
      **DONE (Session 13):** special-table scan ($46F2–$470F, 30 B) replaced
      in-place with `ld hl,$6900` + `rst $10` + 26-byte NOP pad (zero shift);
      faithful port of the scan loop + per-entry check in `patches/bank_069.asm`
      (`db $69`, jump table, scanner, then the table). `rst $10` ABI decoded
      from ROM bytes (H=bank, L=entry<$80; far func ends `ret` → returns to the
      bank-$16 plus-clamp at $4710). Relocated table sourced from the **patched**
      `bank_016.asm` (via `build_breeding.py --emit-relocation`), so it carries
      existing custom recipes. Verifier PASS 4/4; full-ROM diff shows bank $16
      changed only in the 30-byte window. User-confirmed in SameBoy: Anteater×
      BattleRex→GoldSlime (both orders) + vanilla crosses unchanged; saving OK.
      *Note:* rev 1 wrongly sourced the table from vanilla and silently reverted
      the Session-12 recipe (parents fell through to the family table); fixed by
      sourcing from patched bank_016. The `--emit-relocation` self-check now
      asserts relocated == patched table.


### B3

- [x] **B3 — Capacity 1×–2×.** Raise special capacity to ≥1650; add recipes past
      index 824. *Accept:* a recipe at index >824 fires in-game.
      **DONE (Session 15):** the bank `$69` scanner walks to the `$FF` terminator
      with no hardcoded count, so `build_breeding.py` appends recipes from
      `extracted/breeding_extra_recipes.json` after the 825 base entries and
      re-terminates (`SPECIAL_CAPACITY_MAX = 1650`; bank `$69` fits 2× with
      headroom). Proof recipe at index 825: **BattleRex(Pedigree) × MadCat(Mate)
      → DracoLord** — user-confirmed DracoLord in SameBoy (patched ROM
      `f1cd94b1…`; clean build still `1ca6579…`). Picked because it is UNSHADOWED
      by all 825 base entries (the forward order MadCat×BattleRex is the vanilla
      → Yeti recipe at index 187, which would win first — see KEY_LESSONS S15).
      Self-checks: base 825 == patched bank_016 table; S12 recipe intact; appended
      bytes placed + `$FF`-terminated; emit-time SHADOW CHECK fails the build on a
      dead appended recipe. Focused diff: 4 bank-`$69` bytes + checksum.
      *Open follow-up:* fold "base 825 of relocated table == patched bank_016
      table" into `verify_integrity.py` so future table edits can't silently
      diverge (the tool asserts it; the verifier does not yet).


### B4

- [x] **B4 — Family-defaults rewrite.** New family×family map compiled in-place
      (family table `$16:$4974`, same length = zero shift; result = slot index, so
      the compiler inverts `A×B→C` to slot order and rejects positional conflicts;
      preserve the `$FA` wildcard + two-pass search). *Accept:* 8–10 sample crosses
      give NEW results in SameBoy; untouched crosses unchanged. *Note:* family
      table is strictly 1:1 (one cross per result species, no many→one) — put
      flexible/many→one family×family in the SPECIAL table instead (works now).
      **DONE (Session 16, user-confirmed in SameBoy).** `build_breeding.py --emit-family`
      reads `extracted/breeding_family_defaults.json` (positional `result→{p1,p2}`
      overrides), applies them to the vanilla family decode, validates positional 1:1 +
      444-byte zero-shift + shadow classes, and rewrites only the `FamilyRecipeTable` db
      block in `patches/bank_016.asm`. Authored proof set (zero-collateral permutation of
      the three Dragon-mate matchers + one NEW recipe at empty separator slot 37):
      Bird×Dragon→DrakSlime, Slime×Dragon→Almiraj, Beast×Dragon→Wyvern,
      Dragon×Dragon→GreatDrak. **5 changed bytes total** in bank `$16` (focused diff vs the
      B3 ROM = those 5 + 1 checksum byte; the B3 baseline rebuilt as the recorded `f1cd94b1…`).
      User-confirmed: FunkyBird×BattleRex→DrakSlime, Snaily×BattleRex→Almiraj,
      Dragon×Dragon→GreatDrak (patched ROM `caa597d1…`; clean build still `1ca6579…`).
      Beast×Dragon→Wyvern is present but correctly shadowed for MadCat by SPECIAL entry 187
      (MadCat×BattleRex→Yeti) — precedence, not a bug. Untouched BattleRex×Healer→DragonKid
      (vanilla family slot 20) unchanged. Method + precedence: KEY_LESSONS "Session 16".


### B5

- [x] **B5 — Full special-table authoring + overhaul spec.** Extend
      `build_breeding.py` to own the WHOLE special table as authored data (base +
      overrides + appends) and emit it to bank `$69`, leaving bank `$16` fully
      dead; supports edit-in-place of any base entry (e.g. **replace Yeti** =
      change entry 187 result byte) and append. Includes a precedence/shadow
      validator (first-match-wins across the whole table). Author the complete
      `special` + `family_defaults` (incl. Spirit-as-a-breedable-family), build a
      test ROM. *Accept:* user playtest sign-off on the rewritten recipe set.
      **DONE (Session 17, user-confirmed in SameBoy).** `build_breeding.py
      --emit-special` decodes the 825 vanilla entries from the ROM as the base,
      applies `overrides` (edit any entry, by `index` or by parent `match`) and
      `appends` from `extracted/breeding_special.json`, runs a whole-table
      first-match-wins shadow validator (ERRORS on a shadowed append/override;
      WARNS on new collateral shadowing and on a result-species change that other
      entries still produce), and emits only `patches/bank_069.asm`. Bank `$16`'s
      special table stays byte-identical to the ROM (single source = JSON → bank
      `$69`). Self-checks: emitted == authored bytes + `$FF`; untouched base ==
      vanilla; overrides present at their indices; capacity ≤ 1650. Proof
      (confirmed): MadCat×BattleRex → **DracoLord** (in-place edit of entry 187,
      was Yeti), Darkdrium×BattleRex → **Armorpion** (unshadowed append),
      Anteater×BattleRex → GoldSlime both orders (S12 carried forward as overrides
      at dead entries 693/803). Patched ROM `c95f62ce…`; clean build still
      `1ca6579…`. **Supersedes B3's `--emit-relocation` + `breeding_extra_recipes.json`
      as the canonical bank `$69` emitter.** *Note:* the spec carries `base`,
      `overrides`, `appends`; this is the editor's emit backend — the actual recipe
      REWRITE (Spirit-as-breedable, new results across the board) is authored by hand
      in the editor UI later (B5 delivers the machinery, not the content).
      *Folded into `verify_integrity.py`? No — see B3 open follow-up; the tool
      self-asserts, the verifier does not yet run `--emit-special` self-checks.*


### B6

- [~] **B6 — Family reassignment + ??? → "Spirit".** Same-size family-byte edits
      (offset $00 of each 43-byte monster-info entry `$03:$4461`).
      **REASSIGNMENT DONE + reader-gate CLEARED (Session 18, user-confirmed in
      SameBoy).** `tools/build_family_reassign.py` (spec
      `extracted/breeding_family_reassign.json`, validated `from`==vanilla) emits
      `patches/bank_003.asm` as exact-line db edits (zero shift). Monsters move
      between ANY families incl. in/out of ??? (Boss=9). **Reader trace (the gate)
      cleared:** family-byte readers outside breeding are DISPLAY/struct-copy only
      (bank `$01` battle copy, `$04` FamilyTextPtrTable text dispatch, `$07`
      sprite/icon, `$09` VRAM index, `$14` recruit stamp); none gate scout/recruit/
      AI/resistance on family==9 — eligibility is the enemy-stats joinability byte
      (`$14 +$3`) + boss table (`$14:$4897`), independent. Annotated inline at bank
      `$03` `label443f`. **Three family representations found** (BREEDING_SYSTEM
      "B6"): breeding=live byte; status/menus=struct +$0A stamped at creation
      (snapshot — pre-existing monsters keep old value, correct for a fresh hack);
      library=id-range (see below). **Dynamic library PROOF OF CONCEPT done**
      (`patches/bank_012.asm`, `tools/build_dynamic_library.py`): `SetItem_6242`
      redirected to a family-byte scan; all 8 reassigned monsters group correctly
      in SameBoy. POC only (lags ~221 far-loads/render; bearable). *Still TODO,
      split out below:* the ??? → "Spirit" RENAME (the doc's old `FamilyTextPtrTable`
      entry-9 claim was WRONG — that's a per-family monster-text dispatch, not the
      family-name string; find the real string first); the production library table;
      the 11th-family feature.


### B7

- [x] **B7 — Production library grouping table (replaces the B6 POC).**
      **DONE (Session 19, user-confirmed in SameBoy — zero lag, reassigned monsters
      under correct tabs).** `tools/build_library_table.py` emits a precomputed
      **family→members** table into bank `$12` trailing free space (`$7B9B+`) at build
      time and rewrites `SetItem_6242` zero-shift (`jp LibScanByFamily`, 82-byte body →
      `jp` + 79 `nop`). The walker reads the table directly — **zero far-loads, zero
      scratch RAM** (the POC's two costs eliminated), and restores vanilla blank-slot
      semantics ($E0 for unseen / id for seen) the POC had dropped. Table format is a
      pointer table + length-prefixed member lists (additive for an 11th family);
      family assignment sourced from the vanilla family byte + `breeding_family_reassign.json`
      (the SAME spec `bank_003`/B6 consumes, kept in lock-step). Build-time validation:
      `--selftest` proves no-reassign grouping reproduces the vanilla bounds table
      exactly (parity); every family ≤ buffer capacity (32); free-space fit; ids ≤ 255.
      Data deliverable `extracted/library_grouping.json`. **Extension-aware (no hardcoded
      221):** species ids are 1 byte (256-ceiling); `COLLECTIBLE_MAX` (→255) and
      `NUM_FAMILIES` (→11, B9) are the only knobs — table + walker are already count/id
      agnostic. The 6 special non-collectible entries (215–220: TERRY? story enemy +
      4 summon tiers + 1 blank) are enumerated and PROTECTED (excluded, never a
      reassignment target). Test ROM `065943f6…`; clean build still `1ca6579…`. Method:
      KEY_LESSONS "Session 19 — Breeding B7"; format: BREEDING_SYSTEM "Dynamic library
      → PRODUCTION (B7, done)". *Open follow-up:* tool not yet folded into
      `verify_integrity.py` (self-asserts via `--selftest`; the verifier does not run it).


### B8

- [~] **B8 — ??? → "Spirit" rename (10 families, no insert).** **PREREQ SOLVED
      (S20):** the "family name" is an ICON font tile, not a string — there is no name
      string to edit (`FamilyTextPtrTable` confirmed a red herring). 10 icons at
      `$4F:$4110-$41A0`, text bytes `$10-$19`, addr = `$4010 + byte*16`; detail line is
      `<$F0><icon>"family"` (bank `$4D`), tab strip blits the same tiles. So a
      rename-only is "swap the `$19` (???) icon tile." **NOT the chosen route** — per
      the S19/S20 user decision Spirit is ADDED (B9), not a 10-family replace; this row
      stays as the solved-trace record. *Accept (if ever taken):* the ??? tab shows the
      new icon; clean build still `1ca6579…`.


### B9

- [~] **B9 — Add an 11th family (keep ??? AND add Spirit).** **VRAM CORRUPTION FIXED +
      ICON SHIPPED (2026-06-19, user-confirmed in SameBoy; built ON TOP of the gate fix).**
      The family-10 catch→map VRAM wipe is fixed (`ClampFamIdx` in ROM0 clamps the
      10-entry family-indexed GFX table `01:$4BAD` so family 10 can't read OOB; the
      species-indexed `$499D`/`$49DF` follower lookup is left alone). The Spirit whip
      (option 5) ships on font byte **$19 (`$4F:$41A0`)**, overwriting vanilla ??? — NOT
      the free $1A slot, which the menu blanks at runtime. Followers, library grouping,
      and family attribution confirmed correct; clean build `1ca6579…`; integrity PASS.
      See KEY_LESSONS "Spirit B9 Lessons" + PROJECT_STATE (2026-06-19 block). *Remaining
      polish (not blocking play):* the "$1A vs $19" line in the S20 notes below is stale;
      tab-strip/nav-grid layout for an 11th visible tab is the only open UI nicety.
      ~~**ICON HALF DONE (S20,~~
      pending SameBoy sign-off).** The family-icon path is traced (see B8) and the 11th
      icon's free slot is found: **byte `$1A` → `$4F:$41B0`** (blank filler; charmap
      "20-23 are blank"). `patches/bank_04f.asm` inserts the user's "Fire Whip Spirit"
      art there as a same-size 16-byte 2bpp tile (zero shift; bank `$4F` otherwise
      byte-identical to vanilla). Tool `tools/build_family_icon.py` + data
      `extracted/family_icons.json` (Variants A/B: head on palette index 0 for a yellow
      head if the menu palette allows, else index 2). Verifier PASS 4/4 (bank_04f added
      to patch set). Test ROM `ab59c842…`; clean build still `1ca6579…`. **STILL OPEN
      (rest of B9, next session):** (1) confirm the "yellow head" palette in SameBoy
      (menu BG pal via `LoadGBCPalettes`→`rst $10` `$17:$03`); (2) wire Spirit as
      family 11 — the `$4D` detail line (`$F0 $1A "family"`), the tab-strip 11th cell
      (`LoadItem_4241` `b=5,c=10` grid + tab graphics), the family-code (`$FA` wildcard
      question), `NUM_FAMILIES`→11 in `build_library_table.py`, family reshuffle. Icon
      is not yet referenced by any family, so view it via SameBoy's VRAM viewer until
      wired. Scope (full): BREEDING_SYSTEM "Family icons (B8/B9)" + "Future — 11th family".
      *Decision (user, S19/S20):* Spirit is ADDED as the 11th family, then families
      reshuffled.


### BUG breeding cutscene

- [x] **BUG — breeding cutscene: parent sprites glitch.** **FIXED Session 14.**
      Observed Session 13 while playtesting B2; confirmed **not caused by B2**. Root
      cause was an incomplete bank `$0B` labelization: three raw pointer refs into the
      bank's shift region (`$4974` sprite-pointer table; `$42c8`/`$4308` gate table)
      were never converted to labels, so the custom dispatch's shift left them stale —
      and in `patches/bank_00b.asm` the sprite ref was additionally **mislabeled** to
      `RoomScreenPtrTable` (`$49b5`) instead of the real `$4974` data (`$4911`).
      Fixed by re-sectioning both tables into labeled `dw`/`db` (disassembly stays
      byte-identical to `1ca657…`) and repointing the sprite consumer. User-confirmed
      in SameBoy (clean build still `1ca657…`; patched ROM `b43a04fe…`). See
      KEY_LESSONS "Session 12 Lessons — Bank $0B repointing" and PROJECT_STATE.



### Archived ROADMAP narratives — Phases D / F / N (cut 2026-07-02)

### PhaseD: seams

- [x] **Annotate the new-species fork SEAMS in clean disassembly (labels/comments
      only, byte-perfect `1ca6579…`).** The "which site is the seam" knowledge currently
      lives only in patches + MONSTER_DATA. Propagate it as comments at the clean anchors:
      `bank_003 label443f`/`SaveMon_4446` (single info indexer; id≥224 fork point),
      `bank_014 LoadEnemyStats` + the `$7EAD` trailing free run (16-bit EID → append, no
      fork), `bank_001 EncounterPool_000` (slot = EID(+10,×2)/weight(+20); empty slot =
      insertion point), and the **8 follower gfx-ID copies** (`$01 $06 $07 $09 $0b $12 $18
      $59` — the mgbdis defaults `FieldPtrLookupTable`/`TextDataPtrLookup`/`TileRefLookupTable`
      etc. don't reveal they're copies; rename/annotate so a swap knows to repoint all 8).
      CAUTION: a mislabel that resolves to the wrong address passes review but glitches at
      runtime (SESSION_PROTOCOL §4) — verify the build stays `1ca6579…` after each label.
      *(Flagged S30, deferred from the two-defect-fix session — own scoped pass. PARTIAL: the
      follower render seams `bank_011 HramUnk11_406e` (attr read + overshoot) and `bank_001
      GetActiveMonsterStatus` (overworld walk loader + clamp) annotated when N4 was finished —
      build still `1ca6579…`.*
      ***S33 — the name/text/lineage/follower DISPLAY seams DONE*** (labels/comments only,
      build `1ca6579…`, integrity 4/4, all referenced labels sym-verified to their addresses):
      bank `$41` `$4007` mode→table config list (modes 5/7/8/11 documented) + the corrective
      `FamilyCodePtrTable` block (species-indexed 2-letter default-nick, NOT family; legacy
      labels) + `Func_Bank41_GetText/GetPutText`; ROM0 `SaveBankAndSwitch $092F`/`TextHandler_0940
      $0940` two-level `[mode][id]` lookup + overshoot hazard + `LoadModeBaseRedirect $00F0` fork
      cross-ref; bank `$12` `LoadItem_6456`/`LoadItem_65a8`/`CmpItem_65cb` lineage chain; and the
      **8 follower gfx-ID copies** at their add-base sites (`$01:$49a7`→`ScreenTransDataTable`,
      `$06:$4d7e`→`MapNPCPosDataTable`, `$07:$66b8`→`TileRefLookupTable`, `$09:$61fb`→
      `FieldPtrLookupTable`, `$0b:$490f`→`SpritePtrTable_4974`, `$12:$65de`→`ItemSlotPtrTable`
      [= the lineage parent-icon table, doubles as the menu copy], `$18:$40bf`→`TextDataPtrLookup`,
      `$59:$42ca`→`SaveSlotPtrTable`); + one optional cross-ref at bank `$16` `$0301` parent-family
      load. CORRECTIONS recorded in source + MONSTER_DATA: **ItemNamePtrTable = mode 8** (not 11);
      **`$4739` overshoots at id≥215, fork covers id≥224**.
      ***S38 — the DATA-TABLE seams DONE*** (labels/comments only, build `1ca6579…`, integrity
      4/4; new label `EnemyStatsTrailingFree` sym-verified to `14:7ead`, cross-ref patch labels
      `FamilyRecipeResolve`/`NewSpeciesInfoCopy` confirmed to exist): `bank_003 label443f`/
      `SaveMon_4446` (single info indexer; patched `cp $e0` → bank `$6A` fork; also reached as
      `$03` entry 1 by breeding's `$0301` parent-family load); `bank_014 LoadEnemyStats` (16-bit
      EID → NO fork) + new label `EnemyStatsTrailingFree` @ `$7EAD` (append region — records that
      the 487-entry table ends at `$7BAC` but `$7BAC..$7EAC` is CODE, so EIDs 487–517 are unusable
      and the first grid-aligned slot is EID 518 `$7EB3`); `bank_001 EncounterPool_000` (empty
      slot = EID 0/wt 0 = in-place insertion point, Iron-Rule-2 safe); `bank_016 label16_485c`
      (entry-1 recipe lookup overshoots the 222-entry `FamilyRecipeTable` → `FamilyRecipeResolve`
      DISPLAY fork) + the two `$0301` parent→family conversion sites (new species resolves a real
      family as a breeding PARENT via the forked info loader). **STILL PENDING (own pass, NOT a
      new-species seam — general breeding mechanics): bank `$16` breeding-determination internals
      proper (`LoadBrd_4653` plus/special, `LoadBrd_45d5/45ff` family scan, special→family→pedigree
      precedence) — deferred to a breeding-mechanics annotation pass.**


### PhaseD: resection

- [~] **Re-section misassembled data tables → labeled `db`/`dw`.** mgbdis decoded
      many in-bank DATA tables as fake instructions (`rst $38`, `db $fc`,
      `ld hl,sp+$nn`, stray `stop`, etc. appearing mid-routine). These pass the build
      (bytes are identical) but READ as garbage code, so a future session can't edit
      the table in source and wastes time re-deriving it from raw bytes — it bit S18
      (the library bounds table) and earlier ($0B sprite/gate tables, fixed S14).
      Convert each to a labeled `db`/`dw` block; **the build MUST stay `1ca6579…`**
      after each (a wrong split changes bytes → fails instantly — same guard as the
      S14 labelization rule, KEY_LESSONS). Drive this by what the editor must EDIT,
      not completionism. *Accept:* targeted tables read as `db`/`dw` with names; MD5
      unchanged; the editor can address them by label.
      **DONE (Session 26 + Session 27): bank `$12` library/family data — COMPLETE.**
      `tools/resection_library_tables.py` converted `LibraryFamilyTabBounds` (`$6294`,
      the S18 case), the two tab-column cursor-position tables (`$564a`/`$5a8e`), and
      the **entire contiguous window-draw layout run `$710c..$7b9b` (29 layouts)**.
      Session 26 did the directly-referenced subset (`$710c/$71aa/$71f4`/`$759a`/`$7b42`/`$7b6c`);
      **Session 27 finished the two remaining contiguous gaps** (`$724e..$759a` = 10
      layouts, `$75c0..$7b42` = 13 layouts), including the 380-B `$79c6` full-screen
      view whose fake `jr` labels (`$7a05`…`$7aca`) vanished cleanly with their
      in-range `jr` sources. 44 raw-pointer reference sites labelized in total; the 21
      `ld hl,$XXXX; rst $10` far-call descriptors (`$5605`/`$6100`/`$6101`) correctly
      LEFT raw. Clean build still `1ca6579…`, integrity PASS 4/4. All 29 layouts also
      decoded to `extracted/library_layouts.json` (`--dump-json`). Format + addresses
      in DATA_STRUCTURES "Library / family-tab menu data (bank `$12`)". The tool uses a
      zero-byte probe-build to map source line → address (no opcode-size summing — the
      S22 trap), is per-table idempotent, and is re-runnable from the clean tree
      (verified: clean-tree run reproduces the byte-perfect build + identical 29-label set).
      **NEXT (per-session, one each):**
      (1) ✅ **Finish bank `$12`** — DONE (Session 27, above). The whole `$710c..$7b9b`
          run now reads as labeled `db`/`dw`; `$79c6` converted; far-call descriptors left.
      (2) **Tick the STALE BOXES below** — bank `$03`/`$14`/`$16` look already
          `db`-converted (`$14`/`$16` clean; `$03` has 23 `rst $38` runs to confirm as
          padding vs data). Cheap verify-and-check-off.
      (3) **Editor-driven only:** bank `$01` encounter pools → `db` (Encounters #2 needs
          to edit pools), bank `$51` transitions, bank `$50` event state machine — do
          these when the feature is built, not for completionism.
      (4) **Checked, SKIP (no editor value, mis-split risk):** the `$ff`-padding banks
          `$08/$15/$2c/$33/$55/$66` from the old seed list — verified mostly filler
          (`$08`: 2061, `$55`: 2112 `rst $38`). Not discrete tables.


### GFX-1

- [x] **GFX-1 — Graphics system: gfx-ID indirection + sprite decompressor → annotate + tool.** ✅ DONE (Session 22)
  *DONE Session 22 — see PROJECT_STATE "Session 22" + KEY_LESSONS "Session 22" +
  MONSTER_DATA "Monster sprite graphics system". Delivered: (a) battle gfx-ID table
  `$00:$2B9F` re-sectioned to `MonsterBattleGfxTable` (`tools/resection_battle_gfx_table.py`,
  build still `1ca6579…`, 23 cross-refs preserved); (b) `dwm/sprite_codec.py` — shared
  LZ codec, decode byte-exact, `decode(encode(x))==x` on all 442 streams; (c)
  `tools/extract_monster_sprites.py` + `extracted/monster_sprites.json` (all 221,
  count-parameterised); (d) `tools/build_sprite_swap.py` generalised species-agnostic.
  ACCEPT criterion adjusted: round-trip is SEMANTIC (`decode(encode)==x`), NOT vanilla
  byte-identical re-encode (no editor value — documented). Dracky→Anteater swap
  user-confirmed in SameBoy. Doc errors below FIXED in the re-section comments.
  REMAINING (moved to editor-backend / GFX-3): cross-bank free-space allocator (swap
  tool knows bank `$36` only); follower-sprite extraction + animation-frame layout.*
  *Original verified facts (kept for reference):*
  - **gfx-ID = `(bank<<8)|index`.** High byte = ROM bank, low byte = index.
  - **Resolver `DecompressTileLayout` @ `$00:$1627`:** switches to `bank` (`ld[$2100],a`
    low bits; `swap a/rra/and 3 → ld[$4100],a` high bits — also twiddles SRAM bank,
    restored after, harmless). Reads per-bank pointer table at **`$<bank>:$4001 + index*2`**
    → stream addr in `$4000–$7FFF`.
  - **Stream header (3 bytes):** `[declen_lo, declen_hi, runmark]`, then LZ body.
    Decompressor path `WaitDMATransfer $00:$1577` → `TextScrollWindow` → writes to VRAM dest HL.
  - **LZ body:** byte≠runmark → literal; byte==runmark → back-ref: next 2 bytes `b0,b1`,
    offset = `b0 | ((b1>>4)&0xF)<<8` (**ABSOLUTE** index into output base `$ac/$ad` = VRAM dest),
    count = `(b1&0xF)+4`, extension if low-nibble=`$F` (count = next_byte + `$13`).
  - **KEY ARCHITECTURE:** back-refs point into a **SHARED VRAM tile pool pre-loaded before
    the per-monster stream**, so one monster stream does NOT decode standalone (Dracky's
    battle stream is ~9 on-disk bytes → 576 decompressed). **POC lever:** a stream with NO
    runmark byte in its body = pure literal copy = self-contained (ignores the shared pool).
    `tools/build_sprite_swap.py` (added this session) uses exactly this to repoint Dracky.
    *(Gotcha: fill the WHOLE tile field with the backdrop index, not just the sprite
    footprint — else the surround renders as palette index 0. For Dracky's battle palette
    that index 0 is red; backdrop is index 1. Fixed in the tool via `BG_INDEX`/`BODY_INDICES`.)*
  - **Battle path (VERIFIED):** `SetFld_466d` (bank `$07`, ~line 1008) reads species (`$caca`),
    indexes table at **`$00:$2B9F`** by `species*2`, DMAs to VRAM **`$8B00`**. Dracky (sp 78)
    → gfx-ID **`$3627`** (bank `$36` idx `$27`; 576 B / 36 tiles / 48×48; runmark `$02`).
    Word lives at ROM0 `$2C3B` = `27 36`.
  - **Follower path (VERIFIED):** table `ScreenTransDataTable` @ `$01:$49DF`, loader
    `GetActiveMonsterStatus` @ `$01:$4986`, index `(species+$10)*2`; plus a family-shared
    2nd load via `$01:$4BAD`. Dracky follower = gfx-ID **`$383E`** (bank `$38` idx `$3E`; 256 B / 16 tiles).
  - **DOC ERRORS to fix while annotating:** `bank_038.asm` header says "gate dungeon tileset J"
    but it ALSO holds monster follower sprites; `bank_036.asm` pointer table is labeled
    "Cross-bank dispatch table (40 entries)" but is actually the **gfx pointer table**.
  - **DISCARD (bogus):** an earlier `$382E` battle guess came from scan-tables at
    `$07:$6E14`/`$09:$6B10` that have **NO code references**; `$382E` is a dungeon tile, not Dracky.
  - **Deliverables:** labels/comments on the resolver, decompressor, pointer tables, and both
    species→gfx-ID tables; fold a proper decode/encode into the tool; extract the gfx-ID
    tables to JSON (tool ships with data). **Accept:** clean build still `1ca6579…`; tool
    round-trips a sprite byte-identically; Dracky→clam swap reproducible.



### GFX-2

- [x] **GFX-2 — Monster palette system + recolour + cross-bank sprite backbone.** ✅ DONE (Session 23)
  *DONE Session 23 — see PROJECT_STATE "Session 23" + KEY_LESSONS "Session 23" +
  MONSTER_DATA "Monster battle palette system". Delivered: (a) `dwm/sprite_bank.py` —
  cross-bank overflow allocator (places streams in reserved `$7E–$7F`/`$7C/$7A/$79`
  with a `$4001` pointer table; resolver reads `$<bank>:$4001+index*2` with no bank
  gating, so ANY of 221 monsters repointable regardless of source bank); (b)
  `tools/build_sprite_swap.py` rewritten — cross-bank, `--relocate` (lossless proof) /
  `--png` / `--payload`, `--palette` recolour, `--build-rom` focused test ROM; (c) the
  monster battle palette SOLVED — per-species table `MonsterBattlePalettes @ $17:$62FD`
  (was mislabeled `RoomAttrDataBlocks`), 8 B/species, loaded by entry 6 (`$1706`); found
  via SameBoy BG-slot-4 dump + ROM grep; annotated in `bank_017.asm` (byte-perfect);
  (d) `tools/extract_monster_palettes.py` + `extracted/monster_palettes.json`;
  `extracted/monster_sprites.json` regenerated (all 221, was a 3-monster subset).
  Proofs (user-confirmed in SameBoy): Slime relocated cross-bank renders identically;
  DWM2 clam→Dracky battle + correct purple palette; and the full combined ROM (clam +
  Dracky→Spirit family + custom room with random encounters + breeding/library) clean.
  REMAINING (GFX-3): follower path needs `$01:$49DF` re-section + its own palette table
  (find the same way) + the family-shared `$4bad` block.*
  *Original verified facts (kept for reference):*
  - **Why needed:** the clam swap renders correctly but in Dracky's palette {red, white,
    gold/brown, black} — no purple available from tiles alone. Recolour = editing palette data.
  - **VERIFIED (probe ROM this session):** Dracky's battle palette indices are
    **0=red, 1=white/transparent (backdrop), 2=gold/brown, 3=black** (index 1 is the backdrop).
  - **Traced (speculative chain):** CGB upload routines live in **bank `$17`** (`rBCPS/rBCPD/rOCPS/rOCPD`
    writes); bank `$00` has buffers `wBGPalette/wObj1Palette/wObj2Palette` + loaders
    `SetGBCPalette`/`SetPaletteGBC`/`LoadGBCPalettes`. `SetGBCPalette(a=palID)` →(GBC)→
    `SetPaletteGBC` stores ID at `$c850`, then `ld hl,$1704; rst $10` (far-call into bank `$17`)
    does the upload from a palette table. **The per-monster/family palette SELECTION point is
    NOT yet pinned** — the battle display init (bank `$07` ~lines 1090–1180) reads family
    (`$cacb`) + species and calls `FuncFld_6942` etc.; start tracing there. NOTE the
    `SetGBCPalette` calls in bank `$07` at lines 2460/2609 are SCENE palettes (warp/gate id `$03`),
    **not** the monster's — don't be misled.
  - **NEW LEAD (Session 22, user SameBoy VRAM data):** the enemy monster's tiles use ONE
    **shared OBJ palette slot — slot 4** (confirmed: Dracky AND a blue slime both show OBJ
    attribute `04` in the VRAM viewer). So the SLOT is fixed; the per-species COLOURS are written
    into slot 4 at battle-init. This means recolour = edit the **per-species colour data loaded
    into slot 4**, NOT a slot/palette-ID assignment. Concrete entry point: `FuncFld_6942` (bank
    `$07` ~line 6567) and `SetGBCPalette` — note `FuncFld_6942` does `ld h,$04` (matches slot 4).
    Trace from there to the colour table that feeds the `$1704`/`rst $10` upload.
  - **Recolour approach (speculative):** find the palette DATA table in bank `$17` reached via the
    `rst $10`/`$1704` path, indexed by the monster/family palette ID; edit the 4 RGB555 colours,
    OR repoint selection to a custom palette. **First confirm scope** (per-family vs per-monster):
    a family palette edit recolours Dracky's whole family. **Accept:** clam renders in corrected
    (e.g. purple) colours in SameBoy.



### GFX-3

- [x] **GFX-3 — Walking/follower sprite swap.** ✅ DONE (Session 24)
  *DONE Session 24 — see PROJECT_STATE "Session 24" + MONSTER_DATA "Follower /
  walking-sprite system" + KEY_LESSONS "Session 24" + TOOLS_AND_DATA. User-confirmed in
  SameBoy: blue dragon → DarkDrium follower, all 4 directions perfect.*
  **Delivered:**
  - **Re-section:** `ScreenTransDataTable` @ `$01:$49DF` → labeled `dw` block
    (`tools/resection_follower_gfx_table.py`; 231 entries `species+$10` + `FollowerFamilyGfxTable`
    @ `$4BAD`; build still `1ca6579…`). `build_sprite_swap.py --kind follower --payload F.bin`
    repoints + DMAs a 16-tile (256 B) self-contained literal stream.
  - **Render engine reverse-engineered:** `SaveScr_40cd` @ `$04:$40cd` (GBC variant of ROM0
    `$0d91`). Metasprite list of 4-byte **(dy, dx, tile_offset, attr)** entries, `$80`-term;
    OAM tile = `tile_offset + [$ffc9]` (follower base `$20/$30/$40` per party slot); OAM attr
    = `[$ffca] XOR attr` (X-flip bit5). 2-level table, sprite-type `$ffc7`(=`[$ca91]`) →
    frame/dir `$ffc8`. Head-mirror = two entries sharing a tile_offset, one X-flipped.
  - **OBJ transparency:** idx0 = HARDWARE-transparent for OBJ (battle BG used idx1 — opposite).
    8 OBJ palettes @ `$17:$5615`.
  - **118-layout library** (`tools/extract_follower_layouts.py` → `extracted/follower_layouts.json`):
    76 non-sharing (disjoint down/up/side → any distinct art renders clean; 202 types) + 42
    sharing (blob-only; 58 types). **Layout is per-monster, not universal** — this is why a
    symmetric blob (clam/Healer) hides layout errors and a directional dragon exposes them.
  - **Tooling:** `tools/follower_frame_picker.html` (drag 6 boxes, engine-accurate preview,
    export coords/payload) + numbered-tile calibration ROM method (each VRAM tile shows its hex
    index + flip-foot; `--palette` override = black digit / red foot for terrain legibility).
  *Original plan (for reference):*
  GFX-3 — Walking/follower sprite swap. Rides the Session-23 cross-bank backbone
  (`dwm/sprite_bank.py` + `build_sprite_swap.py`), but via the FOLLOWER path. Prereqs now
  known: (1) **re-section `ScreenTransDataTable` @ `$01:$49DF`** from mgbdis fake
  instructions to a labeled `dw` block (byte-perfect, same job as the S22 battle gfx
  table — preserve any cross-bank referenced labels), then `build_sprite_swap.py --kind
  follower` can repoint it (the tool already has the follower table wired, gated until the
  re-section lands); (2) the follower likely has its OWN palette table — find it the same
  way GFX-2 found the battle one (SameBoy dump of the follower's palette slot + ROM grep);
  (3) handle the **family-shared `$4bad` second DMA** (the B9-clamped 10-entry family GFX
  table) — verify in SameBoy whether it overlaps the swapped walk frames. Follower = 16
  tiles (`$383E` for Dracky); the 16-tile stream holds the full walk-animation frame set.



### GFX-4

- [x] **GFX-4 — Monster → follower-layout auto-map (completes GFX-3 automation).** ✅ DONE (Session 25)
  *DONE Session 25 — see PROJECT_STATE "Session 25" + MONSTER_DATA "Monster → layout dispatch" +
  KEY_LESSONS "Session 25" + TOOLS_AND_DATA. User-confirmed in SameBoy: Healer→Dragon clone and
  Dracky→custom blue-dragon (imported art), correct all directions, consistent across overworld +
  menu + library.*
  **Delivered:**
  - Level-1 layout tables LOCATED at fixed `$10:$407f` (species 0–127) / `$11:$407f` (species 128+),
    indexed by species; per-species attr/palette table at `$10:$417f` / `$11:$412d` (bit6=Y-flip, bit5=X-flip, low3=OBJ palette). (`[$caca]` is the SPECIES,
    not a "sprite-class" byte; bank `$05` is the ObjTest viewer path, not the follower path — both
    pre-GFX-4 doc errors, corrected.)
  - `tools/extract_monster_follower_layouts.py` + `extracted/monster_follower_layouts.json` (every
    species → layout id + addresses + sharing). `--selftest` reproduces Healer/DarkDrium anchors and
    confirms all 215 collectible species map.
  - `extracted/follower_layouts.json` REGENERATED & REPLACED — **155 complete layouts** (old 118 dropped
    the 3-entry small/blob layouts), canonical `$10/$11` addresses.
  - **8 follower-art table copies** discovered (`$01 $06 $07 $09 $0b $12 $18 $59`); a consistent swap
    must repoint all 8 (layout/attr are single/shared).
  - `tools/build_follower_reassign.py` — reassignment primitive: clone layout+art+attr from another
    same-bank monster, OR import custom 16-tile art (placed cross-bank, all-8-copies repointed) and set
    layout (default layout 0) + palette. Builds focused test ROMs; clean build stays `1ca6579…`.
  *Original plan (for reference):*
  layouts** (`extracted/follower_layouts.json`). The one remaining link is which layout each
  of the ~215 monsters uses, so the editor can (a) slice imported art into the correct tiles
  automatically, and (b) reassign a monster to a clean non-sharing layout on demand.
  **Known structure (from GFX-3):**
  - Render path: `AdjustGateFloorIndex` (`$01`) sets `$ffc7 = [$ca91]`, base `$ffc9 =
    $20/$30/$40`, calls `$0402` (`NPCSpriteLoadAlt`) → `SaveScr_40cd`.
  - `$ffc7 = [$ca91] = GetActiveMonsterStatus` return = `$01` (if bit7 of `[$cb0b]`) else
    `[$caca] + $10`. So a monster's layout is driven by its **sprite-class byte `[$caca]`**.
  - The 118 layouts are the **level-2** frame-pointer tables (6 ptrs each: down/right/up × 2),
    living in banks `$05`/`$10`/`$11`. A **level-1** table indexes them by `$ffc7`, with the
    BANK chosen by `$ffc7` magnitude (`NPCInteractDispatch` routing: `<$10`→`$04`,
    `$10–$8F`→`$10` (sub `$10`), `≥$90`→`$11` (sub `$90`)). Bank starts are code, so the
    level-1 tables are NOT at `$4000` — they must be located.
  - **TODO:** (1) locate the level-1 dispatch table(s) per bank; (2) extract each monster's
    `[$caca]` sprite-class from the monster data table; (3) compose monster → `$ffc7` → layout
    id; emit `extracted/monster_follower_layouts.json`; (4) wire into `follower_frame_picker.html`
    + `build_sprite_swap.py` so imports default to a non-sharing layout and reassignment is a
    same-size `[$caca]` edit. **Accept:** every monster maps to a layout; a distinct-art import
    on any monster renders clean (matching the DarkDrium-dragon result).


### T1

- [x] **T1 — Re-section keystone (bank `$47`). DONE (S43, byte-perfect).**
      `tools/resection_text_bank.py` converts a corpus bank's contiguous DTE string run
      from mgbdis fake-instructions to `TextStr_<bank>_<addr>:` + `db` blocks (one label
      per text id, decoded text in a comment), labels/comments only. Region from data
      (first string addr `text_id_map.json`; end = bank trailing-fill scan); `R_start/R_end`
      snapped to real line boundaries via a probe-build line→address map (same machinery as
      `resection_library_tables.py`) so no fake instruction is split; emits exact ROM bytes.
      Idempotent, re-runnable from clean tree. **bank `$47`: 69 strings, run `$4174-$5b74`,
      5607 fake lines replaced; clean build stays `1ca6579…`, integrity PASS 4/4.** Method +
      per-bank bounds in TEXT_SYSTEM.md "Source re-section". *Accept met:* bank reads as
      labeled `db` with decoded comments; MD5 unchanged.


### S1

- [x] **S1 — Skill data foundation + round-trip keystone (S44).** *Reshaped on audit:* the
      bank `$52` function table was already re-sectioned, so the real work was the data tables.
      Decoded + FAQ-validated `SkillMPCostTable` ($07:$570C) and `SkillLearnReqTable`
      ($06:$50E0, incl. prereqs); `gen_skill_records.py` → `skill_records.json` (222 records,
      `kind` = 155 skill / 37 item_effect / 30 internal, family-cut codes, monster/enemy usage);
      `build_skill_tables.py --selftest` proves the function/MP/learn tables re-emit
      **byte-identical**. Corrected bank `$52` header ($4211→$6CC7, 256→222, 140→115). Found id
      215 "Sheldodge" = the **Bug-family cut**; renamed → "BugCut" in `patches/bank_041.asm`
      (**SameBoy-confirmed**). Comment-only annotation of the two tables in `bank_006/007`
      (flagged the `TilesetLookupTable` mislabel at `$570C`; rename + full `dw` re-section
      deferred pending SameBoy confirmation of the `$56E8` fn role). MD5 unchanged; integrity PASS.


### S2a

  - [x] **S2a — Alias EFFECTS POC (S45, SameBoy-confirmed).** Net-new ids $DE "Scorch"
        (reuses Blaze handler) + $DF "Smite" (NEW handler, 80 dmg) on starter EID 1, via the
        **skill-alias framework** (commit-time templatize to Blaze + `$db86` stash + `$db8a==0`
        guard + `FarSkillFork`). Works in battle. **Narrow:** single custom-caster, Blaze-shaped
        presentation only; enemy-real-Blaze edge case unclosed. `BATTLE_SKILL_SYSTEM.md` §1–§6.


### S2b

  - [x] **S2b — Presentation foundation + record round-trip keystone (S46, byte-neutral;
        NOT yet user-tested).** Proved handler=effect TYPE (shared) / record=per-skill params.
        Decoded the **record table** `$54:$4013`→`$41CF` (222×19B): field map FAQ-validated
        (+0 effect_class, +1 effect_category, +2 target_mode, +3 ai_weight, +4 mp_cost,
        +5 status_id, +6 damage_class, +11/+13/+15/+17 power min/range — 31/32 FAQ ranges exact).
        `build_skill_tables.py --selftest` re-emits ptr table + data **byte-identical**; the 4218B
        block **re-sectioned to `db`** in `bank_054.asm`. Decoded the **item-effect/meat** system
        (`$52:$4625`, meat 194–198 → `$58:$591E`) and the **animation dispatch** (`$52:$5460–$54f8`
        → `$dd6f`/`$dd70` → bank `$4c`/`$55`). MD5 unchanged, integrity PASS. `BATTLE_SKILL_SYSTEM.md` §7–§10.


### S2c

  - [x] **S2c — Effect-script MESSAGE format (RE, discovery). [2026-06-28]**
        *Reframed on RE:* bank `$4c` is **not** a novel effect-bytecode interpreter — it is the
        shared text VM, and the `$dd70/71` "pointer" is a **packed pair of message ids** (low=hit,
        high=miss) resolved via the mode-0 two-level table at `$4c:$4019`. *Accept met +
        validated:* Blaze `$b882` decoded to bytes (`$4c:529f` + `$4c:5871`); **67/67**
        statically-resolved skills' messages cross-checked against the categorized FAQ
        (`extracted/skill_faq.json`), 0 contradictions. Tool
        `tools/decode_effect_messages.py` (`--selftest`, `--validate`) →
        `extracted/effect_messages.json` (222 skills, 203 message ids). Format in
        BATTLE_SKILL_SYSTEM.md §9.


### S2c-anim

  - [x] **S2c-anim — Animation FORMAT / renderer (RE, discovery). [RENDERER REVERSED + EMULATOR-VERIFIED 2026-06-28]**
        The `$dd68` renderer is a **metasprite/OAM engine** (same 4-byte `dy,dx,tile,attr`
        $80-term format as the follower system). Full chain emulator-verified: skill id →
        `$5f:$52F0` → side-select tables `$5f:$58dd/$59c3/$5aa9` → routine dispatch
        `$5f:$5441` → routine table `$5f:$58bd` (index `$0d`=`$55cc`=`ret`=NO VISUAL) → sets
        `$dd68` anim-type → builder `$5c:$40fc`/`$5d:$4122`/`$5e:$413a` (de=`$4071`, two-level
        `[$c7]`anim/`[$c8]`frame → metasprites). **3 presentation layers** mapped: (1) sprite
        anim, (2) sound+flash (`$56ed/$57d5`→`$da81`; heal chime, TatsuCall `$da83` blink),
        (3) vertical screen-shake `$5f:$4c0c` (SCY via `$da84`/`$bb`). See §11. Tool:
        `decode_battle_animations.py` → `extracted/battle_animations.json` (45 anims/~600 frames).
        *Reuse* a known animation on a new id = table edit (`$58dd/$59c3/$5aa9`). *Authoring a
        novel animation* = add metasprite frame lists + a `$4071`-table entry (now fully
        specified; **remaining static-only:** per-bank table extent + tile-graphics VRAM source).


### S2d-audit

  - [x] **S2d-audit — Skill-ID bucketing audit (de-aliasing FOUNDATION, RE/discovery). [S48, 2026-06-28]**
        Byte-neutral. The prerequisite S45 skipped: a complete map of where the engine buckets the
        working skill id (`$db8a`, 254 reads / 9 banks). **Surface reduces to a small verified fork
        set** — 204 equality reads (max `$C5`, custom id matches none), 15 windowed range gates (fall
        through to defaults), exhaustive enemy-AI `$57` pass (148 reads, ZERO mishandle a custom id;
        high-id sub-dispatch guarded by `cp $d9; ret nc`). **Keystone = the record-table indexer
        `$54:$4013` (3 sites `$5251/$5276/$529E`)**: one fork fixes magnitude/targeting/MP-in-record/
        status/ai_weight + the AI. HW-confirmed (SameBoy): `$52:$66D9` writes `$db4c=$db8a`; `$535F`
        divert is a minor path; menu Flee ≠ skill `$DB`. **Keystone fork PROVEN byte-neutrally
        implementable** (5-byte `call Fork`+nop+nop trampoline, RGBDS-assembled + byte-executed,
        in-bank tables in `$54`'s ~10550 free bytes). Other forks: MP (3 readers, mirror `record+4`),
        sound (`$55:$4067`), name (repoint), anim (none for no-visual). Tool
        `tools/map_skill_id_buckets.py` → `extracted/skill_id_bucket_map.json`. Full RE: **§12.**


### S2d

  - [x] **S2d — Proper per-id custom-skill records + PRESENTATION (skill #1 live). [S49, 2026-06-29, v32]**
        Skill **MagicBurn (`$E0`)** ships non-aliased, end-to-end in SameBoy (user-confirmed):
        own record (½ current MP → all foes), result text, **announcement**, **animation**,
        **hit-flash**, **cast sound** — via clean dynamic indirection (own record/handler/name +
        `AnnounceTemplateTable` slot + `$4c:$7326` message pool + `GetPresentId` presentation
        proxy in `$5f`), no per-aspect hacks. Integrity PASS 4/4, byte-perfect. The earlier
        "anim blocked on `$5f` cleanup" is **solved**. Full system + per-skill recipe:
        **BATTLE_SKILL_SYSTEM.md §13**.


### S2e

  - [x] **S2e — Custom skill #2 (Tame `$E1`) — system GENERALIZES. [S50, 2026-06-30, user-confirmed]**
    Recruit + anti-abuse damage (ATK/4), single-target. Built the reusable **custom-message
    render fork** (`$FD`→per-skill pool string, `LoadB4c_Fork`; MagicBurn migrated onto it) and
    the **presentation-timing** path (per-id anim-wait gate `$53:$5b07` + fixed frame delay
    `wTameDelay` sequences note→hit; damage sound moved off the note onto the text). Full RE:
    BATTLE_SKILL_SYSTEM §13.5 + §11.7; TEXT_SYSTEM ($FD fork); KEY_LESSONS (S50). **Deferred:**
    Tame Stage 2 (revert meter crank $0640→$000A; 3 upgrade tiers via learn-chain fork bank $06;
    make natural to Slime via a $03:$4461 slot). **Known minor defect:** per-enemy-sprite blink
    unsolved (not wBGPalette/whole-screen, not OBP-only; likely an OAM visibility toggle — §11.7).


### S2e-orig (deleted, superseded)

  - [ ] **S2e-orig (superseded desc) — Custom skill #2 (prove the system generalizes).** Add a skill of a
        DIFFERENT shape than MagicBurn to stress parts skill #1 didn't: a **non-damage** skill
        (ally heal, a buff, or a status effect) and/or a **single-target** one. *Accept:* it
        works in SameBoy with its own record/handler/name/announce/presentation, no aliasing.
        **SHOVEL-READY:** follow the 5-step recipe in **§13.4** — each layer is a one-line edit;
        nothing is rebuilt. Watch the two open follow-ups in §13.4 (custom-id skill-NAME insert
        for name-inserting announce templates; a 2nd bespoke-message render path beyond `$FD`) —
        a heal that reuses a self-contained stock announce template hits neither.


### Recommended-order (old)

**Recommended order:** T1 ✅ → S1 ✅ → S2a ✅ → S2b ✅ (S46) → S2c-msg ✅ → S2c-anim ✅ → S2d-audit ✅ (S48) → S2d ✅ (S49, skill #1 live) → **S2e** (next — custom skill #2) / S2f (field skill) / S3 → S4 → M1 → M2 → M3 / T2-roll-out,
slotting the text roll-out into spare sessions. Cheap high-confidence wins early; fire the
two RE discovery sessions (M1, S3) before their authoring items depend on them.

### N1

- [x] **N1 — Scope / RE + slot map (DONE, Session 28).** `tools/map_species_slots.py`
      + `extracted/species_slot_map.json` (256-slot map, self-checking). Verified:
      single indexers (info `$03:SaveMon_4446` ×43, enemy-stats `$14:LoadEnemyStats`
      ×25 with 16-bit EID); slot geography (215–219 special, 220–223 empty, 224–255
      free); the 4 hand-decoded top-range `cp`-ladder sites (flagged for N6 — since
      RESOLVED as `$db8a` skill/effect gates, NOT species gates) vs ~40 false-positive
      `cp $dd` hits. No bytes changed; integrity PASS 4/4.


### N2

- [x] **N2 — Info-table fork (keystone). DONE (S29 impl, S30 verified + made reproducible).**
      `SaveMon_4446`/`label443f` forked zero-shift (id ≥ 224 → bank `$6A` high table via
      `ld hl,$6a00; rst $10`); `MonsterInfoTable` stays pinned at `$4461`, ids 0–220
      byte-identical (only the 2 B6 family-byte reassigns differ). Authored by
      `tools/build_new_species.py` (`extracted/new_species.json` → `patches/bank_06a.asm`),
      byte-exact round-trip validated. Gorbunok (id 224 = Dracky info, family→Slime).
      *Accept met:* id 224 loads correct 43 B; clean build `1ca6579…`; SameBoy-confirmed
      (S30: caught, correct Slime-family stats).


### N3

- [x] **N3 — Enemy-stats. DONE (no fork needed).** EID is 16-bit, so a new entry placed in
      bank `$14` trailing free at EID×25+`$4C1D` is read by vanilla `LoadEnemyStats` with no
      code change. EID 518 → `$14:$7EB3` (Slime EID 2 clone, monster_id→224). Tool
      `build_new_species.py` → `patches/bank_014.asm`. SameBoy-confirmed (S30: fightable/
      catchable). Wild-encounter wiring: same-size `EncounterPoolData` edit (pool 0 slot 3 =
      EID 518 wt 1), tool-owned in `patches/bank_001.asm` (S30 — was a hand-edit before).


### N4

- [x] **N4 — Sprite + palette. DONE (user-confirmed v7).** Tool
      `tools/build_new_species_follower.py` builds a standalone test ROM (patches/ untouched,
      clean build stays byte-perfect) giving id 224 a real follower + battle sprite + palettes:
      • **Follower art:** all **8** gfx-ID copies forked byte-neutral to a real overflow stream
        (`$7e00`); the overworld loader `GetActiveMonsterStatus` ($01) clamp narrowed `cp $e0`→`cp $e1`
        so id 224 reaches the fork (the placeholder clamp had pinned it to DarkDrium).
      • **Follower layout:** level-1 slot `$11:$413f` → Armorpion's layout-0 level-2 `$4184` (proven
        upright, matches `pack_png_layout0`).
      • **Follower attr (palette + flip):** the per-species attr read (`HramUnk11_406e`) overshoots its
        87-entry table into live layout data at `$418d=$41` — bit6 was a stray **Y-flip** (upside-down
        tiles) and low3=1 the **green** palette. Forked the read (`$11:$406e`→`$792d`) to hand id 224 a
        clean attr (no flip, OBJ palette 2 = blue). Both cosmetic bugs were this one overshoot byte.
      • **Battle:** gfx `$00:$2d5f` `$320f`→`$7e01`; palette reader `label17_41d0` forked (resolver
        `$17:$6ce0`) to a custom blue palette. (Full mechanism: MONSTER_DATA.md "NEW species followers".)
      **Follow-up status:** the **FOLLOWER half is now baked into `patches/*.asm`** — Milestone **G1,
      DONE (S34, user-playtested OK, all 4 directions).** id-indexed (content-sized) gfx-ID tables in all
      8 banks, layout slot, attr fork, clamp; new `patches/bank_011/059/07e.asm` + tool
      `tools/bake_follower_overflow.py`; in verify_integrity PATCH lists; integrity PASS 4/4.
      Orientation fixed at root: art stored **un-flipped** (no `--flip-y`), clean-attr mask **`$B8`**
      (preserves the engine's bit5 X-flip for LEFT). The **BATTLE half is now baked too** — Milestone
      **G2, DONE (this session).** Battle gfx `$00:$2d5f` `$320f`→`$7e01` (a **same-size 2-byte repoint**,
      no fork: the species-indexed gfx table `$2b9f` has a real padding slot for id 224, unlike the
      follower tables that overshoot); the dragon battle pose packed as a 2nd overflow entry
      (`Battle_sp224` @ `$7e01`, follower stays `$7e00`) by the extended `tools/bake_follower_overflow.py`
      (`--battle-art/--battle-spec`); battle palette reader `label17_41d0` forked byte-neutral to
      `HighBattlePal` in bank `$17` filler tail (id≥224 → custom blue palette `67 4d ff 6b ff 7f 00 00`,
      else vanilla `$62fd+species*8`). New `examples/follower_swap/gorbunok_battle.json`; bank `$000/017/07e`
      in verify_integrity PATCH lists already; integrity PASS 4/4, user-playtested OK. (Full mechanism:
      MONSTER_DATA.md "NEW species battle sprite".)  **Remaining new-species item → G3:** new_species.json
      schema fold.


### N5

- [x] **N5 — Name + joinability + breeding/library wiring. DONE (S32, user-tested).** Name
      DONE ("Gorbunok" @ `$41:$7E46`). Library DONE + reproducible. Joinability via EID 2 clone.
      **Breeding now DONE — all three paths, user-confirmed:**
      - **Result-path:** Snaily(4) × BattleRex(42) → Gorbunok, a verified-free cross (no special,
        no family default) appended in `extracted/breeding_special.json`. `build_breeding.py`
        extended to admit a declared new-species id (>220) as a recipe result. Bank `$69`.
      - **Parent-path:** works with zero new code — breeding loads parent family via the forked
        `$0301` loader, so Gorbunok resolves to its Slime family `$F0`. Verified by simulation +
        user playtest (Funkybird×Gorbunok→Picky, Dran×Gorbunok→DragonKid, Gorbunok×Funkybird→
        Healer, AntEater×Gorbunok→Tonguella, Gorbunok×AntEater→SpotSlime).
      - **Display-path:** `FamilyRecipeResolve` (`patches/bank_016.asm`) returns the parent pair
        `db $04,$2a` so the encyclopedia shows the Snaily+BattleRex icons.
      - **Hatch:** crashed on the first build — bank `$0b` follower-gfx copy overshot for id 224
        (user pinned via SameBoy breakpoint `$0b:$48ac`). Fixed with `FollowerArtResolve0b`
        (`patches/bank_00b.asm`), same byte-neutral pattern as `$07/$09/$18`.
      - **Default-nickname / "take X with you" narration:** both used the 2-letter `FamilyCode`
        short-name table (`$4739`, 215 entries) which overshot for id 224 into `ItemName[9]` =
        "SkyBell". Fixed via `LoadModeBaseRedirect` (16 bytes in the `$00F0` ROM0 padding,
        `patches/bank_000.asm`): mode-7 lookups for id≥224 redirect to a new-species SHORT-name
        entry (first 4 letters, "Gorb") at bank `$41` tail (`$7FF9`). Generic (no per-monster
        handcoding); gated on `$4739` so all other text is byte-identical.
      - **[x] SUB-ITEM (DONE, S38 — user-confirmed in SameBoy):** library/encyclopedia lineage
        showed parent *icons* correctly but "?????" next to each instead of "Snaily"/"BattleRex".
        Root cause (S32): the parent-name line is rendered via `LoadItem_6456` (`$12:$6456`) → bank
        `$4d` entry 2, **mode 0 = line 1** (`$4d:$400b`), indexed by the **offspring** id; slot 224
        held the vanilla shared "?????    ?????" placeholder @ `$53C4` (256-entry table, NOT an
        overshoot — un-authored slot, shared with 220/225). **FIX (S38):** first verified from clean
        source that the lineage path routes through the fork (bank `$4d` entry 2 = `call SetB4d_43b9`
        → `HighDetailTextFork` → `HighModeTable4D` for id≥224), then wired `HighModeTable4D` mode-0 →
        new `HighMode0Ptrs` → `GorbunokRecipeLine` (`patches/bank_04d.asm`). **Also corrected a
        latent format bug** in the S32-staged string: real recipe lines use TWO fixed 9-char fields
        (e.g. slot 200 "Servant  GreatDrak", slot 214 "DeathMoreWatabou"), so the single-spaced
        staged string would have mis-columned parent 2 — rebuilt as `"Snaily   BattleRex"` (names
        sym-verified vs `MonsterNamePtrTable $41:$4339`). id≥224-gated → ids 0–223 byte-identical;
        built-ROM check `[mode0base+224*2] → GorbunokRecipeLine` → "Snaily   BattleRex". Test ROM
        `DWM-lineage-fix-v1.gbc`. Breeding itself unaffected. **Phase N now has only G3 open.**


### N6

- [x] **N6 — Top-range gates verified (DONE, S31): NOT species gates → no patch.**
      `bank_05f/057/058/052` all branch on `$db8a`, which is a battle skill/effect/
      animation id (written only from constants + skill tables), never a species byte.
      A new species 224 cannot reach them, so they were false positives in the S28
      slot-map. Phase N requires no species-gate patch. (Detail in MONSTER_DATA.md
      "Species ID geography" → N6; DOC_AUDIT.md.)


### S29 trailing blockquote (all items resolved or folded into G3)

> **S29 progress (stage1ac / Gorbunok id 224 track).** The **encyclopedia DETAIL page
> freeze** — the last blocker for the new-species *display* feature set — is FIXED
> (`TEXT_SYSTEM.md`): the text engine's mode×species double indirection
> (`SaveBankAndSwitch $092F`) overshot the 215-entry line-2 description table at
> `$4D:$420B`. Forked via `HighDetailTextFork` (`patches/bank_04d.asm`). Also fixed the
> independent 222-entry `FamilyRecipeTable` overshoot (`FamilyRecipeResolve`,
> `patches/bank_016.asm`). Detail page user-confirmed clean (mirrors Dracky), ROM
> `DWM-Gorbunok-stage1ac-v16.gbc`. Every species-indexed table and its overshoot status
> is now catalogued in `MONSTER_DATA.md` (Species ID geography).
>
> **Next steps / deferred (next session):**
> 1. **Custom Gorbunok sprite + palette** (the N4 work) — currently a DarkDrium
>    placeholder (`MonsterBattleGfxTable[224]=$320F`); follower sprite also deferred.
> 2. **Bespoke Gorbunok description string** — line 2 currently reuses Dracky's
>    (`$60BC`) as a valid placeholder; author a real string (needs font-glyph encoding
>    like the name) and point `HighLine2Ptrs[0]` at it.
> 3. **Optional: make Gorbunok breedable** — wild-only today (recipe = `$FF,$FF`); both
>    the result-path (`SpecialRecipeTable` append) and parent-path (extend
>    `FamilyRecipeResolve`) are documented in `BREEDING_SYSTEM.md`.
> 4. **Re-check N4/N5/N6 formal acceptance** against the stage1ac implementation and
>    tick the boxes whose acceptance tests are now met.

