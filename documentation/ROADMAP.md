# ROADMAP — Verified DONE / NEEDS DOING

Two sections. Section 1 lists what is DONE, each row with the **evidence**
(how it was verified — most re-verified 2026-06-13, in-game items at ROM
v23). If you can't point at evidence, it doesn't go in Section 1.
Section 2 is what NEEDS doing, phased, each item with an acceptance test.
A session picks ONE item. Status legend: [ ] open · [~] partial · [!] blocked.

---

## 1. VERIFIED DONE

### Infrastructure
| Item | Evidence |
|------|----------|
| Byte-perfect clean build | `make` → MD5 `1ca6579…` == original ROM (re-verified after restoring bank_00b from the drift) |
| Patch system (clean repo + patches/ overlay) | `verify_integrity.py` check 2: patched build assembles, bank $60 populated |
| Integrity guardrail + doc-MD5 police | `tools/verify_integrity.py`, 4 checks, PASSING |
| RGBDS 0.6.1 build chain documented | README quick start, exercised this session from scratch |

### Reverse engineering (formats fully decoded, ROM-verified)
| Item | Evidence |
|------|----------|
| FIELD-cast skill pipeline (menu shell $c90d 0-4, usability whitelist, $da5e, bank $14 entries 4/5, menu-armed script protocol ctr=$FFFF) — S73 | BATTLE_SKILL_SYSTEM §14; skill $E4 Anchor round trip verified in PyBoy + USER-CONFIRMED in SameBoy |
| Monster info table $03:$4461, 221×43 B | family bytes 0–9 across all entries (DOC_AUDIT B) |
| Enemy stats $14:$4C1D, 487×25 B | 487/487 $FF delimiters at +$18 |
| Boss table $14:$4897 (32×4 B) + redirect $4893 | ROM bytes + bank_014 header (DOC_AUDIT A.5) |
| Breeding tables $16:$4B30 (825×5) + $4974 | terminator at base+4125; extracted JSON |
| Room system: ptr table $0B:$4B43, 107 rooms; step/interact/exit formats | 106 valid ptrs + $FFFF hole; interact/exit semantics SameBoy-confirmed (ROOM_DATA_FORMAT) |
| NPC RAM: $D7D2, 32 B/slot | parser `add $20` at $0B:~$4820 (DOC_AUDIT A.3) |
| Script engine: 100 opcodes; 518 `*_ScriptNN:` labels in $0C–$0F (census 129+168+130+91) = 551 unique script bodies = 732 (map_type, script_id) pointer-table entries in all_scripts.json (map types share banks/scripts — all three counts correct on different bases, verified S51) | compile/decompile roundtrip; branch-following work-queue (810/866 WriteRAM = 93.5%) |
| Text system: charmap, DTE, control codes, 2,067 IDs, routing cascade | text_id_map.json count; control codes proven in-game (v23) |
| Event flags: fns $26A0/$26A6/$26AE; 328 referenced, 298 with sets (branch-following) | EVENT_FLAGS.md statistics; analyze_event_flags.py |
| Encounter pool format: 32 gates → pools 0–127 | encounters.json structure audit |
| Gate floor GENERATION: procedural maze grid `$C940`, per-gate `GateFloorDataTable` `$16:$70A6`, `SelectFloorType`/`FloorTypeSelectionTable`1/2/3, special-room `rst $00` dispatch `$16:$5C1C`, damage tiles (class `$0E`/`FloorDamageTable` `$01:$5E7D`) | S37: pipeline traced end-to-end + damage tiles SameBoy-watchpoint-confirmed; **GATE_GENERATION.md** |
| Vanilla-empty banks: 23 = 368 KB | full-ROM scan; CURRENT allocation lives in PROJECT_STATE "Bank allocation" (8 banks now patch-owned) |
| ~~Custom WRAM $D378–$D477 unclaimed by original code~~ **REFUTED S54**: that range sits INSIDE the party/storage monster array `$CAC1-$D664` (20 slots × $95, `GetMonsterDataPtr` — indexed access, zero literal refs, which is why the grep missed it). Every custom WRAM var ($D378-$D48B) collides — root cause of the S53 egg-give room corruption. See `tools/audit_wram.py` + `extracted/wram_usage.json`; relocation is a Phase 0 item | audit_wram.py --selftest; slot math $CAC1+20×$95=$D665 |

### Custom content primitives (proven in-game, v23)
| Item | Evidence |
|------|----------|
| Custom rooms (mapID ≥ $6B) in bank $60: multi-screen, scroll, exits (vanilla↔custom AND custom↔custom via exit entries) | v23 test rooms $6B/$6C reachable from GreatTree; $6B exits to $6C and back |
| Custom NPCs + scripts (bank $60 entry 4 dispatch) | BeefJerky NPC, room $6B |
| Custom text IDs $0A00+, two-level table, multi-page | v23 dialogue |
| YES/NO branching ($E7 $F0 + opcode $15 / $C83C) | room $6C NPC |
| Item give + inventory-full ($2A wrapped, $2C) | v23 |
| Event flag ops from custom scripts ($00/$01/$03) | v23 |
| All mapID-table intercepts (11 sites, 4 banks) | CROSSBANK_ROOMS table; 19 debug iterations documented in KEY_LESSONS |
| Custom breeding recipes (special table, same-size edit) | v31/Session 12: Anteater×BattleRex→GoldSlime via two provably-dead entries (803 dup, 693 shadowed); focused build diffs original at exactly the intended bytes; confirmed in-game. Tool `patch_breeding_recipe.py`, `patches/bank_016.asm`. |

### Tooling (re-verified this session)
| Item | Evidence |
|------|----------|
| LZSS compressor/decompressor | roundtrip: 512→141 B, decompress == original |
| Script compiler + decompiler (all 100 opcodes) | `compile_script.py --test` passes |
| Dumpers: bosses, encounters, monsters, NPCs, text, exits, rooms | smoke-tested dump_boss_table, decompile_script, analyze_event_flags |
| Room renderer | ALL_ROOMS_FINAL.png exists (not re-run) |

---

## 2. NEEDS DOING

### Phase 0 — Foundation (finish before feature work)
- [x] **SRAM save audit** — SRAM layout fully traced and documented in
      ARCHITECTURE.md + known_RAM_map.md. Custom flags $0158-$0277 in save
      range. Flag byte collisions mapped (D9CB/D9CD/D9CF-D9D6/D9E3/D9E6/D9E9).
      Safe contiguous block: $0158-$017F (40 flags).
      *Verified Session 8*: flag $0158 (byte $D9C6, bit 0) set via NPC script,
      persisted through save+reload in SameBoy. PASS.
- [x] **Fix `dump_all_scripts.py` branch-following** — linear decoder missed
      ~45% of WriteRAM operations. Fixed: work-queue follows 9 branch opcodes
      ($00/$01/$0E/$14/$15/$27/$28/$2C/$37). 810 unique WriteRAM found (was
      482; ROM ground truth 866 = 93.5% coverage). 56 remaining are in
      alternate dispatch paths (entry 1/2 tables). Canonical room names from
      editor/editor.py (96 entries). New `branch_targets` field per script.
      Castle script_id=0 now shows 69 branch targets, WriteRAM for D92B/D92C/
      D92D/D92F/D93C. all_scripts.json regenerated.
- [x] **Fix `dump_map_table.py` swapped interact/exit labels**, regenerate
      map_table.json. *Accept*: JSON field names match ROOM_DATA_FORMAT;
      spot-check 3 rooms against bank_00b labels.
- [x] **Commit CI workflow** (`.github/workflows/verify.yml`, provided).
      *Accept*: green run on GitHub on next push.
- [x] **Reconcile dump_enemy_stats.py with its richer committed JSON**
      (port exp_reward/ai_weights/skills/joinability decode back into the
      tool). *Accept*: regen == committed byte-identical → Tier A.
- [x] **Recover/write generators for frozen-source JSONs** — dump_skills.py,
      dump_text_id_map.py, dump_all_scripts.py written and verified.
      breeding_complete, resistance_*, tile_registry reclassified as
      hand-authored reference (not frozen-source). See TOOLS_AND_DATA.md.
- [~] Move one-off investigation tools to tools/archive/ and delete
      superseded data (monsters.json, event_flags.json, edits.json) per
      TOOLS_AND_DATA.md. *(Postponed — low priority.)*
- [~] Housekeeping deletions/moves per PROJECT_STATE. *(Postponed.)*
- [x] **Custom-WRAM relocation — DONE S55 IN DELIBERATELY REDUCED FORM** (user
      decision: the hand overlay is exploration scaffolding; the editor system
      gets the structural fix — see "Cold Farm" arc below). What moved: step
      counters (compiler region, base $D478→**$DE74**), wRoomRecScratch
      (→$DE7B), wRoomEncFlag, Tame vars, wCustomRoomFlag (→$DE88) — the S53/S54
      CRASH VECTOR (a slot-16 give landed on the counters/scratch) is gone.
      What stayed: the NPC/exit buffers ($D379-$D477, inside monster slots
      14-15) — ACCEPTED legacy hazard: forward corruption is transient
      (buffers self-heal per read), reverse corruption of stored monsters
      #15-16 remains → **(RETIRED S60 — window freed by CF3)** keep the array ≤14 occupied around custom rooms on
      the exploration overlay** (saves there are disposable, user decision).
      S55 vetting findings that forced the reduction (details in
      wram_usage.json + KEY_LESSONS S55): the S54 gap candidates were FALSE —
      $C200-$C2FF is the attr decompression staging buffer (declen 256 in
      every stream), $C300-$C4FF is a 512-B screen staging unit (bank $06 bulk
      copy; both save-copied to SRAM); $DD80-$DE2B is the AUDIO engine (6
      chan × 26 B + scalars — known_RAM_map's "battle structs" was wrong);
      stack tops $DFFF. $DE74-$DEDD was the ONLY vetted block (junk-only refs
      above the $DE2B audio ceiling; SVBK windows are $DB00-only) — 21 B used,
      $DE89-$DEDD reserved. **Retired alternative — cap monster slots 20→18**
      (reclaim $D53B-$D664, 298 B proven, with $00 in-use pads defusing all 44
      read-walkers): fully vetted and viable, but retired because it spends
      surgery on the throwaway overlay; do NOT re-derive it — Cold Farm
      supersedes. Cascade done: project.py STEP_COUNTER_BASE, example project
      (reserved hole 0xDE78), regression md5 re-pinned
      (patched-build reference `cc62b50119368eb24a40564e23d66779`), 18/18 tests, audit_wram selftest
      re-pinned (buffers still flagged; relocated labels clean). Template
      sha256 pins UNCHANGED (label-only refs). *Accepted — USER-CONFIRMED
      2026-07-10 on both S55v2 ROMs:* well entry, egg-give → exit +
      scroll-up, and save-in-room → reload → scroll all work; stored
      monsters #15-16 still corrupt on transitions (expected, ≤14 rule).
      The fixed-table run also cleared S53's master-table test debt.
- [x] **Fold tool selftests into `verify_integrity.py` — DONE S59.** (promoted S51
      from *Open* notes buried in the B3/B7/S1 completed stubs): the byte-identity
      selftests of `build_breeding.py`, `build_library_table.py`, and
      `build_skill_tables.py` only ran when someone remembered to invoke them — the
      verifier didn't, so a table edit could silently diverge from its JSON.
      **As built:** `check_tool_selftests()` + `SELFTEST_TOOLS` list; labels
      renumbered `/4`→`/5`. **ROM-tolerant by design** (the load-bearing decision):
      `data/DWM-original.gbc` is gitignored/user-provided and `.github/workflows/
      verify.yml` runs with no ROM ("MD5 compare needs only the expected hash"), so
      an absent ROM **SKIPs** check 5 instead of failing — otherwise every CI push
      would break. A present-but-non-canonical ROM still FAILs.
      *Accept — MET, all four branches proven S59:* PASS 5/5 on the clean tree;
      FAIL on a deliberately mutated `skill_records.json` `mp_cost` (pinpointed
      `SkillMPCostTable mismatch at offset 0 (got 0x09 want 0x02, skill id ~0)`,
      restored → PASS); SKIP with the ROM absent; FAIL on a 1-byte-corrupted ROM.
      Owning doc: TOOLS_AND_DATA "Guardrail".
- [x] **Retire `extracted/skills.json` — DONE S59.** Superseded by
      `skill_records.json` (S44). **This box's stated scope was WRONG** (DOC_AUDIT
      S59): "only `gen_name_tables_db.py` still reads it" was inverted — that tool
      declared `SKILLS_PATH` and never opened it (dead constant, removed; output
      byte-identical), while THREE unmentioned tools actually read it:
      `gen_skill_table_db.py`, `gen_enemy_stats_db.py`, `gen_monster_db.py`. All
      three ported to `skill_records.json` (`json.load(f)['records']`); they consume
      only `id`→`name`, never `function_addr`, so the port is a one-line change each.
      Output diffs: `gen_enemy_stats_db` + `gen_monster_db` **byte-identical**;
      `gen_skill_table_db` comments-only (34 garbage ids gained `?NNN` in place of
      blanks) with emitted code identical.
      **Root cause found + fixed (the real prize):** `skills.json`'s 34 junk records
      (ids 222–255, not "33") came from reading the 222-entry skill function table
      as 256. The table is `$52:$4011..$41CC` (222 × 2 = 444 B) and is UNTERMINATED —
      it ends where `SkillBlaze` begins at `$52:$41CD` (`CD FF 5B` = `call $5BFF`),
      so the phantom entries were handler CODE read as pointers. `gen_skill_table_db.py`
      still emitted 256/"512 bytes" and a bogus `$4211` xref (real site: `$6CD5`, the
      only `21 11 40` in bank $52, inside `jr_052_6cc7`) — corrected to 222 + `$6CC7`;
      it now emits zero `?` fallbacks, proving `skill_records.json` covers the table's
      id space exactly. `disassembly/` + `patches/bank_052.asm` header `$41BC`→`$41CC`
      (comment-only, build re-verified `1ca6579…`). `dump_skills.py` is now an inert
      documented tombstone (exits non-zero) rather than a live tool that would
      silently recreate the deleted file — the `dump_monsters.py` hazard class.
      *Accept — MET:* repo-wide grep shows zero readers (only tombstone/historical
      mentions); TOOLS_AND_DATA updated. Owning docs: BATTLE_SKILL_SYSTEM (table
      extent), KEY_LESSONS S59, DOC_AUDIT S59.
- [x] **Housekeeping deletions — EXECUTED S51 (user OK'd):** actually deleted:
      `__pycache__/`, 8× `.DS_Store`, `breeding_extra_recipes.json` — all three
      were TRACKED at HEAD, so recoverable from git history if ever needed
      (breeding_extra_recipes was a self-described B3 capacity TEST fixture; its
      facts are in SESSION_HISTORY's archived B3 narrative). THREE queue rows
      were stale: `monsters.json`, `event_flags.json`, `edits.json` were all
      already absent (untracked at HEAD — a fresh clone never contained them;
      verified S51 during the no-loss audit). `build_breeding.py
      --emit-relocation` help marked LEGACY (absence-tolerant). Verifier PASS 4/4.
      NEW defect found: `dump_monsters.py` WRITES the legacy `monsters.json`
      schema and READS `monsters_full.json` — the Tier-A generator attribution for
      `monsters_full.json` is suspect (see PROJECT_STATE Open defects).
- [x] **S51 — Doc consolidation + audit** (2026-07-02): PROJECT_STATE 1,071→~280 and
      ROADMAP 1,176→~640 lines with ZERO deletion (everything cut moved verbatim to
      the new cold archive `documentation/SESSION_HISTORY.md`); contradictions fixed
      in place (bank counts, script/flag counts, stale paths/headers);
      TOOLS_AND_DATA refreshed to 103 tools / 56 JSONs; `TilesetLookupTable` →
      `SkillMPCostTable` + `LoadFld_56e8` → `GetSkillMPCost` renamed (byte-perfect).
      → PROJECT_STATE "S51" block; SESSION_HISTORY.md.

### Phase 1 — Remaining primitives (1 session each; ordered by editor impact)
- [x] **Script-driven teleport** — exit-based room transitions already
      work in all directions (vanilla↔custom, custom↔custom — proven in
      v23). Opcode **$0F** (MapTransitionFull) **confirmed working** from
      custom scripts — tested vanilla (Castle) and custom ($6B) destinations.
      Note: $0E is BranchByScreen, NOT teleport (bank $04 inline comment
      at $59D2 was wrong, fixed). $0F writes gate_id → $C96D, flag → $C96E,
      spawn XY → $C96F-$C972, sets wIsPlayerChangingMaps=1.
      Format: `$FF0F <gate_id:flag> <spawnX> <spawnY>` (3 word params).
- [x] **NPC show/hide by flag/step** — mechanism is the step system (multiple step
      entries per screen; opcode $12 advances the counter; custom counters moved to
      safe $D478+, not SRAM-persistent). Confirmed in-game v25.
      → ROOM_DATA_FORMAT "Room State System"; archive: SESSION_HISTORY Part 3.
- [x] **BGM change** — opcode $41 (SetBGM) **confirmed working**.
      Saves current BGM to $C8B6, plays new track from param.
      Track IDs in known_RAM_map ($C8B5). Tested: Arena ($1E) in
      custom room; reverts on room exit.
- [x] **Monster/egg give** — opcode $29 (AddMonster, wrapped in bank $04 padding) +
      $28 storage-full. Egg path proven (SkyDragon EID 350) and is the practical
      choice; direct give needs the `$FF04 $000F` preamble.
      → DATA_STRUCTURES; KEY_LESSONS S3; archive: SESSION_HISTORY Part 3.
- [x] **Custom tile LAYOUTS** — tile_layout_compiler.py → bank $64 (ptr table +
      LZSS); a nowhere-in-ROM layout renders in-game; palette-attr fix v28
      (CustomAttrCheck, bank $17); collision thresholds ROM0 $26E3 ×8 stride.
      → ROOM_DATA_FORMAT "Tile Layout System"; KEY_LESSONS S4–S5; archive: SESSION_HISTORY.
- [x] **Custom tile GRAPHICS (multi-tileset mashup)** — full pipeline: editor JSON →
      build_combined_tileset.py → bank $67/$17 patches → playable room (4-palette-group
      budget; gate-detection fixes in $06/$07; --build automation; runtime-correct
      tileset PNGs S9). Confirmed in-game.
      → KEY_LESSONS S6–S9; TOOLS_AND_DATA; archive: SESSION_HISTORY Part 3.
- [~] **Multi-screen room editing** — ROM-side patches complete (v28):
      2-screen vertical room proven (Room $6B, screens 0+4). Key changes:
      room height in $26DD table ($2A39: $80→$00,$01 = 256px = 2 rows),
      sub-table indices 0+4, bank $64 entries 0-3 (per-screen layout+attr),
      CustomAttrCheck screen-aware (bank $17), wCustomStep_Room6B_S1 added.
      **Remaining**: editor UI for multi-screen (canvas, screen selector,
      per-screen NPC/exit placement); `build_combined_tileset.py` multi-screen
      export; extend to horizontal and larger grids.
      *Accept*: editor exports a 2+ screen room; `--build` produces a ROM
      where the player can scroll between screens.
- [x] **Random encounters in custom rooms** — PROVEN S11 (Strategy A: mapID whitelist
      in $0B:Jump_00b_4674 + pin wGateID/wCurrentFloor + arm wEncounterCounter);
      generalized per-room S42 (RoomEncTable, bank $71 — see Encounters #1).
      → CROSSBANK_ROOMS "Random Encounters"; KEY_LESSONS S11; archive: SESSION_HISTORY.
- [ ] Custom music — parked; sound engine unexplored, BGM-change suffices
      for v1 stories.

### Arc COLD FARM — farm slots → SRAM, exp via chokepoint (editor-era WRAM strategy; scoped S55)
The structural fix for ALL custom-WRAM scarcity, replacing the retired cap-18
plan. User-designed (S55): party stays hot (slots 0-2 WRAM — S56: vanilla
party is NOT positional; CF3 must add a party-first sort, see CF1); farm/eggs become
SRAM-resident like the existing sleep pool ($B124 — vanilla's own precedent:
bank $07 already scans it in place with EnableSRAM per access). Per-battle exp
loops re-bound to party-only + a pending-exp accumulator; the accumulator
DRAINS EAGERLY at the gate-exit chokepoint — user-confirmed (S55): EVERY gate
exit funnels through the castle return warp (boss/warpwing/death/revisit),
GreatTree is battle-free except the Arena which awards NO exp, and in-gate
colosseum battles exit through the same funnel. Eager-drain-at-chokepoint means
farm SRAM data is CURRENT whenever any reader can run → the "proxy all 44
walkers" problem collapses to: (1) re-bound the post-battle exp-add +
level-scan loops (level-scan found S55: bank $50 `jr_050_6318`, b=0..$13 over
`CmpBtl_6383`) to party + accumulator, (2) one chokepoint hook, (3) redirect
the genuine farm read/write paths (farm UI drop/pick, give `label4_5c14`,
full-check `label4_5f67`, breeding parent fetch, trades) to SRAM addressing.
In-gate farm touches (give/full-check) read occupancy only — exp staleness
invisible. Farm level-ups apply at the chokepoint ("grew while you were away").
Prize: ~2.5 KB contiguous WRAM freed ($CBEB-$D664) + the S54 collision class
dies structurally. Est. 2-3 sessions after the boundary-semantics RE.
- [x] **CF1 — RE: party/farm boundary semantics.** DONE S56 (byte-neutral).
      Party is NOT positional: dual representation = in-use flag +$00
      ($00/$01 farm/$02 party) + party list $CA8D/$CA8E-$CA90, synced by the
      canonicalizer ReadPartySlotInfo ($01 entry 5, 22 call sites) which
      also COMPACTS the array (records move). Exp: party = total/eligible,
      farm = total/16 each — the fork is ONE `cp $02` site in the exp
      walker $50:$61E2. Egg flag +$63; KO bit +$4A.7; staging pseudo-slots
      $14/$15 @ $D665/$D6FA (breeding/trade/menus). All 44 $CAC0 writers +
      60 register walkers classified: MONSTER_DATA "Party/farm boundary
      semantics" + extracted/monster_walkers.json (self-checking generator).
      ⚠ DESIGN NOTE for CF3: the arc premise "party stays hot in slots 0-2"
      needs a party-first sort added to the canonicalizer (or index
      remapping) — vanilla does not keep party at 0-2. The "$15-special"
      (S55) turned out to be trade/breeding STAGING, not a release variant.
- [x] **CF2 — exp accumulator + chokepoint drain — DONE S57,
      USER-CONFIRMED 2026-07-13.** Accept test passed: farm exp/levels
      correct at the farm UI after a multi-battle gate run; save in an
      in-gate save room → reload → exit gives the FULL run's exp (pending is
      PERSISTENT: $D9C8-$D9CA inside the save image, because in-gate save
      rooms exist — FAQ); party level-ups + town behavior unchanged.
      As built (owning section MONSTER_DATA "CF2 as built"): bank $50
      `CF2FarmShareDivert` (same-size 14-B window at the exp-walker head)
      zeroes the per-monster farm share and banks total/16 into
      `wPendingFarmExp` — walker + post-battle level scan become farm-inert
      with zero loop edits; NEW bank $73 entry 0 `CF2WarpCommitDrain`, hooked
      at the bank-$0B RoomEntry0 map-change commit (same-size 6-B window),
      pays + silently levels eligible farm monsters when the destination is
      non-gate, using the vanilla $1300/$1302/$510d pair. Semantic deltas
      accepted-pending-veto: payout at first non-gate transition (not per
      battle; invisible — farm UI is town-only, vanilla farm level-ups are
      silent); mid-run storage recruits get the full run's pending; drain
      also fires entering in-gate special rooms (early, safe). Flag indices
      $0168-$017F retired to the accumulator (EVENT_FLAGS).
- [x] **CF4 — freed-window layout + custom-state migration — DONE S65,
      USER-CONFIRMED S66 (test ROM v7 `de0c5a672e7e7e1fb834dd7afe70b9e7`,
      patched: "custom rooms work fine after WRAM move, no issues").** The S58 layout-rule remainder, executed with one
      correction: **the S58 "EXPLOIT" persistence decision is dead as-built
      and unrevivable** — the freed window's SRAM image ($A3BA-$AD9E) is
      CF3's live farm, so the S60 copy skips the window BOTH ways; nothing
      in it can persist via the vanilla block copy (DOC_AUDIT S65).
      Persistent state stays flags (32) + entry scripts; larger persistent
      state = SRAM expansion (E3). As built: wCustomNPCBuffer→$CC80,
      wCustomExitBuffer→$CD00 (label-only relink; bank $60 template TEXT
      unchanged, sha256 pins untouched); step-counter region $DE74→$CD80,
      default/max 640 B (region cap = the $D000 wram0 section boundary,
      validated); static `ds 7` keeps wRoomRecScratch at $DE7B; wCustomPool
      $D001-$D664 (1,636 B transient reserve); **init guarantee** — bank
      $73 entry 6 tail zeroes the window after the main-image restore copy
      (unique src end $B124), joining ClearAllWRAM (power-on) and
      CF3NewGameClear (new game): gameplay always starts window-zeroed,
      immunizing against data-as-code boot residue and making reload step
      state deterministic. audit_wram.py learned freed windows (F-class,
      S54 detection power kept via probe; arg guard added) + regenerated
      wram_usage.json. *Accept*: v7 smoke on the historical crash vectors —
      enter $6B/$6C/$70, NPC interact, exits both ways, step advance,
      save-in-room → reload → scroll (expect step-0), egg give in-room.

- [x] **FX1 — active farm expansion 17 → 37 slots — DONE S71,
      USER-CONFIRMED 2026-07-26 (farm menus >17, sleep whole-swap,
      save/reload, breeding + 21-hatch session: "everything works").
      Exp-scale VETOED same session → S71v2 restores the vanilla
      per-monster rate (drain pays full pending; pin `46ba6991…`,
      patched; v2 delta = payout only, PyBoy-verified both regions).** User decisions (S71): 37 active farm; whole-swap sleep
      (pool scaled to a FULL 40-slot non-party mirror); exp "scale" =
      payout halved at drain (each eligible farm monster gets pending/2 →
      aggregate 37/32 of total ≈ vanilla 17/16; per-monster growth is HALF
      vanilla's — flagged for veto); built incrementally. As built (owning
      section MONSTER_DATA "FX1 as built (S71)"): array = 40 slots (0-2
      party WRAM, 3-19 farm $A1FB+s*$95, 20-39 farm $B124+(s-20)*$95 = the
      EVICTED sleep pool's bank-0 home); sleep pool → SRAM BANK 2 ($A010+
      c*$95 ×40, "P1" magic) via bank $73 entries 10/11/12 (record swap /
      zero-init / census); staging pseudo-slot INDICES 20/21 → 40/41
      (computed-window remap in the rebase; ADDRESSES unchanged $D665/$D6FA
      so every address-based staging path is untouched); one-time "F2"
      reformat gate at $BFC8-9 inside entry 4 (ORDER LOAD-BEARING — see
      KEY_LESSONS S71); checksum v3 (3 segments, excludes $B124-$BCC7 too;
      heals vanilla/S60v1/S60v2); snapshot v4 "R4" dual-region ($A1BF ×95 +
      $B124 ×94 chunks, R3 auto-upgrade); roster display lists + the
      canonicalizer compaction map relocated $C0D8 → wMonList $D001 (40
      entries overflow $C0D8's ~36-byte safe extent). PyBoy-verified on the
      user's real .sav: reformat preserves the save; R3→R4 upgrade;
      canonicalize/compaction with 25 farm across the slot-19 boundary;
      farm list builds 28 entries incl. slots 20-27; reset-no-save rewind
      over BOTH regions; dual-region snapshot commit+restore across a power
      cycle; drain pays extended slots pending/2 and levels them; full
      battle round-trip clean. *User accept (visual/UI, not yet run)*: farm
      menu deposit/withdraw beyond 17 + browse/pages; sleep/wake whole-swap;
      explicit save → reload; trade receive; breeding; battle join with
      farm > 17; link viewer nav.

- [x] **CF3 — farm storage → SRAM + path redirects — DONE S60,
      USER-CONFIRMED 2026-07-17 (sleep/unsleep, breeding + reload,
      in-gate saves; "all tests normal").** Farm slots 3-19 live at
      SRAM $A1FB+s*$95; WRAM $CC80-$D664 freed; buffers legal in
      place; ≤14 rule RETIRED. Roster uniformly EAGER (checksum v2
      excludes $A1C7-$AD9E; canonicalizer-tail mirror). Pre-CF3 AND
      S60v1 saves self-heal at boot verify. See MONSTER_DATA "CF3 as
      built (S60)". ⚠ save states from pre-CF3 builds are invalid
      under CF3 (two-timeline splice — documented, unfixable).
      *Original accept:* full
      drop/pick/breed/give/library loop in SameBoy; WRAM $CBEB-$D664 free per
      audit_wram; custom buffers relocated into it; ≤14 rule deleted from docs.
      **STEP 1 DONE S58, USER-CONFIRMED 2026-07-14 (v2: farm multi pick/drop,
      breeding, full gate run + boss, party shuffles, save/reset; battle
      JOIN not explicitly exercised): party-first sort in the
      canonicalizer** — 2-byte operand hook at $01:$4809 ($0106→$7301) + bank
      $73 entry 1 CF3PartyFirstSort; invariant "party at slots 0-2 in list
      order, farm contiguous after" now holds after every canonicalize.
      **v2 (S58):** fixups = party list + $DA15-$DA17 cache only; the v1
      $CA40 fixup REMOVED ($CA40 is dual-role — also the farm drop/pick
      candidate register; rewriting it fed unguarded flag-marking paths).
      $CAC0, $CA40, $DA14 deliberately not remapped (analysis + watch items:
      MONSTER_DATA "CF3 step 1 as built"). Compiler regression re-pinned (v2)
      `d31c9300e13b98f516c6bee8b446069d` (patched; v1 `79dd32c5…` (patched)
      historical).
      **USER DECISIONS SETTLED 2026-07-13 (this conversation):**
      (1) party-first SORT chosen over index remapping;
      (2) save semantics of the freed range = **EXPLOIT** (keep the vanilla
      block copy; the range persists across save/load). **[REFUTED AS-BUILT,
      S65: S60's copy-skip excludes the window from save AND restore — its
      SRAM image is the live farm; unrevivable. See CF4 + DOC_AUDIT S65.]**
      Layout rule for the
      arc: transient scratch stays at $DE74; the relocated legacy NPC/exit
      buffers take a small corner of the freed range; the BULK is reserved
      as the editor's persistent-state pool (flag-allocator expansion of
      FLAG_SAFE_RANGES comes AFTER the redirects land — the space is not
      usable before then, see (b)).
      Remaining (order):
      (a) ~~party-first sort FIRST~~ DONE S58 (pending user test).
      (a2) NEW (S58): pre-sort save migration — loading an old save restores
      a vanilla-layout roster; force a canonicalize (or sort) on the load
      path before any walker redirect assumes slots 3-19 == farm.
      (b) THE REDIRECTS ARE THE GATE, the space is NOT incrementally usable:
      every all-slot walker reads the +$00 flags of slots 3-19 (first-empty
      scans, $C0D8 list builders, exp/level walkers, occupancy counts); one
      unredirected first-empty scan reading custom bytes as flags = a 149-B
      record written into custom state (the S54 crash class). Two shared
      idioms → two redirected helpers cover most sites (see
      monster_walkers.json).
      (c) Trade-receive inserts at HARDCODED slot 19 ($D5D0, $18:~$4CB0
      copy loop) — inside the freed range; redirect with the trade flow.
      (d) NEW (S58, confirmed by user repro + byte trace): the buffer overlay
      ALSO phantom-spawns monsters in EMPTY slots 15/16 (flags $D37C/$D411 =
      NPC buffer byte 3 / exit buffer byte 24 — well-room repro: 2 Drakslimes
      "0095" per visit; the S57 gate save's 4 fossils were this + the CF2
      drain leveling them). USER RULING S58: hazard re-accepted as-is on the
      exploration overlay (no interim flag-zeroing patch); the CF3 buffer
      relocation must retire BOTH facets (real-monster corruption AND
      phantom spawning). Stale $D478/$D479 step-counter comments in the
      bank_060 emitter output noted for the next compiler-touching session
      (labels resolve correctly to $DE74+; comments only).

### Arc LAYER A′ — vanilla-room coexistence (revised S55: vanilla rooms KEPT as postgame)
User decision (S55): the romhack occupies a NEW world (custom rooms); most
VANILLA rooms remain as postgame content, lightly edited (rewired
entries/exits, e.g. around the castle chokepoint). Consequences, replacing the
earlier "Layer A = replace vanilla" sketch: (a) the vanilla step-counter pool
$D92A-$D99A stays vanilla-owned — NOT harvestable; custom counters keep $DE74
(+ Cold-Farm-freed space later); (b) the **mapID ≥$80 audit is IN scope**: 75
custom rooms on top of $00-$6A cross $7F at custom room #22 — audit the engine
for sign-bit tests (`bit 7` / `add a` / `jp m`-class patterns) on wMapID/
wScriptMapType before content crosses $7F; (c) Layer A shrinks to "edit
vanilla room data in place" (bank $0B emitter per PROJECT_COMPILER §6
pattern) rather than wholesale replacement. Parallel-architecture rule
(user, S55): the hand patch overlay stays AS-IS for exploration (known ≤14
limitation); editor-era systems (Cold Farm, Layer A′) land in the compiler
pipeline — never retrofit the overlay.
- [x] **A′1 — mapID ≥$80 audit (DONE S66): engine is ≥$80-READY as patched.**
      No sign tests on mapID exist anywhere (SM83 has no sign flag; every
      comparison is unsigned `cp` — ≥$80 takes the branch already proven by
      $6B-$70). Real hazard classes were 8-bit `add a` carry-loss walks
      (RST_00 is $7F-capped by construction) and fixed tables — every
      instance is diverted ≥$6B / clamped / gate-context in the patched
      tree. Ceilings: hard $FE, practical $EA (sub-$6B 8-bit idiom); 75-room
      plan (max $B5) fits with margin. Census tool:
      `tools/audit_mapid_range.py` (SELFTEST-pinned, re-run before shipping
      rooms ≥$80). Full adjudication: CROSSBANK_ROOMS "mapID ≥$80 readiness
      audit". Follow-up (compiler-owned, do when first room ≥$80 ships —
      recipe in that section): extend CustomRoomBGMTable 128→256 + bank $71
      `cp $80` guard + music.py validator + template re-pin; add validators
      (custom-dest exits must have gate_flag=0; trigger_x≠$FF).
- [ ] **A′2 — bank $0B in-place room emitter** (Layer A of project.json).
- [ ] **A′3 — bank $60 multi-bank spill** (bank_map; 16 KB won't hold 75
      rooms of scripts+dialogue; 13 banks / 208 KB free).

### Phase 2 — Content format & compiler (the editor backend)
- [x] **Architectural keystone — table-driven custom-room dispatch (DONE S42, user-confirmed).**
      All remaining hardcoded per-room intercepts are now table-driven and the old `$6F` room
      ceiling is lifted to editor scale. Dispatch *logic* lives in the previously-empty bank
      `$71` (reached via `rst $10`) so every in-bank edit is byte-neutral. `$70+` rooms get
      their `$26DD` tileset/dims/threshold record from `Custom26DDTable` (bank `$71`,
      far-copied to `wRoomRecScratch`), sidestepping the in-ROM0 `$70`↔`$2A5D` gate-table
      collision. Encounters folded in (see Encounters #1). Proven by room `$70` (amber) added
      *past* the ceiling by table rows alone — renders, encounters, exits all confirmed.
      Owning doc: **EDITOR_DESIGN.md §2** (as-built map). This is the green light for
      `build_project.py`.
- [x] **`project.json` schema (DONE S53; fix-build NOT yet user-tested).**
      Layer B (custom) + Layer D (build): rooms/screens/NPCs/exits (dense
      mapIDs, records ≥`$70`, per-room render + encounters), scripts (op
      model, `@label` branches, symbol pass-through), dialogue (explicit
      `lines`, `auto` 18-cell wrap, `raw` escape; two-level table emitted;
      DTE deferred, matches proven hand text), palettes (placement a/b),
      wram step counters (auto-alloc reproduces hand addresses), named
      flags from the EVENT_FLAGS safe pool. Layers A/C + music/skills
      HARD-ERROR (never silently ignored). → **PROJECT_COMPILER.md §2**.
- [x] **`tools/build_project.py` (DONE S53).** project → generated
      `bank_060.asm`/`bank_071.asm` (sha256-pinned engine template heads)
      + `@BUILD_PROJECT` regions in `bank_017.asm`/`wram.asm` → stage →
      `make` → ROM + `manifest.json` + `game.sym`. Deterministic (emit ×2
      compared); bank accounting BEFORE rgbasm (pinned template sizes);
      KEY_LESSONS rules are validations (spawn script 0, screen_byte
      required, terminators, dense tables, flag pool, palette shape).
      Layouts/tilesets stay tool-owned ($64/$67 referenced, not compiled) —
      multi-bank spill deferred until content needs it (bank_map declared).
      18/18 tests. → **PROJECT_COMPILER.md §3–5, §10**.
- [x] **Regression baseline (DONE S53 — exceeded: byte-identity, not just
      behavior).** `editor2/example-project/project.json` re-expresses ALL
      current user-confirmed content (6 rooms, 21 texts, 10 scripts, 4
      palettes, enc/record rows, step counters); generated patched ROM ==
      S53 reference patched build, md5-equal (`--expect-md5`). The
      `build.compat.master_table_rooms` key pins legacy bytes; removing it
      emits the FIXED full-width script master table (+ shared no-op) —
      built S53, NOT yet user-tested; delta measured = bank `$60` + header
      checksums only. → **PROJECT_COMPILER.md §1, §7**.
- [x] **Encounters #1 — per-room toggle** (DONE S42, user-confirmed). `RoomEncTable`
      (bank `$71`, 3 B/room `[enabled, gateID, floor]`, indexed `mapID−$6B`) scanned by
      `CustomEncResolve` (bank `$71` entry 1) via the bank-`$0B` whitelist hook, replacing
      the hardcoded `cp $6B`. `$6B` reproduces its old gate-0/floor-1 behavior exactly;
      `$6C-$6F` silent; `$70` enabled (proof). Project fields per room: `encounters`,
      `gate_id` (0-31), `floor`. Spec in CROSSBANK_ROOMS.md.
- [ ] **Encounters #2 — custom monster pools**: 26-byte pool in a free bank +
      intercept of `EncounterMonsterSelect`'s pool fetch for custom mapIDs (or
      reuse a verified-unreferenced pool slot). Project fields: up to 5
      `{enemy_stats_id, weight}` + header template. Spec in CROSSBANK_ROOMS.md.
- [ ] **Preserved-systems flag-dependency audit + orphaned-trigger validator
      (ADDED S72 — EDITOR_DESIGN §1/§6 cite this box, but it had never been
      created).** The romhack keeps six vanilla islands (Arena, Shrine,
      Library, Vault, shops — EDITOR_DESIGN §1 table); any island that READS
      a vanilla story flag the new campaign stops SETTING will misbehave.
      Two halves: (a) one-time audit — for each preserved island, list every
      flag it reads (from `all_scripts.json` branch data + EVENT_FLAGS) and
      classify satisfy/strip/re-author; (b) the compiler's orphaned-trigger
      validator (EDITOR_DESIGN §6, spec'd since S13, never implemented) —
      when Layer A lands, error on any flag read by a kept script that
      nothing sets in the project. *Accept:* (a) a table per island in
      SIDEQUEST_MAP; (b) a failing fixture in test_compiler.py.

### Phase 2C — Gate generation (system mapped S37; see GATE_GENERATION.md)
- [x] **Custom room into the gate rotation** — BOTH halves done, user-confirmed:
      render (S39 gate-tileset room; S40 Pillar A — fully table-driven by mapID−$6B,
      no hardcoded cp $6B) + insertion (S41 Pillar B — GateDecisionFork at $16:$5BA9
      routes gate 1 → custom $6D; descent feel via transient wInGateworld=$01 during
      transition only). → GATE_GENERATION §7.1–7.5; archive: SESSION_HISTORY Part 3.
- [x] **Room-palette derivation from ROM** (S39) — derive_room_palette.py, validated
      30/30 SameBoy dumps + gate floor. → GATE_GENERATION §7.1.
- [ ] **`piece_id → screen layout` map** — decode the table turning a grid cell's
      high nibble into the rendered screen layout (needed to author NEW maze
      pieces vs. only reweighting existing ones). (GATE_GENERATION.md §12.2.)
- [ ] **Full `rst $00` dispatch enumeration** — list every special-floor handler
      slot so reusable slots are known precisely. (§12.3.)
- [ ] **`SetBrd_6744`/`SetBrd_6800` carve algorithm** — step-trace the maze
      connectivity guarantee. (§12.4.)

### Phase 2B — Breeding overhaul & extension (specced Session 12; see BREEDING_SYSTEM.md)
Keep 10 families. Defaults rewritten; special recipes extended to 1×–2× (→~1650).
Mechanism ROM-verified: relocate special table + scanner to free bank `$69`,
call via `rst $10`; rewrite family table in place (result = slot index, so the
compiler inverts `A×B→C` to slot order and rejects positional conflicts); bank
$16 edits same-size only (leave vanilla tables dead-in-place).
- [x] **B1 — Round-trip encoder (keystone)** — DONE S13: build_breeding.py --selftest
      re-emits BOTH vanilla tables byte-identical ($4B30 4126 B; $4974 444 B);
      reconciled 825/825 + 197/197 vs the hand-authored JSON.
      → BREEDING_SYSTEM; TOOLS_AND_DATA; archive: SESSION_HISTORY Part 3.
- [x] **B2 — Relocation harness** — DONE S13: bank $16 special scan replaced in place
      with `ld hl,$6900`+`rst $10` (zero shift); faithful scanner + table in
      patches/bank_069.asm sourced from the PATCHED bank_016 (rev-1 lesson: sourcing
      vanilla silently reverted S12's recipe). User-confirmed; saving OK.
      → BREEDING_SYSTEM; archive: SESSION_HISTORY Part 3.
- [x] **B3 — Capacity 1×–2×** — DONE S15: scanner walks to the $FF terminator, so
      appends past index 824 work (cap 1650); unshadowed proof recipe user-confirmed.
      SUPERSEDED as the bank-$69 emitter by B5. *Open follow-up:* fold the
      "base 825 == patched bank_016" assert into verify_integrity.py (tool
      self-asserts; the verifier does not run it — same note on B7).
      → BREEDING_SYSTEM; KEY_LESSONS S15; archive: SESSION_HISTORY Part 3.

### Breeding romhack plan (user goal — Session 15 signpost; test each part separately)
Target: rename the **??? family ($F9) → "Spirit"**, shuffle monsters out of ???
and Spirit-looking monsters in, and **fundamentally rewrite all recipes**. Monster
count stays 221 (shuffle + rename only → same-size byte edits, NO table expansion;
expansion would shift every species-ID-indexed table and is not needed). DWM2
sprite swaps are an independent same-size graphics job (does not touch this logic).
Verified mechanics (Session 15, grepped — do not re-trust): resolver is
special → family → **fallback = parent 1** (`$16` Step 4: `ld a,[$da6f]; ld
[$da71],a`). **??? has ZERO family-table defaults** and appears as a matcher in
only 2 of 825 specials (both as the *mate*: Slime×Boss→KingSlime,
Dragon×Boss→sp$29). So "??? × anything → itself" is the **universal fallback**
showing through, NOT a ???-specific rule — nothing special to dismantle; Spirit
recipes are pure authoring.

- [x] **B4 — Family-defaults rewrite** — DONE S16, user-confirmed: --emit-family
      authors the positional family table in place (1:1 + 444-byte zero-shift + shadow
      validation); 5-changed-byte proof set incl. Dragon×Dragon→GreatDrak.
      → BREEDING_SYSTEM; KEY_LESSONS S16; archive: SESSION_HISTORY Part 3.
- [x] **B5 — Full special-table authoring** — DONE S17, user-confirmed: --emit-special
      OWNS the whole special table (825 ROM base + in-place overrides + appends +
      whole-table first-match-wins shadow validator) → bank $69; bank $16 stays
      vanilla. Supersedes B3's emitter. Delivers the machinery; the recipe REWRITE is
      editor-authored content later.
      → BREEDING_SYSTEM; KEY_LESSONS S17; archive: SESSION_HISTORY Part 3.
- [~] **B6 — Family reassignment** — reassignment DONE S18, user-confirmed
      (build_family_reassign.py: same-size family-byte edits, ANY family incl. ???;
      reader gate cleared — eligibility is joinability + boss table, NOT family; three
      family representations documented). Dynamic-library POC superseded by B7.
      *Remaining, split out:* the rename / 11th-family work = B8/B9 below.
      → BREEDING_SYSTEM "B6"; KEY_LESSONS S18; archive: SESSION_HISTORY Part 3.
- [x] **B7 — Production library grouping** — DONE S19, user-confirmed zero-lag:
      build_library_table.py emits a build-time family→members table into bank $12
      free space + a zero-shift walker (zero far-loads/scratch RAM; vanilla blank-slot
      semantics; NUM_FAMILIES/256-id aware; specials 215–220 protected). *Open:* tool
      selftest not run by verify_integrity.py (see B3 note).
      → BREEDING_SYSTEM "B7"; KEY_LESSONS S19; archive: SESSION_HISTORY Part 3.
- [~] **B8 — ??? → "Spirit" rename** — trace SOLVED S20: the family "name" is an ICON
      font tile ($4F:$4110–$41A0, text bytes $10–$19, addr=$4010+byte*16), not a
      string. NOT taken — user decision: Spirit is ADDED (B9). Kept as the
      solved-trace record. → BREEDING_SYSTEM "Family icons"; archive: SESSION_HISTORY.
- [~] **B9 — Add an 11th family (Spirit)** — VRAM corruption FIXED (ClampFamIdx,
      ROM0) + Spirit whip icon SHIPPED on byte $19 / $4F:$41A0 (user-confirmed; the
      "free" $1A slot is runtime-blanked — not usable). *Open:* wire Spirit as family
      11 — $4D detail line, tab-strip 11th cell, $FA wildcard question,
      NUM_FAMILIES→11 in build_library_table.py, family reshuffle; tab-strip layout is
      the one UI nicety. → BREEDING_SYSTEM "Future — 11th family"; KEY_LESSONS
      "Spirit B9"; archive: SESSION_HISTORY Part 3.
- [x] **BUG — breeding-cutscene parent sprites** — FIXED S14: incomplete bank $0B
      labelization (3 raw pointer refs into the shift region) + one ref mislabeled to
      RoomScreenPtrTable; re-sectioned + repointed, user-confirmed.
      → KEY_LESSONS "Session 14 — Bank $0B repointing"; archive: SESSION_HISTORY.

### Phase 3 — Editor app (see EDITOR_DESIGN.md — PySide6, cross-platform, primary target macOS; S72)
- [x] **Walking skeleton + visual room display — BUILT S72, NOT yet
      user-tested** (`editor2/app/`: open project, toolbar + room list,
      **rendered room view** — real tileset/attr/palette from the last
      built ROM via `editor2/core/render.py` (symbol-driven, reuses the
      proven render_screen/decompress_lz/derive pipeline; EDITOR_DESIGN
      §11 Tier-1 as-built), NPC/spawn/exit marker overlay, zoom 1-3×,
      Fields tab, Build ⌘B off the GUI thread over the UNCHANGED core
      pipeline, Run ⌘R via the new cross-platform
      `editor2/core/emulator.py`, build-log dock, ROM-MD5 gate + emulator
      command in preferences; S72 late addition after the user's first
      run: RGBDS v0.6.1 preflight in builder + File → Set RGBDS folder —
      EDITOR_DESIGN "Toolchain preflight"). *Accept (machine half MET):*
      `editor2/tests/test_app.py --rom` opens the example project (7
      rooms), the room view renders pixels from an existing build
      (placeholders correctly skipped), and the GUI-path build is
      byte-identical to test_compiler's `REFERENCE_MD5` pin (GUI == CLI ==
      hand overlay); renderer emulator-validated (room `$6B` color set ==
      PyBoy in-game capture off the user's real .sav). *User half:* runs on
      the user's Mac (`pip install PySide6 Pillow; python3 -m editor2.app`), opens
      example-project, rooms display with correct tilesets, builds,
      launches SameBoy.
> **RE-SEQUENCED S90** per EDITOR_DESIGN v2 (§5 UI spec, §9 gap register,
> §10 milestones). One box = one session. Order is dependency-driven, not
> sacred: any box whose gap tags are closed may be picked. The old coarse
> boxes ("room canvas → … → world map", "game-data editors after Phase D")
> are replaced by P3.3-P3.15 below.

- [x] **P3.0 — CAPACITIES reference** [G-M] — **DONE S91, NOT yet
      user-tested.** `extracted/capacities.json` (ceilings + evidence +
      measured/documented status); owning-doc section = ROOM_DATA_FORMAT
      "NPC capacity & sprite-sheet budget (S91)". Measured: NPCs/screen-
      state = 8 HARD ($D7D2 fill $101; vanilla census max 8; 9th entry
      silently corrupts $D8D9+ script state vs control — no crash) + a
      SECOND ceiling found: per-screen distinct-sprite-sheet VRAM budget
      (order-filled; 8 light sheets fit, ~2-3 heavy exhaust; blanks on
      overflow, no crash). Screens/room: engine 16 (4×4 scroll math),
      vanilla max 12-declared/9-valid (mt $54-$59), screen_idx 8 render
      PyBoy-verified; custom schema currently 8. Residuals named in
      capacities.json `_deferred_measurement_boxes` (E6 text budget,
      gate slots, per-sheet tile counts, 4×4 schema extension).
- [x] **P3.1 — NPC sprite-id catalog** [G-B] — **DONE S91, NOT yet
      user-tested** (sheet itself user-classified in-session).
      `extracted/npc_sprite_catalog.json` + sheet + 137 per-id crops
      (`npc_field_sprites/`) via tools/dump_npc_sprite_catalog.py (solo
      render per id — mandatory, sprite-sheet budget). ZERO ids crash
      ($11 renders the King; the S70 crash was custom-room context,
      DOC_AUDIT S91). Categories (user, S91): 72 normal / 17
      boss_composite_fragment / 6 alias_of_00 ($4E,$4F,$F0-$F3) / 37
      empty / 5 glitch_invalid. Guardian cosmetic RESOLVED by catalog:
      $23 = boss-composite fragment (the "draconic" tile); NO GoldSlime
      field icon exists — closest intended look = blue slime $3A. The
      project.json sprite byte + stale `_sprite_note` are deliberately
      untouched (byte-neutral session); swap to $3A in the next
      project.json-touching session. npc_catalog.json phantom-step
      contamination found (DOC_AUDIT S91); dumper regen = residual.
- [x] **P3.2 — Bank $64/$67 emission behind project.json** [G-A] (S92, built, NOT yet user-tested) (the
      canvas prerequisite): layouts/attr ($64) + combined tilesets ($67)
      become compiler emitters driven by `custom.rooms[].layout` /
      `custom.tilesets[]` (wrapping tile_layout_compiler /
      build_combined_tileset is acceptable v1). *Accept:* the example
      project expresses its current $64/$67 content in project.json; the
      build is byte-identical to the pinned regression (or the pin is
      re-set in the same session with the example project updated —
      PROJECT_COMPILER rule); test_compiler green.
- [x] **P3.2b — Clone-to-custom room extractor** [G-J] (S92, built, NOT yet user-tested; single-version clone per user decision S92 — state variants are authored on top via states[]; rank-arming via custom.script_preludes because state selection reads the counter at destination LOAD, before its entry script — PyBoy-measured) (the fork
      mechanism, user decision S90): `extract_room.py` — vanilla room →
      full project.json custom clone (layouts/attrs/NPCs/exits/scripts
      decompiled), mapID auto-allocated, entrances repointed; per-island
      literal-mapID audit for the first clone of each preserved island.
      *Accept:* ARENA LOBBY cloned; clone reachable in-game via a
      repointed entrance, renders identical to vanilla, vanilla room
      untouched (clean MD5 unchanged); orphaned-flag list emitted;
      custom→custom clone of an example room also proven.
- [x] **P3.3 — Room canvas v1: paint + states + screen paging** [G-G
      CLOSED] — **DONE S93, built, NOT yet user-tested** (schema/emitter
      half landed S92; the GUI half + the §5.0 shell landed S93 — the
      first "editor as a product" session, user-directed). As built:
      live project.json renderer (pixel-identical to the ROM-built one on
      all 12 example screens), one-screen native canvas zoom 1-6×, 4×2
      mini-map with thumbnails + add/remove screen (record dims synced),
      state switcher (add / duplicate / duplicate-with-own-layout /
      remove; automatic states[] conversion), pencil/rect/fill/eyedrop
      for tiles AND palette slots with QUndoStack, tile picker with the
      collision threshold as the wall boundary, palette panel (idx1/idx3
      locked), layers (grid / palette slots / walkability / markers with
      the S91 sprite crops), "Make editable" for vanilla layout refs,
      inspector (room / screen & state / selection / layout users),
      byte-exact save, shell tabs + Build/Play/Validate/History.
      *Accept MET (machine half):* `editor2/tests/test_canvas.py --rom` —
      paint + 2-state room authored through the GUI code path on a copy
      of the example project; Build; PyBoy VRAM tilemap == canvas grid
      320/320 in BOTH states (step-counter poke), also re-run on the
      user's .sav for the delivered test ROM. *User half:* open
      example-project on the Mac, paint, add a state, Build, see it.
      Residuals (named boxes, none block P3.4+): (a) palette-slot grids
      are per SCREEN, not per state (engine CustomAttrCheck base/base+2;
      KEY_LESSONS S93) — per-state attrs = an engine change (table-driven
      attr per step entry in bank $17/$71) if ever wanted; (b) the
      base+2 attr stride means a multi-screen room's attr items must sit
      exactly 2 entries apart in custom.layouts — the inspector shows the
      grid in effect and warns, the editor does not yet auto-arrange it
      (an "attr set" abstraction or the same engine change fixes it);
      (c) new-room / clone-room / delete-room actions (EDITOR_DESIGN §5.1
      "Room actions") not yet in the GUI — extract_room.py is the backend;
      (d) NPC/exit editing = P3.5/P3.7 (markers are click-to-inspect,
      read-only); (e) rooms $6B-$6F keep hand-patched bank_000 records, so
      their tileset/threshold/size are read-only in the editor (migrate
      them to records = a byte-changing session with a re-pin); (f) 4×4
      screen grid stays a schema residual (capacities.json).
- [x] **P3.3b — Room canvas v2: the room model done right** — **DONE S94,
      built, NOT yet user-tested** (user direction: the editor must not
      be built around the POC content; vanilla vs custom room columns;
      player-sized 4-subtile cells; Select as the basic tool; walkability
      mode; the 4×2 grid was a schema leftover). Landed: vanilla column
      (98 rooms live, read-only) + "Make editable" clone-with-confirm
      (paintable at once) + custom column with New / Copy / Rename /
      Delete + File → New project (blank template); metatiles (found-in-
      room + my metatiles + editor) as the unit; Select-first with real
      selection outlines; Walkability mode (bottom-right-subtile twin swap
      — engine measurement in ROOM_DATA_FORMAT; vanilla tileset copied into
      the project); 4×4 grid + schema; ENGINE: vanilla-format per-(screen,
      state) attr + palette tables (CustomAttrCheck/CustomPalCheck rewrite)
      and compiler-owned ROM0 records for $6B-$6F (`record` required
      everywhere). **S94b (same session): ENTRANCE REDIRECTS** — "Route a
      vanilla door here…" (inspector Entrances group / vanilla-view exit
      marker) writes `custom.entrance_redirects[]`; the compiler rebuilds
      that (room, screen)'s exit list per valid vanilla step with only
      that door re-pointed (per-(map, screen) `VanillaExitExtTable` rows,
      bank $0B Entry 9 diverted too, template re-pinned; pin `fc1caa98…`).
      Vanilla rooms browse EVERY valid step; clones carry all of them as
      states[] (per-state layout/attr/palette). *Accept MET (machine
      half):* `test_canvas.py --rom` — fresh project → Farm clone → paint →
      wall/open cells → Library door routed to the clone → PyBoy: VRAM ==
      canvas, player blocked / walks through, walks through the GreatTree
      Library door into the clone at the authored cell, the neighbouring
      door still vanilla. *User half:* open the editor on the Mac, clone a
      room, paint, flip walkability, route the Library door to it, Build,
      walk through that door in SameBoy.
      Residuals: (a) ~~no in-game route~~ closed S94b (redirects); the
      exits editor proper (custom-room exit rows, return doors, world
      graph) stays P3.7; (b) ~~S92 Library-door POC repoint in the hand
      overlay~~ closed S94b (vanilla bytes restored; the repoint is example
      data); (c) bank $64 capacity: clones localize every screen's
      layout (~200-500 B each compressed; a clone with N states adds N-1
      more) — the capacity meter landed S96 (status bar); still needed eventually: layout spill into
      a second bank (the step entry has a bank byte, so it is compiler
      work only); (d) NPC editing = P3.5; (e) walkability fallback when
      the wall side of a tileset is full moves the threshold (remaps
      layouts) — works, but a per-tileset "free slots" meter belongs in
      the picker — S95 added the import-time free-slot report; (f) ~~vanilla rooms show step 0 only~~ closed S94b
      (valid-step filter in `editor2/core/vanilla.py`); (h) S95: the
      metatile picker keeps the room's whole VOCABULARY (never shrinks) and
      borrows tiles from any vanilla room under this room's palettes
      (same tileset = brush, other tileset = import into free slots);
      old projects migrate their missing $6B-$6D records on open; S95 round
      2: `screens[k].palette` + "palette here" selector + copy-from-vanilla
      palettes, GUI exits (see P3.7), Borrow tab;
      (g) NPC thumbnails
      are the S91 throne-room crops with the floor knocked out in the
      editor — a transparent-background census (OBJ-only capture) and
      whole-boss composites belong to P3.5's sprite picker.
- [x] **P3.3c — Tileset slot map + vocabulary release** — **DONE S96,
      built, NOT yet user-tested** (acceptance MET in test_canvas v3: the map's
      free count == `Document.used_tiles`; a GreatTree-sheet import fails with 8
      free and succeeds after release (125); re-protect restores 8; overwritten
      vocabulary flagged red in "This room"). Original spec (user direction S95): the 128-tile-per-room budget is a hard engine limit
      (one 2 KB sheet per room, ids ≥ 128 are font/HUD), and today the
      only feedback is the import error text. Build a slot-map panel for
      the room's tileset: 128 cells with the collision threshold drawn
      (wall half below, walkable half above), coloured PLACED (on any
      screen/state) / VOCABULARY-ONLY (protected source tiles not placed)
      / MY METATILES / ANIMATED 77-78 / FREE, hover = which screens use
      it, click = highlight every cell on the canvas using that tile. Add
      "Release unused vocabulary" (un-protect vocabulary-only tiles so
      imports/twins may take their slots — the picker then marks such a
      metatile as "graphic may change") and its inverse. Show free counts
      per side ("12 wall / 40 walkable free") in the picker header and in
      the import error. *Accept:* on a Servant clone the map reports the
      same numbers as `Document.used_tiles`; releasing the vocabulary lets
      an import succeed that failed before; re-protecting restores the
      count; a released tile that an import overwrote is visibly flagged
      in "This room's tiles". Files: new `rooms/tileset_map.py`,
      `Document.release_tiles/protect_tiles/tile_usage`, picker flag.
- [x] **P3.3d — Rooms group A: tilesets + PNG art import + space meters**
      — **DONE S96, USER-CONFIRMED 2026-09-25 ("Everything works")** (user: "finish out the rooms
      stuff … do all of A"; EDITOR_DESIGN §5.1 "S96 additions"): Change
      tileset (vanilla / project / blank) + New room with a blank sheet;
      **Import art tab** (per-panel grids with nudge/auto-align, mask, walls,
      key colours, palette fit with keep, GBC preview, stamp with spill onto
      new screens — a whole DWM2 town in one import); metatile palettes per
      subtile; bank $60/$64/$67/$71 space meters (closes P3.3b residual c's
      "capacity meter"); **"Make editable" fixed for all 98 vanilla rooms**
      (extract_room script bank, handler-derived opcode arity for all 102
      opcodes, 4×4 attr lookup, per-screen palettes; test_canvas all-clones).
      *Accept (machine half MET):* test_canvas v3 + `--rom` (imported screen
      VRAM == canvas, BG palette RAM == project palette, WALL cell blocks) and
      the all-clones sweep. *User half:* import a DWM2 panel on the Mac, mark
      walls, stamp, route a door, walk it in SameBoy (test ROM
      `DWM-S96-pei-import-test.gbc` = Pei behind the Library door).
      Residuals: (a) ~~forced colour 1~~ **DONE S96 round 2** (user: "extra
      colour would be good"): `FreeColor1Hook` + `free_color1` palettes
      (three own colours per slot in custom rooms; PyBoy: palette RAM ==
      project incl. colour 1, system slots 4-6 still cream, holds across
      scrolls; menus/battles re-enter the same load path — user SameBoy
      check still wanted); pin `07a71f20…` (patched);
      round 4 (USER-CONFIRMED 2026-09-25 ("Everything works")): user SameBoy found the menu
      washing the room out + colour-1 squares in the menu wipe → per-slot
      markers kept in the buffer + bank $73 `MenuOpenFreePal` (menu, INFO,
      scrolls, battle PyBoy-verified); pin `5db25d15…` (patched);
      round 3 (USER-CONFIRMED 2026-09-25 ("Everything works")): walkability left to the author
      (only Wall-marked cells bind a side; strict mode optional), import-tab
      "New room…", `EDITOR_REVISION` in the title bar;
      (b) import allocates tiles only, it never removes stale ones (the slot
      map shows them); (c) flipped/mirrored duplicates in a rip cost separate
      slots (DWM1 attrs carry no flip bits — vanilla census values 0-3 only).
- [ ] **P3.4 — Embedded PyBoy preview panel** [G-E] (EDITOR_DESIGN §7
      Tier 2): Build → cached post-boot savestate → warp to the room under
      edit → frames in a Qt widget with input. *Accept:* one click plays
      the room being edited, < 10 s from Build-done to walkable.
- [x] **P3.5a — Declarative room-state rules** — **DONE S97, built, NOT yet
      user-tested** (user: "all of group B"; terms are AND-ed flag set/clear
      conditions — "Flag A set and Flag B set but C NOT set"). As built
      (PROJECT_COMPILER §2.13): ROOM-level ordered `state_rules` (first match
      wins, optional `screens`, trailing unconditional rule = "Otherwise"),
      bank $60 entry 8 `CustomStateRules` called from bank $17
      `CustomAttrCheck` FIRST (the attr/palette walk reads the counter before
      Entry 0 — measured; A/B proven) and from `CustomReadStep`; inspector
      rules group + "State shown when" line. Also the persistence fix: custom
      counters are transient, flags are saved. *Accept MET (machine half):*
      test_canvas v4 --rom — servant clone, flag clear/set selects layout +
      palette + NPC set, wiped counter re-selected, flag cleared + otherwise
      → state 0; example project's rank demo moved from the prelude to a rule
      (pin `6e97fd37…`, patched). *User half:* test ROM
      `DWM-S97-npc-rules-test.gbc` (fire out → save → reload → still out).
      **Split out (user OK'd S97): "a redirected door arrives in the chosen
      state" → P3.7** (exit rows have no spare byte; needs exit-path code).
- [x] **P3.5 — NPC inspector** — **DONE S97, built, NOT yet user-tested**:
      Add NPC here / drag to move / delete, sprite picker (S91 catalog),
      facing, the 13 MEASURED behaviours (bank $06 NPCBehaviourTable decoded +
      re-sectioned S97; ROOM_DATA_FORMAT "NPC behaviour types"), hidden bit,
      script binding + plain talk text, per-state presence checkboxes, walk
      path overlay, vanilla NPCs read-only in the same form. "Flag gating" =
      states + state rules (P3.5a). *Accept MET (machine half):* test_canvas
      v4 --rom — an NPC authored through the panel code path has the chosen
      sprite/type byte in RAM, the pace_x1 walker visits exactly x−1..x+1, the
      talker shows its GUI-authored text and turns to the player.
      Residuals: (a) how vanilla REVEALS a hidden (bit-6) entry — candidate
      `$0D` WriteNPCByte on field 0, unmeasured; (b) the named-flag pool is
      16 flags (EVENT_FLAGS safe range) — campaign scale needs the E3 SRAM
      flag schema; (c) walkers ignore walls (engine fact) — the editor warns
      but cannot prevent; (d) per-screen sprite-sheet VRAM budget is still a
      warning count, not a measured per-sheet meter (capacities residual);
      (e) scripts beyond plain talk are edited in P3.6/P3.8.
      **S97 round 2 (user test of r1; built, NOT yet user-tested):** text
      boxes stay cream in free-colour rooms (dialog + YES/NO box attrs, bank
      $73 entries 14-18, pin `ce24de8b…` patched); talk text authored per box
      with the ROM-font preview (the measured 16/18-cell, 2-line rules; the
      `boxes` form waits per box) — this delivers P3.6's preview/wrap/page
      core for PLAIN talk text; NPC section of its own, panels start folded;
      new-flag selection fixed. Open (offered, awaiting the user): an NPC
      "sets flag X when talked to" option — nothing in the GUI sets a flag
      yet. *User half:* `DWM-S97-r2-textbox-test.gbc`.
- [ ] **P3.6 — Dialogue editor**: WYSIWYG pages with ROM font tiles, live
      wrap/DTE/page-split, YES/NO branch wiring. (S97 r2 built the per-box
      editor + ROM-font preview for plain talk text — `talk_editor.py`;
      remaining: choice texts + branches, DTE, $EB indented opener, names.) *Accept:* GUI-authored
      multi-page + choice dialogue renders in-game byte-exact to preview.
- [ ] **P3.7 — Triggers/exits editor + World graph v0** (+ S97 carry-over from
      P3.5a: a door that arrives in a chosen STATE — needs exit-path code,
      e.g. a per-door flag set by bank $60 entry 7 before the transition): interact/spawn/
      exit editing incl. vanilla_exit_extensions; read-only world graph of
      rooms/warps. *Seeded S95:* "Add exit at this cell…" / "Delete this
      exit" (custom-room exits, PyBoy-verified) + entrance redirects (S94b)
      are the two halves; still needed: a DOOR object that owns both ends
      (auto return exit, drag-to-move), spawn-point editing, edge-vs-scroll
      conflict check on the canvas, and the graph. *Accept:* a custom↔vanilla
      door pair authored in the GUI works in-game; the graph shows it.
- [ ] **P3.7b — Gates tab** [G-F partial]: per-gate config-row editing
      (floors/weights/pool binding — Layer A-lite rows), custom-room-at-
      depth-N insertion surfaced (built S41), boss floor (template +
      boss EID script param + Set-2 coherence), entrance + unlock
      trigger. *Accept:* a vanilla gate's floor count + pool edited and
      a custom room inserted at a chosen depth, all from the GUI,
      verified in PyBoy descent.
- [ ] **P3.8 — Cutscene storyboard + playback** [G-H]: symbolic stepper
      over ops, blocking keyframes on canvas, virtual flag/inventory
      branch walking; playback via P3.4. *Accept:* the S70 demo quest's
      entry cutscene is legible & editable in the storyboard; an edit
      round-trips through compile_script and plays.
- [ ] **P3.9 — Layer A-lite gamedata backend** [G-D]: `gamedata.monsters/
      skills/breeding/encounters` emitters as same-size table patches;
      readers ported from randomizer/romdata.py. *Accept:* unedited
      gamedata → ZERO byte diffs (per-table regression); one stat edit
      lands in-game; test_compiler extended + green.
- [ ] **P3.10 — Monsters tab** (needs P3.9): stats/growth/ai_weights/
      learnset forms + battle-sprite and follower pickers over the GFX
      stack; new-species wizard hooks Phase N (G3 fold folded here or
      ticked separately). *Accept:* a vanilla species stat+sprite edit and
      a follower reassignment authored in GUI, verified in PyBoy.
- [ ] **P3.10b — Arena editor** [G-L] (E1→E2 wiring, promoted from
      Phase E): tiers×matches×slots grid over enemy-stats rows 224-304 +
      King 481-483 (stats/skills/ai_weights per enemy via Layer A-lite);
      victory cascade shown read-only. Bracket-shape constants = expert
      knob only. *Accept:* one arena match's team re-authored in GUI and
      fought as-authored in PyBoy.
- [ ] **P3.11 — Skills tab**: the S74 knob surface as forms with the
      invariant validators (MP pair sync, budgets, table existence).
      *Accept:* a custom skill's damage tier + description edited in GUI,
      verified in battle in PyBoy.
- [ ] **P3.11b — AI ban-list (OPTIONAL)** [G-N]: measure the clean
      knows-it-never-casts-it mechanism (option-list filter in the AI
      build path; per-actor or per-skill ban table in a patch bank),
      then the per-boss checkbox UI. *Accept:* a boss with HealAll
      learned NEVER casts it across a scripted battle corpus; field-only
      skills confirmed already rejected (S73b).
- [ ] **P3.12 — Breeding tab: edit + simulation** (needs P3.9): table
      editor over the B1-B7 stack + the randomizer-derived tree explorer
      (depth profiles, reachability, orphans; live re-sim on edit;
      coherence Set 1 live). *Accept:* an added recipe shows correct tree
      placement + depth in the panel and works at the Starry Shrine in
      PyBoy.
- [ ] **P3.13 — Encounters + Music tabs**: (a) Encounters cross-view +
      per-room pools — requires **Encounters #2 custom pools** [G-C]
      (the Phase-2 box, folded here if not done earlier) — PLUS
      **flag-keyed pool variants** [G-O] (bank-$71 RoomEncTable resolver
      extension; the Triggers backend); (b) Music library/assignment
      matrix + MIDI import UI + audition harness [G-I]. *Accept:* a
      custom pool authored in GUI spawns in-game; a trigger flips a
      room's pool variant in-game; a MIDI-imported song assigned to a
      room plays on entry.
- [ ] **P3.13c — Shops (E8, promoted from Phase E)** [G-K]: decode the
      stock/price table (opcode $04 sub 0 → bank $09; expected shallow
      per user S72), `gamedata.shops` emitter, shopkeeper-NPC click
      surface. *Accept:* a changed price + item list visible in SameBoy;
      a NEW shopkeeper in a custom room sells an authored list.
- [ ] **P3.14 — Progression & Flags tab**: flag manager (named flags,
      cross-ref), quest editor forms over progression.quests, orphaned-
      trigger report, **Triggers-as-sentences authoring** (EDITOR_DESIGN
      §5.1c; compiles to flag branches / state advances / show-hide /
      [G-O] pool variants). *Accept:* the S70 demo quest is fully re-authorable
      in forms; report lists preserved-island dependencies.
- [ ] **P3.15 — Balance tab** (simulator-as-a-service): TTK/pacing sweeps,
      what-if deltas on gamedata edits, obedience curves; unvalidated
      subsystems greyed. *Accept:* a stat edit shows its TTK delta for an
      affected pool before Build; numbers match a CLI sweep_ttk run.
- [ ] **P3.16 — M2R bifurcation** (one of the only remaining in-place
      vanilla edits under clone-to-custom, EDITOR_DESIGN §6.3): the
      dresser repoint + Terry-intro strip, authored via the World tab. *Accept:* new game →
      dresser → Milayou's first custom room in SameBoy; preserved-island
      flag audit run.
- [ ] **CONTINGENCY (banked, not scheduled) — ROM expansion 2→4 MB**:
      assessed S90 (EDITOR_DESIGN §6.4) — MBC5 8-bit ROMB0 covers 256
      banks; needs header size byte + link layout + a stored-bank-number
      audit. Open ONLY if the 176 KB free + spill ever runs out. NO
      prior session built or promised this (the expanded thing is SRAM,
      S69).
- [ ] **P3.17 — Packaging**: per-OS bundles with RGBDS v0.6.1 bundled,
      signed macOS `.app`. *Accept:* a fresh Mac with no dev tools opens
      the example project, builds, plays.

### Phase D — Disassembly deepening (parallel; pick when blocked elsewhere)
Driven by what the editor must EDIT, not completionism:
- [x] **Annotate the new-species fork SEAMS in clean disassembly** — DONE across
      S30/S33/S38 (labels/comments only, build byte-perfect each time): info indexer
      ($03 label443f/SaveMon_4446), enemy stats ($14 LoadEnemyStats +
      EnemyStatsTrailingFree @ $7EAD — EIDs 487–517 unusable, first slot EID 518),
      encounter pool ($01), breeding sites ($16 label16_485c + the two $0301
      parent-family loads), the 8 follower gfx-ID copies, and the name/text/lineage
      chain ($41 / ROM0 $092F / $12 / $4d). Corrections recorded: ItemNamePtrTable =
      mode 8 (not 11); $4739 overshoots at id≥215 (fork covers ≥224).
      **STILL PENDING (own pass, general breeding mechanics — NOT a new-species
      seam):** bank $16 breeding-determination internals (LoadBrd_4653 plus/special,
      LoadBrd_45d5/45ff family scan, special→family→pedigree precedence).
      → MONSTER_DATA "Species ID geography"; archive: SESSION_HISTORY Part 3.
- [x] Bank $03 monster table → `db` ✅ VERIFIED S51: `MonsterInfoTable` +
      per-monster `MonsterInfo_NNN_Name:` labeled `db` blocks (stale box; the
      conversion had already landed in an earlier pass).
- [x] Bank $14 enemy stats + boss tables → `db` ✅ VERIFIED S51: `EnemyStatsTable`
      + per-EID `EnemyStats_NNN:` labeled field-commented `db`/`dw` blocks.
- [ ] Bank $01 encounter pools → `db` (editor-driven — Encounters #2)
- [x] Bank $16 breeding tables → `db` ✅ VERIFIED S51: `SpecialRecipeTable` +
      `FamilyRecipeTable` labeled `db` blocks.
- [ ] Bank $51: annotate transitions + prove/disprove the 1,228 B
      free block is reference-free
- [ ] Bank $50 event state machine (story events)
- [ ] Save/SRAM code annotation (supports Phase 0 audit)
- [~] **Re-section misassembled data tables → labeled `db`/`dw`.** mgbdis rendered
      many in-bank DATA tables as fake instructions — they build byte-identical but
      can't be edited in source; this bit S14 ($0B tables), S18 (library bounds), S22.
      Convert per table with the probe-build line→address method (no opcode-size
      summing — the S22 trap); **build MUST stay `1ca6579…` after each**.
      Bank `$12` COMPLETE (S26+S27: bounds table, tab-column tables, all 29 window
      layouts → library_layouts.json). → DATA_STRUCTURES "Library / family-tab menu
      data (bank $12)"; TOOLS_AND_DATA; archive: SESSION_HISTORY Part 3.
      **NEXT (per-session, one each):**
      (1) ✅ bank `$12` — DONE (S26/S27).
      (2) ✅ STALE BOXES verified + ticked (S51): bank `$03`/`$14`/`$16` were
          already `db`-converted.
      (2b) ✅ DONE (S51): `SkillMPCostTable` ($07:$570C, 222×`dw` with per-skill
          name/MP comments) + `SkillLearnReqTable` ($06:$50E0, 222×18B `db` with
          decoded stat/prereq comments) re-sectioned in BOTH trees via the new
          `tools/resection_skill_tables.py` (probe-build; clean build byte-perfect;
          verifier PASS 4/4). Two fake-decode artifact labels (`DispMapS_566b`,
          `label6_6034`) are kept at exact offsets — they're referenced by fake
          instructions in not-yet-re-sectioned regions of bank `$06`.
      (3) **Editor-driven only:** bank `$01` encounter pools (Encounters #2), bank
          `$51` transitions, bank `$50` event state machine — when the feature needs them.
      (4) **Checked, SKIP (no editor value, mis-split risk):** the `$ff`-padding banks
          `$08/$15/$2c/$33/$55/$66` — mostly filler, not discrete tables.
**STALE BOXES (verify + tick):** the first three boxes above (bank $03 monster
table, $14 enemy stats/boss, $16 breeding) appear ALREADY `db`-converted on disk
(bank_003/014/016 are heavily `db`/`dw` with labeled loaders). Confirm against
disassembly and check them off.

- [x] **GFX-1 — Sprite codec + gfx-table re-section** ✅ S22 — MonsterBattleGfxTable
      $00:$2B9F re-sectioned (23 cross-refs preserved); dwm/sprite_codec.py (decode
      byte-exact; decode(encode(x))==x on all 442 streams; round-trip is SEMANTIC by
      design, not vanilla re-encode); extract_monster_sprites.py (all 221);
      build_sprite_swap.py; Dracky→clam swap user-confirmed.
      → MONSTER_DATA "Monster sprite graphics system"; KEY_LESSONS S22; archive: SESSION_HISTORY.
- [x] **GFX-2 — Palettes + cross-bank sprite backbone** ✅ S23 — dwm/sprite_bank.py
      overflow allocator ($7E,$7F then $7C,$7A,$79; resolver has no bank gating →
      any of 221 monsters repointable); MonsterBattlePalettes @ $17:$62FD SOLVED
      (was mislabeled RoomAttrDataBlocks; 8 B/species, loaded by $17 entry 6);
      recolour = same-size 8-byte edit. User-confirmed (clam→Dracky purple + full
      integration ROM). → MONSTER_DATA "Monster battle palette system"; KEY_LESSONS
      S23; archive: SESSION_HISTORY Part 3.
- [x] **GFX-3 — Follower/walking sprite swap** ✅ S24 — ScreenTransDataTable
      $01:$49DF re-sectioned; metasprite render engine reversed (SaveScr_40cd:
      4-byte dy,dx,tile_offset,attr entries, $80-term; OAM tile += $ffc9 base
      $20/$30/$40; attr XOR $ffca; **OBJ idx0 = hardware-transparent** — opposite of
      the battle BG path); 118-layout library + follower_frame_picker.html +
      numbered-tile calibration method. User-confirmed all 4 directions.
      → MONSTER_DATA "Follower / walking-sprite system"; KEY_LESSONS S24; archive: SESSION_HISTORY.
- [x] **GFX-4 — Species→layout auto-map + custom-art import** ✅ S25 — level-1 layout
      tables LOCATED at $10/$11:$407f (+ per-species attr tables $10:$417f/$11:$412d);
      155 complete layouts (monster_follower_layouts.json); the **8 follower gfx-ID
      table copies** discovered ($01 $06 $07 $09 $0b $12 $18 $59 — a swap repoints
      ALL 8); build_follower_reassign.py (clone or custom-art import; reassignment =
      level-1 repoint, NOT a [$caca] edit). User-confirmed across overworld+menu+library.
      → MONSTER_DATA "Monster → layout dispatch"; KEY_LESSONS S25; archive: SESSION_HISTORY.

Raw audio banks ($5A, $63…) stay LOW priority. **Graphics banks ($32–$3A are NO LONGER
low-priority** — the monster sprite system there is editable and proven; see GFX-1/2/3 above.

---

## Definition of editor v1
A user with zero ASM knowledge builds: a custom room with their own layout,
NPCs with flag-gated branching dialogue, an item + monster reward, a warp
between two custom maps, a BGM change — clicks Build, plays it in SameBoy.
Everything except encounters/custom-art is already proven at ROM level;
the gap is formats and UI, not reverse engineering.

---

## Definition of a NEW CAMPAIGN (beyond editor v1) — Phase E gap analysis

Editor v1 (above) deliberately scopes to rooms / NPCs / dialogue / items / warps /
BGM — all proven at ROM level, so "the gap is formats and UI, not RE." **Fundamentally
writing a NEW CAMPAIGN** (a new questline, a new challenge progression, a new world —
not just editing the vanilla one) needs additional load-bearing subsystems that are
currently under-addressed. This section is the Session 27 gap analysis: each item gives
current state (grounded in the repo), why it is campaign-critical, where it is outlined
(if at all), a confidence level, and the owning doc / next step.

### Phase E — Campaign-scale subsystems (the "new campaign" gaps)
Priority: **E1 and E2 are the keystones** (E1 is the one true remaining RE gap; E2 is
the authoring-model backbone). E3/E4 are important; E5/E6 are lighter.
E7–E9 ADDED S72 (the gap-absent-from-scope audit): **E7 (Milayou player art)
is campaign-BLOCKING** — the POV flip cannot ship without it; E8/E9
(shops, items — incl. the WarpWing spec) are likely-shallow RE+authoring.

- [x] **E1 — Arena / gate-boss ROSTER data format — DECODED S67; arena path
      USER-VERIFIED on HW (SameBoy watchpoints: Class D wrote $DA02=$02 at
      $04:$5D8E, EIDs 251/252/253 = exact formula; $DA09=$01 by opcode $20 at
      $04:$5E69).** Headline: there IS no arena roster table — parties are
      FORMULA-addressed consecutive enemy-stats rows, `EID = $E0 +
      9*wArenaGroup + 3*wColiseumBattle + slot` (opcode $1F ArenaBattleSetup
      $04:$5D5B + bank $50 clone; groups 0-7 = G..S, 8 = Starry Night, 9 =
      King override $01E1-$01E3). Gate bosses are the opcode `$5A`/`$05` EID
      param in each boss ROOM's script (53-site census; Medal Gate has 3
      variants; Durran gate = Servants×2 → Terry 343 → Durran 199, all found);
      `$14:$4893` is only the fight→join RECRUITMENT redirect — the "boss
      table" framing was wrong semantics (DOC_AUDIT S67). In-gate Coliseum +
      Mimic + opcode-$52 battles are RNG (level-banded windows; Mimic tier =
      `$CAB4` = arena progress). Per-class VICTORY cascade (rank+catch-up
      flags, `$CAB4`, world step counters) extracted from Arena Lobby scr0.
      Owning prose: SIDEQUEST_MAP "Arena / gate-boss ROSTER format — DECODED
      S67"; data pair: `tools/dump_arena_brackets.py` →
      `extracted/arena_brackets.json` (self-checking); authoring spec for the
      E2/project.json wiring is in that section (arena bracket = rows
      224-304/481-483; boss = script param + redirect pair + stats row;
      bracket SHAPE changes = patch the formula constants). Residuals (minor,
      banked): `$DA09` modes 0/2/3 code-derived; intro Dracky (EID 4) trigger
      is engine-side; matches-2/3 re-entry loop not single-stepped (bank $50
      regen HW-observed). Byte-neutral session (clean build `1ca6579…`).

- [x] **E2 — Story progression as an AUTHORABLE model. COMPLETE S70,
      user-confirmed** (RE half + spec S68; schema wiring + demo quest +
      bug-fix pass S70, pin `a5a5e0d5…`). As built: `progression.quests[]`
      + `progression.enemies[]` lower to generated quest:/entry: scripts
      (condition ladder, YES/NO offer, trigger_battle3, init_dialog'd
      on_win tail, entry cutscene with seen/done gating) + bank $14 quest
      EID rows (519+, 12-row tail capacity); `custom.vanilla_exit_extensions`
      adds doors to vanilla rooms via bank $60 entry 7 (VanillaExitExtTable,
      step-counter variants). Demo: Medal Chamber ($71, GoldSlime L30 boss,
      joins on win, Castle re-arm on loss) — full round trip PyBoy-proven +
      user-played. Flag capacity: safe pool ($0158+) auto-allocation; the
      32-flag audit remains an E3-adjacent follow-up. Cosmetic residual:
      NPC sprite-id catalog (guardian renders draconic; species+$10
      disproven). S68 RE facts below remain the reference. S68 decoded, all ROM-byte-verified: wGameMode $C88A +
      the two ROM0 mode tables ($030F/$050F); bank $50 = BATTLE mode
      manager; $D9EC = 18-phase battle machine (BattlePhaseTable $5F3A,
      phase labels in both trees); $D9F4 = nested battle sub-machine (the
      old "11-state event machine" framing was wrong — DOC_AUDIT S68);
      $DB55 outcome 0/1/2 + bank $52 KO scans; **the win→script-resume
      guarantee** ($C8EA.7 makes bank $01 skip the script-state reset, so
      post-battle-opcode commands = the on-win rewards) and the LOSS path
      ($D92B=8, Castle warp, gold/2, item drop with keep-on-defeat bit
      +$0B.2 — TinyMedal/BeastTail/WarpStaff/ShinyHarp/BookMark, user FAQ
      list verified); the evaluation opcodes resolved ($CA8D = party count,
      $FF92 = hPlayerX, $D8E1 = 10-opcode evaluator family — census in
      BANK04_SCRIPT_ENGINE). **Remaining (wiring, weak-model-safe):**
      `progression.quests[]` schema layer in project.json that GENERATES
      room scripts (condition ladder + battle opcode + on_win tail) through
      the existing compiler — spec'd in SIDEQUEST_MAP; plus capacity
      (32-flag pool → E3 or audited vanilla-flag reuse). HW-pinned same
      session (user SameBoy): flee → $DB55=2 neutral (no penalty, resolver
      $50:$5808), caught → win 0, $C899/9A = live RNG → LoadBtl_5d29 =
      1/32-per-side random intro event. Residuals: $CAB9 snapshot writer;
      intro-event message text. Byte-neutral session (`1ca6579…`).
      *Recommendation recorded for the campaign (user Q, S68): author new
      spines in custom rooms via generated scripts; keep vanilla intact as
      postgame; arena gating survives as re-authored Arena Lobby scr0.*

- [~] **E3 — New-game initialization + save-schema headroom.
      THE 32 KB SRAM EXPANSION IS BUILT (S69, NOT yet user-tested);
      init-object (a2) + story-variable schema (b2) remain open.**
      As built (owning doc: ARCHITECTURE "SRAM banking as built S69"):
      `$0149` $02→$03; **RAMB PIN** — the 19 ROM0 quadrant-convention RAMB
      writers retargeted one operand byte each to the MBC5-ignored `$6100`
      (boot's literal `RAMB:=0` writes kept; bank $20/$40 explicit writers
      untouched, adjudicated safe), so every existing SRAM consumer hits
      bank 0 with zero consumer changes; new banks 1-3 reachable ONLY via
      `CF3SRAMBankedCopy` (bank $73 entry 9, `wSRAMXfer*` mailbox
      $DE8B-$DE91, per-byte di-bracketed). **The S65 sketch ("RAMB=0
      establishment inside CF3's SRAM entry points") was INSUFFICIENT and
      was not built**: the audio ISR restores RAMB by *quadrant of the
      interrupted ROM bank* (AudioPopSetDE), so a per-entry set would be
      clobbered by any vblank mid-scan (DOC_AUDIT S69; KEY_LESSONS S69).
      Validation S69: byte-diff = exactly 19 operands + header + bank $73;
      entry 9 byte-executed (emitted-bytes interpreter): both directions,
      bank isolation, DE preserved, zero pin-invariant violations;
      verifier PASS 5/5; compiler 25/25 re-pinned `e719d286…` (patched).
      *Smoke results (user, S69 same session): old 8 KB .sav loads (32 KB on
      disk confirmed via uploaded .sav); gate run / warp heal / save+reload /
      breeding / farm pick+drop PASS. USER-REPORTED DEFECT, root-caused and
      FIXED same session (v2 ROM): unsaved battle deaths — and, per user, an
      unsaved CATCH — survived reset+reload. NOT an S69 regression: this was
      the CF3 v2 EAGER-ROSTER architecture's documented-but-untested reload
      consequence (canonicalizer mirrors party incl. HP to SRAM at every
      canonicalize; farm writes land live). Confirmed empirically from the
      user's .sav (slots 1-2: HP field $0000 + status bit 7 at +$4A; slot 0
      healthy). The initial S69 adjudication (Coliseum faint) was WRONG —
      user testimony: fainted monsters auto-revive win or lose (DOC_AUDIT
      S69v2). FIX = persistence v3, the ROSTER SNAPSHOT (owning: MONSTER_DATA
      "Persistence model (v3)"): bank 1 magic-gated save-time roster copy,
      restored over the eager image at load; reset-without-save now rewinds
      party AND farm to the last explicit save, vanilla semantics; first
      consumer of the E3 expansion, exercising CF3 bank-1 access in real
      gameplay. Validated: 4-scenario emitted-bytes execution (save/commit,
      death+catch+reset rewind, migration seed, non-main no-trigger); diff
      vs v1 = bank $73 + global checksum only; verifier 5/5; compiler 25/25
      re-pinned `94731e60…` (patched). *v2 USER-CONFIRMED (same session): all 5 smoke
      tests PASS — migration, death-rewind, catch-rewind, breed/deposit
      persistence, sleep/wake + in-gate save. E3 [~] status now reflects
      only the open subscopes (a2 init object; banks 2-3 schema), not the
      expansion itself, which is BUILT AND USER-TESTED.*
      Still open: (a2) new-game INIT data as an authorable object; (b2)
      story-variable headroom — allocation map + init/versioning convention
      for banks 1-3 (first consumer brings the format; banks arrive
      uninitialized by design).
      *(Historical S65 audit below — superseded where it sketches the
      per-entry approach.)*
      A new campaign sets its own starting party / items / flags / map position, and may add
      story variables. The opening is script-traced (ROUTING.md, FIRST_5MIN_TRACE.md; intro
      marker flag `$0000`). Persistent headroom TODAY: **32 safe flags**
      ($0158-$0167, $01E0-$01EF — EVENT_FLAGS) + the SRAM tail **$BFC8-$BFFF
      (56 B, untouched emergency reserve — user decision S65)**; the
      CF3-freed WRAM window is TRANSIENT permanently (CF4). The structural
      fix is declaring 32 KB SRAM ($0149 $02→$03; MBC5 + SameBoy support it;
      old .sav files load padded) — **BLOCKED on RAMB discipline, audited
      S65 (ARCHITECTURE "SRAM banking")**: (a) RST_18 writes
      RAMB:=rom_bank>>5 on EVERY `rst $10` (quadrant convention; $FFA3 is
      the shadow; vanilla's live SRAM users all run from quadrant 0, and
      bank $40 carries a genuine `di`-bracketed multi-bank 32 KB wipe —
      the infrastructure exists); (b) CF3 runs from bank $73 → RAMB=3 under
      expansion → farm hits the wrong bank; (c) the audio ISR dispatches
      into bank $74 every vblank while music plays → RAMB flips mid-access
      for anything not `di`-bracketed. Implementation session: RAMB=0
      establishment inside CF3's SRAM entry points with interrupt
      discipline, an accessor convention for new banked state, then flip
      $0149 + smoke (boot/new-game/save/reload/farm/sleep/custom rooms +
      .sav grows to 32 KB). Do NOT flip the header byte alone — silent
      farm/save corruption. Also still open from the original scope:
      (a2) new-game INIT data as an authorable object; (b2) story-variable
      headroom analysis beyond the audited custom range. *Confidence:
      HIGH for the expansion mechanics (instruction-verified S65);
      MEDIUM for init-object scope. Owning doc: ARCHITECTURE (SRAM
      banking) / known_RAM_map ($FFA3); this item for the editor-object +
      implementation work.*

- [ ] **E4 — Overworld / gate-network structure at campaign scale.**
      Custom rooms (mapID ≥ `$6B`, bank `$60`+) and individual warps are proven, but the
      **gate-selection / world-hub network** as an authorable graph — which gates exist, their
      unlock order, the gate-warp/selection menu, the GreatLog hub topology — is not specced
      beyond the Phase 3 "world/warp map" UI line. A *new world* (vs. editing the vanilla gate
      set) is the least-proven-at-scale piece. *Confidence: MEDIUM (rooms + warps proven; the
      gate-network DATA MODEL is the unknown). Owning doc: CROSSBANK_ROOMS / map docs; this
      item for the network-graph schema.*

- [ ] **E5 — Title screen + ending / credits sequences.**
      The opening cutscene is script-traced, but the title screen and the ending/credits
      sequences are not covered. A complete new campaign needs its own bookends; these are
      likely special-cased rendering paths that must be located. *Confidence: MEDIUM. Lower
      priority (cosmetic bookends). Owning doc: a new subsection of CUSTOM_CUTSCENES /
      DATA_STRUCTURES once found.*

- [ ] **E6 — Text / script capacity at full-campaign scale.**
      The dialogue compiler is specced (Phase 2: auto-wrap 18 ch, auto-DTE, page-split,
      two-level table emission, multi-bank spill). What is NOT validated is total capacity for
      a full new script across the four script banks (`$0C-$0F`) and the text banks — i.e. an
      allocation/budget strategy so a campaign-length script *provably* fits. *Confidence:
      MEDIUM. Mostly covered by Phase 2; flag capacity-planning as an explicit acceptance test.
      Owning doc: TEXT_SYSTEM + Phase 2 `build_project.py` validations.*

- [ ] **E7 — Player-character art = Milayou (ADDED S72 — the POV flip's most
      glaring un-scoped requirement).** Zero coverage existed anywhere of
      the PLAYER's walking sprite (Terry's sheet) or any other player-art
      surface; the monster follower/battle sprite systems are solved but do
      not cover the hero. Likely small once located (find the sheet + its
      loader, same-size 2bpp swap through the proven codec pipeline), but
      it is unlocated RE today. Also sweep for other player-art surfaces
      (menu/status portraits if any exist, intro art). *Accept:* player
      walks all 4 directions as Milayou in SameBoy; loader + sheet
      addresses documented in MONSTER_DATA or a new ARCHITECTURE subsec.
      *Confidence: MEDIUM-HIGH (pipeline proven; location unknown).*

- [ ] **E8 — Shop system RE + authoring (ADDED S72).** EDITOR_DESIGN §1
      assumes "new shops = scripted room type, replicable" — UNVERIFIED.
      Total current knowledge: script opcode `$04` GameActionDispatch →
      bank `$09`, subcommand 0 = shop (BANK04_SCRIPT_ENGINE). Inventory
      lists, prices, buy/sell flow: undecoded. User note (S72): community
      hex editors already edit shop stock/prices, so the data is likely a
      simple table — find it, decode it, round-trip it
      (keystone-first per Phase F methodology). *Accept:* shop
      inventory/price table decoded + `extracted/` JSON + a changed price
      visible in SameBoy; authoring schema (`gamedata.shops`) specced.
      *Confidence: HIGH it's shallow (per user), unproven.*

- [ ] **E9 — Item authoring: edit vanilla items + custom items (ADDED S72;
      carries a concrete user spec).** Read-only knowledge exists
      (ItemNamePtrTable/ItemDescPtrTable `$41`, 44 items; 37 item_effect
      records in `skill_records.json`); there is NO edit/add arc. Wanted:
      (a) edit existing items — names/descriptions (T-author path),
      effects (item_effect record edits), and item CLASS bits (what makes
      BeastTail single-slot/non-stacking, what makes an item consumed on
      use vs permanent); (b) net-new item ids past 44 (table extents +
      every indexer — same high-table pattern as Phase N species).
      **USER SPEC (S72), the acceptance content:** make **WarpWing a
      single-slot item like BeastTail AND permanent (not consumed on use)
      for warping anything** — i.e. the inventory-class bit flip + the
      consume-on-use flip, with warp behavior retained. *Accept:* that
      WarpWing lands in SameBoy (stays in inventory after use, occupies a
      single slot); the class/consume bit locations documented.
      *Confidence: MEDIUM (bits unlocated; likely near the item tables).*

**Bottom line (updated S67):** for editor v1 the RE is done and the gap is formats + UI.
**E1 is DECODED (S67, arena path HW-verified)** — for a *new campaign* the remaining work
is **E2** (the authoring backbone, now unblocked: E1's authoring spec feeds straight into
it, and E1 removed part of E2's unknowns by decoding the Arena Lobby scr0 victory cascade
and the `$CAB4` progress tier); E3-E6 are schema / UI / capacity questions on top of
largely-known mechanics.

---

## Phase F — Authorable subsystems: text, custom skills + AI, custom music
Three subsystems promoted from "parked/under-stated" to first-class after the S43
disassembly audit (PROJECT_STATE "S43"). Methodology mirrors the proven arcs
(breeding B1→B6, GFX): **prove understanding with a byte-identical round-trip
keystone first, then relocate/redirect into a free bank, then author**. One item =
one session, each with a hard acceptance test. Honest risk: **S3 and M1 are real RE**
(could expand); their downstream authoring items can't be precisely scoped until they
land. Arc 1 (text) is fully predictable.

### Arc 1 — Text re-section + vanilla-text editing (lowest risk, useful now)
Extends the `[~]` "re-section misassembled tables" item to the dialogue corpus; the
text *format* is fully known (TEXT_SYSTEM.md) and the dumpers already locate every
string, so this is mechanical + byte-perfect. Unlocks Layer-A vanilla-text edits and
yields the E6 capacity numbers.
- [x] **T1 — Text re-section keystone (bank `$47`)** ✅ S43 — resection_text_bank.py:
      69 strings, run $4174–$5b74, 5607 fake lines → labeled `db` with decoded
      comments; byte-perfect, idempotent, data-driven bounds.
      → TEXT_SYSTEM "Source re-section"; TOOLS_AND_DATA; archive: SESSION_HISTORY.
- [ ] **T2…Tn — Roll-out across `$42-$46, $48-$4B, $4E`** (one or two banks/session, same
      tool). *Accept:* each bank re-sectioned; MD5 stays `1ca6579…` after each.
- [ ] **T-author — Edit/replace a vanilla string.** A tool that rewrites a vanilla text id's
      bytes (same-size in place, or relocate to a free bank via its pointer-table entry).
      *Accept:* a known vanilla line shows new text in SameBoy; clean MD5 unchanged. Byproduct:
      the E6 per-bank capacity/budget numbers.

### Arc 2 — Custom skills, then per-skill AI (high value; one real RE gate)
Skill *effects* are a known pattern (`SkillFunctionTable $52:$4011`, **222 entries** ($00–$DD)
→ 115 handlers, dispatch `$52:$6CC7`; names `$41:$4539`); plus the now-decoded
`SkillMPCostTable $07:$570C` (u16, 999=ALL) and `SkillLearnReqTable $06:$50E0` (18B/skill).
The editor data side is captured in `extracted/skill_records.json`; the **presentation**
layer (record params, item/meat, animation dispatch) is decoded (S46, `BATTLE_SKILL_SYSTEM.md`
§7–§10). Remaining RE: the full AI weighted-pick (S3). (S2c message format done + validated 2026-06-28; S2c-anim renderer reversed + emulator-verified 2026-06-28 — see §11.)
- [x] **S1 — Skill data foundation** ✅ S44 — SkillMPCostTable ($07:$570C, renamed
      S51) + SkillLearnReqTable ($06:$50E0) decoded + FAQ-validated;
      skill_records.json (222 = 155 skill / 37 item_effect / 30 internal);
      build_skill_tables.py --selftest byte-identical; BugCut (id 215 = the
      Bug-family cut) proven 3 ways + renamed, SameBoy-confirmed; bank $52 header
      corrected ($6CC7 / 222 / 115). → BATTLE_SKILL_SYSTEM; DOC_AUDIT #12–14;
      archive: SESSION_HISTORY Part 3.
- [~] **S2 — Custom skills (ARC, not a single item).** S45 marked this "done" off a
      narrow POC; corrected (S46). The arc:
  - [x] **S2a — Alias EFFECTS POC** (S45, SameBoy-confirmed): net-new ids $DE Scorch /
        $DF Smite via commit-time templatize-to-Blaze + $db86 stash + FarSkillFork.
        Narrow (single caster, Blaze-shaped). → §1–§6; KEY_LESSONS S45; archive: SESSION_HISTORY.
  - [x] **S2b — Record-table round-trip + presentation foundation** (S46,
        byte-neutral): record table $54:$4013→$41CF (222×19B) decoded, FAQ-validated
        field map, re-sectioned to `db` in bank_054; item-effect/meat system; animation
        dispatch located. → §7–§10; archive: SESSION_HISTORY Part 3.
  - [x] **S2c — Effect MESSAGE format** (S47): bank $4c is the shared text VM;
        $dd70/71 = a packed hit/miss message-id PAIR (mode-0 two-level table
        $4c:$4019); 67/67 statically-resolved skills FAQ-validated. Tool
        decode_effect_messages.py → effect_messages.json. → §9; archive: SESSION_HISTORY.
  - [ ] **S2c-anim-cleanup — convert the verified battle-anim DATA tables to `db`/`dw` in the
        disassembly (label-only, byte-neutral). [OPEN — blocked on `$5f` map-script RE]** The
        anim tables (`$5f:$56ed/$57d5/$58bd/$58dd/$59c3/$5aa9`; `$5c/$5d/$5e` frame tables at
        `$4071`+) currently mis-disassemble as instructions. `tools/emit_anim_data_sections.py`
        emits byte-exact directives, but the `$5f` span overlaps mgbdis `Map*_Script*` labels
        (some bogus, some maybe-real) — see DOC_AUDIT #15. **Must reverse the `$5f` map-cutscene
        script accessors first** to set correct boundaries, else risk mislabeling real scripts
        or absorbing them into anim tables (a silent error a passing MD5 won't catch). The
        `$5c/$5d/$5e` frame tables have the same code/data-interleave hazard.
  - [x] **S2c-anim — Animation renderer reversed** (S47, emulator-verified): $dd68 is
        a metasprite/OAM engine; full chain skill id → $5f:$52F0 → side tables
        $58dd/$59c3/$5aa9 → routine table $58bd ($0d = no visual) → builders
        $5c/$5d/$5e; 3 presentation layers (sprite anim, sound+flash, SCY shake).
        Tool decode_battle_animations.py → battle_animations.json (45 anims).
        → §11; archive: SESSION_HISTORY Part 3.
  - [x] **S2d-audit — Skill-id bucketing map** (S48, byte-neutral): $db8a, 254 reads /
        9 banks → reduces to a small verified fork set; keystone = the record indexer
        $54:$4013 (3 sites — one fork fixes magnitude/targeting/MP/status/ai_weight +
        the enemy AI). Tool map_skill_id_buckets.py (self-checking).
        → §12; KEY_LESSONS S48; archive: SESSION_HISTORY Part 3.
  - [x] **S2d — Skill #1 MagicBurn ($E0)** (S49, user-confirmed): non-aliased,
        end-to-end — own record/handler/name + announce + animation + hit-flash +
        cast sound via clean indirection (AnnounceTemplateTable slot, $4c:$7326
        message pool, GetPresentId proxy in $5f). Per-skill recipe: **§13**.
        → KEY_LESSONS S49; archive: SESSION_HISTORY Part 3.
  - [x] **S2e — Skill #2 Tame ($E1)** (S50, user-confirmed): recruit + anti-abuse
        damage (ATK/4), single-target. New reusable infra: custom-message render fork
        ($FD → per-skill pool string) + presentation timing (note→hit sequencing).
        → §13.5 + §11.7; TEXT_SYSTEM ($FD fork); KEY_LESSONS S50; archive:
        SESSION_HISTORY Part 3. **Follow-ups split out as the next three boxes.**
  - [x] **Tame Stage 2 / SKILL EVOLVE** (S52). Crank reverted (`TameMeterTable` dw
        10/100/400 = FeedMeat/PorkChop/Sirloin; the box's "$000A = Beef Jerky" was a
        mislabel and "mirrors in bank_052" was FALSE — the vanilla cap; DOC_AUDIT S52).
        3-tier chain $E1→$E2→$E3 via `LearnLoopFork` (bank $06 loop-bound splice +
        `CustomLearnReqTable`); vanilla EVOLVE/replace semantics (prereq path);
        real MP 10/30/50 via `MPPtrFromId` fork of ALL THREE `$570C` readers;
        `AnnounceIdxFork` (vanilla table tail overlaps code at `$58E8`); upgrade-msg
        "!"-orphan fixed by `MiscText_03_Paged` repoint. *Accept variance:* natural-to-
        Slime DE-SCOPED by user ("editor lays real data" — the fork makes any species
        slot work); harness KEPT per user. Learn/upgrade user-confirmed (v34); MP
        charge + meter values + msg page-split built, NOT yet user-tested.
        → §13.6 (systems), §11.7 (blink), KEY_LESSONS S52.
  - [ ] **§13.4 follow-ups** — (a) custom-id skill-NAME insert so name-inserting
        announce templates work for ids ≥ $DE; (b) a 2nd bespoke-message render path
        beyond the single `$FD` escape. *Accept:* a custom skill using a
        name-inserting stock announce template renders correctly. → §13.4.
  - [ ] **(optional polish) Per-enemy hit-blink** — mechanism SOLVED S52 (HW captures):
        enemy is BG-DRAWN; blink = tilemap toggle, bank `$5f` entry 5, `$da83` phase →
        `$da84` sub-dispatch `$4b99` (blank `$4ba5`/enemy `$4bcb`, copy `$4e1f`).
        Implementation deferred by user ("bank it"). Plan: drive the blink phase from
        `TameGateHook` via `$da82/$da83/$da84/$da34` state injection; expect 1-2
        SameBoy iterations. Full map: → §11.7.
  - [ ] **S2f — FIELD-cast custom skill (e.g. teleport/warp).** A different code path the
        battle foundation (§13) doesn't touch yet — genuinely new groundwork. *Accept:* a custom
        field skill (warp) fires from the field menu in SameBoy.
- [~] **S3 — AI selection RE (partly answered S46).** **Found:** the per-skill AI lever is
      **record +3 (`ai_weight`)** — the enemy AI (`$57 AIState3SkillSums_7529`) walks its skill list and
      SUMS record[+3] into the score table `$dce4`, then picks weighted (Sacrifice/MegaMagic=0).
      Distinct from per-monster enemy-stats `+17..20`. *Remaining:* trace the weighted pick + how
      per-monster weights combine; confirm with a SameBoy watchpoint on `$dce4`/record+3.
      *Accept:* selection algorithm documented (MONSTER_DATA battle-AI subsec).
- [ ] **S4 — Per-skill AI authoring.** Likely easy now: edit record +3 (`ai_weight`) per skill
      (round-trips via `build_skill_tables.py`). *Accept:* changing a skill's ai_weight measurably
      shifts enemy choice in SameBoy.

### Arc 3 — Custom music (discovery-gated; longest pole)
Unparks the "custom music" line. ~~Song data lives in banks `$61 $62 …`~~ **CLAIM
FALSIFIED S61 (DOC_AUDIT S61):** the engine is entirely ROM0 ($3331–$3AB2 region,
VBlank-driven) and ALL audio data lives in banks **$1C/$1D/$1E** (master table @
ROM0 `$3466`); banks $61+ hold sparse non-audio data. Owning doc: SOUND_SYSTEM.md.
- [x] **M1 — Audio engine + data discovery (RE, no patch).** DONE S61 (byte-neutral).
      Master table, per-id channel records, 2-byte-pair sequence format, pitch/noise/wave
      tables all pinned; `tools/enumerate_songs.py` + `extracted/songs.json`: 86 sounds /
      158 streams, all terminate, zero overruns; track $06 decoded note-by-note.
      **BONUS (user-supplied DWM2 GBS):** DWM2 runs the same engine family — pitch table
      + all 16 wave instruments byte-identical, same stream format; **DWM2 BGM #06
      (user's target track, internal id $16) = 1,762 B of relocatable data, direct port
      judged feasible** (SOUND_SYSTEM.md §7). This replaces MP3 transcription for the
      user's custom-well-music goal.
- [x] **M2 — Song round-trip keystone.** DONE S62, acceptance exceeded: `tools/song_codec.py
      selftest` decodes ALL audio in banks $1C/$1D/$1E (157 streams incl. 4 orphans) and
      re-emits the full 16KB banks **byte-identical**; `extracted/songs_spec.json` is the
      M3 common intermediate. Grammar corrected en route (no 3-byte $FC token; loop-jump =
      Bn-pair prm=$FC + target pair — SOUND_SYSTEM §5, DOC_AUDIT S62).
- [~] **M3 — Custom song authoring.** Core acceptance MET (custom tracks play in-game,
      user-confirmed S62/S63); M3a complete; M3b/M3c open below.
  - [x] **M3-POC (S62, user-confirmed by ear):** DWM2 BGM #06 ported into custom well
        room $6B (BGM NPC, SetBGM $9E). **ZERO ROM0 changes** — ids $9E-$A0 ride the
        4 orphan record slots @ $1E:$419D that the open-ended master-table row already
        resolves; translated streams (5,035 B) in bank $1E filler @ $6B80.
        **DWM2→DWM1 translation layer** (song_codec.py, trace-equivalence proved): DWM2's
        $AC/$AD call-return phrases (stored past $FF!) inlined; per-slot mark loops →
        Bn/$FC jump form; nested counted loops unrolled; headers carried verbatim
        (field-identical parse, verified in the GBS driver). SOUND_SYSTEM §7 has the
        full DWM2 driver grammar.
  - [x] **M3a — general song slots. COMPLETE S63, USER-CONFIRMED (v4 + v5: two custom songs live).** The ROM0
        free-run blocker dissolved by auditing our own claims instead of vanilla filler
        (KEY_LESSONS S63): `MapIDClampForDispatch`/`ForPalette` were byte-identical
        twins (merged @ $3BC2, both labels one body) and `CustomGFXMapID` was dead
        since S42 (deleted) — freeing the 24-B $3FE8 slot for **`AudioMasterTableExt`**
        (3 vanilla rows byte-identical + row `[$9E,$4001,$74]` + sentinel; one spare
        future row). One 2-byte operand repoint @ $33D9 (`AudioProcess`). **Bank $74 =
        song bank** (fixed 95-slot record area $4001-$417C, streams from $4180;
        `song_codec.py emit-song-bank` ← `extracted/custom_songs.json`); BGM #06
        migrated byte-identically (import-port; static re-trace matched S62's
        1858/1566/2287 event counts); **bank $1E reverted to 100% vanilla** (orphan
        route retired). Static proof: all vanilla ids $00-$9D resolve identically
        through the new table. Capacity: ~31 3-ch songs / 10,965 stream B free.
        *v4 acceptance MET (user)*: well BGM identical, no issues; save/reload
        transience = vanilla SetBGM (SOUND_SYSTEM §8, M3b room-defaults). *Also fixed en route*: S62's silent
        compiler-regression break (bank_060 hand edits folded into the example
        project; pin `168c5f1b…`→`c23beed7…`; DOC_AUDIT S63).
  - [ ] **CI gap (S63)**: `.github/workflows/verify.yml` runs only
        `verify_integrity.py` — add `editor2/tests/test_compiler.py --rom` so
        compiler-owned-bank hand edits fail in CI, not two sessions later.
  - [ ] **M3b — USER REQUIREMENTS (S62): song LIBRARY in the editor** — import multiple
        custom songs, assign to rooms/gates/events (SetBGM wiring per assignment).
        *v5 BUILT + USER-CONFIRMED S63*: **DWM2 BGM #07**
        (GBS index 6 → internal id $19; song map @ GBS $0FC0) → DWM1 ids $A1-$A3,
        2,471 B in bank $74 via new `add-gbs-song` mode; room $6C screen 0 NPC (5,6)
        `SetBGM $A1` — wired through project.json + `--apply` (bank_060 now
        compiler-generated; pin `3009b75e…`). End-to-end trace proof from ROM bytes
        vs GBS bytes (954/645/840 ev). Foreign `$AA`×20 = DWM2 ornament, verified
        non-flow @ GBS $37AE, dropped as no-op in DWM1 — ear test judges.
        *v5 acceptance MET (user)*: both NPC songs play; $AA-ornament drop
        unremarked by ear. Remaining M3b (then): room defaults, schema, MIDI.
  - [x] **M3b — COMPLETE S64, USER-CONFIRMED (v6)**: room-default music for
        ANY mapID (vanilla or custom) + `custom.music` schema. Traced
        `LoadNewBGMIdIntoA` ($01:$432D; caller runs on map entry AND
        save-load — hence the S63 transience) + `RoomBGMTable` ($01:$4373,
        $70 entries, re-sectioned from fake instructions in both trees);
        SAME-SIZE 70-byte rewrite dispatches bank $71 entry 2
        `CustomRoomBGMResolve` first (E-return; generated 128-entry
        `CustomRoomBGMTable`; gate floors excluded). Schema: `music.
        {libraries, songs, room_defaults}` + `rooms[].music`; music emitter
        owns bank $74; full 31-song DWM2 catalog committed
        (`extracted/dwm2_song_library.json`, all trace-proven;
        `custom_songs.json` retired byte-identically). v6 confirmed:
        Library ($12) plays the MIDI song, gate_island ($6B) defaults to
        BGM #07 incl. save/reload, NPC overrides still work. Details:
        SOUND_SYSTEM §8, PROJECT_COMPILER §2.9.
  - [x] **M3c — MIDI import. COMPLETE S64, USER-CONFIRMED (same v6)**:
        `tools/midi_to_song.py` (pure-python SMF 0/1): frame-accurate
        boundary rounding (engine lengths ARE frames — S64 correction,
        SOUND_SYSTEM §4), per-channel monophonize, lowest-mean-pitch→wave
        auto-map, $A7 tie-holds past 255 frames, `$A3 $80` groove-off
        (every groove row is live vibrato — §5), `B0 $FC` whole-song loop,
        decode round-trip check. dq6_town1: 3ch, 1,325 B, 92s loop.
  - [ ] **InitBGM channel-count extension** (unblocks DWM2 BGM #04's noise
        channel + 4/5-channel jingles as BGM): InitBGM starts exactly 3
        consecutive ids for a normal BGM; the music emitter currently pads
        2ch→3ch silent and DROPS >trio channels with a warning. Extension =
        a per-first-id channel-count column (or id-range rule) in the
        InitBGM path.
  - [ ] **Gate/event music assignment**: gate floors derive music from the
        floor path ($34 / boss-type table), deliberately excluded from
        CustomRoomBGMResolve (wMapID is not room-meaningful in gateworld).
        Assigning per-gate/per-floor music needs its own hook at the
        gate branch (+ event triggers = script `set_bgm`, which already
        works).

**Recommended order:** T1 ✅ → S1 ✅ → S2a–S2e ✅ → **Tame Stage 2 ✅ (S52 — four
custom skills live, evolve chain proven)** → S2f (field
skill) / S3 → S4 → M1 → M2 → M3 / T2 roll-out, slotting text roll-out into spare
sessions. Fire the two RE discovery sessions (M1, S3) before their authoring items
depend on them.

---

## Phase N — Add NEW monster species (ids 224–255, 32-slot budget)
User goal: add brand-new monsters *on top of* the existing 221 (not reskins of
existing slots). Scoped Session 28. Architecture: **high-table + single forked
loader, vanilla 0–220 byte-identical** (full detail in MONSTER_DATA "Species ID
geography"). Species id is a byte → first free id **224 (`$E0`)**, budget **32**.
Beyond 32 needs 16-bit ids everywhere (avoid).

- [x] **N1 — Scope + slot map** (S28): 256-slot species map (map_species_slots.py,
      self-checking); single indexers verified; slot geography 215–219 special /
      220–223 empty / 224–255 free. → MONSTER_DATA "Species ID geography"; archive: SESSION_HISTORY.
- [x] **N2 — Info-table fork (keystone)** (S29/S30, SameBoy-confirmed): SaveMon_4446
      forked zero-shift, id≥224 → bank $6A high table; ids 0–220 byte-identical;
      tool-owned (build_new_species.py ← new_species.json). → MONSTER_DATA; archive: SESSION_HISTORY.
- [x] **N3 — Enemy stats: NO fork needed** (16-bit EID; EID 518 @ $14:$7EB3, bank
      trailing free); wild-encounter wiring tool-owned (same-size EncounterPoolData
      edit, validates the slot was empty). SameBoy-confirmed. → MONSTER_DATA; archive: SESSION_HISTORY.
- [x] **N4 — Sprite + palette, BAKED** — follower half = **G1** (S34: all-8-copy
      gfx-ID fork, attr-overshoot fixed at root, clean-attr mask $B8, art stored
      un-flipped); battle half = **G2** (S35: $2b9f same-size repoint → $7e01;
      HighBattlePal fork in $17 filler tail). User-playtested OK.
      → MONSTER_DATA "NEW species followers" / "NEW species battle sprite";
      KEY_LESSONS S35; archive: SESSION_HISTORY Part 3.
- [x] **N5 — Name / joinability / breeding / library wiring** — DONE S32,
      user-tested: all 3 breeding paths (result append; parent via the forked $0301
      loader; display via FamilyRecipeResolve); hatch crash fixed
      (FollowerArtResolve0b, bank $0b); default-nickname/narration overshoot fixed
      (LoadModeBaseRedirect @ ROM0 $00F0 → short-name "Gorb" @ $41:$7FF9). Lineage
      parent-name line fixed S38 (HighModeTable4D mode-0 → "Snaily   BattleRex",
      two fixed 9-char fields). → BREEDING_SYSTEM; MONSTER_DATA; TEXT_SYSTEM;
      archive: SESSION_HISTORY Part 3.
- [x] **N6 — Top-range gates: NOT species gates** (S31): the 4 cp-ladder sites branch
      on $db8a (a skill/effect id, never a species byte) — false positives; no patch.
      → MONSTER_DATA "Species ID geography" N6; DOC_AUDIT; archive: SESSION_HISTORY.
- [ ] **G3 — new_species.json schema fold (the last open new-species item).** One
      JSON drives EVERY Gorbunok artifact (info, enemy stats, encounter, name,
      short-name, library, breeding, **the real description string** — line 2 still
      reuses Dracky's $60BC placeholder — and the art hooks) through
      build_new_species.py; reproducible from the clean tree. *Accept:* rebuilding
      from the JSON alone reproduces the current baked state byte-for-byte; the
      hand-staged pieces are deleted.

## S73 user-directed item — custom skill $E4 "Anchor" (outside the numbered phases)
- [x] **SHIPPED, USER-CONFIRMED** (v1 mechanics + S73b descriptions/battle rejection; pin `224b1176…`): field-cast skill
  "Anchor" — anchor a STANDARD gate floor → confirm dialog → warp to GreatTree
  (WarpWing recipe); cast in town → confirm ("spend most MP") → return to the
  exact anchored floor, regenerated + FORCED standard, 3/4 of current MP
  charged upon arrival; anchor persists through save (save-image bytes
  $D9D7-8), single-use, overwritten by re-anchoring. Error dialogs in
  special/boss/custom rooms and for no-anchor town casts. Slim (new-game
  harness) knows it. v2 backlog: boss-room anchoring (needs the 53-site
  boss-script flag survey), "can't use in battle" message (battle cast is a
  silent no-op in v1), YES/NO default-cursor feel, dedicated script-container
  room instead of medal_vault hosting, optional persist-after-use policy flag.
- [x] S73b (user feedback round 1): mechanics USER-CONFIRMED; skill
  descriptions added for $E0-$E4 (blank-box fix; table $56:$6667 found);
  battle cast now rejects via StepGuard's exact path (message, no turn
  consumed, excluded from the AI pool). New pin `224b1176…`. The reported
  save-wipe + castle-top corruption did not reproduce (user retest + 3 PyBoy
  cycles) — transient/unconfirmed, watch.
- **S74 (2026-08-01, v2 2026-08-02): Earthquake chain $E5-$E8 — v2 BUILT +
  PyBoy-verified end-to-end, awaiting user test.** v2 delivered: allies hit
  even on a battle-winning cast (step-6 victory gate; `$70bd` lands
  victory/defeat one action later); Infernos wind anim removed at the
  anim-index source (`GetAnimPresentId` → quiet id, idx `$0D`) with the
  ordering announce → tier-count shake bursts (1/2/3/4 × 16 f) → damage
  text; 2-line announce (`$F1` exonerated); bank $056 SKIL descriptions for
  all four tiers; ROM0 reverted to vanilla. v3 (2026-08-02b): announce -> shakes ->
  blink/damage ordering (shake train lives in the cast-anim slot), 3-line
  "Allies are caught in the seismic wave!" banner, per-target "But X flew
  above it!" fly beats on both sides (solo-caster silent). v4 (2026-08-02c): banner box-fit,
  party-side-only fly line, honest per-beat damage sounds. Remaining
  backlog: earth-resistance slot (+$29) semantics; caster derivation
  robustness (two same-tier queuers); all-enemies-flying cast is a no-op
  (the commit has no valid target — vanilla behavior); full "the seismic
  wave" wording needs the engine-driven page path (gate-inserted renders
  cap at 2 lines).

## S75 user-directed item — custom skill $E9 "Mourn" (outside the numbered phases)
- [x] **BUILT + PyBoy-VERIFIED, awaiting user test** (patched pin `a914e489…`):
  battle skill "Mourn" — single-foe attack; damage = the vanilla ATK-vs-DEF
  physical roll × (dead allies + 1): 0 dead (all alive or caster alone) = 1×
  = a normal attack, 1 dead = 2×, 2 dead = 3×. MP 10. Natural learn:
  standalone, lvl 3, no prereq. Announce "used Mourn!"; boost banner
  "Fallen allies / lend power!" (2-line, 40-frame hold) only when the
  multiplier fired. Presentation: EvilSlash proxy played TWICE back-to-back
  (anim-slot replay, sticky $FF terminal). Architecture new to this session:
  the SECOND dispatch trampoline (MournDispatch52 in the $52:$6c56 dead
  bytes, `call CalcDefenseWrapper` instead of MegaMagicDamage_653e) lets any
  custom skill pick which vanilla damage machine seeds $db56 — zero cost to
  existing customs. Measured: multipliers 1×/2×/3× incl. persistence across
  8+ rounds after the engine's KO scan ($dd1b three-state finding: presence
  = != $FF, NOT == 0); MP deduct + afford stop; announce→banner→damage
  ordering; kill chain + victory; Tremor/Infernos/plain-attack regressions.
  Details: BATTLE_SKILL_SYSTEM §13.8. v1 backlog: real-menu battle commit
  not rig-exercised; one -13 among eleven 2× events (apply-time variance
  suspicion — watch in user test); aborted-action $FF leftover skips one
  animation then self-heals; slash count is fixed at 2 (could scale with
  dead count as a v2 flourish).
- [x] **v1 mechanics USER-CONFIRMED 2026-08-02 ("works perfectly").**
- [x] **v2 (same day): banner BEFORE the attack animation (user feedback) —
  BUILT + PyBoy-verified, awaiting user test.** Pin `762c0df0…`. Dead-count
  evaluated in the anim fork (shared MournCountDead); banner + $FE hold
  precede the slashes; handler keeps only the multiplier; bank $72 only.
  v3 flourish ideas: N slashes scaling with dead count (arm with explicit
  $da82 clear — see §13.8 v2 note on the stale done-flag).
- [x] **S75 v3/v4 — crash investigation + hardening (user-reported wild-gate
  Dracky freeze).** The rig-stall "bank_006 regression" was RETRACTED (input-
  alignment artifact — S74 stalls at other cadences too). Shipped: the
  LearnCode2Guard06 fence (custom ids can never stat-learn via code 2), the
  SlotProbeGuard50 fence (level probe rejects slot >= 40; kills the phantom
  slot-40 echo-RAM read/write hazard, plausibly the S73b transient), and
  tools/validate_custom_data.py wired into verify_integrity check 6 + the
  editor builder (crash-capable configs are build errors at every level, per
  user directive). Pin `ce1e7369…`, verifier 6/6, compiler 39/39, Mourn
  suite re-verified on v4. **The user's actual crash is NOT yet reproduced**
  — SameBoy trap kit issued; if it fires, that trace lands the origin
  directly (next session).

---

## S76 user-directed item — standalone randomizer (outside the numbered phases)

- [x] **Randomizer built, user-tested, SHIPPED.** `randomizer/`, no patches
      applied, runs on the English and German builds. Bosses (identity, moves,
      joinability), breeding (family + special), encounters, natural skills,
      growth, resistances, exp-curve remap, arena rosters, starter-with-Heal.
      Deterministic per seed; spoiler log in the ROM's own language.
- [x] German build (`08bca718…`) audited for portability — see DATA_STRUCTURES
      §"Region portability". Only bank `$14` moves (`+$70`); boss trigger EIDs
      proven region-independent.
- [x] Library recipe TEXT decoded (bank `$4D`, entry = species + 5) and made
      rewritable — see BREEDING_SYSTEM §"Library recipe TEXT".
- [x] Power calibration captured for editor use — BATTLE_SKILL_SYSTEM §"Power
      calibration", PROJECT_COMPILER §"Coherence sets the editor must maintain".

Follow-on candidates (not scheduled):
- [ ] Editor: enforce the three coherence sets (PROJECT_COMPILER §"Coherence
      sets") — regenerate bank `$4D` strings whenever a family recipe changes,
      keep boss fight/join rows in sync, and run `audit_threat.py` in the build.
- [ ] Randomizer: option to keep `SpecialRecipeTable` coherent with the family
      defaults so the library's displayed default is not shadowed more often
      than vanilla's 9%.
- [ ] Third-region support: the tools fail loudly rather than guessing; a new
      build needs its family-word strings identified for `librarytext.py`.


## S77 — randomizer part 2 (user-directed)

- [x] Breeding tree REGENERATED rather than re-pointed; depth targeted and
      reached (3-6, tiers built in ascending order, best-of-N retry).
- [x] Bosses / arena / wild stratified by breeding depth and level cap against
      vanilla's measured correlations; boss joinability level-biased so the
      endgame showcase survives.
- [x] Skill assignment rebuilt on **vanilla placement** rather than record power,
      fixing the whole handler-computed-damage blind spot in one change.
- [x] Growth shuffled within vanilla-ordering bands; paralysis and full heals
      banned on boss/arena rows; encounter pools de-duplicated.
- [x] `randomizer/profile_check.py` — per-entity envelope checks, build gate.
- [ ] Starter roll is unconstrained (`--starter-min-cap` floors at 20 only) and
      is probably the largest single driver of early-game difficulty across
      seeds. Constrain to a band.
- [ ] Residual `profile_check` failures: 27 growth pairs (all on species whose
      vanilla baseline is ~14 points, where ratio is misleading) and 2 skills
      drifting >8 rows. Needs a per-species absolute clamp.
- [ ] Combat simulator for pacing/TTK — UNBLOCKED by S78: the full damage
      layer is traced and differentially validated (698 exact checks, 0
      mismatches; `simulator/damage.py`, BATTLE_SKILL_SYSTEM §15). Spell/DEF
      answered (DEF does NOT reduce spells). Remaining for the simulator
      itself: turn order + AI (S79 boxes below).


## S78 — combat simulator arc part 1: damage tracing (user-directed)

User direction: full simulator, "not just for randomizer but the full
romhack"; two control variants matter for acceptance — gates/bosses
(per-monster commands) vs arena (tactics only, e.g. Passive = guard if
high HP / heal if ally low); AI itself to be reverse-engineered "at some
point". EDITOR_DESIGN §11's never-simulate rule superseded by the user.

- [x] Physical roll, record spells, resistances (packing + all ladders),
      boss-protection gate ($DB73 battle type), handler specials — traced,
      modelled (`simulator/damage.py`), 698/698 differential checks exact.
- [x] Measurement tooling: `simulator/measure_rig.py` (S75 rig + waypoint
      hooks), `simulator/validate_damage.py`, corpus
      `simulator/s78_master_events.json`.
- [x] S79 — simulator core: turn order (AGL formula), action loop, damage
      APPLY step exclusions ($52:$6DB0), status application/durations;
      measure the traced-only items (slot-2 ×0.8 via 3-monster party,
      RainSlash hits 2+, Sacrifice magnitudes, arena variants).
      DONE S79: turn order traced ($58:$54D1 TurnOrderBuild — key =
      AGL−span+rand, span≈31%, +$0600 defensive class / +$0400 SquallHit /
      PsycheUp-last) and validated 143/143 over 47 rounds
      (simulator/turn_order.py + measure_order.py + validate_order.py +
      s79_order_events.json). All four traced-only items MEASURED: slot-2
      ×0.8 (party3 rig), RainSlash 4-hit cap + per-hit ×0.8/0.6/0.4/0.4,
      Sacrifice (CURRENT-HP kill/survivor, 4/4), arena variants — which
      falsified two forks: Kamikaze's and WindBeast's "arena" branches key
      on $C86C (LINK), and real arena (db73=2) takes the boss/enemy-side
      paths (measured; damage.py corrected, S78 corpus still 698/698).
      28-state action machine mapped ($52:$6C60), apply-step id lists
      named, phase 9 = END-OF-ROUND DoT processor (poison /16, heavy /6,
      caps), status byte map measured per-skill (§15.8), sleep wake exact
      ($53:$4AEB port). Round core assembled: simulator/battle.py
      (components engine-exact; loop glue NOT yet differentially
      validated — S80 box below). NOT built S79: AI, meta-actions,
      $DB07 timer statuses, curse magnitude, loop-level validation.
      ROADMAP breadcrumb falsified: BattleFunc_6a13/6a49 are the
      Upper/AglUp stat-CAP helpers, not flee/order checks.
      S78 breadcrumbs for the tracer: the turn SEQUENCER is battle phase 9
      = bank $50 $6AAC (sub-machine on $D9ED; the per-action dispatch is
      the `ld a,[$d9ed] / rst $00` table at $52:$6C5C — states 0-7 =
      6C98/6CB2/6D56/6E2B/6E74/6F56/6FFA/7227, state 3 routes Sacrifice
      to bank $53 entry $0D). Candidate order/flee math glimpsed but NOT
      traced: BattleFunc_6a13 ($52) compares target DEF×2-or-×4, and
      BattleFunc_6a49 compares wBattleAGL×4 capped $01FF — likely the
      flee/order checks. The damage APPLY (HP subtract + skill-id
      exclusion lists) is the jr_052_6db0..6de8 block. Beat outcome hook
      pattern for rigs: hit path $52:$4200, miss $52:$4225. To rebuild
      the rig environment: make (emits disassembly/game.sym), pip install
      pyboy, boot patched ROM + hacked .sav, CONTINUE, close menus,
      p.save_state -> boot.state (recipe in simulator/measure_rig.py).
- [x] S80 (partial) — AI reverse-engineering: the enemy decision machine
      is traced + validated 26/26 (BATTLE_SKILL_SYSTEM §15.10;
      simulator/ai.py + measure_ai.py + validate_ai.py; 10-EID event
      corpus in simulator/ai_events_*.json). CORRECTION: the machine is
      bank $57 (not $58 — $58 entry 11 is only the cat-1 plain-attack
      score service). Pinned: ai_weights→category-base mapping
      (+17/+19/+18→cat1/2/3, +20→$DC5C state-0 preamble), category score
      formula + mod ladder, quirky partial sort + the not-rank1 +$1E
      cat1 bonus (hidden $73AB check), option-list {tag, skill} layout,
      per-skill sum, tag filter, pick argmax + RNG-bit0 tie, commit
      (skill only, target $FF), $dd0b modes (0 lightweight/1 full/
      2 finisher), retry $76A9 = the S79 stall ROOT CAUSE ($dd02++
      unbounded). PyBoy hook-timing trap found + protocol fixed
      (PYBOY_DEBUGGING).
- [x] **S82 — ANNOTATION CATCH-UP, part 1 (GATE — Iron Rule 6): bank $57
      AI machine. DONE S82** via `tools/resection_ai_bank57.py`
      (idempotent, probe-build technique; both builds byte-perfect):
      state dispatch AIDecisionStateDispatch_6e0e + AIStateDispatchTable_6e12
      converted (states 0-7 named); AIRuleChainIndex_4302 + the three
      chains converted to labeled dw lists — counts BYTE-VERIFIED
      39/**85**/40 (the S81 "61" for cat2 was a miscount; DOC_AUDIT S82);
      all 131 rules labeled (~30 semantic + provenance comments, rest
      AIRule_<addr>); stage/helper renames (AIState1..7, AISatAdd_455f,
      AIScanSlots_4456, AICategoryRank_7322, walker/veto/retry/commit
      family) with references updated repo-wide; $4E36 bug comment;
      CheckMonsterSlot ($00:$2FA5) contract comment FIXED — old comment
      said CF=valid, actual is CF SET = NOT live (byte-verified).
      Acceptance met: verifier PASS, clean build `1ca6579…`.
      **Residuals (named backlog, per Iron Rule 6 → S83+):**
      (a) rule BODIES: inline rst $00 handler tables desynced mgbdis
      inside many rule internals (all 131 heads boundary-align;
      64 `call AISatAdd_455f` sites render as soup) — body re-emission
      with table-aware decode is future re-section work;
      (b) DanceShut/MouthShut ($91/$92) + DeMagic/ThickFog ($80/$83)
      rule addresses not yet identified among the neutral labels.
- [x] **S83 — ANNOTATION CATCH-UP, part 2 (GATE): banks $52/$53/$58
      battle core.** ✅ DONE 2026-08-20 (byte-neutral; verifier PASS 6/6;
      `tools/resection_battle_core.py`, idempotent per bank). All §15.1-
      15.8 damage/status/turn-order findings + the S81 target-resolution
      trace are now labels/comments/dw-dp tables in source: 28-state
      BtlActStateTable_6c60, SetupSubStateTable_44ce (9),
      ActPhaseStateTable_51ec (16), the bank $58 head split into 14
      rst $10 service slots + the 230-dw per-skill
      BtlSkillTargetDispatch_401d (previously undocumented), turn-order
      family, boss gate, sleep wake, Sacrifice, confusion rewrite
      (+ table = bank $52, DOC_AUDIT). **CORRECTED: the act-time
      resolver far-call is $58 ENTRY 8 (BtlQueueFetchService_5498), not
      entry 4** — $6379 (dw slot 4) is the measured resolver reached
      per-skill; rst $10 convention pinned (addr=$4001+2·L).
      **THE ANNOTATION GATE IS CLEAR — the S81 remainder and S80 pacing
      layer are UNBLOCKED.** Residual (non-gating): the neutral
      BtlActState_/ActPhaseState_/SetupSub_ internals and the unlabeled
      per-skill service bodies ($62BF/$63D6/$634D…) get semantics only
      when future sessions measure them (S70 rule).
- [ ] S81 — AI residuals + loop validation (**PARTIAL, S81 session 1;
      REMAINDER was BLOCKED behind the S82/S83 annotation gate — GATE CLEARED S83**):
      ✔ evaluator rule chains DONE — per-CATEGORY chains (NOT
      effect_class-indexed; hypothesis falsified), full 160-skill sweep,
      model `simulator/ai_rules.py` **240/240** vs corpus
      (`validate_rules.py` + `s81_sweep_corpus.json`); vanilla bug found
      + user-flagged as romhack enemy-AI fix candidate ($4E36
      non-incrementing AoE scan). §15.10.5 rewritten.
      ✔ S84: enemy target resolution CLOSED (commit-time write site =
      entry 8 itself, frame-exact; $6379 side-blind BY DESIGN =
      Massacre-class; $4C87 breadcrumb resolved = player Massacre path);
      $dd0b init assignment CLOSED (per-slot INT ladders both sides,
      boundary-measured, enemy lo-byte quirk = editor validation note);
      tactics CLOSED ($DD03 nibble tactic 0-3, +20/+45 category bias via
      $6F8C, obedience level gate, $7997 table extracted — the "$DB50-52
      plan adjusts" hypothesis confirmed-with-mechanism; user anchors
      match: Cautious biases cat3-heal, 77a4 IS the Cautious check);
      lightweight picker tail CLOSED (full decode incl. self-healing
      empty-category cursor walk); MISS/dodge CLOSED (bank $53 act-time
      gate machine, thresholds byte-exact; $DA33 = presentation only;
      $52 twins dead code). §15.10.7a-.10.10.
      ✔✚ S84 CRASH FIX: dispatch-table bounds guard (DispatchBoundsStub)
      for AI-committed ids > $E5 — built, PyBoy-verified, NOT yet
      user-tested (PROJECT_STATE S84, KEY_LESSONS S84).
      ✔ S85: **loop-level differential validation of simulator/battle.py
      DONE** — `measure_battle.py` (31 waypoints, full board) + 25-battle
      corpus `s85_battle_events.json` + `validate_battle.py`: **6614
      comparisons / 0 mismatches**, 37 check kinds (BATTLE_SKILL_SYSTEM
      §15.8b). CLOSED with it: group-cast→$3A rule
      (`EnemyDupCastConversion_4e63`: enemy converts iff ANY enemy
      precedes it in the order, per-EID flag table $53:$41DF, list
      $4EE4, $DD0B!=2 — 424/424); $DB07 timer TICK (phase-9 sub 0/2);
      +2 bit1 applier = PoisonAir $6D; curse self-hit (4 RNG2 branches,
      MaxHP/6); LoadBtlC_5857 (= skill $41 exemption); act-time re-resolve
      + MP/seal veto rules; status-spell ladders; DoT cap CORRECTED
      (remainder, not quotient — status.py fixed).
      ✚ S85 PATCH: AI-committed Tremor/Quake swept the PARTY (stub row
      $6367 = own-side base) → $E5-$E8 now route to $62BF; AI-committed
      Anchor was a self-inflicted MegaMagic → S85b: AI-committed $E4 is
      rewritten to Attack at commit (vanilla-equivalent; the no-op showed
      an orphan "Has no effect" line in the user's test). **USER-CONFIRMED
      S85: AI Tremor/Mourn/Infernos work** (ROM `4c8de38a…`); the Anchor
      rewrite (patched ROM `a17bff8e…`) USER-CONFIRMED S86 (works, no
      orphan-line recurrence; user-reported).
      Still open: multi-candidate target RNG pick (commit/act dispatch RNG
      not captured — validator takes the engine's); confusion action
      table vs the curse-induced $99 HitAlly; PoisonHit/Paralyze rider
      chances; poison cap >=10 sample; curse MP-drain amount;
      $DB07 timer WRITERS; `simulate_round` driver not validated as a
      whole (needs an RNG idle-step policy — the pacing layer's first
      question); editor2 `test_compiler --rom` pin RE-PINNED S85b to `a17bff8e…`
      (39/39; S84's `b99455d6…` move was never recorded there);
      state-0 TRUE-loaf branch runtime sighting ($6f64 codes $98/$8D);
      mode-2 finisher variant $448A internals; $7997 table consumption
      point; bank $58 entry 11 internals; meta-action codes (vanilla
      flee $E9 vs custom Mourn id COLLISION — vanilla flee path
      reachability unmeasured, SameBoy candidate); small rule residuals
      (§15.9: $4DF9 condition, Shut/util pass-branches, SuckAir/Surge
      presumptions). Also still open from S79: sleep-application writer;
      $db06 bit2 semantics. (Timer tick, DoT applier, curse magnitude and
      LoadBtlC_5857 closed S85 — see above.)
- [x] S80 — pacing layer — **DONE S86** (byte-neutral; verifier PASS):
      ✔ RNG policy ANSWERED BY MEASUREMENT: the live RNG is a full-period
      16-bit LCG, so every idle-step count between captured waypoints is
      uniquely recoverable offline — `simulator/measure_idle.py` over the
      S85 corpus (5,636 pairs) → `simulator/s86_idle_model.json` (8
      measured per-class pools + proofs: same-frame pairs carry only the
      deterministic k∈{0,1}; phase-9 consecutive DoT rolls are k=0, an
      IDENTICAL state; MISS→core is same-frame). `battle.simulate_round`
      restructured to idle at exactly the measured sites (+ the decoded
      §15.10.10 front-weighted target pick); validate_battle regression
      intact 6614/6614.
      ✔ Full-battle driver `simulator/pacing.py`: IdlePolicy (empirical /
      uniform / identity; O(log k) affine stepping), commit machine
      (category machine + S81 chains for $dd0b 1/2; decoded lightweight
      picker for 0; tactics bias + obedience gate per §15.10.7a),
      `simulate_battle()`, `ttk()`, board construction from
      enemy_stats/encounters/species (resistance packing).
      ✔ Aggregate validation `simulator/validate_pacing.py`: LEVEL 1 =
      round-level PIT, 197 clean corpus rounds ×200 sims from the
      engine's own board+queue — engine outcomes rank UNIFORM (KS 0.038 <
      0.097 crit, coverage 87.8% in [5,95], KO sets always ≥5% model
      events); **empirical and uniform idle policies statistically
      indistinguishable** (the "both work" hypothesis is now a finding —
      'empirical' stays default as the measured one). LEVEL 2 = 5 FRESH
      unforced real-save battles (S86 .sav; corpus
      `simulator/s86_fresh_battles.json`): validate_battle 802/802 on
      never-seen data; engine outcomes at sim percentiles 75/46/85/82/48.
      ✔ TTK sweeps `simulator/sweep_ttk.py` (any ROM build via
      randomizer Rom.load; gate pools from extracted/encounters.json;
      level-scaled reference parties `party_for_level`; both party
      policies) — vanilla early-gate curve is clean and monotonic.
      ✔ Wired: `randomizer/profile_check --ttk` (opt-in; default run
      unchanged) — per-pool weighted median TTK ≤ 2.0× vanilla,
      level-scaled party, identically-seeded per ROM so
      vanilla-vs-vanilla is exactly 1.00× (verified PASS, 128 pools).
      RESIDUALS (S86, also §15.9): ~~party-side category-base fill~~
      **CLOSED S87** (instance record +$5B..$5E; creation roll; WLD);
      ~~obedience mid-band banded-RNG term~~ **CLOSED S87** (exact,
      889/889); the rule chains' element→resist_score mapping unpinned
      (validated with the zero stub; pacing keeps that configuration —
      feeding flags9 is WRONG and was reverted in-session); custom-room
      pool sweeps (bank $71 RoomEncTable) out of sweep_ttk scope.

## S87 — commit-model close-out: party bases, obedience, WLD (user-directed)

User direction: finish the simulator arc's remaining stand-ins; "err on
the side of doing more". Hacked .sav supplied (fresh game, Slib L1 with
custom skills $E4/$E5/$E9).

- [x] Party-side category-base fill DECODED + MEASURED (hook-verified on
      the real save): bank $51 `LoadBtlS_44cb` walks the party monster's
      own instance record; +$5B/+$5C/+$5D/+$5E → $DC44/$DC54/$DC5C/$DC4C
      (wBattlePostFlag-gated; swap-in re-sync $53:$6236). Source =
      enemy-stats ai_weights through the one-time CREATION ROLL
      (bank $14 `SaveEnem_47fd`/`_4821`: ($CD+RNG mod $34)/256, the $100
      overflow = exactly 1.0×). Slib's 80/186/189/85 = a legit roll of
      EID 1's [100,200,100,200]. §15.10.1; MONSTER_DATA.
- [x] Obedience gate EXACT + validated **889/889**
      (measure_obedience.py → s87_obedience_events.json →
      validate_obedience.py): band table {5,7,9,11,13,15}, the
      mod-with-multiples-promoted quirk over RNG&$3F with LCG-step
      replay, the COMPLETED inequality (S84's note dropped $db4d and
      $db53), boundaries + all four tactics. §15.10.7a.
- [x] $7997 consumption point CLOSED (= the decide's $db53 addend);
      table re-sectioned to `db` (`ObedienceThreshTable_7997`,
      byte-identical).
- [x] TRUE-loaf RUNTIME-SIGHTED: plan-$81 Command carry-divert; all
      three codes ($98/$3A/$8D) live; `SetBtlAI_7f5f` exact
      (cat1-dominance rule). The sim's tactic-3 always-Attack shortcut
      corrected.
- [x] **wBattleLVL = the WLD stat, not the level** (INFO-screen
      verified; record slot+$60; init 5×level − 10×arenaTier; breeding
      zeroes it; Add/SubMonsterWLD item adjusters). Instance-record map
      corrected (MONSTER_DATA — the old $4B..$5A rows were missing the
      MaxHP/MaxMP words; the S36 "±2 WLD-style" prose was the LEVEL CAP
      roll).
- [x] Mislabels fixed both trees: SetMonsterSkill1/2/3 +
      ClearMonsterSkill1/2/3 → Add/SubMonsterAIWeightCat1/3/2;
      ClearMonsterAGL → SubMonsterWLD (+ AddMonsterWLD label).
- [x] pacing.py: exact obedience on WLD; real party bases
      (make_board `ai_weights`/`wld`, `party_bases_from_row`,
      `default_wld`; PARTY_FALLBACK_BASES = labeled reference);
      validate_pacing `--pbases` (default = the measured Slib record).
      Full regression green: 6614/0 + 802/0, rules 240/240, ai 26/26,
      idle CHECK OK, level-1 PIT unchanged, level-2 72/44/89/77/46
      (S86's recorded 75/46/85/82/48 = `--pskills 0xe9,0xe5`, now
      recorded), profile_check --ttk PASS 1.00× vanilla-vs-vanilla.
      Byte-neutral session (clean `1ca6579…`, patched `a17bff8e…`
      both verified after every annotation batch).

## S88 — Simulator wrap-up part 1: Group A residuals (built S88, NOT yet user-tested)

- [x] Confusion end-to-end (§15.8c): generator $4BEB decoded + measured
      (10/10 picks incl. live RUN + blocked-$A1 re-roll), meta-actions
      $99-$A1, uniform target picks ($642C/$6479 family), on-hit
      snap-out $5F15 (8/8, mask &$63), curse-confusion unified (state
      $11). The S79 $7AB5 attribution was WRONG (Transform/BeDragon —
      DOC_AUDIT S88; labels corrected, byte-neutral).
- [x] Status riders $67/$68/$69 modelled (rider_roll 40/40); $69 boss
      veto = application-only ($69 REMOVED from BOSS_PROTECTED_SKILLS —
      its damage lands); $68 = sleep rider via $5C8F -> $6749 STATUS
      ladder (only Sleep $15 gets the B-ladder).
- [x] Poison DoT cap >=10: 15/15 exact (10 + RNG16%6) on MaxHP 300.
- [x] Curse MP drain = MaxMP//6 (4/4; maxmp plumbed through rig+Board).
- [x] Sleep counter source: CONSTANT $8C (SleepApply_4262).
- [x] PsycheUp carry-over: closed EMPTY — $56 shares the x1.5 TwinSlash
      handler $462F; no charge mechanism. PHYSICAL_IDS += $56/$9A/$9B.
- [x] $DB06 map + $DB07 surround/dodge writers + TailWind guard (+4
      bit6) + incapacitated-target dodge exemption (miss_gate fix) +
      one-shot consume-clear (status_forced_action fix).
- [x] New corpora: s88_confusion_events (2824/0), s88_rider_events
      (3422/1 — ONE flagged ±1 calcdef anomaly, repro in §15.9),
      s88_curse_events (3083/0). Legacy corpora green: s85 6614/0
      (count changed 6614->6614 after the wrong confusion_clear check
      was replaced by modelled checks), s86 802/0. measure_battle: 9 new
      waypoints + --db73 + maxmp capture.
- [x] $DB07 stun writers — CLOSED S89: **Ironize $2A / IRONIZE $DC**
      ($C0 = 3-round counter, phase-9 tick; forced $11 + FULL incoming
      immunity via the $56E1 flags8-bit2 gate; party cast irons the
      WHOLE side per byte-read). WarCry-family EXONERATED (+5 one-shots:
      $7D bit4, $7B/$7C bit2). §15.9 CLOSED S89.
- [x] "Interception redirects" referent — CLOSED S89: the act-time
      guard-table redirect (Cover $88 one ally / Guardian $89 both
      others; $DB08/09+8t mark+protector, one round, first-protector-
      wins; consumers ~$552x/$567x flags8-bit1-gated + $670E state 0;
      HP-flow-proven). $670E rst table re-sectioned byte-neutrally.
      Model: battle.guard_redirect (driver path; validator integration
      = open box below).
- [x] element -> resist_score mapping PINNED (record status_id = res
      pos; $6A8A service + $7AA6 shifts + $4532 prologue byte-read;
      packing verified vs live arrays; 240/240 + PIT green; stub
      retired in validate_rules AND the pacing adapter).
- [x] S87 corpus-field deferral discharged: measure_battle now captures
      ai_bases ($DC44..$DC63) + WLD words ($DC23+2i), live-verified
      (Slib WLD 5 / enemy $00FF). s88 corpora predate the fields.
- [x] WLD post-creation level-up writer trace — CLOSED EMPTY S89:
      L1→L13 one-scan, +$60 frame-sampled unchanged; writer set closed
      (creation/breeding/items). MONSTER_DATA + default_wld updated.
- [x] s85/s86 corpus regeneration carrying the new ai_bases/WLD fields —
      DONE S89 (patched pin a17bff8e + the user's .sav boot.state):
      s85_battle_events.json REPLACED (25 scenarios, 5751 ev, 6614/0
      exact check parity); s86_fresh_battles.json KEPT (802/0);
      s89_fresh_battles.json ADDED (5 fresh unforced, 343 ev, 426/1 —
      the 1 = the flagged low-stat calcdef edge, §15.9).
      board_from_event now consumes the fields; level-1 PIT re-run
      GREEN with them (KS 0.055, coverage 91%).
- [~] Meta-actions — PARTIAL S89: $E9-class metas are the HERO slot's
      MENU verbs (queue-forcing idx 3 never enters the order —
      readiness-gated); empty-option-list enemies never emit metas;
      outleveled wild EID 3 never fled (db73=0). NEXT: real-menu drive
      (directed d-pad) for Flee/Item/Shift commit writes; vanilla id
      space needs the CLEAN ROM + franken-state (the hacked .sav is
      REJECTED by the clean build — S75 build-specificity, confirmed
      live S89).

      Still open (inherited): bank $07 CallFld_451e INFO-screen
      renderer noted, internals unexplored. (S89 discharged: the WLD
      writer trace, the corpus fields, the stand-ins.)

## S89 — Simulator wrap-up part 2: Group B residuals (built S89, NOT yet user-tested)

- [x] All four Group B boxes above (stun writers / interception / WLD /
      corpora) + the defensive-set sweep (+8/+9 flags: Imitate/Dodge/
      SuckAll/Defence-class levels — setters measured, §15.9).
- [x] Annotation (byte-neutral, clean MD5 1ca6579… re-verified): $670E
      dispatcher re-sectioned (7-state rst table) + InterceptGate_6720
      label; GuardMark writer, $4BD3 checker, SkillIronize/SkillCover/
      SkillDodge/SkillBladeD_Defense comments. SacrificeEntry_670e
      attribution corrected (DOC_AUDIT S89).
- [x] Validator suite re-run on the final layout: battle s85 6614/0,
      s86 802/0, s88 2824/0+3083/0+3422/1(known), s89 426/1(flagged);
      damage all-exact; obedience 889/0; rules 240/240; order 143/0;
      ai 26/26; pacing level-1 UNIFORM w/ real fields (KS 0.055).
- [x] LOW-STAT CALCDEF EDGE — SOLVED S89 (PyBoy): never a calcdef bug —
      an unmodelled **×1.5 damage boost gated on `$DB42` bit 6**
      (attacker). Consumer decoded byte-exact at `$53:$59CD`
      (`dmg + (dmg>>1)`, half truncated), runs after CalcSkillDefense and
      after the slot-2/floor adjust. Correlation 8/8. Closes BOTH
      deterministic repros — s89_fresh 426/1→426/0 AND the S88 rider
      anomaly 3422/1→3422/0. Model: `battle.db42_boost()` in the physical
      and record damage paths; Board carries `db42`.
- [ ] `$DB42` bit6 SETTER — the one genuinely open sub-item: observed set
      in the command/order phase ($D9EC==5) and cleared in phase 9 (a
      one-round actor mark), but NOT written as `set 6,[hl]` / `or $40` /
      `ld [hl],$40` against a `$DB42` pointer anywhere in banks $50-$5F.
      Find the writer (some other addressing form) and the game-facing
      trigger (crit? charge? tactic?).
- [x] guard_redirect FULL per-victim integration — DONE S89: marks are
      set when Cover/Guardian resolve (`battle.set_guard_mark`) and
      cleared each round (`clear_guard_marks`); side sweeps start at the
      QUEUED target and walk forward (measured: $0A queued on slot 5
      swept [5,6], never touching 4 — `side_victims(start=)`), each
      victim redirecting independently WITHOUT dedupe (a protector
      covering two allies is hit twice). s89_guard 20 mismatches → 1
      (a residual waypoint-grouping edge where one victim group lacks a
      `miss_in`), pinned corpora unaffected.
- [x] guard_redirect VALIDATOR — DONE S89: new `guard_redir` waypoint
      ($53:$5544) in measure_battle.py + `s89_guard_events.json`
      (--eskill 0x89/0x88 --ecount 3); model validated **14/14** against
      the captured marks (incl. dead-protector fall-through). Full per-
      victim integration into validate_battle's main runner is the
      remaining polish (standalone check green).
- [ ] +8/+9 defensive-flag CONSUMERS (Imitate/Dodge/SuckAll/defense
      levels) + the $4BD3 attacker $30 setter.
- [ ] Meta-actions real-menu drive (recipe in the [~] box above).

## S90 — EDITOR_DESIGN v2: UI/use-perspective revision (user-directed; byte-neutral)

User direction: "revisit plan but also from ui and use perspective" +
tab list (rooms/palette/NPCs/dialogue/triggers/cutscenes+playback, room
state switching, monster editing incl. sprites, breeding edit+simulation
per the randomizer, encounters, flags, music/MIDI, one-screen canvas
with obvious room boundaries) — "We want to make a game here."

- [x] EDITOR_DESIGN rewritten as v2: full tabbed UI spec (§5, every
      surface citing its decoded/built backing), Layer A-lite decision
      (§6 — vanilla data-table editing via same-size emitters before
      full extraction), simulator-as-a-product Balance tab (§5.9),
      backend gap register (§9, G-A..G-I), milestones re-cut (§10),
      superseded-v1 ledger (§11; stale v1 §7/§8 retired — DOC_AUDIT S90).
- [x] Phase 3 re-sequenced into one-session boxes P3.1-P3.17, each with
      an acceptance test (replaces the coarse "canvas → … → world map"
      and "game-data editors after Phase D" boxes).
- [x] Simulator arc adjudicated DONE for purpose (audit, this session):
      residuals banked as existing boxes ($DB42 setter, +8/+9 consumers,
      meta-actions menu drive [needs a CLEAN-build .sav or franken-state],
      guard validator polish) — none block Phase 3.
      Byte-neutral session: verifier PASS 6/6, clean MD5 1ca6579… only.
- [x] v2.1 (same session, user workflow decisions): FORK-DON'T-FIDDLE
      principle (clone vanilla→custom + repoint while capacity lasts;
      in-place edits only under capacity pressure) + CANVAS-FIRST
      interaction rule; clone-to-custom extractor specced (P3.2b, arena
      first); Gates tab (P3.7b); Triggers-as-sentences (+ flag-keyed
      pool variants G-O); Arena editor (P3.10b) + Shops decode (P3.13c)
      promoted from Phase E; AI ban-list banked optional (P3.11b);
      CAPACITIES reference (P3.0) + capacity-meters principle; family-
      icon editor + follower visualizer + the sprite-background
      white-vs-cream defect logged (G-P; PROJECT_STATE Open defects);
      ROM-expansion 2→4 MB assessed + banked as contingency (NO prior
      session claimed it; the S69 expansion was SRAM). Layer A proper
      shrunk to exit repoints + M2R (EDITOR_DESIGN §6.3).
