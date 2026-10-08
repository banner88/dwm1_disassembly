# TOOLS & EXTRACTED DATA — Audited Manifest

Full audit 2026-06-13 (method: regenerated dumps against the original ROM,
diffed vs committed JSON, dry-ran every generator, traced every JSON to its
writer/readers — 62 tools / 37 JSONs then). **Manifest re-synced 2026-07-02
(S51): now 102 tools in `tools/` + 7 `dwm/` package modules, 54 JSONs in
`extracted/`.** Rows added after 06-13 are manifest entries, not re-audits.
SESSION_PROTOCOL §3 rule 5: new/changed tools + JSONs get their row the SAME
session.

---

## 1. extracted/ — JSON inventory

### Tier A — Regenerable & verified fresh
Regen produces identical output to committed file. Safe to re-run.
| File | Generator | Notes |
|------|-----------|-------|
| service_lines.json | extract_service_lines.py | **NEW (S126, P3.14e1; S128: + kind `arena` — 10 blocks, 188 lines).** The service menus' text blocks (shop `$0680`, Vault `$06A0`, farm `$06C0`, Medal Man `$0720`, Library `$0740`, egg appraiser `$0750`, namer `$0780`; 139 lines): per line the raw bytes, voice, speaker (+ raw), tail, the words (textenc + `{hero}` / `{ins0..3}`), block bases / screen types / handlers / the game's NPC, the offsets the ENGINE speaks, and the Medal Man's reward table (`$12:$6D29`, 4 rows) + its count sites. `--selftest` (verify check 5): JSON == ROM, every line re-encodes to its bytes, retyped words match. Read by editor2/core/services.py. Owning prose: PROJECT_COMPILER §2.39. **S127:** + Grandpa `$06F0` (32 lines, bank $0A, two say ranges) and the breeding masters `$0600` (10 lines) — 9 blocks, 181 lines; PROJECT_COMPILER §2.40. |
| mapid_range_audit.json | audit_mapid_range.py | S66: A′1 census — every `ld a, [wMapID]` site in BOTH trees (58 clean / 56 patched in S66; 58 / 86 as regenerated S126) with pattern classification and the S66 adjudicated verdict per site (label-keyed), plus the ceilings dict (hard $FE / practical $EA / BGM-default $7F). Tree-derived only (no ROM needed). Regenerate with `--json`; selftest pins the counts and fails on any NEEDS_REVIEW (new consumer since S66 → adjudicate by hand, key it in the tool, record reasoning in CROSSBANK_ROOMS). |
| wram_usage.json | audit_wram.py | S54; REGENERATED S55 (curated arrays added: attr staging $C200, screen staging $C300 ×$200, battle tile buffer $C500, audio channels $DD80-$DE2B, battle stat tables — gaps 51→34; the S54 relocation candidates $C20D/$C42B were FALSE, see KEY_LESSONS S55). Selftest re-pinned S55: buffers still class-B (accepted legacy), relocated labels at $DE74 clean, audio ceiling pinned. Regenerate with the tool; not ROM-derived alone (also parses docs + patches). REGENERATED S56: curated staging pseudo-slot entry added ($D665-$D78E, monster-array indices $14/$15); gaps 34→31; selftest re-pinned (staging extent). REGENERATED S65 (tool+data together): FREED_WINDOWS model added (CF3 window $CC80-$D664 — in-window collisions with the retired vanilla claimant AND in-window vanilla literal refs classify informational F:cf3-freed[-vanlit], never A/B; the literal refs are data-as-code artifacts, $CD=CALL opcode — KEY_LESSONS S65); vanilla-alias filter exempts freed-window labels (junk refs at $CD00/$D001 were dropping the migrated buffers/pool); selftest re-pinned (S54 detection power kept via a synthetic probe at $CAC5 which must still flag class B; migrated labels must classify F); arg guard added (unknown flags incl. --help print usage instead of silently regenerating the JSON — the prior behavior caused an accidental regen this session, reverted). NOTE: this regen also refreshes referenced_by lists that had drifted as later sessions added labels to banks. |
| monster_walkers.json | map_monster_walkers.py | **NEW (S56, CF1).** The monster-array access map: all 44 `ld [$cac0],a` writer sites + 60 register/stride walkers classified (party-only / all-slot / farm-write / single-slot / staging), membership semantics, exp-share model, roster mutation path table, staging pseudo-slots. Self-checking: writer-set drift or missing labels abort. Owning prose: MONSTER_DATA "Party/farm boundary semantics". |
| songs.json | enumerate_songs.py | **NEW (S61, M1).** Full sound enumeration: 86 sounds / 158 channel streams from the master table @ ROM0 $3466 (banks $1C/$1D/$1E), each stream statically walked to termination (zero overruns), with per-channel slot/hw/seq/extent/header. Owning prose: SOUND_SYSTEM.md. |
| songs_spec.json | song_codec.py | **NEW (S62, M2).** Full decoded-song spec: every stream in banks $1C/$1D/$1E as a token list (notes/ctl/fx/slides/loop_jump/mark), records, orphan records, unreferenced tails — the byte-exact round-trip source (`selftest` re-emits all three 16KB banks byte-identical) and the M3 common intermediate for DWM2/MIDI import. Owning prose: SOUND_SYSTEM.md §5/§8. |
| dwm2_song_library.json | song_codec.py extract-gbs-library | **NEW (S64, M3b).** The FULL DWM2 catalog: all 31 subsongs (19 BGM + 12 jingles; names per the zophar m3u set; `gbs_index`/`dwm2_internal_id` via the GBS song map @ $0FC0) translated to DWM1-native tokens with DWM1 slots + per-channel trace proofs; `_source_gbs.md5` recorded so the GBS never needs re-uploading. 57,383 stream B — a CATALOG: the music emitter bakes only songs assigned in project.json (bank $74 streams cap 16,000 B). Foreign cmds carried inert: $AA (BGM #07/#14 — DWM2 ornament), $A4 (BGM #19 — no-op in BOTH engines, S64-verified). Owning prose: SOUND_SYSTEM.md §7/§8. |
| midi_song_library.json | midi_to_song.py | **NEW (S64, M3c).** MIDI conversions in the same catalog schema. 1 song: `dq6_town1` (3ch, 1,325 B, 92.0 s loop; source m3u/md5/tempo-map + full conversion options recorded for reproducibility). Owning prose: SOUND_SYSTEM.md §8. |
| sound_catalog.json | dump_sound_catalog.py | **NEW (S116, P3.13b).** Every vanilla START id (92: the 85 sound first ids + the other ids the room table / scripts / code / sound test start, e.g. $61): kind (music / jingle / effect — the bank $55 developer sound test lists + a measured play on the editor's sound engine: music = still sounding after 3 minutes), channels + state slots as started, length in frames, the rooms (RoomBGMTable $01:$4373), the set_bgm scenes (all_scripts.json) and the SetBGM code sites (code-read, the `ld a/b, n` bytes checked). `--selftest` = the anchors (verify check 5). The Music tab's vanilla list. Owning prose: SOUND_SYSTEM.md §9. |
| ~~custom_songs.json~~ | — | **RETIRED S64** (was S63's M3a library). Song ownership moved to project.json `custom.music` + the library JSONs above; its two songs re-emit BYTE-IDENTICALLY from `dwm2_song_library.json` (verified against the pre-S64 `patches/bank_074.asm` — the fixed-record-area property held). |
| monsters_full.json | none (first import `cba8952`; S120 — no tool writes it) | 221 monsters, all 43 fields. S120: == the ROM's MonsterInfoTable rows — a frozen, correct input. |
| encounters.json | dump_encounters.py | **REWRITTEN + REGENERATED S114** (tool + data together): 32 gates → their floors (1 .. floor count − 1, the game's numbering) grouped by list, 125 lists reached; per list rate code, 1/2/3-monster %, five slots (EID, species, level, chance %, real chance, max count) and `_generator`. The pre-S114 file had the floor ranges one floor late, ignored floor counts, read 4 slots and called +20 a weight (DOC_AUDIT S114). `--selftest` (verify check 5). Readers: editor2/core/monsters.py (fallback only — live usage comes from encounters_doc), simulator/sweep_ttk.py (skips `_` keys), tools/gen_encounter_db.py. |
| boss_table.json | dump_boss_table.py | $4897 table, 32 gates. Verified identical. **SEMANTICS CORRECTED S67:** this is the tail of the fight→join REDIRECT table ($4893, recruitment mapping) — it does NOT select which boss you fight (that's the $5A/$05 param in each boss room script; see arena_brackets.json). Data unchanged. |
| arena_brackets.json | dump_arena_brackets.py | **NEW (S67, E1).** The complete opponent-roster system: arena formula rosters (10 groups × 3 matches × 3 slots, EIDs 224-304/481-483 with full stats), master lobby sprites ($04:$5E22), entry gold ($09:$5D23), all 53 script battle-trigger sites (opcodes $5A/$05/write_ram2, script-attributed), redirect table, coliseum RNG level bands + prize tables, Mimic ($04:$63EF, $CAB4-tiered) and random-scaled ($04:$6A3C) tables. Self-checking ROM anchors. Arena path USER-VERIFIED S67 on HW. Owning prose: SIDEQUEST_MAP "Arena / gate-boss ROSTER format — DECODED S67". |
| all_exits.json | dump_all_exits.py | Verified identical. |
| enemy_stats.json | dump_enemy_stats.py | **RECONCILED this session.** Full 25-byte layout now decoded: +1..2 exp LE16, +3 joinability, +17..20 ai_weights, +21..24 skills. 487/487 match. |
| ~~skills.json~~ | ~~dump_skills.py~~ | **RETIRED S59 — file DELETED, do not recreate.** Superseded by `skill_records.json`. It read the skill function table as 256 entries; the table is 222 (ids $00–$DD, $52:$4011..$41CC, 444 B), ending where the first handler begins (`SkillBlaze` @ $52:$41CD, bytes `CD FF 5B` = `call $5BFF`). The extra **34** ids (222–255, not 33) were that handler's CODE decoded as pointers — hence blank names and bogus `$FFCD`/`$CD5B`/`$E7CD` addresses. All readers ported to `skill_records.json` S59: `gen_skill_table_db.py`, `gen_enemy_stats_db.py`, `gen_monster_db.py` (the pre-S59 note claiming `gen_name_tables_db.py` was the sole reader was backwards — that tool declared the path but never opened it; the dead constant is gone). `dump_skills.py` is now an inert documented tombstone (exits non-zero). |
| skill_records.json | gen_skill_records.py | **NEW (S44).** 222 records ($00–$DD), the editor source of truth. Per skill: name, `kind` (155 skill / 37 item_effect / 30 internal), mp_cost (ALL=999), handler + shared-handler group, learn block ($06:$50E0), prereqs, family code, monster/enemy usage; `_generator` key lists all 6 source addrs. Round-trip proven by `build_skill_tables.py --selftest` (function/MP/learn tables re-emit byte-identical). |
| skill_id_bucket_map.json | map_skill_id_buckets.py | **NEW (S48).** The de-aliasing FOUNDATION for S2d: every place the battle engine buckets the working skill id (`$db8a`, 254 reads / 9 banks), classified (equality/range/table-index) with per-gate verdicts for a custom id (`≥ $DE`); the verified fork points (record `$54:$4013` keystone, function, MP, sound, anim, name, learn-req); the high-range special gates; the full cast pipeline (production→consumption); the byte-neutral fork feasibility proof; and the SameBoy hardware-verification block. Self-checking: the tool re-derives the load-bearing anchors from the ROM and aborts on drift. See BATTLE_SKILL_SYSTEM.md §12. |
| text_id_map.json | dump_text_id_map.py | **S108: REBUILT from the measured `dialogue.json`** (2,558 ids; the pre-S108 file — "2,061 entries … structurally identical" — modelled the cascade and matched the game for 62 entries: DOC_AUDIT S108). Schema unchanged (id / bank / index / addr / one-line text). |
| map_table.json | dump_map_table.py | **REWRITTEN this session.** Fixed TWO bugs: (1) interact/exit label swap (DOC_AUDIT A.11), (2) screen enumerator stopped at first $FFFF hole, dropping a third of rooms (exits 541→812, NPCs 961→1320). Ground-truth verified (GreatTree→Well exit found). |
| exit_table.json | dump_map_table.py | Regenerated with fixed semantics (trigger coords, dest_map_type, spawn). |
| room_connections.json | dump_map_table.py | Regenerated with fixed connection graph. 262→361 connected rooms. |
| all_scripts.json | dump_all_scripts.py | **BRANCH-FOLLOWING added this session.** Follows 9 branch opcodes ($00/$01/$0E/$14/$15/$27/$28/$2C/$37) via work-queue. 732 scripts, 810 unique WriteRAM locations (was 482 linear-only; ROM ground truth 866 after false positives = 93.5% coverage). 56 unreached WriteRAMs are in alternate dispatch paths (entry 1/2 tables). Canonical room names from editor/editor.py (96 entries). New `branch_targets` field per script. |
| event_flags_complete.json | analyze_event_flags.py | **REWRITTEN this session.** Now reads all_scripts.json (branch-following) instead of linear ROM scan. 328 flags, 298 with sets (was 92). 29 check-only anomalies (was 219). Includes collision zones, SRAM boundary. |
| breeding_tables.json | build_breeding.py | **NEW (Session 13, B1 keystone).** Round-trip-faithful decode of BOTH vanilla breeding tables (special $16:$4B30 825×5; family $16:$4974 222 pairs). `--selftest` proves re-emission is byte-identical to the ROM. Independently reconciled with hand-authored breeding_complete.json (825/825 + 197/197, 0 diffs). Name-annotated; `_generator` stamped. |
| monster_sprites.json | extract_monster_sprites.py | **NEW (Session 22, GFX-1); REGENERATED Session 23 (all 221 — the shipped copy was a 3-monster subset, a data defect now fixed).** All 221 monsters' battle + follower sprites: species → gfx-ID, bank, index, stream addr/len, declen, tile count, grid, and decoded 2bpp tile bytes (hex, regenerable without PNGs). Count-parameterised (`--count`). Decoded via `dwm/sprite_codec.py`; `--png` writes images to `extracted/monster_sprites/`. **REGENERATED S106 with the corrected decoder:** 262 of the 442 streams (213 battle, 49 walking) had been decoded wrong since S22 (garbled battle art); now == the game's own decompressor for all 442 (`tools/census_lz_decode.py`, PyBoy; test_compiler --rom re-checks the manifest). |
| monster_palettes.json | extract_monster_palettes.py | **NEW (Session 23, GFX-2).** All 221 per-species BATTLE palettes from `MonsterBattlePalettes` `$17:$62FD` (8 B/species, 4 RGB555 `[c0, c1=$6bff backdrop, c2, c3=$0000 black]`). Recolour via `build_sprite_swap.py --palette`. |
| follower_layouts.json | extract_monster_follower_layouts.py | **REGENERATED & REPLACED Session 25 (GFX-4).** Now the COMPLETE **155 distinct follower layouts** decoded from the REAL species-indexed dispatch (`$10/$11:$407f`), incl. the 3-entry small/blob layouts the S24 brute-force scan dropped (old count 118). Per layout: six frames as `{dy,dx,tile,xflip}`, sharing classification, usage count, canonical `$10/$11` example level-2 addr. *(Supersedes the S24 `extract_follower_layouts.py` output; that tool is retained but its bank-`$05` example addrs are the ObjTest-viewer path, not the follower path.)* |
| monster_follower_layouts.json | extract_monster_follower_layouts.py | **NEW (Session 25, GFX-4).** Every species (0–220) → `{bank, l1_index, l1_addr, l2_addr, attr_base, layout_id, sharing}`, traced through the real follower dispatch (`$ffc7=species+$10` → bank `$10`/`$11` `$407f` level-1 table). `--selftest` reproduces the Healer (sp9, sharing) + DarkDrium (sp214, non-sharing) anchors byte-for-byte and confirms all 215 collectible species map. **REGENERATED S106:** `attr_base` for bank-$11 species (128-214) was read at `$417F` (bank $10's base) — level-2 layout bytes; now `$412D` (`FollowerAttrTable11`): every collectible species is 0-7 (palette only); the editor's walking previews built on it match the S101 PyBoy census for 213 / 215 species (the other two: the census build's own S105 bug). |
| library_layouts.json | resection_library_tables.py --dump-json | **NEW (Session 27, Phase D).** All **29** bank-`$12` monster-library / family-tab menu window-draw layouts (contiguous run `$710c..$7b9b`) decoded to `{addr, label, pos, length, ld_de_ref, rows[]}`. `$d8`=newline, `$d9`=terminator; rows are literal tile ids. 7 layouts are direct `ld de,$imm` entry points (`ld_de_ref:true`); incl. the 380-B `$79c6` 18×20 full-screen view. Same tool re-sections the asm (labels-only, build stays `1ca6579…`). |

| species_slot_map.json | map_species_slots.py | **S28 (N1).** The 256-slot species-ID map: per id → occupancy class (real 0–214 / special 215–219 / empty 220–223 / free 224–255) + per-table presence. Self-checking anchors. **HISTORICAL classes (S105 G3):** the usable new-species range is 221–239 (PROJECT_COMPILER §2.21); its `N6_GATES` are skill-id ladders, not species gates (DOC_AUDIT S105). |
| library_grouping.json | build_library_table.py | **S19 (B7), re-owned S30.** The build-time family→members grouping table emitted into bank $12 free space; owns the 3 unseen-marker sites ($E0→$FE). Inputs: spirit_family.json + new_species.json. `--selftest` proves vanilla parity. |
| battle_animations.json | decode_battle_animations.py | **S47 (S2c-anim); S112 schema 2** (frames, timelines with sounds, tile sheets, palettes, shades, debugger gfx ids, per-skill rows, extents — the decoder is `editor2/core/battle_anims.decode_rom`). All 45 battle-effect animations; census-verified frame by frame (S112). See BATTLE_SKILL_SYSTEM §11.9. |
| effect_messages.json | decode_effect_messages.py | **S47 (S2c).** Packed hit/miss message-id pairs ($dd70/71) for all skills; 67/67 statically-resolved FAQ-validated. See BATTLE_SKILL_SYSTEM §9. |

### Tier R — Hand-authored reference material (not auto-generated; preserve as-is)
These are knowledge artifacts — human analysis in JSON form. No generator
was lost; they were intentionally curated. Treat as documentation.
| File | Contents | Used by |
|------|----------|---------|
| breeding_complete.json | System overview + 825 special recipes (ROM data at $16:$4B30) + family recipe analysis | reference |
| resistance_types.json | 27 resistance types with FAQ-confirmed mappings, letters, skill lists | reference |
| resistance_mapping.json | Structured resistance→skill mapping with skill IDs | reference |
| tile_registry.json | 9 hand-cataloged tile entries (Milayou sprite tiles) | reference |
| custom_layouts/room_6b_custom.json | 20×16 tile grid for Room $6B — user-designed Farm tileset room | tile_layout_compiler.py → bank_064.asm |
| breeding_family_defaults.json | B4 family-default overrides: positional `{result,p1,p2}` list applied in place to `$16:$4974` (offspring species == slot). Includes the shadow avoid-list inline. | HISTORICAL S103 — re-expressed as the example project's `gamedata.breeding.family` (the `--emit-family` path is retired) |
| breeding_special.json | B5 full special-table spec: `base:"rom"` + in-place `overrides` (edit any base entry, by `index` or by parent `match`) + `appends` (new entries past 824). The SINGLE authored source for the whole special table; bank `$16` stays vanilla. | HISTORICAL S103 — re-expressed as the example project's `gamedata.breeding.special` (`--emit-special` retired) |
| breeding_family_reassign.json | B6 family reassignment spec: `{id,name,from,to}` list of same-size family-byte edits ($03:$4461+$00). `from` is validated == vanilla at build time. | HISTORICAL S103 — B6 proof spec, never the committed bytes; family edits = `gamedata.monsters[].family` (`--emit` retired) |
| custom_layouts/room_6b_medalman.json | 20×16 tile grid for Room $6B — user-designed MedalMan tileset room (v28) | tile_layout_compiler.py → bank_064.asm |
| *(Room $6B current = gate-tile room)* | **S39:** Room $6B is now the Gate-of-Beginning maze-tileset room (gfx-ID `$280D`), authored directly in **`tools/build_gate_room.py`** (no JSON) → `patches/bank_064.asm`. Sandy island: ocean-wall border, 2×2 tree/dune/pit metatiles, per-position palette. Builds the v5 ROM. See GATE_GENERATION.md §7.2–7.3. | tools/build_gate_room.py → bank_064.asm |
| family_icons.json | S20: the 10 vanilla family ICON tiles ($4F:$4110-$41A0, text bytes $10-$19) decoded as 8×8 grids + the free $1A slot + the authored Spirit icon (Variants A/B). Round-trip safe (decode→encode == ROM). `_generator` stamped. **S104 (regenerated with the tool the same session):** `spirit` = byte `$1A` / `$41B0`, note updated; the grid (placeholder whip, pending the user's pick) also feeds the bank $6D `SpiritIconStream`. | tools/build_family_icon.py → patches/bank_04f.asm ($41B0) + patches/bank_06d.asm (SpiritIconStream) — lines printed by `--png`, checked by `--selftest` (verify check 5, S104) |
| new_species.json | **HISTORICAL since S105** (`_status` key): superseded by project.json `custom.species` (editor2/core/species.py, PROJECT_COMPILER §2.21) — nothing in the build reads it; `build_new_species.py --check` still validates it. Phase-N authored spec (normalized/stamped by build_new_species.py): first_free_id 224, high bank $6A, per-species info/stats/encounter/name blocks. G3 (ROADMAP) will fold ALL Gorbunok artifacts into this schema. | tools/build_new_species.py → patches/bank_06a.asm (S103: its bank $14 / bank $01 writes are retired — the EID-518 row is hand-kept in bank_014, pool slots are `gamedata.encounters`; `extract_gamedata`/the compiler read its `species[].id / name / info / enemy_stats.eid`) |
| spirit_family.json | B6 authored spec: Spirit-family reassignment list (`{id,name,from,to}`), `from` validated vs vanilla. | HISTORICAL S103 — re-expressed as the example project's `gamedata.monsters` 78 / 214 → family 10; the library grouping is the compiler region `gd_library_grouping` |
| skill_faq.json | **EXTERNAL ground truth** (community skill FAQ, transcribed — `_source`, deliberately NOT `_generator`): per-skill MP/target/learn/family data used to validate S44/S46 decodes. | build_skill_faq.py (writer); gen_skill_records.py + docs (validation) |
| npc_names.json | Hand-curated naming reference: sprite/type names, NPC labels, room-name overrides, **+ `sprite_classes` (S91: user visual classification — empty / glitch_invalid / boss_composite_fragment)**. No generator by design; merged into npc_sprite_catalog.json at `--finalize`. | dump_all_npcs.py, dump_npc_sprite_catalog.py, editor tooling |

### Tier S — Stable analysis output (generator not in repo; data is ROM-derived and unchanging)
| File | Contents | Used by |
|------|----------|---------|
| crossbank_calls.json | 1,028 cross-bank calls + dispatch tables (all 105 banks) | reference |
| room_palettes.json | 81 room palette sets (raw GBC palette values) | render_rooms.py |
| decoded_text.json | Per-bank decoded text ($42–$4E) | gen_bank41_remaining_db.py |

### Tier L — Legacy / superseded (safe to delete)
| File | Why |
|------|-----|
| monsters.json | Old schema, superseded by monsters_full.json. **Already absent before S51** (stale queue row). ⚠️ `dump_monsters.py` still WRITES this legacy schema when run — and reads monsters_full for names, the Tier-A "monsters_full ← dump_monsters" attribution was wrong (S120: no tool writes monsters_full). |
| event_flags.json | Superseded by event_flags_complete.json. **Was already absent** (untracked at HEAD; stale Tier-L row, verified S51). |
| edits.json | Legacy Streamlit-editor patch store. **Was already absent** (untracked at HEAD; stale Tier-L row, verified S51 — legacy tools already tolerate absence). |
| breeding_extra_recipes.json | B3 append path, superseded by B5. **DELETED S51** (was tracked → recoverable from git; content = one self-described capacity-proof TEST recipe, BattleRex×MadCat→DracoLord, archived in SESSION_HISTORY B3); `build_breeding.py --emit-relocation` is marked LEGACY and tolerates absence (emits base table only). |

Everything else (all_text, all_transitions, transitions, npc_catalog,
npc_with_text, npc_text_mapping, free_space, gate_names, orphan_pointers,
pointer_tables, routing_table, screen_counts, sprite_reference,
text_blobs): regenerable from named dumpers; not
freshness-tested this session — verify before relying on one for the
editor (snapshot → regen → diff). ~~npc_catalog.json is CONTAMINATED by
phantom-step rows~~ — **S120: dump_all_npcs.py applies the valid-step rule and
npc_catalog.json / sprite_reference.json are regenerated** (772 → 716 rows; S120 rows).

## 2. tools/ — classification (102 files in tools/ + the `dwm/` package)

`dwm/` package (importable, not scripts): `rom.py`, `text.py`, `map_names.py`,
`sprite_codec.py` (GFX-1 codec), `sprite_bank.py` (GFX-2 overflow allocator:
$7E,$7F→$7C,$7A,$79), `build.py`.

### Guardrail
`verify_integrity.py` — run at every session start/end. (S57:
`bank_073.asm` added to `PATCH_NEW_FILES` — the CF2 drain bank; the
compiler's builder parses these lists, so staging stays single-sourced.)
**S59: check 5 = tool selftests** (`SELFTEST_TOOLS`): runs `--selftest` on
`build_breeding.py`, `build_library_table.py`, `build_skill_tables.py`, so a
hand edit to a generated table can no longer silently diverge from the
JSON/ROM it must reproduce (previously these ran only when someone
remembered). **ROM-tolerant by design:** `data/DWM-original.gbc` is
gitignored/user-provided and CI runs without it (CI needs only the expected
MD5), so an absent ROM SKIPs check 5 rather than failing — a present but
non-canonical ROM still FAILs. Verified S59 all four ways: PASS 5/5 clean;
FAIL on a deliberately mutated `skill_records.json` mp_cost (pinpointed
`SkillMPCostTable` offset 0); SKIP with no ROM; FAIL on a 1-byte-corrupted ROM.

### Core pipeline (editor sits on these)
`tools/build_project.py` + **`editor2/` package** (✅ new S53 — the headless
editor backend: compiles `project.json` (Layer B custom + Layer D build) into
generated `patches/bank_060.asm`/`bank_071.asm` (verbatim sha256-pinned engine
template heads in `editor2/core/templates/`) + `@BUILD_PROJECT` regions in
`bank_017.asm`/`wram.asm`; content-validate → deterministic emit ×2 →
pre-rgbasm bank accounting → splice → stage/`make`/restore →
`build/manifest.json` + `game.sym`. Modules: `project.py` (schema/alloc),
`formats.py` (byte formats, doc-cited), `textenc.py`, `scriptgen.py`
(bank_004-verified param counts), `validators.py` (KEY_LESSONS rules),
`emitters.py` (registry), `compiler.py`, `builder.py`. Regression:
`editor2/example-project/` == the current reference patched build,
byte-identical (re-pinned S57, md5 `6c41f0d8…` **patched** — see
PROJECT_COMPILER §1);
`editor2/tests/test_compiler.py` 18/18 (`--rom` builds both ROMs).
S57 fixes: `project.py FLAG_SAFE_RANGES` corrected to the per-byte-audited
pool [(0x0158,0x0167),(0x01E0,0x01EF)] (EVENT_FLAGS; DOC_AUDIT S57). Owning doc:
**PROJECT_COMPILER.md**) ·
`compile_script.py` (✅ --test passes; ⚠️ S53: its OPCODES table says `set_bgm`($41)=2 params — handler `$04:$669D` consumes ONE; fix together with decompile_script.py's PARAM_COUNTS copy + round-trip re-test, see PROJECT_COMPILER.md §8) · `decompile_script.py` (✅) ·
`compress_tiles.py` / `decompress_tiles.py` (✅ roundtrip; S100 r3: copies capped at 256 B = the game's 8-bit length, decoder 8-bit like the game — longer copies had shifted imported sheets 256 B in-game) ·
`tile_layout_compiler.py` (✅ — standalone layout compiler: JSON grid
→ padded → LZSS → ASM db; roundtrip verified; editor backend module) ·
`generate_attr_map.py` (✅ new — builds tile→palette maps from ROM for
all 85 tilesets, generates LZSS-compressed nibble-packed attr data;
collision thresholds from ROM0 $26E3 ×8 stride) ·
`regenerate_tileset_pngs.py` (✅ new Session 9 — renders all 86 editor
tileset PNGs using runtime palettes from room_palettes.json; also
generates force-preview variant with colour index 1 marker tint;
outputs JS for editor HTML embedding) ·
`resection_text_bank.py` (✅ new S43 — Arc-1/T1: converts a dialogue-corpus bank's
contiguous DTE string run from mgbdis fake-instructions to `TextStr_<bank>_<addr>:` +
`db` blocks, one label per text id with decoded comment; labels/comments only, build
stays `1ca6579…`. `--bank 0xNN [--apply|--check]`. Region from data (`text_id_map.json`
first addr + ROM trailing-fill end), boundaries snapped to real line addresses via a
probe-build so no fake instruction is split. Idempotent. bank `$47` done; rest of
`$42-$4B,$4E` pending (ROADMAP Phase F Arc 1). See TEXT_SYSTEM.md "Source re-section") ·
`resection_library_tables.py` (✅ Session 26/27 — same probe-build machinery for bank `$12`) ·
`resection_ai_bank57.py` (✅ new S82 — Iron-Rule-6 annotation of the bank-`$57` AI
decision machine, same probe-build machinery: converts the `$D9EE` state-dispatch
table (`AIStateDispatchTable_6e12`, states 0-7 named) and the three evaluator rule
chains (`AIRuleChainIndex_4302` → cat1/2/3 = 39/**85**/40 dw, byte-verified — the
S81 "61" was a miscount) to labeled dw lists; labels all 131 rule routines
(~30 semantic + S80/S81-provenance comments incl. the `$4E36` vanilla-bug block,
rest `AIRule_<addr>`); renames the stage/helper family (`AIState0..7…`,
`AISatAdd_455f`, `AIScanSlots_4456`, `AICategoryRank_7322`, walker/veto/retry) with
repo-wide reference updates; fixes the INVERTED `CheckMonsterSlot` CF comment in
`bank_000.asm`. Labels/comments only — probe AND final builds asserted
`1ca6579…`; idempotent; `--analyze` reports alignment without writing. Produces no
extracted/ data. Residual: rule-BODY re-emission around inline rst $00 handler
tables — see ROADMAP S82 box) ·
`resection_battle_core.py` (✅ new S83 — Iron-Rule-6 annotation of the battle core,
banks `$52/$53/$58`, same probe-build machinery per bank: converts the 28-state
action table `BtlActStateTable_6c60`, the bank-`$53` `SetupSubStateTable_44ce` (9) +
`ActPhaseStateTable_51ec` (16), and splits the bank-`$58` head into 14 rst `$10`
service slots + the 230-dw per-skill `BtlSkillTargetDispatch_401d` (skill names
inline); semantic renames across the damage/turn-order/status/target families with
repo-wide reference updates incl. `patches/`; labelizes the raw `$7aff`/`$401d`
pointers. Idempotent per bank (marker labels); probe AND final builds MD5-asserted) ·
`gen_script_banks.py` · `render_rooms.py` · `dwm/` package ·
`dwm/sprite_codec.py` (✅ new Session 22 — the SINGLE LZ codec for tiles+sprites:
`decode` byte-exact = game + `decompress_tiles.py`; `encode`/`encode_safe` valid/compact
or `literal_only` self-contained; `tiles_to_indices`/`indices_to_tiles`;
`gfxid_stream_offset`/`read_stream`. Round-trip `decode(encode(x))==x` on all 442 monster
streams; NOT vanilla-byte-identical re-encode by design) ·
`extract_monster_sprites.py` (✅ new Session 22 — all 221 monsters' battle+follower
sprites → `extracted/monster_sprites.json` (+`--png`); count-parameterised) ·
`build_sprite_swap.py` (✅ Session 22, REWRITTEN Session 23 — CROSS-BANK battle swap +
recolour. `--species id|Name --kind battle`; `--relocate` (lossless cross-bank copy,
regression proof) / `--png` / `--payload` (new art) / `--palette c0,c1,c2,c3` (RGB555
recolour) / `--build-rom` (focused test ROM = clean tree + only these changes). Resolves
gfx-ID → encodes (`dwm/sprite_codec`) → places via `dwm/sprite_bank.py` overflow allocator
→ repoints `MonsterBattleGfxTable` (needs the S22 re-section in `disassembly/bank_000.asm`).
The gfx swap is ASM-based; `--palette` is a same-size POST-BUILD BINARY PATCH + checksum
fix (`fix_header_checksum`/`fix_global_checksum`) of `MonsterBattlePalettes[species]` —
fine for test ROMs; for PERMANENT integration do the palette edit in `patches/bank_017.asm`
against the annotated table. **Follower path UNGATED Session 24 (GFX-3):** `--kind follower
--payload F.bin` repoints `ScreenTransDataTable` `$01:$49DF` (`repoint_follower`, species+$10)
and DMAs a self-contained 16-tile (256 B) literal stream; the numbered-tile calibration ROM is
built the same way + a `--palette`-style 8-OBJ-palette overwrite (idx1→black digit, idx2→red
foot) for legibility. Depends on `dwm/sprite_codec.py`) ·
`dwm/sprite_bank.py` (✅ new Session 23 — `SpriteOverflowAllocator`: places encoded streams
into reserved overflow banks `$7E,$7F` then `$7C,$7A,$79` with a `$4001` pointer table,
returns gfx-ID `(bank<<8|index)`, emits the bank `.asm`. The editor's sprite-asset backend;
the resolver `$00:$1627` reads `$<bank>:$4001+index*2` with no bank gating) ·
`extract_monster_palettes.py` (✅ new Session 23 — dumps `MonsterBattlePalettes` `$17:$62FD`
→ `extracted/monster_palettes.json`, all 221, count-parameterised) ·
`resection_follower_gfx_table.py` (✅ new Session 24, GFX-3 — re-sections `ScreenTransDataTable`
`$01:$49DF` into a labeled `dw` block (231 entries) + `FollowerFamilyGfxTable` `$4BAD` (10);
zero external refs into range; build stays `1ca6579…`; idempotent — same job as the S22 battle
re-section) ·
`extract_follower_layouts.py` (✅ new Session 24, GFX-3 — walks the follower metasprite
frame-pointer tables in banks `$05/$10/$11`, decodes each `(dy,dx,tile_offset,attr)` list,
dedupes → `extracted/follower_layouts.json` (118 layouts) + classifies sharing vs non-sharing.
**SUPERSEDED Session 25 by `extract_monster_follower_layouts.py`** — kept for reference, but its
brute-force scan misses 3-entry blob layouts and reports ObjTest-viewer (`$05`) addrs, not the
follower path) ·
`extract_monster_follower_layouts.py` (✅ new Session 25, GFX-4 — the AUTHORITATIVE follower-layout
extractor. Walks the REAL species-indexed dispatch the engine runs: `$ffc7=species+$10` → bank `$04`
entry-2 routing → bank `$10`/`$11` `$407f` level-1 table → level-2 frames. Emits BOTH
`extracted/monster_follower_layouts.json` (species → layout id + addresses + sharing) and a complete
`extracted/follower_layouts.json` (155 layouts, incl. 3-entry blobs; S107: + stored bytes, per-bank
instances, bank frames, Y-flip). `--selftest` reproduces the
Healer/DarkDrium anchors byte-for-byte + asserts 215/215 collectible coverage (S107: + stored bytes /
instances decode back, JSON == ROM). Delivered WITH both JSONs) ·
`build_follower_reassign.py` (✅ new Session 25, GFX-4 — follower reassignment primitive + custom-art
import. `--clone-from SRC` copies a same-bank monster's layout+art+attr (the same-bank constraint is
enforced: the level-2 pointer is dereferenced with the routed bank mapped). `--art-png PNG
--frames-json J` imports custom art: packs the 6 picker frames into layout 0's 16-tile order, encodes
a literal stream (`dwm/sprite_codec`), places it cross-bank (`dwm/sprite_bank` overflow allocator),
and repoints the species in ALL 8 follower-art table copies; `--attr N` sets the OBJ palette; layout
defaults to layout 0 (`$10:$4e33`). Builds a focused test ROM (clean tree + overflow bank art +
same-size binary repoints + checksum fix); clean canonical build stays `1ca6579…`. Reassignment is a
`$407f` level-1 repoint, NOT a `[$caca]`/species edit. User-confirmed: Healer→Dragon, Dracky→custom
blue-dragon) ·
`follower_frame_picker.html` (✅ new Session 24, GFX-3 — standalone interactive tool: drag/resize/
arrow-nudge six boxes over an embedded sprite sheet, live per-direction engine-accurate preview,
set the transparent colour, export frame coordinates JSON + 256-byte payload hex. The art-import
front-end for follower/walking-sprite swaps) ·
`resection_battle_gfx_table.py` (✅ new Session 22 — re-sections the misassembled battle
gfx-ID table `$00:$2B9F` into `MonsterBattleGfxTable`; anchors between real `.sym` labels,
emits exact ROM bytes, preserves 23 cross-refs; build stays `1ca6579…`; idempotent) ·
`resection_library_tables.py` (✅ new Session 26, extended Session 27 — re-sections ALL bank-`$12`
monster-library / family-tab menu data: `LibraryFamilyTabBounds` `$6294`, `LibTabColPos_564a/_5a8e`,
and the entire contiguous window-draw layout run `$710c..$7b9b` (29 `LibWinLayout_<addr>` blocks).
Maps source-line→address via a zero-byte probe-build read from the linker `.sym` (no opcode-size
summing — the S22 trap); per-table idempotent; re-runnable from the clean tree. Labels/comments only,
build stays `1ca6579…`. `--dump-json` writes `extracted/library_layouts.json`) ·

> **S105 correction:** the in-place S21 Dracky → clam swap (`patches/bank_036.asm`) WAS
> in every patched build until S105 (deleted; DOC_AUDIT S105), and bank $7E is now
> compiler-owned (`custom.species`, PROJECT_COMPILER §2.21) — the recipe below is historical.
> **Making a sprite swap PERMANENT (in the canonical patched build).** The S23 hand-off
> left the patched build CLEAN — the clam swap is a reproducible example
> (`examples/sprite_swap/`), NOT baked in. To make any swap permanent you must edit the
> DATA tables in the patch copies: `patches/bank_000.asm` (gfx-ID repoint) and
> `patches/bank_017.asm` (palette), add a `patches/bank_07e.asm` overflow bank + its
> `game.asm` include, and register `bank_07e.asm` in `verify_integrity.py`
> PATCH_NEW_FILES. Those patch copies PREDATE the S22/S23 re-sections, so sync the
> re-sectioned `MonsterBattleGfxTable` / `MonsterBattlePalettes` into them first.
`build_breeding.py` (✅ new Session 13 — breeding round-trip decode/encode/emit;
`--selftest` byte-identical to ROM; keystone for the Phase 2B overhaul; produces
breeding_tables.json. `--emit-relocation` (B2) writes `patches/bank_069.asm` —
the relocated special-table scanner + table, sourced from the **patched**
`bank_016.asm` so custom recipes survive; self-checks relocated == patched). `--emit-family` (B4) authors the POSITIONAL family table in place: reads `extracted/breeding_family_defaults.json` (`result→{p1,p2}` overrides), applies them to the vanilla decode, validates positional 1:1 + 444-byte zero-shift + shadow classes, and rewrites only the `FamilyRecipeTable` db block in `patches/bank_016.asm`. `--emit-special` (B5) OWNS the whole SPECIAL table as authored data: 825 vanilla ROM base + in-place `overrides` (by index or by parent `match`) + `appends`, from `extracted/breeding_special.json`; runs a whole-table first-match-wins shadow validator (ERRORS on shadowed append/override; WARNINGS on new collateral shadowing + on a result-change other entries still produce); emits only `patches/bank_069.asm`, leaving bank `$16` byte-identical to the ROM (single source of truth). Supersedes `--emit-relocation` as the canonical bank `$69` emitter.

`build_family_reassign.py` (✅ new Session 18 — B6 family reassignment): reads
`extracted/breeding_family_reassign.json` (`{id,name,from,to}`), validates every
`from` == the vanilla ROM family byte, and rewrites only the targeted Family `db`
lines in `patches/bank_003.asm` (same-size, exact-line, zero shift). `--selftest`
asserts the clean source's 221 family bytes == ROM. Delivered WITH its spec JSON. ·
`build_dynamic_library.py` (✅ new Session 18 — B6 dynamic-library PROOF OF CONCEPT):
redirects the library tab-populate `SetItem_6242` ($12:$6242) to `LibScanByFamily`
in bank `$12` free space ($7B9B+), which groups by the family byte instead of the
hardcoded id-range table at `$12:$6294`. Emits `patches/bank_012.asm` (zero-shift
`jp` + routine in trailing pad). POC only — see BREEDING_SYSTEM "Dynamic library";
production is a build-time family→members table (ROADMAP B7), do NOT optimize the
runtime path.

`build_family_icon.py` (✅ new Session 20 — B8/B9 family-icon path): the family
"name" is an ICON font tile ($4F:$4110-$41A0, text bytes $10-$19; addr = $4010 +
byte*16). `--dump` decodes the 10 vanilla icons (+ the free $1A/$41B0 slot) to
`extracted/family_icons.json` (round-trip safe). `--png FILE [--head-index N]`
encodes an 8×8 PNG to a 2bpp tile and prints the `db` line for the Spirit slot.
`--selftest` asserts vanilla icons round-trip and the Spirit grid in the JSON ==
the bytes in `patches/bank_04f.asm` at the Spirit slot. Delivered WITH `family_icons.json`. **(CORRECTED 2026-06-19: Spirit ships on byte $19/`$41A0`, overwriting vanilla ???; the free $1A/`$41B0` slot is left blank — it is not fill-immune at runtime. selftest now checks $41A0.)** **(S104: SUPERSEDED — Spirit is on byte $1A/`$41B0` again and the ??? glyph at `$41A0` is vanilla; `--selftest` checks the full vanilla INCBIN, the `$41B0` glyph AND the bank $6D `SpiritIconStream` against the JSON grid; `--png` prints both lines; verify check 5 runs it.)**
The Spirit icon insert itself is `patches/bank_04f.asm` (same-size 16-byte tile at
$41B0, zero shift; bank $4F otherwise byte-identical to vanilla).

### Builders / decoders added after the 06-13 audit (rows synced S51)
`enumerate_songs.py` — S61 (M1): sound-engine enumerator + stream decoder.
`song_codec.py` — S62 (M2+M3-POC), extended S63 (M3a) + S64 (M3b): song
round-trip codec (decode / selftest / extract-gbs / build-port /
patch-bank1e[historical] / import-port[historical] / emit-song-bank /
add-gbs-song / **extract-gbs-library** — S64: ALL 31 DWM2 subsongs →
`extracted/dwm2_song_library.json`, per-channel trace-proven; the canonical
gbs-index→name map is embedded with zophar-m3u provenance). Corrected loop-jump grammar (vs
enumerate_songs.py's S61 mislabel — DOC_AUDIT S62); DWM2→DWM1 translation
layer (`translate_dwm2_stream` + `prove_translation` static trace-equivalence
prover). S63: `import-port` recovers a ported song from a generated full-bank
patch .asm into the song library (lossless — round-trip-checked incl. the
translator's unreachable trailing $FF); `emit-song-bank`/`song_bank_asm` generate the
bank-$74 image (fixed 95-slot record area, streams from $4180 — SOUND_SYSTEM
§2); since S64 the editor2 `music74` emitter calls `song_bank_asm` directly
from project.json `custom.music` (custom_songs.json retired). `patch-bank1e`
retained for S62 provenance only; bank $1E is vanilla again.

`midi_to_song.py` — **NEW S64 (M3c)**: pure-python SMF 0/1 → catalog entry.
Frame-accurate boundary rounding (engine note lengths ARE frames — S64
correction, SOUND_SYSTEM §4), tempo-map handling, per-channel monophonize
(new note-on truncates; counts reported), auto-map lowest-mean-pitch→wave +
rest→pulse1/pulse2 (--map overrides; ch10→noise via a documented GM map),
$A7 tie-holds past 255 frames, `$A3 $80` groove-off (every groove row is a
live vibrato shape — SOUND_SYSTEM §5), `B0 $FC` whole-song loop (--no-loop
for jingles), silent-rest channel-end equalization so the loop stays
phase-locked, decode round-trip check before writing. Options for duty/
envelope/wave-instrument/out-level/transpose.
Reads the master table @ ROM0 $3466, per-id channel records, walks every
sequence stream (2-byte pairs, $FC jump follow, revisit = loop) to
termination; `--decode <id>` prints a track note-by-note; `--json` emits
`extracted/songs.json`. Engine facts it encodes are documented in
SOUND_SYSTEM.md; exit non-zero on any stream overrun. ·

`audit_mapid_range.py` — S66: mapID ≥$80 readiness census (A′1). Scans both
trees for `ld a, [wMapID]`, classifies the consuming pattern (unsigned cp /
8-bit `add a` doubling / 16-bit index / rst $00 / copy / bounds check), and
attaches the S66 per-site verdict from an embedded label-keyed table.
SELFTEST-pinned (clean=58 exactly; patched in [50,90] band so
compiler-regenerated banks don't false-alarm); any unadjudicated site prints
NEEDS_REVIEW and fails. Run it before shipping the first room with mapID
≥$80 (ROADMAP A′1 follow-up) and after any session that touches wMapID
consumers. Owning doc: CROSSBANK_ROOMS "mapID ≥$80 readiness audit (A′1, S66)".

`audit_wram.py` — S54: WRAM usage mapper. Classifies every WRAM byte from four
evidence sources (vanilla literal refs with data-as-code 'suspect' filtering;
curated evidence-cited indexed arrays — incl. the monster array $CAC1-$D664
whose invisibility to grep caused the S54 collision; known_RAM_map sized spans;
patch-only refs + wram.asm label resolution with comment cross-check). Emits
`extracted/wram_usage.json`; reports gaps as UNVETTED, never "free";
`--selftest` pins detection of the S54 custom-block/monster-array collision
(the tool must always find the bug that motivated it). Rerun after ANY
wram.asm change or before placing new WRAM state. ·
`build_combined_tileset.py` — multi-tileset editor JSON → bank_067.asm (cherry-picked
LZSS GFX) + bank_017.asm palette wiring; the Phase-1 "custom tile GRAPHICS" pipeline. ·
`build_library_table.py` — B7 production library grouping → patches/bank_012.asm;
owns the $E0→$FE unseen-marker sites; inputs spirit_family/new_species; `--selftest`
vanilla parity (see library_grouping.json row). ·
`build_new_species.py` — Phase N: info-table fork ($6A), enemy stats (EID 518),
same-size wild-encounter edit, name wiring, from new_species.json; SameBoy-proven.
**S105: writer RETIRED** (its bank_06a slot data is the compiler region `ns_info`
from `custom.species`); `--check` / `--dump-json` still run on the historical JSON. ·
`build_new_species_follower.py` — G1 follower-art path for ids ≥224 (all-8-copy
gfx-ID fork + attr fix); standalone TEST-ROM emitter during bring-up. ·
`bake_follower_overflow.py` — encodes follower (layout-0 pack) + battle art (PNG +
frames / battle-spec JSON) into literal LZ streams. **S105:** `--stream-dir DIR --name N`
writes `N_follower.bin` / `N_battle.bin` for a project's `custom.species` (the example's
Gorbunok assets are reproduced byte-for-byte from `examples/follower_swap/`); writing
into `patches/` is refused (bank $7E is compiler-owned); `--out` elsewhere still emits
a stand-alone overflow-bank .asm. ·
`build_skill_faq.py` — transcribed community FAQ → skill_faq.json (external ground
truth, `_source`-stamped). ·
`decode_battle_animations.py` / `decode_effect_messages.py` — S2c/S2c-anim decoders
(see their Tier-A JSON rows). ·
`emit_anim_data_sections.py` — rgbasm `db`/`dw` emitter for the battle-effect
presentation tables mgbdis mis-rendered as instructions (Phase-D re-section helper). ·
`extract_png_tileset.py` — PNG map rip → unique 8×8 GBC tiles, 4-colour quantize,
palette-group clustering (custom-art import front door). ·
`patch_breeding_recipe.py` — S12 keystone: direct same-size edits to the vanilla
special table $16:$4B30 (predates B5; kept as the minimal-edit precedent). ·
`resection_skill_tables.py` — **NEW S51**, Phase-D item (2b) [S100: learn
region corrected 222 → **218** rows — its $6034+ tail is bank $06 entry-6 code,
re-sectioned back to code by hand S100; DOC_AUDIT S100]: converts
`SkillMPCostTable` ($07:$570C) + `SkillLearnReqTable` ($06:$50E0) from fake
instructions to labeled `dw`/`db` in BOTH trees via the probe-build method;
byte-perfect asserted; keeps outside-referenced fake-artifact labels at exact
offsets; idempotent (`--check`) ·
`sm83dis.py` — targeted SM83 disassembler for bank:addr regions mgbdis left as `db`
(unreferenced routines / data-reached code); used by the RE arcs.

### Prototype editor (towards_editor/)
`DWM1_Tile_Editor.html` — standalone HTML file (open in browser); earlier docs
call it "DWM1_Multi_Tileset_Editor" — same artifact, current filename is
`DWM1_Tile_Editor.html`.
Multi-tileset room designer: browse 85 tilesets (with names), pick tiles
from any source into a combined palette (128 max), paint 20×16 rooms,
collision-threshold-based walkability overlay (W key), variable-size stamps
(1×2, 2×1, 2×2+), add/remove markers with 2×2 NPC/exit display.
Exports JSON with full source mapping (`{ts, idx, pal, walkable}` per tile)
for backend consumption. Proof-of-concept — the Phase 3 romhacking tool
will have an integrated editor with build pipeline. Known issue: localStorage
key should auto-version instead of requiring manual cache clear.

### Dumpers (refresh extracted/ — all tested this session)
`dump_monsters` `dump_enemy_stats`(✅ reconciled) `dump_encounters`
`dump_boss_table` `dump_all_exits` `dump_all_npcs` `dump_all_text`
`dump_map_table`(✅ rewritten) `dump_routing_table` `dump_room_data`
`dump_monster_names` `dump_steps` `dump_bank` `dump_skills`(⛔ RETIRED S59 — inert tombstone; use `gen_skill_records.py`)
`dump_text_id_map`(✅ new) `dump_all_scripts`(✅ new)

### Phase-D db generators (all dry-run OK; apply+MD5-check remaining)
`gen_monster_db` · `gen_enemy_stats_db` · `gen_encounter_db` ·
`gen_skill_table_db` · `gen_room_data_db` · `gen_name_tables_db` ·
`gen_growth_tables_db` · `gen_bank41_remaining_db` · `gen_tileset_banks`

### Analyzers
`analyze_event_flags` · `find_free_space` · `find_orphan_pointers` ·
`find_pointer_tables` · `find_safe_wram` · `find_bank0_space` ·
`search_bytes` · `search_text` · `scan_text` · `view_string` · `hl_calc` ·
`gate_reference` · `test_roundtrip` (needs pytest) ·
`map_gate_names` (writes gate_names.json — used by dump_room_data,
gen_encounter_db, editor2 Gates tab; do NOT archive; **REWRITTEN S100** — see
the S100 rows) ·
`match_npc_text` (writes npc_text_mapping/npc_with_text — NPC↔dialogue
join, useful for editor; do NOT archive) ·
`derive_room_palette` (**NEW S39** — derives any room's runtime BG palette from
ROM: colours 0/2 from the room/gate palette pointer, forces idx1=`$6bff`/idx3=
`$0000`, scans screens, refuses cleanly when unresolvable. `--map 0xNN` /
`--gate 0xNN`. Validated 30/30 dumps + gate floor; see GATE_GENERATION.md §7.1.
Prints, no JSON.) ·
`map_skill_id_buckets` (**NEW S48** — writes skill_id_bucket_map.json: the skill-id
de-aliasing surface for S2d. Auto-scans `$db8a` reads + curated fork points/special
gates/cast pipeline/fork-feasibility; self-checks load-bearing anchors against the ROM
and aborts on drift. `--print` dumps the range-gate table. See BATTLE_SKILL_SYSTEM.md
§12; precedent `map_species_slots`.)

### One-off investigations → move to `tools/archive/` when convenient
`analyze_bank0b` `analyze_bank17` `analyze_screens` `annotate_bank052`
`check_exit_byte5` `copy_room_test` `dump_medalman` `find_boss_table`
`find_transitions` `find_all_transitions` `fix_bank_headers`
`inspect_roundtrip_failures` `investigate_npcs` `investigate_tail`
`test_exits` `verify_boot` `verify_edit`

### Legacy (frozen Streamlit editor)
`build_rom.py` · root-level `build.py` ·
`randomize.py` (reads monsters_full.json, writes `extracted/edits.json` when run — never commit after; S120 corrected)

## 2.9 randomizer/ — standalone game randomizer (NEW S76)

Its own top-level package, deliberately outside `tools/`: it edits ROM bytes
directly, applies NO patches, and runs on the English AND German builds. Nothing
in `disassembly/`, `patches/` or `editor2/` depends on it, and it depends on the
repo only for `dwm.text` (charmap).

| File | Role |
|------|------|
| `randomizer/romdata.py` | ROM layout resolution + typed table access. `RomLayout` locates the two bank-`$14` tables by content signature with an MD5 fast path for the two known builds, and runs structural sanity checks that fail loudly on an unrecognised image. Byte-perfect round-trip verified on both ROMs (load → write_all → identical MD5). Also fixes the header global checksum on save. |
| `randomizer/logic.py` | The randomization passes: natural skills, growth, resistances, exp-curve remap, enemy identity, enemy movesets, boss joinability, encounter pools, breeding, obtainability closure, starter. Owns `BOSS_EIDS` (S67 census) and `validate_boss_eids()`, which proves the boss set is region-independent by counting `<opcode> $FF <eid16>` script tokens in banks `$0C`-`$0F`. |
| `randomizer/librarytext.py` | Rebuilds the 221 bank-`$4D` library recipe strings (BREEDING_SYSTEM §"Library recipe TEXT"). Extracts family tokens, pad byte and token2 padding convention FROM the ROM; gates on reconstructing ≥95% of the vanilla strings byte-for-byte before writing; refuses if a foreign dispatch entry points into the repack region or if the rebuild would not fit. |
| `randomizer/names.py` | Region-aware monster/skill name decoding for the spoiler log. Locates the bank-`$41` pointer tables by scoring candidates (German bases are −2) and auto-detects the German charmap overlay via the `$5B` tell. |
| `randomizer/randomize_rom.py` | CLI. Deterministic per `--seed`; emits the ROM plus `.spoiler.txt` and `.spoiler.json`. Hard sanity pass refuses to emit a ROM with any out-of-range species/skill/growth/resistance/recipe field. |
| `randomizer/audit_threat.py` | **Regression harness, useful beyond the randomizer.** Per-row worst-case enemy damage parity against a vanilla ROM across all 487 enemy rows; non-zero exit if any row got harder. Run it against ANY edited ROM. |
| `randomizer/README.md` | Usage, flags, design invariants. |

Produces no `extracted/` JSON — the spoiler log is a per-seed build artefact and
is deliberately not committed.

### randomizer/ additions (S77)

| File | Role |
|------|------|
| `randomizer/breeding.py` | Depth-targeted tree generation. Assigns target depths by level cap, builds tiers in ascending order against measured depth, best-of-N retry. Keeps species met at L<=6 free of specific x specific recipes. |
| `randomizer/plusgrowth.py` | The ONE code change: extends vanilla's plus-value growth bonus (`PlusGrowthBonus`, `FuncExp_4163` before the S130 rename) to MP and INT. Byte-neutral trampoline in bank `$13`'s free tail, four guard checks before writing. |
| `randomizer/profile_check.py` | **Per-entity envelope checker.** Six invariants against vanilla, non-zero exit. Runs on any edited ROM, not just randomized ones — see PROJECT_COMPILER "Validation the editor must run". |

`randomizer/profile_check.py --ttk` (S86, opt-in): simulated pool-TTK parity gate driven by the pacing layer — per-pool weighted median rounds-to-outcome (level-scaled party, attack policy) capped at 2.0x vanilla; identically-seeded per ROM (vanilla-vs-vanilla exactly 1.00x). Default run unchanged.

## 2.10 simulator/ — combat simulator package (NEW S78)

| File | Purpose |
|------|---------|
| `simulator/damage.py` | The exact DWM1 damage model: LCG RNG, physical roll (`CalcSkillDefense` all 3 regimes + slot-2 rule + zero floor), record power rolls with side selection, packed-resistance decode ($DD28), every multiplier/hit ladder, the $DB73 boss-protection gate, and the handler-computed specials (MegaMagic, WindBeast, Vacuum, Kamikaze both paths, Ramming, slashes/cuts, multipliers). Every function names its bank-$52/$53 routine. Owning prose: BATTLE_SKILL_SYSTEM §15. S130: holds `SPELL_LADDER` (moved from validate_damage.py); its `vacuum(enemy_side=True)` 1.5L branch is wrong (§15.5, use `skillfx/f23_phys.vacuum_base`). |
| `simulator/validate_damage.py` | Differential validator: replays a measure_rig event corpus through damage.py and diffs against the engine's own values at matching waypoints. S78 corpus: **698 comparisons, 0 mismatches** across 13 categories. Exit 1 on any mismatch. |
| `simulator/measure_rig.py` | PyBoy capture rig: S75 TriggerBattle-mimic battle + per-frame skill/stat forcing + hooks at the damage waypoints ($52:$60D7/$61EC/$679C/$67BA/$54E7/$54EA, special entries, Beat outcome branches). `--db73 0` reproduces the wild-battle condition inside rig battles (the rig's $DA09=1 makes them "boss" type). Needs a patched ROM + CONTINUE-able .sav + post-boot savestate. |
| `simulator/s78_master_events.json` | The S78 validation corpus (1,140 events; the 698 checks). Regenerable with measure_rig.py; kept so `validate_damage.py` runs without an emulator session. |
| `simulator/turn_order.py` | Exact turn-order model (S79): per-combatant AGL key roll (GenerateRNG step + span math + $55/$56/defensive-class tweaks + floor), the literal 9-wide shrinking-bound bubble sort (ties swap; out-of-range pair modelled), $DB79 compaction. Owning prose: BATTLE_SKILL_SYSTEM §15.6. |
| `simulator/measure_order.py` | Turn-order capture rig (S79): 4 hooks ($58:$54D1 build entry, $5662 per-combatant pre-RNG key roll, $55C2 unsorted keys+ids, $5707 final $DB79); `--agl` per-slot forcing, `--party3` (real slot-0 record duplicated into party 1/2 pre-battle). |
| `simulator/validate_order.py` | Differential validator: replays key_roll pre-states through turn_order.py, diffs keys+ids at the sort entry AND the final order. S79 corpus: **143 comparisons, 0 mismatches over 47 rounds** (incl. a 4-actor round). Exit 1 on mismatch. |
| `simulator/s79_order_events.json` | The S79 turn-order corpus (validate_order.py's default input). |
| `simulator/s79_damage_events.json` | S79 damage-side captures: slot-2 ×0.8 (party3), RainSlash 1-4 hits, Sacrifice kill/survivor (HP≠MaxHP), Kamikaze/WindBeast/Vacuum under db73=0/2 incl. enemy-cast (corrected S130: its 2 Vacuum events are both PARTY-cast; enemy Vacuum is measured in `f23_phys_events.json.gz`). Spot-validated in-session (not yet folded into validate_damage's category runner). |
| `simulator/status.py` | Status model (S79): $DB00-block byte/bit map (measured per-skill), exact sleep-wake port of $53:$4AEB, curse/confusion gates, phase-9 DoT formulas. Owning prose: §15.8. |
| `simulator/battle.py` | Round-loop core, **differentially validated S85** (6614/6614 via `validate_battle.py`): Board snapshot type, turn order, per-actor status gates (sleep/paralysis/stun/one-shots), curse self-hit (4 branches), enemy duplicate-group-cast conversion (literal `$4E63` scan + tables), act-time re-resolve + MP/seal veto, unreachable-target pre-gate, per-victim MISS/dodge machine, damage-core classification (calcdef/record/quake/heal/status), Quake/side victim lists, apply/KO, phase-9 status decay + DoT (via status.py). `simulate_round()` = offline driver over the same functions with a caller-supplied RNG idle policy (NOT validated as a whole — stand-ins marked). |
| `simulator/measure_battle.py` | S85 LOOP-LEVEL capture rig: one complete rig battle on the real save (boot.state from the hacked .sav), 31 waypoint hooks (round start $58:$54D1, actor fetch/gates/forced/curse/dup-conv/skill load in bank $53, target fetch/re-resolve/dead-redirect, MISS machine entry/RNG/miss/dodge/block/pass, damage-core entries $52:$60D7/$679C/$54E7, status ladders $5C8F/$5CBC/$5CDA + $65B5/$65C9, apply $6D56, KO $7EE3, phase-9 $50:$6B25/$6C14/$6C59, side wipe, round end), FULL 8-slot board per event. Options: `--ecount`, `--pskills` (rewrite the save's slot-0 movepool), `--php/--phpcur/--pmp/--ehp/--emp`, `--pst/--est` (status pokes), `--skill/--eskill` (forced queues, phases 4-6 only), `--skip`, `--maxev`. Unforced mode = the engine's own tactics/enemy AI. |
| `simulator/validate_battle.py` | Differential validator for battle.py: replays each captured round/actor/victim with the engine's RNG injected at each waypoint; 37 check kinds (order, fetch, gate, curse, dupconv, veto, reresolve, target, victims, miss, core, damage_phys/record/quake, heal, hp, ko, status_roll/byte/already, boss_gate, unreachable, decay, p9_order, dot, dot_dmg/hp, round_hp/dd1b/st). Exit 1 on mismatch; `-v` prints failures inline. |
| `simulator/s85_battle_events.json` | The S85 corpus, **REGENERATED S89 on the patched pin `a17bff8e…`** with the same 25-scenario recipe (header of measure_battle.py) and now carrying the S88 fields per event: `ai_bases` ($DC44..$DC63, 4×8) + `wld` ($DC23 words). validate_battle: **6614/0 — exact check parity with the retired S85 capture** (which was on `4c8de38a…`). `board_from_event` consumes the fields (stand-ins retire on S88+ corpora). |
| `simulator/measure_obedience.py` | S87 obedience capture rig: 4 hooks on the state-0 preamble ($57:$7A16 band entry pre-RNG, $7A5D decide entry, $6F8C no-carry, $6EF4 carry) over a 21-case matrix (forced wBattleLVL=WLD boundaries $00/$14/$15/$EF/$F0 + mid-band × tactics 0-3 × three base sets) on the real save; per-frame WLD forcing, record-nibble tactic set, init-time base pokes. |
| `simulator/s87_obedience_events.json` | The S87 corpus: 127 decisions / 381 events (`_generator` stamped; patched `a17bff8e` + hacked-.sav boot.state). |
| `simulator/validate_obedience.py` | Differential validator: replays each decision — seeds ($db4c/4d/4e), ObedienceThreshTable lookup ($db53), banded RNG incl. ONE exact LCG-step replay from the pre-state and the multiples-promoted-to-b quirk, and the decide outcome. **889 checks, 0 mismatches.** Exit 1 on mismatch. |
| `simulator/measure_idle.py` | S86 idle-step extractor (OFFLINE, no emulator): the live RNG is a full-period 16-bit LCG, so the step count between consecutive S85-corpus waypoints is uniquely recoverable; buckets all 5,636 counts into 8 idle classes → `s86_idle_model.json`. `--check` re-derives and diffs (selftest). Embedded proofs assert the same-frame k∈{0,1} rule and the phase-9 k=0 rule. |
| `simulator/s86_idle_model.json` | The measured idle model (per-class k pools + proofs; `_generator` stamped). Consumed by `pacing.IdlePolicy('empirical')`. |
| `simulator/pacing.py` | S86 pacing layer: IdlePolicy (empirical/uniform/identity; O(log k) affine k-stepping), the offline COMMIT machine (ai.py category machine + ai_rules chains for $dd0b 1/2, decoded lightweight picker for 0, tactics bias + obedience gate), `simulate_battle()`, `ttk()`, board construction (resistance packing, dd0b INT ladders). Commit stand-ins marked (party bases, obedience mid-band, zero resist_score — §15.9). Owning prose: BATTLE_SKILL_SYSTEM §15.8c. |
| `simulator/validate_pacing.py` | S86 aggregate validator: `--level1` = round-level PIT over the S85 corpus (engine outcome ranked in 200-sim distributions per round; KS + decile + coverage envelope; exit 1 on failure) — result: UNIFORM, and empirical ≡ uniform policies; `--level2 FILES` = whole-battle envelope vs captured battles (splits multi-scenario files by `sc`). |
| `simulator/s86_fresh_battles.json` | 5 fresh UNFORCED real-save battles (S86 .sav, patched `a17bff8e…`, measure_battle.py, skips 101-113): level-2 input + never-seen-data regression for validate_battle (802/802). |
| `simulator/sweep_ttk.py` | S86 TTK sweep over gate encounter pools (extracted/encounters.json) for ANY ROM build via randomizer Rom.load; per-row 1-vs-1 weighted pool medians, `party_for_level` level-scaled reference parties, 'attack'/'tactics' policies, `--out` JSON. |
| `simulator/ai.py` | Enemy/tactics AI model (S80): category scoring (base//10 + plan adj + swapped-r16 % ladder-mod), the exact quirky partial sort + not-rank1 +$1E cat1 bonus, per-skill sums (rec_ai_weight + rand%16), tag filter, pick argmax with RNG-bit0 ties, retry cursor (ROM-unbounded; model guards), category epilogues. Evaluator rule chains STUBBED (RuleChainStub — S81). Owning prose: BATTLE_SKILL_SYSTEM §15.10. Built S80, NOT yet user-tested. |
| `simulator/measure_ai.py` | AI capture rig (S80): 6 stage hooks on bank $57 ($7129/$73b9/$7529/$7439/$75a2/$7859), full AI RAM context per event, ENEMY queue left unforced. Embeds the S80 hook-safety protocol (dense 4-on/4-off cadence; no per-frame-polled hook addresses — PYBOY_DEBUGGING). |
| `simulator/validate_ai.py` | Differential validator: category-cell residuals vs the mod ladder, exact ranking replay (incl. the +$1E undo), sum residuals <16, filter zeroing, pick-vs-queue consistency. S80 corpus: **26/26 checks over 10 EIDs** (0/7/33/34/35/37/40/51/52/53; EID 37 exercises the $dd0b=0 lightweight path and is grouped out of full-machine checks). Exit 1 on mismatch. |
| `simulator/ai_events_<eid>.json` | The S80 AI event corpus (validate_ai.py inputs; regenerable with measure_ai.py). |
| `simulator/measure_rules.py` | S81 rule-chain capture rig: hooks the state-7 walker ($57:$7865 skill-entry / $7874 rule-call [reads chain cursor via register_file] / $7877 rule-return / $78A2 chain-end / $788B veto) so every RULE INVOCATION is captured with its ($DD26,$DD27) delta + board context. Forcing: `--ehp/--ehp-cur/--php/--php-cur/--pmp/--emp`, `--ebase c1,c2,c3` (category bases), `--elist tag:skill,..` (option-list forcing), `--pstatus/--estatus off:val,..`. Bails the frame loop at `--max-events`. |
| `simulator/sweep_rules.py` | S81 full-skill sweep driver: forces the enemy option list + category bases per-frame (all enemy slots when `--ecount`>1) and drives ANY skill through its category's real evaluator chain under a named board state (`clean/psleep/ppoison/e<status>/ehurt/allyhurt/allypara/allyconf/allydead/elowmp/...`). One pyboy process, boot.state reloaded per 4-skill batch. This is also the S79-hazard **custom-skill AI audit** instrument: a skill that all-vetoes under every board state will stall the $76A9 retry loop. |
| `simulator/ai_rules.py` | The evaluator rule-chain MODEL (S81): authoritative per-rule skill sets derived from the full 160-skill sweep corpus + decoded conditions; `evaluate_chain()` mirrors the $78A2/$788B writeback exactly (bonus/penalty pair, mid-chain veto, borrow-veto). **240/240** vs the sweep corpus (validator: `simulator/validate_rules.py` replays every corpus decision; corpus: `simulator/s81_sweep_corpus.json`, regenerable with sweep_rules.py). Owning prose: BATTLE_SKILL_SYSTEM §15.10.5. Built S81, NOT yet user-tested. |

`measure_rig.py` S79 extensions: `--party3`, `--skip` (RNG shift), `--eskill/--etarget` (force the enemy queue), `--ecount`, `--thp` (current-HP-only), `--elvl`, `--emp`; MaxHP now forced alongside HP (HP>MaxHP sends the enemy AI into flee/re-roll loops — see KEY_LESSONS S79); bank-$53 Sacrifice hooks ($67DB roll / $684E out).

## 3. Rules

1. Commit the tool with the data, same change. No exceptions.
2. Any dumper that writes extracted/ should stamp a `"_generator"` key.
3. Editor (Phase 2/3) consumes ONLY Tier A files.
| tools/dump_flying_flags.py | extracted/flying_flags.json | Every species' can-fly flag (monster info +$04, $03:$4461+sp*43+4): 221 species, 48 flying, per-species name + ABSOLUTE ROM byte offset so the editor can read AND write the stat (0=grounded, 1=flying). Battle copy = $db8b[slot] bit4 (bank $51 init); gates LegSweep $4E + Earthquake $E5-$E8. [S74] |
| tools/dump_dupconv_table.py | extracted/enemy_dupconv_flags.json | The two bank $53 tables behind the enemy duplicate-group-cast conversion (S85): per-EID flag byte `EnemyDupConvFlagTable_41df` (487 rows, 181 set) + the 77-id `GroupDupSkillList_4ee4`. `--check` re-reads the ROM (selftest). Consumed by validate_battle.py / battle.simulate_round. |

### tools/validate_custom_data.py (S75)
Hard-error validator for crash-capable custom-data configurations. Checks:
custom learn records (18-byte stride, level 1-99, prereq ids must be existing
custom records, LearnLoopFork scan bound == last id + 1), universal-qualifier
rows (no prereq + all-zero stats) require the LearnCode2Guard06 fence bytes in
the built ROM, the SlotProbeGuard50 fence must be present in bank $50, and
every redirected bank-$36 battle-sprite pointer must decode (dwm.sprite_codec)
to exactly the original entry's tile count (S105: no entry is redirected any
more — the only one, the S21 Dracky clam, was purged — so this is a guard;
`custom.species` art gets the same decode-size check in the compiler). `--rom <gbc>` = full check;
`--records-only` = source-only. Exit 1 = FAIL. Runs as verify_integrity
check 6 and inside editor2/core/builder.build_rom (the editor refuses to
return a failing ROM).

### S91 additions (P3.0 CAPACITIES + P3.1 sprite catalog)

| Item | What | Notes |
|---|---|---|
| tools/dump_npc_sprite_catalog.py | NPC field-sprite render census (PyBoy): solo render per id via binary-poked temp ROM (Castle scr1 step4 block, flat 183595), `--render` (chunkable) / `--finalize` / valid-step `--census`; crop box snaps to the 16px cell grid | Committed crops = the S91 sav-mode canonical run (user-validated sheet); clean-ROM `--render` reproduces on the intro-skip state |
| extracted/npc_sprite_catalog.json | Per-id record: renders, category (from npc_names.json sprite_classes), diff_px_vs_empty, name, alias_of; `_meta` documents method + valid range | 137 ids: 72 normal, 17 boss fragments, 6 aliases of $00, 37 empty, 5 glitch; ZERO crashes |
| extracted/npc_field_sprites/ | 137 per-id 16×16 crops (throne-room background; the editor knocks the floor out at load, S94b) — the sprite picker / canvas thumbnail source | id_XX.png |
| extracted/npc_sprite_catalog_sheet.png | Labeled contact sheet (user-classified S91) | |
| extracted/capacities.json | P3.0 CAPACITIES reference: every known authoring ceiling + evidence + status (measured_s91 / structural_s91 / documented); `_deferred_measurement_boxes` names the residuals | Hand-compiled, no generator by design; EDITOR_DESIGN §5.C meters read it |

### S88 additions

| artifact | producer | notes |
|---|---|---|
| simulator/s88_confusion_events.json (403+ x8 sc) | measure_battle.py (S88 hooks) | confusion arc corpus; validate_battle 2824/0 |
| simulator/s88_rider_events.json (10 sc) | measure_battle.py | rider corpus; 3422/1 (one flagged §15.9 anomaly) |
| simulator/s88_curse_events.json (6 sc) | measure_battle.py | curse-branch amounts; 3083/0 |
| simulator/s89_fresh_battles.json (5 sc, 343 ev) | measure_battle.py (S89; skips 101-113, patched a17bff8e) | fresh unforced never-seen-data corpus WITH ai_bases/wld; validate_battle **426/1 — the 1 is the FLAGGED §15.9 low-stat calcdef edge** (fresh_c r1, atk 9/dfn 6, RNG (8,103), engine 6 vs model 2, deterministic; second sample beside rid_yp2). Pinned s86_fresh_battles.json KEPT (802/0, level-2 input). |
| simulator/s89_guard_events.json (2 sc, 713 ev) | measure_battle.py (S89; new `guard_redir` waypoint $53:$5544, patched a17bff8e + hacked-.sav boot.state) | Cover $88 / Guardian $89 interception corpus: enemy trio guards, party forced to attack a protected slot. `battle.guard_redirect` validated **14/14** (Guardian→both allies protector 4; Cover→one ally; incl. dead-protector fall-through). Consumed by the standalone guard check (§15.9 CLOSED). |

measure_battle.py S88: waypoints conf_pick/meta_*/snap_roll, `--db73`
per-frame forcing, maxmp ($DBD3) captured per event. Battles run on the
patched pin a17bff8e with boot.state from the user's S87-class .sav.

## S92 rows

`tools/extract_room.py` — vanilla room → full project.json custom clone
(P3.2b [G-J]): $26DD record, screens with RAW-verified interact/exit bytes
(verbatim 5/7-byte pass-through), vanilla layout REFERENCES, attr decompressed
→ custom.layouts re-emission, palette via derive_room_palette logic, all
scripts via a segmentation-PROOF decoder (branch targets must land on op
boundaries; merged param table = decompile_script overridden by
handler/PyBoy-verified rows: $27=0p NOT-branch, $21=1p, $07=0, $41=1, $5A=1;
bare words = text displays), BGM from RoomBGMTable, orphaned-flag report per
script. `--source-custom <id>` = custom→custom deep-copy. Delivered WITH its
regenerated data (the arena_clone/island_copy content in the example project)
same session.

`tools/build_gate_room.py` — RETIRED S92 (grids moved into
editor2/example-project project.json custom.layouts; regen==committed verified
at the move). Kept for history; do not run.

`tools/decompile_script.py` — DEFECT LIST grew S92: 0x27 rendered as
"post_battle_check, goto p[0]" (it is MonsterPartyOp2, 0 params, NOT a
branch — PyBoy ctr trace + handler $04:$5F5C) and 0x21 param count 2 (actual
1, bank_004 reference block "read 1 param, discard"). Twin-tool rule stands:
do not "correct" the compiler from this tool; extract_room.py carries the
verified overrides.

## S93 rows (P3.3 room canvas + editor shell — editor2/, no extracted/ change)

| Item | What | Notes |
|---|---|---|
| editor2/core/render_project.py | LIVE room renderer from project.json + original ROM (custom layouts/tilesets/palettes, vanilla bank refs, derived palettes, base/base+2 attr stride, forced idx1/idx3); tile-sheet + single-tile renders for the picker | Pixel-identical to core/render.py on all 12 example screens (test_canvas.py parity check); ~1 ms/screen |
| editor2/core/document.py | Editable project.json model: byte-exact load/save (indent + trailing-newline detection), tile/attr cell edits, states ensure/collapse/add/remove, layout localization, add/remove screen with record dims synced, palette colour edit, NPC capacity | New layout items always APPEND (bank-$64 order == declaration order; mid-list insert would break other rooms' base+2 attr stride) |
| editor2/app/session.py, main.py | One Session per project (Document + renderer + QUndoStack + signals); the §5.0 shell: tab strip, Save ⌘S, Undo/Redo, Build ⌘B (saves first), Play ⌘R, Validate, History + Build-log docks | Rooms live; other tabs = stubs naming their ROADMAP box |
| editor2/app/rooms/ (tab, canvas, tile_picker, palette_panel, minimap, inspector, commands) | The Rooms tab: canvas v1 (paint tiles + palette slots, undo), states, screens, layers, markers with the S91 sprite crops, inspector | EDITOR_DESIGN §5.1 "As built S93" |
| editor2/tests/test_canvas.py | P3.3 acceptance: render parity + GUI round trip (exact undo, save, compile) on a scratch copy of the example project; `--rom` builds it and asserts PyBoy VRAM tilemap == canvas grid in both states; `--out DIR` keeps project + ROM + screenshots | Produced the S93 test ROM; SKIPs without PySide6 |
| editor2/tests/test_app.py | Updated for the shell (live canvas, placeholders, read-only vanilla refs, state switch, byte-exact doc round trip); `--rom` still asserts GUI build == the test_compiler pin | |

## S94 rows (canvas v2 + room model; engine/compiler foundation)

| Item | What | Notes |
|---|---|---|
| patches/bank_000.asm `@BUILD_PROJECT rom0_room_records` | ROM0 `$26DD` rows `$6B-$6F` (40 B) — compiler-owned; emitter `rom0_records` (editor2/core/emitters.py) keeps the jr-target labels at their addresses | GATE_GENERATION §7; `record` required for every room |
| patches/bank_017.asm `CustomAttrCheck` / `CustomPalCheck` (rewrite) + `render17` emitter | per-(screen, state) attr + palette tables in the VANILLA format: `CustomAttrPtrTable` → `RoomAttr_<mid>` (16 dw) → `ScrAttr_<mid>_<k>` (`dw counter` + per state `db entry, bank / dw pal_ptr`); `dw $0000` = vanilla walk | S94b (supersedes the interim S94 17-byte map); pin `fc1caa98…`; PyBoy-verified on a 6-screen Farm clone and the 2-state Servant room |
| editor2/core/vanilla.py (S94b) | PIL-free `VanillaTable`: `valid_steps` (the S91 prefix filter), `step_exits` (every 7-byte row verbatim), `counter` — shared by the compiler's redirect lowering and the renderer | source: extracted/map_table.json |
| `custom.entrance_redirects[]` → project.py `_lower_entrance_redirects` + emitter `_vanilla_exit_exts` (`db mapID, screen`) + template `VanillaExitResolve` (383 B, re-pinned) + patches/bank_00b.asm `RoomEntry9` divert | route ONE vanilla door into a custom room; per-step lists rebuilt from map_table.json with that row substituted | PROJECT_COMPILER §2.12; `Exit_GreatTree_s8` vanilla again; example project carries the Library-door and (4,5)→$6B redirects |
| editor2/app/rooms/redirect_dialog.py + inspector "Entrances" group + canvas `R`/`IN` markers | "Route a vanilla door here…" (room → screen → door, previews, wall warning); from the vanilla view: exit marker → "Route this door into a custom room…" | `Document.add_redirect/remove_redirect/redirects_to` |
| editor2/core/render_project.py (vanilla API) | `vanilla_rooms/gfx/record/screen_grid/attr_grid/palettes/markers`, `render_vanilla_screen` — every vanilla room live from map_table.json + ROM | 98 rooms / 211 screens; clone == vanilla parity test |
| editor2/core/document.py (S94 ops) | `clone_vanilla` (extract_room as a library + layouts localized per screen), `copy_room`, `new_room`, `rename_room`, `delete_room`, metatiles (`custom._editor`), `localize_tileset` (→ assets/<id>.2bpp + custom.tilesets), `ensure_twin` / `set_cell_walkable`, `snapshot/restore` | walkability twin logic skips animated 77/78; wall-side-full fallback moves the threshold and remaps |
| editor2/app/rooms/metatile_picker.py, metatile_editor.py | found-in-room + my metatiles picker; the 4-slot editor (only subtile-level surface) | |
| editor2/app/rooms/canvas.py v2, tab.py v2, inspector.py, commands.SnapshotCommand | cell-unit canvas, Select default, walkability mode, two-column browser, room actions, File→New project | |
| editor2/templates/blank-project/project.json | the blank project template (compiles: placeholder $6B synthesized) | |
| tools/extract_room.py (S94) | emits `screens[k].attr = {id}` per screen (per-screen attr maps) | |
| editor2/tests/test_canvas.py (v2) | vanilla render + clone parity; v1 round trip on the 4×4 grid (screen 8); v2 fresh-project round trip; `--rom`: both PyBoy checks incl. WALKING into flipped cells | |
| editor2/tests/test_compiler.py | 61 tests; pin `fc1caa98…`; new: 4×4 screen 12, ROM0 record row, record-required-below-$70, redirect lowering/validators, per-state ScrAttr rows | |
| editor2/app/rooms/metatile_picker.py v2 + tab.py `_room_vocab/_vanilla_vocab/_refresh_foreign/_import_metatile` (S95) | picker sections: this room's VOCABULARY (never shrinks; slots protected) · From <room> (combo; this room's palettes; same tileset = brush, other = import) · My metatiles | `Document.used_tiles/protect_tiles/import_metatile`; `SnapshotCommand` rolls back + `setObsolete` on a failed op |
| `screens[k].palette` + `Document.effective_palette/set_state_palette/add_palette_from_words` + inspector "palette here" / "copy from vanilla" (S95) | per-screen/state palettes; new screens inherit the shown palette; any vanilla room's palette copied into the project | compiler `state_palette_ref`, renderer `state_palette_id` |
| `Document.add_exit/remove_exit` + `rooms/redirect_dialog.ExitDialog` + inspector "Add exit at this cell…" / "Delete this exit" (S95) | custom-room exits authored on the canvas (walk-on interior / push edge) | PyBoy-verified in test_canvas --rom; P3.7 seed |
| `Document._migrate` / `LEGACY_RECORDS` (S95) | fills the hand-patched `$26DD` rows for `$6B-$6D` into pre-S94 projects on open | user S95 build failure (old project.json + new editor code) |
| editor2/app/rooms/canvas.py `SpriteCache` (S94b) | NPC thumbnails knock out the throne-room floor (border flood-fill over the per-pixel mode of the 137 crops) — the committed crops are unchanged | user report: "castle red tiles where the boss should be"; bosses stay 16×16 fragments until P3.5 |


## S96 rows (rooms tab build-out: tiles & tilesets, PNG import, space meters; script arity)

| Item | What | Notes |
|---|---|---|
| tools/script_param_counts.py → **extracted/script_param_counts.json** | Parameter count + tail kind (continue / branch / ret) of all **102** script opcodes, derived from the bank-$04 HANDLER code: per-path count of 16-bit script-counter increments, tails = ScriptExecContinue `$55F5` / ScriptReturnProcess `$7212` (branch) / ret. `--check`/`--selftest` re-derives from the ROM (verify_integrity check 5) | Replaces decompile_script's guessed PARAM_COUNTS (36 wrong + 2 missing); read by extract_room, compile_script, decompile_script, scriptgen (hex-op arity warnings + `regroup_ops`). Table: BANK04_SCRIPT_ENGINE "Parameter counts" |
| tools/extract_room.py (S96) | scripts read from the map type's OWN script bank (`script_bank()`: <$06 $0C, <$20 $0D, <$40 $0E, else $0F — was always $0D), per-map pointer list bounded by the next in-range map's list; attr rows read by direct screen index (was an 8-slot parse → KeyError on GreatTree); arity from the JSON | all 98 vanilla rooms clone (test_canvas "all clones") |
| tools/decompile_script.py, tools/compile_script.py (S96) | arity + branch set from the JSON (literal tables kept as the pre-S96 record/fallback); `$64`/`$65` known; pretty forms whose arity was wrong print generically | `compile_script.py --test` round trip unchanged |
| editor2/core/png_import.py | PNG → DWM1 background tiles: key colours (border + non-GBC colours), panel detection (run-length union-find, offset = panel corner mod 16), `best_offset`, valid cells, subtile requirements under the forced idx1/idx3, greedy palette fit into ≤4 slots with locked slots, 2bpp encode, `CellPlan`, `slot_demand`, `render_plan` | pure Python + PIL; `nfree` parameter (3 = the "cream freed" what-if) |
| editor2/app/import_tab.py ("Import art" tab) | open PNG (copied to assets/imports/), per-panel grid + nudge (arrows, Shift = 8 px) + Auto-align, tools Select / Mask / Wall (same tile everywhere) / Panel / Key colour, palette slots keep/fit + "Show as GBC", budget line, "Add to My metatiles", "Stamp onto the room" with spill onto new screens | per-image settings in `custom._editor.imports`; edits are merged `EditImport` undo steps; imports are SnapshotCommands |
| `Document.import_png_cells / writable_attr_id` | allocation (identical graphics reused; wall-BR below / walkable-BR above the threshold; free slots only), palette write into the effective palette (vanilla borrow localized), metatiles, stamp across screens (creates screens, record dims follow) | fails before writing when slots run out |
| editor2/app/rooms/tileset_map.py ("Tileset" tab, P3.3c) | 128-slot map: placed / my metatiles / vocabulary / released / animated / free, "graphic changed" dot, threshold step line, hover users, click = canvas highlight, "Release unused vocabulary" | `Document.tile_usage / used_tiles / free_counts / released / set_released / tileset_origin`; the vocabulary is derived from the source room (renderer `vanilla_tiles_used`), no longer session-registered |
| editor2/app/rooms/tileset_dialog.py + inspector "Change…" + New room "blank tileset" | room → another vanilla sheet / a project sheet / a new blank sheet (`Document.set_room_tileset`, `new_blank_tileset`) | layouts keep tile numbers |
| editor2/app/space_meter.py + `compiler.measure_banks` + `validators.bank_usage` | status-bar meters for banks $60/$64/$67/$71 from the UNSAVED document (same count as the pre-build overflow check), amber >80 %, red >95 % | ~0.15 s per measure, debounced |
| metatile `pal` = int or list of 4 (`document.metatile_pals / pal_value / metatile_key`) | per-subtile palettes in picker, canvas strokes, metatile editor ("per subtile") | vanilla census: 3,156 of 42,080 cells mix slots |
| patches/bank_017.asm `FreeColor1Hook` + `LoadPal4102_*` labels (also in disassembly/bank_017.asm, zero-byte) | the engine's colour-1 copy (LoadPal_4102) skips slots 0-3 for custom rooms whose palette carries the `free_color1` marker (round 4: per slot, marker restored in the buffer) | pin `07a71f20…` (patched, historical) → `5db25d15…` (patched) |
| patches/bank_006.asm field A-press menu-open tail (same-size) + patches/bank_073.asm entry 13 `MenuOpenFreePal` (S96 round 4) | cream colour 1 in HARDWARE for free-colour slots during the menu's tile-$E0 wipe | test_canvas --rom: menu open (wipe colour 1 == $6BFF) / close (palette RAM == project) |
| `Document.import_png_cells(strict_walk=False)` + import tab "Unmarked cells must be walkable" / "New room…" + `editor2.EDITOR_REVISION` (S96 round 3) | only Wall-marked cells bind a threshold side (author settles walkability); blank-tileset room from the import tab; revision in title bar + build log | test_canvas v3 asserts the free mode never needs more slots than strict |
| editor2/app/collapsible.py + Rooms right panel (vertical splitter of foldable sections) + palette panel "show system 4-7" / "own colour 1" | S96 user QOL | fold state in QSettings `ui/section/*`, splitter `ui/rooms_right_split` |
| editor2/tests/test_canvas.py (v3 + all clones) | v3: PNG import via the tab (synthetic rip from Farm art: exact fit, pixel-identical stamp, spill), slot map == used_tiles, per-subtile paint, tileset switch, release, meters; `--rom`: VRAM == canvas, BG palette RAM == project, WALL cell blocks. All clones: 98 rooms / 211 screens / 526 states pixel-identical + every clone compiles (~12 s) | |

## S97 rows (rooms group B: state rules P3.5a + NPC inspector P3.5; NPC behaviour decode)

| Item | What | Notes |
|---|---|---|
| extracted/npc_names.json `type_names` (hand-authored, Tier R) | REPLACED by the measured type-byte meanings (behaviour nibble 0-F, $40 hidden) — the pre-S97 names were guesses (DOC_AUDIT S97) | read by the frozen `editor/`; the new editor takes names from `editor2/core/formats.BEHAVIOURS` |
| disassembly/bank_006.asm + patches/bank_006.asm (zero-byte) | `NPCBehaviourTable` + 13 handler labels + 9 phase sub-tables + `NPCFigure8FacingTable` / `NPCFacingFrameTable` / `NPCFacingFlipTable` re-sectioned from fake code; tails `NPCStepX/Y`, `NPCTryStepX/Y`, `NPCBehTail`, `NPCAnim*`; entry 0/1 banners (collision, draw) | one-shot line-number script (not kept); build `1ca6579…` and the patched pin both unchanged by it |
| editor2/core/formats.py `BEHAVIOURS / BEHAVIOUR_PATHS / npc_type_byte / npc_path` | the type-byte vocabulary + measured walk paths (tile offsets from home) | compiler, validators, canvas overlay, NPC panel |
| editor2/core/project.py `state_rules / resolve_flag_ref` + emitters `_state_rule_tables` + template entry 8 `CustomStateRules` + patches/bank_017.asm `StateRulesHook17` | P3.5a (PROJECT_COMPILER §2.13) | template head 492 B, re-pinned; pin `6e97fd37…` (patched) |
| editor2/core/document.py NPC/flag/rule API (`npc_view / add_npc / update_npc / remove_npc / npc_presence / set_npc_presence / new_talk_script / talk_boxes / set_talk_boxes (r2; were talk_text / set_talk_text) / add_flag / flag_pool / state_rules / set_state_rules / rules_for_state`) | the GUI's NPC + rules operations (all wrapped in SnapshotCommands) | raw cloned entries become typed with the same bytes |
| editor2/app/rooms/npc_panel.py (`NpcPanel`, `SpritePicker`, `TalkDialog`) + rules_panel.py (`RulesGroup`, `RuleDialog`) | P3.5 / P3.5a UI | canvas: drag-to-move, path overlay, facing ticks; tab: Add NPC here, "State shown when" |
| editor2/tests/test_canvas.py v4 (+ test_compiler S97 cases) | fresh project → servant clone → rule + named flag + otherwise, NPCs via the panel path (sprite, behaviour, facing, move, talk text, presence, raw edit), exact undo; `--rom`: state by flag incl. palette, wiped counter, otherwise, walker path, talk text + face-player | test_compiler: rule tables, flag words, errors/warnings, type-byte encoding |

### S97 round 2 rows (text boxes)

| Item | What | Notes |
|---|---|---|
| patches/bank_073.asm entries 14-18 (`BoxRowDraw / BoxFrameDraw / BoxRowRestore / ChoiceBoxClose / ChoiceBoxOpen`) + same-size calls in patches/bank_006.asm (`LoadMapS_6939`, dialog state 9, `LoadMapS_6b3d`), bank_056.asm (`SetB56_48a1`), bank_000.asm (`ClearTextBitsRedraw`) + patches/wram.asm `wBoxAttrSave / wBoxAttrMask / wBoxAttrRow / wChoiceAttrSave` | dialog + YES/NO box attrs → palette 7 in free-colour custom rooms, restored on close | PROJECT_COMPILER §2.13 "Round 2"; PyBoy-verified (demo_free), vanilla frames identical |
| editor2/core/textenc.py `boxes` form, `flow_boxes`, `check_boxes`, `codes/cells`, `glyph_2bpp` (+ validators `lines` warning) | talk text as boxes with the measured limits; font at bank $4F $4010 | TEXT_SYSTEM "Text boxes"; test_compiler 4d |
| editor2/app/rooms/talk_editor.py (`TalkDialog`, `BoxEditor`, `render_box`) | per-box editor with the in-game preview | npc_panel re-exports `TalkDialog`; test_canvas v4 (boxes + the first box waits in PyBoy) |
| editor2/app/collapsible.py `remember=False`, `set_expanded` + tab NPC section | panels start folded (only Metatiles open); NPC section | EDITOR_DESIGN "S97 round 2" |
| extracted/wram_usage.json (regenerated by tools/audit_wram.py) | picks up the r2 WRAM carve | no new collisions (window = CF3-freed, structural) |

## S98 rows (rooms group C: P3.7 doors / teleports / spots / talk scripts + World graph v0)

| Item | What | Notes |
|---|---|---|
| disassembly/bank_00b.asm + patches/bank_00b.asm (zero-byte) | renames: `RoomEntry4_TalkTargetLookup` (was `RoomEntry4_NPCMovement`), `RoomEntry5_StepTriggerLookup` (was `RoomEntry5_NPCRender`), `SearchStepTriggers` (was `SearchNPCAtFacing`), `InteractEntryAtPos` (was `CheckExitCoords`), `TalkScanNPCSlots` / `NPCSlotAtPos` / `TalkScanExamineSpots` / `ExamineSpotMatch` (were `Call_00b_433f`/`ReadRoom_433f`, `Call_00b_43e5`/`SaveRoom_43e5`, `jr_00b_4366`, `jr_00b_438d`); headers incl. "scan ENDS at the first NPC entry" | clean `1ca6579…` byte-perfect; patched pin unchanged (`ce24de8b…`, patched) |
| disassembly/bank_001.asm + patches/bank_001.asm, bank_006.asm (comments only) | `CopyPlayerCoordsAndGetNextRoom` header = the step-trigger dispatcher (name kept: tools/audit_mapid_range.py keys on it); bank $06 `Jump_006_611d` + the two `ld hl,$0b04` calls (own cell / facing cell) | ROOM_DATA_FORMAT "Interact entries ≥$80" |
| editor2/core/formats.py `EXAMINE_FACING / EXAMINE_FACING_NAMES / examine_entry / step_trigger_entry` | `$80|facing` / `$90` interact entries | emitters `_room_data`: kinds `examine`/`step`, spots before NPCs (stable partition) |
| editor2/core/project.py `TALK_BLOCK_KEYS / _talk_block_ops / _lower_talk_scripts` | `talk` scripts → ops (PROJECT_COMPILER §2.14) | idempotent (`_talk_lowered`), run after `_lower_quests` |
| editor2/core/validators.py S98 checks | examine/step fields; legacy spawn script 0 warning (the missing-spawn warning and "must be 0" error removed); exit dest screen must exist (error); `_edge_neighbour` edge warnings; talk checks; door end count | test_compiler 4e |
| editor2/core/doors.py (`DoorsMixin`) | doors (`add_door / move_door_end / set_door_states / remove_door / refresh_door / door / doors_touching / door_end_at / default_arrival / vanilla_partner_arrival / vanilla_door_twins / edge_conflict`), teleports (`add_teleport / exit_presence / set_exit_presence`), spots (`add_spot / update_spot`) | mixed into `Document`; each GUI call = one SnapshotCommand |
| editor2/core/talk.py (`TalkMixin`) | `talk_spec / describe_talk / set_talk / new_talk / script_dialogue_ids / flags_referenced` | plain talk stays `[text][end]` ops |
| editor2/core/world.py | `world_graph(doc, renderer, include_vanilla)` nodes/edges (door/exit/redirect/warp/vanilla) + deterministic `layout` (Fruchterman-Reingold, seed 98) | pure data, no Qt |
| editor2/app/rooms/door_dialog.py (`DoorDialog`, `ClickPreview`) + object_panels.py (`DoorPanel`, `TeleportPanel`, `SpotPanel`) + talk_editor.py (`BlockEditor`, spec-mode `TalkDialog`) + canvas/inspector/tab changes | P3.7 UI (EDITOR_DESIGN §5.1 "S98 additions") | `EDITOR_REVISION` = 'S98' |
| S98 r2 door objects: core/doors.py (`add_door(room, key, x, y)` unconnected, `link_doors / unlink_door / rename_door / remove_door` (partner stays) / `move_door / set_door_states / door_end / door_partner / custom_doors / vanilla_door_id / _migrate_doors`), project.py `_unlinked_door` (not emitted), validators door-object checks, door_dialog.py `DoorPropsDialog` + `vanilla_door_list`, canvas `markerActivated` (double-click) + orange `door_open` markers with names, tab `+ Door (D)` action | the user's door design (EDITOR_DESIGN "S98 r2") | test_canvas v5 drives + Door and double-click with real mouse events; test_compiler: unconnected door / link checks; demo ROM unchanged `56e407cf…` (patched); `EDITOR_REVISION` = 'S98r2' |
| editor2/app/rooms/tab.py `_flip_walk` (reads `cmd.error`) + `_walk_button` / `_tool_changed` (S98 r2) | walkability flips report refusals; the Walk toggle is the walkability mode | the S95 SnapshotCommand swallow made the old `except RuntimeError` dead |
| core/document.py `duplicate_tileset / tileset_sharers / _room_tiles / _remap_tile`, `set_room_tileset('own')`, `copy_room` own sheet, `ensure_twin(shift_ok)` + `ThresholdShiftNeeded`; tileset_map.py shared line + own-copy button; tileset_dialog.py "Own copy"; tab `_own_tileset`, `_flip_walk` shift prompt (S98 r2) | no tileset sharing by default; the walkable-side-full split move as an asked option | test_canvas `tileset_sharing_check` (+ `--rom`: the flipped cell walks in PyBoy, a control wall still blocks, screen pixel-identical after the shift) |
| core/document.py `metatile_kind / placed_metatile_keys / unused_metatiles / purge_preview / purge_unused_metatiles`, `add_metatile(src=)`; tileset_map.py purge buttons; tab `_purge_metatiles` (S98 r2) | one-click purge of unused own / borrowed metatiles with the slots it frees | test_canvas `tileset_sharing_check` (placed borrowed kept, 3 unplaced removed) |
| tab.py `_dead_edge` (add/drag refusal), `act_add_examine`, double-click talk edit; canvas `door_dead` marker (S98 r2) | doors on scrolling edges refused / flagged; + Examine button | test_canvas `tileset_sharing_check` §6 + v5 adds the examine spot through the button; PyBoy on the user's project: door at (8,3) both ways |
| editor2/app/world_tab.py (`WorldTab`) | World tab v0 (EDITOR_DESIGN §5.8) | replaces the stub in main.py |
| editor2/tests/test_canvas.py v5 (`--only-v5`) + test_compiler 4e | fresh project through the dialog code paths: 2 doors (one to the GreatTree 2F Library door), drag, one-way teleport, examine (facing up) + step spots, YES/NO NPC (flag + move), world graph, exact undo; `--rom`: both doors both ways with the measured arrivals, facing-only examine, step flag, YES → rule state 1 (VRAM == canvas), teleport | test ROM `DWM-S98-doors-test.gbc` (patched md5 `56e407cf…`, historical; current `DWM-S98r3-doors-test.gbc` patched `72cd22fe…`) = the v5 project; S98 r2/r3 drive + Door / + Examine / double-click with real mouse events and assert whole-tile pixel arrivals |

## S99 rows (P3.3e animated tiles)

| Item | What | Notes |
|---|---|---|
| tools/census_room_animation.py → **extracted/room_animations.json** (Tier A) | Every bank-$01 room-animation handler MEASURED in PyBoy: forced through the $01:$6118 dispatch (hook sets A) in the Bazaar over a patterned VRAM, counter reset to 0, 1024 frames; per handler: effects (roll / sway / swap + partners + period), slots, static VRAM operands, `schedule` {counter: ops} (the editor preview replays it), bgp writes; per map ($00-$6F): handler, slots, shown / hidden_frames (from the vanilla layouts via render_project), inert_in_vanilla | ~26 s, needs pyboy. `--check`/`--selftest` (static, ROM only): jump table == JSON, handler operands re-derived, every measured slot inside the code's operand ranges — **verify_integrity check 5** (SELFTEST_TOOLS). Owning prose: ROOM_DATA_FORMAT "Animated tiles" |
| editor2/core/animation.py | census access (`slots / shown_slots / room_slots / describe_effects / sources`) + `Player` (replays `schedule` over a 2 KB sheet) | canvas preview, slot map, inspector, validators, Document.animated_slots |
| editor2/core/formats.py `anim_source / ANIM_NONE / ANIM_EXCLUDED` + project.py `anim_source` + emitters `CustomAnimSrcTable` + template entry 3 `CustomAnimSource` | `custom.rooms[].animation` → bank $71 | PROJECT_COMPILER §2.15; head 164 B, re-pinned; pin `d072eb51…` (patched) |
| editor2/core/document.py `animated_slots / room_animation / set_room_animation / _migrate_animation` | 77/78 literals replaced by the per-sheet animated set (tile_usage, import_metatile, import_png_cells, ensure_twin); on-open migration | clone_vanilla → `source`; new_room → `source` / `none` (blank) |
| editor2/core/document.py `import_metatile(anim_src=, switch_ok=)` → `_import_animated`, `AnimationSwitchNeeded`, `last_import_note` (S99 r2) + tab.py `_import_metatile` (switch dialog) / `_foreign_brush` | borrowing an animated vanilla tile keeps it animated (same slots, partner frames, relocation, room animation) | test_canvas v6 (+ --rom: the Farm-sheet room's water moves); `EDITOR_REVISION` = 'S99r2' |
| editor2/core/animate.py (`AnimateMixin`: `animate_candidates / make_animated / anim_of_metatile / _vacate / _cells_of`, `source_units / units_of`) + editor2/app/rooms/animate_tab.py (`AnimateTab`, `PixelPad`) + canvas `cellActivated` + inspector `add_cell_row` (S99 r3) | "Make animated": own art as slide / two-frame flip on any vanilla animation's slots | test_canvas v6 (+ --rom: 2 looks, only source slots change); `EDITOR_REVISION` = 'S99r3' |
| editor2/core/animate.py `stray_animated / stray_report / repair_animation / make_still` + main.py `_offer_animation_repair` + animate_tab "Make still" (S99 r4) | unintended animation found on open (asked, one undo step); stop one tile moving | test_canvas v6 (stray repair + Make still, exact undo); user project verified; `EDITOR_REVISION` = 'S99r4' |
| editor2/app/rooms/animate_tab.py part tools (`_set_part / _pick_part / _copy / _paste / _between / _xform / _undo / _revert`, PixelPad `sel / active / partPicked`) (S99 r5) | frame pads: whole tile or one 8×8 quarter, Copy / Paste / A→B / B→A / A⇄B / flip / shift / clear + local undo, on the edited frame | test_canvas v6 (each tool on one quarter, others untouched; undo back exactly); `EDITOR_REVISION` = 'S99r5' |
| editor2/core/animate.py `anim_budget / _cells_touching / _released_by`, candidates `takes / taken_slots / released / short`, `_vacate(release=)` + animate_tab `budget_html / show_room / update_budget` + inspector count line (S99 r6) | take over a full room animation (asked; taken quarters keep their look in a still copy); the per-room count | test_canvas v6 (take-over: same look, only the tile's cells start, taken quarters still, exact undo; count text); user project + PyBoy $6E; `EDITOR_REVISION` = 'S99r6' |
| editor2/core/animate.py `_shift_split / _rewritten / _room_art`, `units_of(cur=)` (still quarters), candidates `shift / short_any / lib_only`, switch counts `A.slots(mid)` + animate_tab ①-④ layout, `why` line (S99 r7) | make a tile animated on a tileset full on one side (split moves; look + walkability kept); only changed quarters move | test_canvas `v6_split` (wall side filled: split moves, 1 pair, every cell same look + walkability) + v6; user project palm + water on Zoma + PyBoy $6E; `EDITOR_REVISION` = 'S99r7' |
| editor2/app/rooms/canvas.py (Anim layer, `set_preview` / `_anim_tick`), tab.py (Anim toggle, ▶ Play, `_animation_chosen`), inspector.py (animated tiles row), tileset_map.py (teal / dashed hidden frames, summary), metatile_picker.py (`set_animated`) | EDITOR_DESIGN §5.1 "S99 additions" | `EDITOR_REVISION` = 'S99' |
| editor2/tests/test_canvas.py v6 (`--only-v6`) + test_compiler S99 cases | GUI: vanilla animated tiles, clone = source, preview, None / Borrow, exact undo; `--rom`: VRAM == census schedule (source / none / borrow / vanilla) | test_compiler 106/106 with --rom |
| tools/audit_mapid_range.py (S99) + **extracted/mapid_range_audit.json** (regenerated) | 11 new verdict keys (9 overdue since S73 + 2 S99) — selftest PASS again | DOC_AUDIT S99; CROSSBANK_ROOMS "S99 adjudication sweep" |
| disassembly/bank_001.asm + patches/bank_001.asm (labels/comments) | 65 `RoomAnim_*` / `RoomAnimNone_*` handler labels with census comments; helpers `RollTilePairWobble`, `GreatTreeSway`, `RollTilesRight4/Left4`, `VRAMSwapBytes`, `RollTileRight/Left`; wrong comments replaced | clean `1ca6579…` byte-perfect; one-shot script (not kept) |

## S100 rows (P3.7b part 1: custom rooms on gate floors)

| Item | What | Notes |
|---|---|---|
| tools/map_gate_names.py → **extracted/gate_names.json** (REWRITTEN + REGENERATED S100, tool + data together) | gate id → name from the gate-indexed `GateFloorDataTable` ($16:$70A6: floor count byte 3 + boss map byte 4), cross-checked against FULL_FAQ "Levels:" for all 32 gates; new shape `{_generator, gates: [{id, name, faq_name, floors, boss_map, boss_room, floor_types, depth_tier}]}`; `--check`/`--selftest` (verify check 5) | the old tool indexed the boss REDIRECT table ($14:$4897, one row per boss — Demolition has two) as if gate-indexed: names 23-31 were one gate late (DOC_AUDIT S100). Readers `dump_room_data.py` / `gen_encounter_db.py` accept the new shape; `load_names()` helper |
| tools/gate_reference.py (hand data, FIXED S100) | keys 12-17 re-keyed to ROM id order (were FAQ chapter order) in both dicts; Medal 19 / Mastermind 27 floors | prefer gate_names.json (ROM-derived) |
| disassembly/bank_001.asm + patches/bank_001.asm (comments only) | 48 gate-name comments in the encounter pointer table + pool headers corrected (they came from the old gate_names.json); `jr_001_4358` gate-music comment (floor before the boss plays the boss theme) | clean build byte-perfect |
| disassembly/bank_006.asm + patches/bank_006.asm (labels/comments/re-section, zero byte) | `FieldStateDispatch` (entry 6, $6034) re-sectioned from fake `SkillLearnReqTable` rows back to code (218-row table); `MapTransitionMachine` header + `MapTransStateTable` (24 × dw, was fake `call c, DispMapS_566b …`) + 12 `MapTrans_*` handler labels (probe-build addresses) | DOC_AUDIT S100 |
| disassembly/bank_007.asm (label + comment) / bank_016.asm (comments) | `SaveAllowCheck` $07:$6061 (vanilla JOURNAL ladder); special-room gating comment (Div8x8 divides B = wCurrentFloor) | GATE_GENERATION §3 / §7.6 |
| tools/build_skill_tables.py (`LEARN_ROWS = 218`, `FIELD_STATE_DISPATCH_BYTES` guard) | `--emit learn` prints 218 rows; any emission that would change rows $DA-$DD (the code) refuses | selftest still round-trips all 222 reads (the game reads those code bytes) |
| tools/verify_integrity.py | check 5 += `map_gate_names.py` | |
| extracted/wram_usage.json (regenerated by tools/audit_wram.py) | picks up wGateDiveGate/Mask $DEBC-$DEBD | class A':rammap-span like the neighbouring S73-S75 vars |
| editor2/core/gates.py (NEW: `vanilla_gates / gate_floors / floor_range / floors_text / arrival_px / effective_chances / stairs_down_row / is_stairs_down` + `GatesMixin` on Document: `gate_inserts / set_gate_inserts / gate_rules_for / rules_serving / gate_rule_rows / gate_floor_plan / describe_gate_rule / set_gate_arrival / clear_gate_arrival / set_can_save / encounter_mode / set_encounter_mode / set_room_music / add_stairs / gate_room_report`) | headless gate model for compiler + GUI | PROJECT_COMPILER §2.16 |
| editor2/core/project.py (`_normalize_stairs / gate_insert_rows / gate_rooms / room_by_id / room_flags`) + emitters `_gate_insert_table`, `CustomRoomFlagsTable`, RoomEncTable `$FF` + validators `_validate_gates` + template entries 4/5 | the compiler half | PROJECT_COMPILER §2.16; TEMPLATE_SIZE[$71] 395 |
| editor2/app/gates_tab.py (`GatesTab`, `GateRuleDialog`) + app/rooms/gate_panel.py (`GateRoomGroup`) + canvas `stairs`/`gate_arrival` markers + inspector More ▾ "Stairs down here" + TeleportPanel stairs view + tab/main wiring + world.py (stairs skipped) | the editor half | EDITOR_DESIGN §5.1b "as built S100" |
| editor2/tests/test_compiler.py (S100 gate cases, pin `7cd7257b…` patched, S100 r3; + LZSS max-copy cases) + test_canvas.py v7 (`--only-v7`) | 121/124 tests; v7 = GUI authoring + PyBoy from a scripted new game | |


## S101 rows (P3.7b part 2, first half: custom boss floors, monster NPCs, conversations, project enemies)

| Item | What | Notes |
|---|---|---|
| tools/census_monster_npc_sprites.py → **extracted/monster_npc_sprites/sp_NNN.png + extracted/monster_npc_sprites.json** (NEW, tool + data together) | every species as a monster NPC ($F0-$F3 display list): builds the example project with four raw $F0-$F3 NPCs on `gate_island` screen 0, PyBoy pokes `$D7CA`, warps in, screenshots with the NPCs shown and hidden — the differing pixels are the sprite → 16×16 RGBA (standing, facing down); blank batches retried singly | `--species 0-216,224` default (217-220 hang/crash, 221-223 do not exist); 218 captured, `blank: [216]`; needs RGBDS + pyboy (~minutes). Owning: ROOM_DATA_FORMAT "Monster NPCs"; the editor's Monsters picker + canvas read it |
| tools/map_gate_names.py → extracted/gate_names.json (UPDATED + REGENERATED S101) | each gate gains `boss_spawn` [x, y] (bytes 5/6) and `row` (the 8 raw bytes, hex) | `--check` still passes (verify_integrity check 5); the compiler reads `boss_spawn` for `vanilla:$xx` boss floors |
| patches/bank_014.asm (hand) | `LoadEnemyStats` head → `LoadEnemyStatsExt` (EID ≥ 519 → bank $6B); `LookupBossRedirect` → `BossRedirectTableExt` (compiler region `boss_redirects`) | MONSTER_DATA "Project enemy rows" |
| patches/bank_06b.asm (NEW, compiler-owned) + editor2/core/templates/bank_06b_head.asm (pinned) + patches/game.asm include + verify_integrity PATCH_NEW_FILES | `CopyEnemyRowExt` + `ProjectEnemyRows` | PROJECT_COMPILER §2.18 |
| patches/bank_016.asm (region wrap) | `GateFloorDataTable` = `; @BUILD_PROJECT BEGIN/END gate_floor_table` | emitter `gates16` |
| disassembly/ + patches/ bank_004 / 00b / 016 / 054 (comments only) | opcode $3B / $58 blocks, $06 / $0D / $1C / $47-$4A catalog lines, the bank $0B sprite resolver ($E1-$E3 / $F0-$F3), the join-tier comment, the boss-path comment | byte-perfect verified |
| editor2/core/conversation.py (NEW: `ConversationMixin`, `EnemiesMixin`, species / skill / vanilla-enemy readers) + project.py (`gate_configs`, `boss_room_ids`, `enemy_ref`, `enemy_redirects`, `monster_cast`, `npc_sprite`, `_lower_steps`, `_place_helpers`) + gates.py (gate settings, `conversation_exits`) + emitters `enemies6b`, `redirects14`, `gates16`, `_monster_cast_tables` + validators + scriptgen OPS names + templates $60/$71 | the compiler + headless document half | PROJECT_COMPILER §2.17/§2.18 |
| editor2/app/enemies_dialog.py (NEW), app/rooms/conversation_dialog.py (NEW), gates_tab.py (Gate settings), npc_panel.py (Monsters tab, New conversation…), gate_panel.py (Arrival conversation…, boss line), canvas.py (`MonsterCache`), tab.py wiring | the GUI half | EDITOR_DESIGN §5.1b "As built S101" |
| editor2/tests/test_compiler.py (S101 cases; pin `9c813041…` patched) + test_canvas.py v8 (`--only-v8`) | 151 tests with --rom; v8 = a boss floor authored through the GUI code paths, played in PyBoy (talk → YES → 2-enemy battle → win → flag → helper → Castle) | |
| editor2/example-project/project.json | raw script ops renamed to the new opcode names (bytes identical) | KEY_LESSONS S101 |
| editor2/app/help_tab.py + **editor2/help/*.md + editor2/help/_revision.md** (NEW S101 r3) | the editor's Help tab and its topics (hand-written Markdown); `_revision.md` = the EDITOR_REVISION the help was updated for | test_app asserts the stamp == EDITOR_REVISION; SESSION_PROTOCOL wrap-up item 7 |

## S102 rows (P3.3f own animated tiles)

| Item | What | Notes |
|---|---|---|
| **tools/sameboy_anim_check.py + tools/sameboy/dwmcheck.c** (NEW) | SameBoy-core cross-check of a room's own tile animations: boots `<project>/build/build/rom.gbc` with a battery save, CONTINUE, warps (pyboy_harness mailbox), then every frame compares each animated slot's VRAM with its authored frames | needs SameBoy cloned + `make tester` (docstring), clang; exit 0 = all frames match, 3 = mismatches. No extracted/ output. PYBOY_DEBUGGING "S102" |
| patches/bank_06c.asm (NEW, compiler-owned) + editor2/core/templates/bank_06c_head.asm (pinned) + patches/game.asm include + verify_integrity PATCH_NEW_FILES | `CustomTileAnimate` / `TileAnimRestart` / `TileAnimCopy` + generated data | PROJECT_COMPILER §2.19; TEMPLATE_SIZE[$6C] 285 |
| editor2/core/templates/bank_071_head.asm (re-pinned) | entry 3 `CustomAnimSource` far-calls bank $6C first | TEMPLATE_SIZE[$71] 444 |
| patches/wram.asm (hand) | `wTileAnim*` carved from wCustomPool ($D0C5-$D109) | known_RAM_map [S102] |
| editor2/core/tileanim.py (NEW) | data model + engine mirror: `steps / groups / roll / offsets / schedule / load / load_words / rom_bytes / problems / Player` | shared by compiler, validators, editor |
| editor2/core/tileanim_doc.py (NEW, `TileAnimMixin` on Document) | `anim_selection / add_tile_anim / update_tile_anim / remove_tile_anim / tile_anim_budget / tile_anim_player / own_anim_slots / anim_of_slot` | Document.animated_slots includes own slots |
| editor2/core/emitters.py `emit_bank_06c` (`tileanim6c`) + project.py `room_sheet / tile_anims` + validators (tile_anims block, bank $6C accounting) | the compiler half | |
| editor2/app/rooms/animate_tab.py (REWRITTEN: `AnimateTab`, `FramePad`) + canvas.py (rectangle selection, own preview) + tab.py (`_tanim_*`) + inspector.py (summary line; combo moved) | the Animate tab | EDITOR_DESIGN §5.1 "As built S102" |
| editor2/help/15_animated_tiles.md (NEW) + 10_rooms.md / 90_limits.md | help | `EDITOR_REVISION` = 'S102' |
| editor2/app/rooms/animate_tab.py r2 (`FramePad.activated / set_zoom`, the side-by-side frame strip `_rebuild_frame_btns / _layout_strip / _zoom_by`, `pad` = the yellow frame) | every frame painted in place, side by side (user S102 r2) | test_canvas v6; `EDITOR_REVISION` = 'S102r2' |
| editor2/app/rooms/animate_tab.py r3 (`FramePad.partPicked / part_rect`, `_set_part / _pick_part / _part_rect / _grid / _put_grid`, `_tool` copy / paste / clear on the part) | tools on one 8×8 tile / 16×16 cell / the whole frame (user S102 r3) | test_canvas v6; `EDITOR_REVISION` = 'S102r3' |
| editor2/tests/test_compiler.py (tile_anims cases; pin `0d60486e…` patched) + test_canvas.py v6 (Animate tab; --rom own flip = authored frames only) | 170 tests with --rom | |
| disassembly/bank_000.asm + patches/bank_000.asm (bytes + comments, zero byte) | `LCDCStateTable` (the LCD STAT job table, was decoded as code) | DOC_AUDIT S102 |

## S103 rows (P3.9 Layer A-lite: the vanilla data tables behind project.json `gamedata`)

| Tool / data | What | Verified |
|---|---|---|
| tools/extract_gamedata.py (NEW) | ROM → `extracted/gamedata_vanilla.json`: the 11 vanilla tables (monster info, enemy stats 0-486, encounter pools, family + special recipes, exp / growth curves, skill learn 218 / MP / records, boss redirects) as hex rows + label/bank/addr/stride, `EncounterChancePercent`, the bank-$41 monster name bytes and the bank-$4D library recipe block (pointers, raw $43CE-$53D2 bytes, pad, family tokens). `--selftest` = JSON == ROM (verify check 5) | selftest PASS; test_compiler: empty gamedata regions == these rows; `--rom`: built ROM == original at every table |
| extracted/gamedata_vanilla.json (NEW, ~150 KB) | the Layer A-lite base read by `editor2/core/gamedata.py` (so the compiler needs no ROM) | `_generator` stamped |
| editor2/core/gamedata.py (NEW) | `Gamedata` (vanilla + overrides, validators, coherence warnings, B5 special logic ported from build_breeding.py) + the 12 region emitters (PROJECT_COMPILER §2.20) | test_compiler 227 (`--rom`) |
| patches/bank_013.asm (NEW hand patch) | the clean bank $13 + two markers (`gd_exp_curves`, `gd_growth_curves`); listed in verify_integrity PATCH_FILES | verifier PASS |
| disassembly/ + patches/ bank_04d.asm | recipe-string block re-sectioned (`LibRecipeTextBlock`, `LibRecipeText_NNN`); patched copy = region `gd_library_text` | clean build byte-perfect |
| disassembly/ + patches/ bank_001.asm (comments/labels) | `EncounterChancePercent` re-sectioned, the pool format + group-size rule annotated | clean build byte-perfect |
| tools/build_breeding.py `--emit-family / --emit-special / --emit-relocation`, build_family_reassign.py `--emit`, build_library_table.py `--emit`, build_new_species.py bank $14 / $01 writes | RETIRED S103 (exit with a message naming the `gamedata` section); `--selftest`s unchanged | run: each refuses; selftests PASS |
| tools/build_new_species.py bank_06a write, tools/bake_follower_overflow.py `--out patches/…` | RETIRED S105 (P3.9b; `custom.species` → `ns_info` / bank $7E — PROJECT_COMPILER §2.21) | run: each refuses with a message; `build_new_species.py --check` PASS; `bake_follower_overflow.py --stream-dir` reproduces the example assets |
| editor2/core/species.py (S105 G3) | ids 221-239; 13 `ns_*` regions + bank $7E (38-word pointer table, computed follower gfx-ID); exact bin-packer `_pack` for the bank-$41 name extents | test_compiler --rom: MiniSM83 runs every fork from the built ROM (example + 19 species); PyBoy fixture 221/224/239 |
| editor2/help/55_game_data.md (NEW) + `EDITOR_REVISION` = 'S103' | help topic: what game data a project can change today, what the build keeps coherent, the checks | test_app `--rom` PASS |
| editor2/tests/test_compiler.py `test_gamedata` + `--rom` table regression; pin `5d1dbc5f…` (patched) | per-table empty == vanilla, field offsets, validators (incl. the measured freeze), example re-expression | 227 tests with `--rom` |

## S104 rows (P3.10a Spirit as the 11th family)

| Tool / data | What | Verified |
|---|---|---|
| patches/bank_06d.asm (NEW hand patch; PATCH_NEW_FILES; `patches/game.asm` includes it instead of the empty bank) | bank $6D FAMILY SYSTEMS: `FamilyIconGfxActive` / `FamilyIconGfxFromE` / `FamilyTextGroupFromE` (+ `FamilyTextPtrTable11`) / `FamilyDefaultNameId` / `SpiritIconStream` | PyBoy stub-calls + screens (BREEDING_SYSTEM "Spirit — the 11th family (S104)") |
| patches/bank_001 / 004 / 009 / 00a / 016 / 007 / 041 / 04f.asm | the same-size forks, `$FA` exact, unknown-parent icon id 11, mode-4 Spirit string + names, ??? restored + Spirit glyph | verifier PASS; old-vs-new build diff = exactly these bytes |
| disassembly/ + patches/ bank_041 (mode list + mode 0-4 tables), bank_00a (`FamilyIconGfxTable0A`, `LoadFldA_46c9`), bank_001 (patched copy of the clean `ScreenTransDataTable` / `FollowerFamilyGfxTable` rendering), bank_009 / bank_007 comments | re-section / labels / comments, zero byte | clean build `1ca6579…` |
| tools/build_family_icon.py | `--selftest` checks the full vanilla INCBIN (??? kept), the `$41B0` glyph and the bank-$6D stream against `family_icons.json`; `--png` prints both lines; `--dump` writes the Spirit slot as `$1A/$41B0` | selftest PASS; now in verify check 5 |
| extracted/family_icons.json (regenerated with `--dump` the same session) | `_note` + `spirit.byte/addr/note` updated; grids unchanged | selftest PASS |
| tools/build_breeding.py | `FAMILY_CODES[$FA]` = "Spirit", `"spirit"` matcher, `"anyfamily"` removed, no `$FA` wildcard in `_entry_matches` (the special scanners never had one) | `--selftest` PASS (round trip unchanged) |
| editor2/core/gamedata.py | `family_index()` (names or 0-10), `"Spirit"` → `$FA`, `"AnyFamily"` / `"any"` ERROR, `FAMILY_CODES` $F0-$FA, `SPIRIT_TOKEN` library text, `_matches` without wildcard | test_compiler 7 new cases |
| editor2/help/55_game_data.md + `EDITOR_REVISION` = 'S104' | Families paragraph (Spirit, stamped vs species family) | test_app `--rom` |
| editor2/tests/test_compiler.py pin `eee9f5b0…` (patched) | example build = S103 + the engine bytes (no project.json change) | 233 tests with `--rom` |

### S104 r2 rows

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/gamedata.py `families` section (`VOICES`, `VOICE_OF`, `SPIRIT_NAMES_DEFAULT`, `emit_family_voices`, `emit_spirit_names`) + emitters REGISTRY `gd_family_voices` (bank $6D) / `gd_spirit_names` (bank $41) + the two marker pairs in patches/bank_06d.asm / bank_041.asm | per-family dialogue voice, Spirit's 8 default names | test_compiler 8 new cases; empty == r1 bytes |
| editor2/core/families.py (NEW, `FamiliesMixin` on Document) | members / vanilla family / voice / names readers; setters that write only differences and validate with the compiler's model | test_app |
| editor2/app/families_tab.py (NEW) + main.py (tab before Monsters) | the Families tab | test_app: move, voice, name, undo == file |
| extracted/family_icons.json `spirit.grid` + patches/bank_04f.asm $41B0 + patches/bank_06d.asm SpiritIconStream | ghost wisp (user pick) | build_family_icon.py --selftest PASS |
| editor2/help/55_game_data.md + `EDITOR_REVISION` = 'S104r2' | Families tab help | test_app |
| test_compiler pin `eb153510…` (patched) | | 241 tests with `--rom` |

### S104 r3 rows

| Tool / data | What | Verified |
|---|---|---|
| patches/bank_012.asm `LibScanByFamily` (2 × `ld hl, $c0d8` → `ld hl, wMonList`) | library list buffer = the FX1 reader buffer | PyBoy: Spirit tab lists Healer, page opens; test_compiler pin `d7b762db…` (patched) |

### S104 r4 rows

| Tool / data | What | Verified |
|---|---|---|
| patches/bank_073.asm `CF3SnapRestore` .r4 (93 chunks) + NEW `CF3SnapTail4` | R4 restore no longer writes the snapshot's stale tile bytes $BCC8-$BCE3 | PyBoy: user .sav continue + reset, farm→castle save cycle, rewind regression; pin `e994173e…` (patched) |

### S104 r5 rows

| Tool / data | What | Verified |
|---|---|---|
| patches/bank_012.asm `LibTabToFamily` / `LibTabOrder` / `LibTabIconId` (+ same-size call in `SaveItem_6184`, a call in `LibScanByFamily`, 39 fill nops consumed) | library tab display order: Spirit before ??? | PyBoy tab pages 2/3; test_compiler checks LibTabOrder == `gamedata.DISPLAY_ORDER`; pin `15f21834…` (patched) |
| editor2/core/gamedata.py `DISPLAY_ORDER` + editor2/app/families_tab.py | Families tab rows / Move-to list in display order | test_app |

## S106 rows (P3.10 part 1: the Monsters tab, the sprite-sheet reader, the LZ decoder fix)

| Tool / data | What | Verified |
|---|---|---|
| dwm/sprite_codec.py `decode` / `read_stream` / `MAX_COPY` | per-byte 4 KB wrap of copy sources (a source below the destination = 0 — the game's `TextMakeVisible`), 8-bit extended copy length (0 = 256), encoder copies ≤ 256 | tools/census_lz_decode.py 442 / 442 == the game; test_compiler S106 LZ cases |
| tools/census_lz_decode.py (NEW) | PyBoy stub-calls `WaitDMATransfer` ($00:$1577) on the original ROM for every monster gfx-ID, compares with `sprite_codec.decode`, twice (VRAM below the destination $00 / $AA) | 442 equal, 0 VRAM-dependent; ~12 s; needs pyboy |
| extracted/monster_sprites.json + extracted/monster_sprites/{008,053,078}_*.png (regenerated, tool unchanged) | the decoded art of every monster | row above; --rom test |
| tools/extract_monster_follower_layouts.py + extracted/monster_follower_layouts.json (regenerated; follower_layouts.json unchanged) | bank-$11 attr base `$412D` | row above; S106 render test |
| editor2/core/sheet_import.py (NEW) | sprite-sheet reader: background, 2-px clusters, frame grids (2 × 3, pitch 14-30 px), poses paired left of their grids; battle 48 × 48 (backdrop idx 1; S106 r2: 4 colours — every sheet colour to the nearest of black / cream / 2 fitted colours, the cream also inside the pose like every original; standing 2 px above the floor; shrink-to-fit) and walking payload (layout 0 order, one luminance mapping over the 4 stored frames, OBJ palette by hue) | test_compiler: the water sheet's blue dragon == the hand-picked S34 / S35 boxes and Gorbunok's committed art byte-for-byte; 31 / 31 complete monsters on that sheet |
| editor2/core/monsters.py (NEW, `MonstersMixin` on Document) | one species source (`species_catalog`), effective rows, sparse writes to `gamedata.monsters` / `gamedata.enemies` / `custom.species[].info`, enemy rows of a species + where they are met (pools, bosses, arena, coliseum / random / mimic / script battles, starter, project uses), curve users, new-species add / art / props / remove (references refused), capacity | test_compiler 15 model cases |
| editor2/core/sprite_render.py (NEW) | battle poses + walking frames (4 directions) as pixels — original species from the extracted data, new species from their streams | test_compiler: == the PyBoy census for 213 / 215 species |
| editor2/app/monsters_tab.py, sheet_import_dialog.py, sprite_qt.py (NEW); main.py, session.py, rooms/canvas.py (`MonsterCache` draws through sprite_render, `bind`s the open project) | the Monsters tab (Species / Where you meet it / Name & art), the sheet dialog (draggable boxes, live preview, colours), NPC-picker thumbnails for new species | test_app --rom (species list, edits, enemy cell, sheet species create + undo removes files) |
| editor2/core/species.py | `custom.species[].source` (sheet + boxes; editor metadata, not read by the compiler) | test_compiler |
| editor2/help/52_monsters.md (NEW) + 00_start / 55_game_data / 90_limits; `EDITOR_REVISION` = 'S106' | help | test_app |
| editor2/app/pool_dialog.py (NEW, S106 r3) + monsters.py `gate_pools` / `pool_slots` / `set_pool_slots` / `new_enemy_for_species` + gamedata.py over-100 % warning; `EDITOR_REVISION` = 'S106r3' | put an enemy row into a gate's encounter list from the Monsters tab | test_compiler (sparse write, < 100 refused, > 100 warns), test_app (GUI put + undo), PyBoy (the user's project: a sheet species met in the Gate of Beginning) |
| tools/validate_custom_data.py + editor2/core/builder.py (S106 r3) | a missing `data/DWM-original.gbc` is a reported error (was an uncaught exception → an empty "crash-config validation failed" in the editor); the build runs the checker with `sys.executable` and shows stderr | run without / with the ROM; test_app --rom |

## S107 rows (P3.10 part 2a: new art for the original monsters)

| Tool / data | What | Verified |
|---|---|---|
| tools/resection_monster_art_tables.py (NEW) | Iron-Rule-6 re-section (probe-build, both trees): the 7 misassembled follower gfx-ID copies → `FollowerGfxTable06/07/09/0B/12/18/59` (mgbdis names kept beside them) and bank $10's `FollowerLayoutL1Table10` / `FollowerAttrTable10`; labels another file references are kept at their byte offsets, the rest dropped and listed. Probes skip lines whose scope uses `.local` labels (a probe is a global label — KEY_LESSONS S107). The patched bank-$0B copy was replaced by hand (its text differs: S14 labels, table at $4914). Produces no extracted/ data | clean `1ca6579…` byte-perfect after every table; patched pin unchanged `f22f56e1…` (patched) |
| tools/extract_gamedata.py + extracted/gamedata_vanilla.json (regenerated, additive) | 7 new tables: `battle_gfx` (221 × 2), `battle_palettes` (216 × 8), `follower_gfx` (bank $01 species rows, 215 × 2), `follower_layout_10/_11`, `follower_attr_10/_11`; `--selftest` also asserts the eight follower copies are identical for species 0-214 | verify check 5 PASS |
| editor2/core/art.py (NEW) | `gamedata.art` → `art_*` regions + art banks $7F/$7C/$7A (`resolve` / `place` / `tables` / `usage`, `ANCHORS`, `rows_text`) | test_compiler S107 cases + `--rom` |
| patches/bank_010.asm (NEW hand patch; PATCH_FILES) + patches/bank_07a/07c/07f.asm (compiler-owned; PATCH_NEW_FILES; `patches/game.asm` includes them) | regions `art_layout_10` / `art_attr_10`; the three art banks (empty = zero) | verifier PASS |
| patches/bank_000 / 001 / 006 / 007 / 009 / 00b / 011 / 012 / 017 / 018 / 059.asm | the `art_*` region markers (filled with the emitter's vanilla output); bank $00's battle table head ported from the clean tree (8 unreferenced patched-only labels dropped); bank $17 `MonsterBattlePalettes` label added | patched pin unchanged |
| editor2/core/gamedata.py `SECTIONS` += `art`; validators call `art.place` | | |
| editor2/core/monsters.py (`original_art / can_reart / original_palettes / original_art_paths / set_original_art / set_original_art_props / reset_original_art / art_capacity`), core/sprite_render.py `original_art`, app/sprite_qt.py (project art first), app/monsters_tab.py (Name & art for originals), app/sheet_import_dialog.py (mode `original`, plain error for an unstorable picture), core/sheet_import.py `literal_stream` (LZ fallback / plain error) | the editor half | test_app (S107 block) |
| editor2/help/52_monsters.md, 90_limits.md, 00_start.md; `EDITOR_REVISION` = 'S107' | help | test_app |

### S107 2b rows (P3.10 part 2b: walking layouts)

| Tool / data | What | Verified |
|---|---|---|
| tools/extract_monster_follower_layouts.py + extracted/follower_layouts.json (regenerated, additive; ids / frames / classification unchanged) | per layout: frame entries gain `yflip`; `instances` = its level-2 tables per follower bank (`"10"` / `"11"`, species 0-214 only); `raw` (the example table's stored frames, hex incl. `$80`) + `share` (frame j = raw[share[j]]); top-level `bank_frames` = every frame address + bytes each bank's species use. Signature now includes the Y-flip bit (count stays 155). `--selftest` also: `raw` decodes to every layout's frames, every instance IS the layout, and the committed JSON files == the ROM (both) | selftest PASS; added to verify_integrity check 5 |
| extracted/monster_follower_layouts.json | regenerated, byte-identical | selftest |
| editor2/core/walk_layouts.py (NEW) | the catalogue (`layout`, `entries`, `native_l2`, `users`, `label`), the packer (`pack` / `render` / `error` / `payload`), the ranking (`fit_all`), the copies (`needed` / `copies` / `l2_ref`, regions `lay_copies_10` / `lay_copies_11`, `COPY_START` $10:$7A83 / $11:$799E) | test_compiler S107 2b cases + `--rom` (ROM-decoded layouts) |
| editor2/core/art.py (`follower.layout`, `l2_for`, label rows in `rows_text`), core/species.py (`follower.layout`, `ns_follower_attr` 1 B, NEW region `ns_follower_layout`), core/emitters.py (`lay_copies_*` registered), core/validators.py (copy room) | the compiler half | test_compiler |
| patches/bank_011.asm | engine: both follower entries `call FollowerLayoutBase11` (same size); `NewAttrHandler` without the `$C7` write; `NewFollowerAttrTable` 1 B / id; NEW `NewFollowerL1Table` (region `ns_follower_layout`), `FollowerLayoutBase11`; the zero tail = region `lay_copies_11` (`ds $8000 - @`) | pin `9740c1c9…` (patched); MiniSM83 over species 128-239; PyBoy |
| patches/bank_010.asm | the zero tail ($7A83-$7FFF, 1,405 `nop`s) = region `lay_copies_10` (`ds $8000 - @`, same bytes) | pin |
| editor2/core/sheet_import.py (`follower_colors` over all six frames, `follower_indexed` / `follower_fit` / `follower_pack`), core/sprite_render.py (entry 0 on top, entry Y-flip, `layout` in previews), core/monsters.py (`layout` stored; the copy room checked before writing), app/sheet_import_dialog.py (Walk style list, "On the sheet" preview, deferred re-ranking) | the editor half | test_app (S107 block) |
| editor2/tests/test_compiler.py (`test_walk_layouts_s107`, `_layout_sig_rom`, MiniSM83 `ld b,[hl]` / `push af` / `pop af`, pin), test_app.py (picker) | tests | 532 / PASS |

### S107 2c rows (P3.10 part 2c: family icons)

| Tool / data | What | Verified |
|---|---|---|
| tools/build_family_icon.py (`--selftest` updated; + `region_db`) | the 10 vanilla glyphs are no longer a full INCBIN: the selftest checks the `gd_family_icons` region of patches/bank_04f.asm == ROM $4F:$4110-$41AF and the `gd_family_icon_streams` region of patches/bank_02e.asm == ROM $2E:$424A-$42F7, plus (as before) the Spirit grid == glyph $41B0 + SpiritIconStream. extracted/family_icons.json unchanged | selftest PASS; verify check 5 |
| patches/bank_02e.asm (NEW hand patch; PATCH_FILES) | = disassembly/bank_02e.asm + region `gd_family_icon_streams` over streams 3-12 | verifier PASS |
| patches/bank_04f.asm (region `gd_family_icons` replaces the INCBIN + the Spirit db line), patches/bank_06d.asm (region `gd_spirit_icon_stream`) | the icon regions (empty = the same bytes) | pin |
| patches/bank_007.asm / bank_00a.asm | same-size forks of the saved-party icon readers (JOURNAL $07, twin $0A) to bank $6D FamilyIconGfxFromE | pin `77ccdab8…` (patched); PyBoy |
| disassembly/ + patches/ bank_007 (`SavedPartyFamilyIconTable07`, `Fld_62bf`), bank_00a (`SavedPartyFamilyIconTable0A`, `FldA_6027`), disassembly bank_02e (stream 3-12 comments) | Iron-Rule-6 re-section of data decoded as code (labels / comments only) | clean `1ca6579…` byte-perfect; patched unchanged before the forks |
| editor2/core/gamedata.py (`icons`, `icon_grid` / `icon_rows` / `icon_tile` / `icon_stream`, `vanilla_icons`, emitters `emit_family_icon_glyphs` / `_streams` / `emit_spirit_icon_stream`), core/emitters.py (3 regions), core/families.py (`family_icon(_grids)` / `vanilla_family_icon` / `set_family_icon`), app/families_tab.py (Icon group, `IconCanvas`, `png_to_grid`, scrolling column) | compiler + editor | test_compiler `test_family_icons_s107` + `--rom`; test_app (S107 icon block) |
| editor2/help/55_game_data.md, 00_start.md | help | test_app |

## S108 rows (P3.10 part 3: renaming the original monsters + every dialogue text)

| Tool / data | What | Verified |
|---|---|---|
| tools/dump_dialogue.py (NEW) + extracted/dialogue.json (NEW) | every text the game can show: the 2,560 text ids $0000-$09FF with their MEASURED bank / address (PyBoy stub-calls ROM0 `TextBankDispatch` $0AD9 per id on the original ROM; covers the corpus banks' forwarding to the overflow banks $1A $1B $1F $21 $22 $3F $18 $4F — TEXT_SYSTEM "Text id resolution (measured S108)"), raw bytes, decoded text (box breaks as blank lines, $E8 / $E9 / $F9 parameters skipped), `same_as` (382 shared strings), `suspect` (2); + `table_entries` for the text tables (battle messages $4C mode 0, bank $41 modes 2 / 9 / 11-14, skill descriptions $56:$6667, monster descriptions $4D mode 1). `--selftest` (no PyBoy): raw bytes + decodes == ROM, 2,560 ids, tables re-read | selftest PASS; added to verify_integrity check 5. Read by the editor's Dialogue tab |
| tools/dump_text_id_map.py (REWRITTEN) + extracted/text_id_map.json (REGENERATED) | now DERIVED from dialogue.json (same schema `{id: {id, bank, index, addr, text}}`; 2,558 ids, `index` = slot in the bank's mode-0 table or null). The pre-S108 generator modelled the cascade (fixed $400B base, guessed index rule, no overflow banks): 62 of its 2,061 entries matched the game (DOC_AUDIT S108) | regenerated after dump_dialogue |
| tools/refresh_script_text_comments.py (NEW) | rewrites the `; Text $XXXX: "…"` previews in disassembly/bank_00c-00f.asm (6,520) and the id lists on bank $47's `TextStr_47_<addr>` labels (70) from dialogue.json — comments only | clean `1ca6579…` byte-perfect |
| tools/resection_monster_desc.py (NEW) | Iron-Rule-6 re-section, both trees: bank $4D $53D3-$7719 (mgbdis fake code) → 215 `MonsterDesc_NNN_<Name>` db rows (decoded comments) + `db $00` ($771A, fused with the last terminator before); dispatch entries 261-475 `dw $XXXX` → the labels (each checked against the ROM word); refuses when a label inside the old run is referenced (none) | clean `1ca6579…`; patched builds unchanged (user project `7f6df249…`, example pin `77ccdab8…`) |
| tools/extract_gamedata.py + extracted/gamedata_vanilla.json (regenerated, additive) | `monster_text`: the name-block order, nicknames (215), descriptions (215) and the three block bounds; `--selftest` proves each block contiguous, id-ordered, unshared | verify check 5 PASS |
| tools/gen_bank41_remaining_db.py | label names follow the S108 rename (`MonsterNickPtrTable`, `MonsterNick_NNN_XX`; historical generator, not re-run) | — |
| disassembly/ + patches/ bank_041 (`FamilyCodePtrTable` → `MonsterNickPtrTable`, `FamilyCode_NNN_XX` → `MonsterNick_NNN_XX`, `FamilyCodeStrings` → `MonsterNickStrings` + corrected comments), bank_000 (comment), bank_009 (`FuncFld9_621f` naming prefill, `LoadFld9_688e` random name) | labels / comments | clean `1ca6579…` |
| patches/bank_041.asm (regions `gd_monster_names`, `gd_monster_nicks`), patches/bank_04d.asm (regions `gd_monster_desc`, `gd_monster_desc_extra`) | markers around the blocks (filled with the emitter's vanilla output) | pin unchanged |
| editor2/core/monster_text.py (NEW) | `gamedata.monster_text`: encoders (`encode_name` / `encode_desc` / `desc_codes` / `decode`), `resolve` / `effective` / `name_overrides` / `layout` / `bank41_spills` / `usage` / `check`, labels, the four emitters | test_compiler `test_monster_text_s108` + `--rom` `test_monster_text_rom` |
| editor2/core/species.py (shared name encoder, `description`, `text_layout(lst, extra)` + `_ffd`, `_spills`, effective names in recipe lines, `desc_pointer` → label), core/gamedata.py (`SECTIONS` += `monster_text`, `text_names`, `library_text_edits` follows renames), core/emitters.py (4 regions), core/validators.py (`MT.check`) | the compiler half | test_compiler 575 `--rom` |
| editor2/core/dialogue_index.py (NEW), editor2/app/dialogue_tab.py (NEW), app/main.py (Dialogue tab + `_show_dialogue_for`), core/monsters.py (`monster_names_effective / monster_text / set_monster_text / reset_monster_text / text_capacity`, `description` prop, `MT.check` in `_commit_data`), app/monsters_tab.py ("Name and library text", `text_pixmap`, `showDialogue`) | the editor half | test_app (S108 block) |
| editor2/help/52_monsters.md, 56_dialogue.md (NEW), 90_limits.md; `EDITOR_REVISION` = 'S108' | help | test_app |
| editor2/tests/test_compiler.py (S108 tests, blank-project sites, the ns_detail_text label assertion), test_app.py (S108 block) | tests | PASS |

## S109 rows (P3.10b: the Arena editor)

| Tool / data | What | Verified |
|---|---|---|
| tools/resection_arena_menu.py (NEW) | Iron-Rule-6 re-section, both trees, of the bank $09 arena class menu (mgbdis code over tables): `ScreenEffectTable09`, `ArenaClassMenu` + `ArenaClassMenuOuterTable` + states `S0Window`..`S4Close`, `ArenaClassMenuRun` (was `Jump_009_5c0a`), `ArenaClassMenuStateTable` + `ArenaClassMenu_State0..8`, `ArenaClassLetterTable` $5D1B, `ArenaClassFeeTable` $5D23, `ArenaMenuCursorTable` $5DA2, `ArenaYesNoCursorTable` $5EA1; renames `SetFld9_5c28` → `ArenaMenuMarkWon`, `CallFld9_5c53` → `ArenaMenuDraw`, `SetFld9_5c97` → `ArenaMenuDrawLetters`, `SaveFld9_5cce` → `ArenaMenuPutLetter`, `SetFld9_5ce0` → `ArenaMenuDrawFees`, `SaveFld9_5cfb` → `ArenaMenuPutFee`. Probe-builds both trees; the patched tree's tail is anchored by length (KEY_LESSONS S109) | clean `1ca6579…`; patched pin unchanged by it |
| tools/extract_gamedata.py + extracted/gamedata_vanilla.json (regenerated, additive) | tables `arena_masters` ($04:$5E22, 30 × 2), `arena_masters_50` ($50:$6778, 27 × 2), `arena_fees` ($09:$5D23, 8 words); `--selftest` asserts the bank-$50 copy == the first 27 rows | selftest PASS (verify_integrity check 5) |
| disassembly/ + patches/ bank_004 / bank_050 (`ld hl, ArenaMasterSpriteTable` / `ArenaMasterSpriteTable50` — were raw `$5e22` / `$6778`; tail comments), bank_000 (`AddGold` subtracts — comment), bank_009 (re-section above, State5 comment) | labels / comments only in disassembly/ | clean `1ca6579…` |
| patches/bank_004.asm, bank_050.asm (6-byte tails → `ld hl,$6E00 / rst $10 / ret / nop`; regions `gd_arena_masters_04` / `_50`), bank_009.asm (region `gd_arena_fees`), patches/bank_06e.asm (NEW hand patch: `ArenaTeamFixup`, region `gd_arena_team_sizes`), patches/game.asm (INCLUDE), tools/verify_integrity.py (PATCH_NEW_FILES += bank_06e.asm) | the arena engine (SIDEQUEST_MAP "Arena authoring as built — S109") | pin `482c949f…` (patched); PyBoy on the user's save |
| editor2/core/arena.py (NEW) | `gamedata.arena`: `GROUPS`, `eid` / `index` / `matches`, `vanilla`, `person_ids`, `master_value` / `master_spec`, `resolve`, `teams`, `check`, the four emitters + `REGIONS` (PROJECT_COMPILER §2.25) | test_compiler (609 with --rom) |
| editor2/core/arena_doc.py (NEW), core/document.py (`ArenaMixin`), core/gamedata.py (`SECTIONS` += `arena`), core/emitters.py (`_arena_regions`), core/validators.py + core/monsters.py (`AR.check`) | the Arena tab's model; the arena check also guards Monsters-tab edits of a team row | test_app |
| editor2/app/arena_tab.py (NEW), app/main.py (Arena tab after Dialogue) | the Arena tab (EDITOR_DESIGN §5.2b) | test_app, test_app --rom (GUI build == pin) |
| editor2/help/53_arena.md (NEW), 00_start.md, 52_monsters.md, 90_limits.md; `EDITOR_REVISION` = 'S109' | help | test_app |
| editor2/tests/test_compiler.py (`test_arena_s109`, `test_arena_rom` incl. MiniSM83 opcodes $80 / $3D / $36, blank-project arena sites, pin `482c949f…`), test_app.py (S109 block) | tests | PASS |

## S110 rows (P3.11: the Skills tab)

| Tool / data | What | Verified |
|---|---|---|
| tools/resection_skill_desc.py (NEW) | Iron-Rule-6 re-section, both trees, of bank $56 $4E4C-$6866 (mgbdis code over data): `SkillDesc_NNN_<Name>` / `SkillDesc_Blank` / `SkillDesc_None` strings, `SkillDescModeTable` $664B, `SkillDebugTextPtrs` $664F (+ the 12 debug strings), `SkillDescPtrTable` $6667 (256 dw); the two `ld de, $664b` by label. Patched tree: region markers `gd_skill_desc` / `gd_skill_desc_ptrs` (rows 0-221; the [S73] rows $E0-$E9 kept) / `gd_skill_desc_extra` (the 2,993-nop pad → `ds 2993, $00`). Probe-builds; the patched region end is found by the clean tail | clean `1ca6579…` |
| tools/annotate_skill_record.py (NEW) | the S110 record READER CENSUS as comments: 60 `; [S110 rec]` sites in banks $50-$54/$57/$58 (clean line numbers; patched sites by a 4+4 code-line signature), the "S110 FIELD MAP" header above `SkillRecordData` (patched tree: above the region marker), bank $54 dispatch rows for entries 3/4/5 relabelled. `--apply` writes; an annotated clean file is left alone | clean `1ca6579…`; patched pin unchanged by it |
| tools/census_skill_present.py (NEW) → extracted/skill_present_census.json (NEW) | PyBoy census: every vanilla skill (0-221) lends its look (`StockPresentTable` / `StockSfxTable` poked in ROM) to 7 borrowers on a real save (`--rom --sym --sav`, `--donors`, `--redo`; resumable, written per donor); per run `result` (ok / stall ≥ 600 frozen frames / nocast < 2 acts), the longest frozen gap and the act count. Forcing per KEY_LESSONS S110. The shipped file: 1,554 runs, all ok, max gap 157 (two halves merged). Read by `editor2/core/skills.py` (`lend_problem`) | measured S110 on the user's save |
| tools/extract_gamedata.py + extracted/gamedata_vanilla.json (regenerated, additive) | `skill_text` (222 names, 222 descriptions, `desc_shared`: ids 151-212 → Blank, 219-221 → None) + table `skill_announce` ($58:$5806, 222 × 1, `AnnounceTemplateTable`); selftest round-trips both | selftest PASS (verify_integrity check 5) |
| disassembly/ bank_050-054, 056-058 (comments + bank $56 re-section + bank $54 dispatch labels) | labels / comments only | clean `1ca6579…` |
| patches/bank_05f.asm (`GetPresentId` → `StockPresentTable` for ids < $DE, region `gd_present_proxy_5f`), patches/bank_055.asm (NEW hand patch: `$4061` → `call SfxPresentId`, `SfxPresentId` + region `gd_present_proxy_55`), patches/bank_041.asm (region `gd_skill_names`; the S44 `SkillName_215_BugCut` hand edit back to vanilla), patches/bank_056.asm (the three description regions), tools/verify_integrity.py (PATCH_FILES += bank_055.asm) | the looks-like engine + the text regions (PROJECT_COMPILER §2.26, BATTLE_SKILL_SYSTEM §11.8) | pin `534bfb62…` (patched); PyBoy on the user's save |
| editor2/core/skills.py (NEW) | ids / blocks, `FLAG_BITS` + `DEAD` (the census in data form, with hints), `vanilla`, `resolve`, `effective`, `names`, `layout` (first-fit + spills), `lend_problem` / `lend_warning`, `check`, the six emitters + `REGIONS` | test_compiler (650 with --rom) |
| editor2/core/gamedata.py (`mp` writes record +4 too; `"ALL"`; `target_mode` set; the `mp_byte` warning retired), core/emitters.py (`_skill_regions`), core/validators.py + core/monsters.py (`SK.check`), core/species.py (skill-name spills join the bank-$41 extents) | compiler | test_compiler |
| editor2/core/skills_doc.py (NEW, `SkillsMixin`), core/document.py | the Skills tab's model (reads, sparse setters) | test_app |
| editor2/app/skills_tab.py (NEW), app/main.py (Skills tab replaces the stub), app/monsters_tab.py, arena_tab.py, enemies_dialog.py (skill names via `doc.skill_names_effective()`) | the Skills tab (EDITOR_DESIGN §5.3 "As built S110") | test_app, test_app --rom (GUI build == pin) |
| editor2/help/54_skills.md (NEW), 00_start.md; `EDITOR_REVISION` = 'S110' | help (every behaviour box named — test_app checks) | test_app |
| editor2/example-project/project.json (`gamedata.skills.215.name` = "BugCut") | the S44 rename as data | pin `534bfb62…` |
| editor2/tests/test_compiler.py (`test_skills_s110`, `test_skills_rom` incl. MiniSM83 push/pop hl, blank-project skill sites, pin `534bfb62…`), test_app.py (S110 block) | tests | PASS |

## S111 rows (P3.11c / P3.11d: the custom skills as project data, new custom skills, elements)

| Tool / data | What | Verified |
|---|---|---|
| tools/extract_custom_skills.py (NEW) → editor2/core/custom_skills.json (NEW) | reads the custom skills' DATA ($DE-$E9: name, SKIL text, MP, record, learn row, announce template, own battle line, look) + the banners, Tame meters and Quake powers out of a built ROM + game.sym; `--write` was run ONCE on the S110 pin `534bfb62…` (patched, historical) — the compiler's built-in baseline; `--check` compares a build with the JSON (both the S110 layout and the S111 engine's tables; the retired $DE/$DF names, dropped S111, are taken from the JSON) | `--check` OK on the S111 example build; test_compiler --rom runs `extract()` on it |
| tools/census_skill_element.py (NEW) → extracted/skill_element_census.json (NEW) | PyBoy: per stock skill (0-221) on a real save, the S110 rig with every packed resistance byte = `$1B` and the RNG pinned; hooks on the 7 byte selectors + 3 damage ladders → which ladder and which resistance (`element`) its damage tests. 38 elemental. Read by `custom_skills.native_element` (the editor's Element box, the compiler's refusal) | the S111 example build `4a2860cf…` (patched) and the S110 pin `534bfb62…` (patched, historical) give identical results (unpinned, CallHelp's helper drifted — the pin fixes it) |
| tools/census_skill_clone.py (NEW) → extracted/skill_clone_census.json (NEW) | PyBoy: per stock skill B, B cast vs a copy at id $EA (ROM bytes poked as a project with `{"base": B}` compiles), RNG pinned; battle lines + HP / MP changes compared → same 114 / differs 41 / not a skill 67. Read by `custom_skills.clone_problem` / `clone_bases` | measured S111 on the example build `4a2860cf…` (patched) + the user's save |
| tools/validate_custom_data.py | reads the custom learn rows from the S111 table (bank $72 `CustomLearnTable`, located by the entry-6 code pattern, or the `gd_custom_learn` source); the code-2 fence pattern is now `cp $da`; levels 1-99 or $FF | verify_integrity check 6 OK |
| disassembly/bank_050.asm (`SkillNameSubst_5ae1` decoded as 4 `db`, `SaveBtl_5ad2` comment), disassembly/bank_052.asm (the dead $51B3 pocket note) | labels / comments only | clean `1ca6579…` |
| patches/bank_072.asm (`FarSkillFork` → `CustomBaseTable`; `CustomBattleExec` returns the element; entries 5 `ElemLevel72`, 6 `CustomLearnRow72`; regions `gd_tame_meter`, `gd_quake_power`, `gd_custom_base`, `gd_skill_elements`, `gd_custom_learn`), bank_052.asm (`ElemLadderA/Breath/Slash` + `ElemLevel52` + `CustomElemTail52` in the dead pocket; 24 ladder calls redirected), bank_006.asm (`LearnLoopFork` via `wLearnRowBuf`; old learn tables removed), wram.asm (`wLearnRowBuf` $D10C, 18 B from wCustomPool), bank_007.asm (`CustomMPCostTable` at $7F59, ids $DE-$FE, region `gd_custom_skill_mp`), bank_054.asm (`gd_custom_records`), bank_058.asm (`gd_custom_announce_lo`, `gd_custom_announce`, `DispatchBoundsStub` → `CustomTargetBaseTable` `gd_custom_target`), bank_04c.asm (`gd_custom_msg_a`, `gd_custom_msg_ptrs`, `gd_custom_msgs`), bank_05f.asm (`gd_custom_present`), bank_055.asm (`SfxPresentId` → `CustomSfxTable` `gd_custom_sfx`), bank_041.asm (`gd_custom_skill_name_ptrs`, `gd_custom_skill_names`; `MiscText_03_Paged` moved to $7F80), bank_056.asm (`gd_custom_skill_desc_ptrs`, `gd_custom_skill_desc`), bank_050.asm (`SaveBtl_5ad2` same-size name fix) | the S111 engine + the 19 regions (PROJECT_COMPILER §2.27, BATTLE_SKILL_SYSTEM §13.9 / §15.3) | pin `4a2860cf…` (patched); PyBoy A/B of the 10 built-ins vs S110 |
| editor2/core/custom_skills.py (NEW) | ids, `resolve` (keys, refusals), `encode_line` / `decode_line` (battle lines, `{name}`), `element_value`, `native_element`, `clone_problem` / `clone_bases`, `names`, `dialog_overrides`, `layout` / `usage` / `check`, the 19 emitters + `REGIONS` | test_compiler |
| editor2/core/skills.py, gamedata.py (`element`, `sounds_like` for stock skills; ids ≥ 222 → custom_skills), species.py (bank $41 spills), emitters.py (`_custom_skill_regions`), validators.py + monsters.py (`CS.check`), project.py (Anchor's dialogs from `dialogs`) | wiring | test_compiler |
| editor2/core/skills_doc.py, app/skills_tab.py, app/monsters_tab.py (pickers rebuild) | the Skills tab for custom / new skills (EDITOR_DESIGN §5.3 "As built S111") | test_app, test_app --rom (GUI build == pin) |
| editor2/help/54_skills.md, help/_revision.md; `EDITOR_REVISION` = 'S111' | help | test_app |
| editor2/tests/test_compiler.py (`test_custom_skills_s111`, `test_custom_skills_rom` on 3 builds; MiniSM83 + register C, calls, push bc/de, srl, 16-bit adds; the S110 retired-id / SfxPresentId expectations updated; pin `4a2860cf…`), test_app.py (S111 block; list count 232) | tests | test_compiler --rom 710/710, test_app + --rom PASS |
| S111b: patches/bank_072.asm (`CustomRatioTable` region `gd_custom_ratios`, `RatioBC72`, `ScaleHL72`, `Div16by8_72`, `Mul16by8_72`, entry 7 `AnchorKeepMP72`; the four handlers read the ratios), patches/bank_073.asm (Anchor arrival: `rst $10` entry 7 instead of `>> 2`), patches/bank_058.asm (`gd_custom_target` MagicBurn / Tame rows + comment), editor2/core/custom_skills.py (`RATIO_KEYS`, `ratio_value`, `emit_ratios`; 20 regions), skills_doc.py / app/skills_tab.py (ratio fields), help 54_skills.md | the built-ins' ratios as data + the AI target-row fix (PROJECT_COMPILER §2.27, BATTLE_SKILL_SYSTEM §13.9) | PyBoy A/B on the user's save (defaults identical, edits as set); test_compiler --rom 727/727 (pin `5a1c5404…`, patched); test_app + --rom PASS |


## S112 rows (P3.11e: skill animation editing)

| Tool / data | What | Verified |
|---|---|---|
| tools/decode_battle_animations.py (rewritten, schema 2) → extracted/battle_animations.json | the 45 stock animations (frame bank / table / pointers / sprites, timeline steps, gfx id, stream, sheet tiles, palette, shade, debugger gfx id) + the 230 skill rows (cmd_foe / cmd_own / party / enemy / link) + the 16 routines; `--selftest` ROM anchors (verify_integrity) | selftest OK; census below |
| tools/census_battle_anims.py (NEW) → extracted/battle_anim_census.json (NEW) | PyBoy: game mode 5 (the developers' viewer) plays each number; per frame the OAM, the sounds, the tiles in VRAM and the OBJ palettes on screen vs the model (start lag 4 / 5 frames); `--project` adds the project's new animations ($2D+, `--only 45-..`), `--negative` a shuffled model | 45/45 ok, negative 45/45 fail; the S112 demo $2D / $2E ok |
| tools/resection_battle_anims.py (NEW) | re-sections the animation system (bank $02 timelines + sequencer, $50 gfx table + loader, $5F tables / routines / debugger, $5C/$5D/$5E frame tables + code, $00 shade table + tick, $17 palettes, $5A/$5B gfx streams) into labelled data in BOTH trees; byte-perfect probe per splice | clean `1ca6579…`; patched pins unchanged by it |
| tools/render_anim_sounds.py (NEW) → extracted/anim_sounds/sfx_XX.wav + index.json (NEW) | the 35 sound effects the timelines cue, recorded from the ORIGINAL ROM's sound engine in PyBoy (wSoundEffect per id), 16 kHz mono 16-bit — the editor preview's sounds | played in the editor (QSoundEffect) |
| disassembly/bank_000/002/017/050/05a/05b/05c/05d/05e/05f.asm (+ the same in patches/) | the re-section; `EffectDebugShadeTable`; the ROM0 tick header; bank $50 `$DA80` comment | clean `1ca6579…` |
| patches/bank_000.asm, bank_002.asm (NEW hand patch), bank_050.asm, bank_05f.asm, game.asm | the forks to banks $6F / $70 + regions `gd_anim_routine` / `gd_anim_cmd` (BATTLE_SKILL_SYSTEM §11.9.1) | pin `9ce03bd0…` (patched) |
| editor2/core/battle_anims.py (NEW), anims_doc.py (NEW), templates/bank_06f_head.asm (NEW, pinned) + PINNED_SHA256, emitters.py, validators.py, gamedata.py / custom_skills.py (`presentation` key), monsters.py (commit check), document.py | decoder, model, compiler, emitters, preview helpers; the Animations tab's model (PROJECT_COMPILER §2.28) | test_compiler (754) |
| patches/bank_06f.asm, patches/bank_070.asm (NEW, generated) | the example project's banks $6F / $70 | pin |
| editor2/app/anims_tab.py (NEW), skills_tab.py (Animation section), main.py (Animations tab) | the editor (EDITOR_DESIGN §5.3 "As built S112") | test_app, test_app --rom |
| editor2/help/57_animations.md (NEW), 54_skills.md, 00_start.md, _revision.md; `EDITOR_REVISION` = 'S112' | help | test_app |
| editor2/tests/test_compiler.py (`test_anims_s112`, `test_anims_rom`, pin `9ce03bd0…`), test_app.py (S112 block) | tests | PASS |
| tools/verify_integrity.py | + bank_002.asm (patch files), bank_06f / bank_070 (new patch files), decode_battle_animations selftest | PASS |

## S113 rows (P3.12: the Breeding tab)

| Tool / data | What | Verified |
|---|---|---|
| tools/census_breeding.py (NEW) → extracted/breeding_census.json (NEW) | PyBoy: stub-calls bank $16 entry 2 `BreedResolveOffspring` for every ordered pair of breedable parents (0-214 + new species) at plus 0, a plus-gated sweep and a seeded random sample, and creates eggs through entry 0 `BreedCreateOffspring` with the real staging records; compares species / plus with `editor2/core/breeding.py`; hooks the unreferenced mutation; `--negative` (no family second pass), `--expect-egg-bug` (a pre-S113 build), `--label` | S113 test ROM: 53,156 calls + 300 eggs, 0 mismatches; negative 31,433; pre-fix build 300/300 eggs wrong |
| disassembly/bank_016.asm + patches/bank_016.asm | the resolver annotated (labels / comments; BREEDING_SYSTEM "The resolver as measured (S113)"); patched: `BreedCreateOffspring` $DA75/$DA76 = $28/$29 (the FX1 egg-plus fix) | clean `1ca6579…`; pin `8cf0b93b…` (patched) |
| patches/bank_069.asm | scanner comment names; region `gd_special_recipes` regenerated (the example's rows auto-ordered) | pin |
| tools/build_breeding.py, tools/patch_breeding_recipe.py | comment label names only | selftest PASS |
| editor2/core/breeding.py (NEW) | `Breeding` (resolver model), `FastResolver`, `obtainable`, `Analysis` (depth, makes / breeds into, never fires, library check) | census; test_compiler `test_breeding_analysis` |
| editor2/core/breed_gen.py (NEW) | depth-profile tree generator on a project (`propose`, `to_gamedata`, `apply_to`) | test_compiler (seeded, compiles, pins) |
| editor2/core/breeding_doc.py (NEW), document.py | `BreedingMixin` (the tab's model + setters) | test_app |
| editor2/core/gamedata.py | special table: `removes`, `table`, auto-order (`special_key`, `special_src`, `special_removed`), same-parents refusal, family-warning summary; emitter tags | test_compiler `test_special_auto_order` |
| editor2/app/breeding_tab.py (NEW), main.py (Breeding tab) | the editor (EDITOR_DESIGN §5.4 "As built S113") | test_app |
| editor2/help/58_breeding.md (NEW), 00_start.md, 55_game_data.md, _revision.md; `EDITOR_REVISION` = 'S113' | help | test_app |
| editor2/tests/test_compiler.py (pin `8cf0b93b…` patched, S113 tests), test_app.py (S113 block) | tests | 773/773 --rom; test_app + --rom PASS |

## S114 rows (P3.13a: the Encounters tab — project lists, gate plans, room lists, flag variants)

| Tool / data | What | Verified |
|---|---|---|
| tools/census_encounters.py (NEW) → extracted/encounter_census.json (NEW) | PyBoy: stub-calls bank $01 entry $0D (the list choice) for every gate floor × the variants' flag states and every custom room with encounters, and entry $0B (the battle draw) 24 times per case with wRNG1/2 pinned; compares wEncounterPoolIndex / wC8A9 / the 26 list bytes (wEncListBuf; the ROM list on the ORIGINAL) and $DA02-$DA08 with `editor2/core/encounters.py`; `--original` (the ORIGINAL ROM vs the vanilla model), `--negative` (draw rule `>`), `--label` | ORIGINAL 633 + 15,192, example 633 + 15,192 (the committed file), fixture 641 + 15,384, user's project, demo: 0 mismatches; negative 1,417 |
| tools/dump_encounters.py (REWRITTEN) → extracted/encounters.json (REGENERATED) | see the Tier A row above | `--selftest` PASS (verify check 5 += dump_encounters.py) |
| tools/extract_gamedata.py → extracted/gamedata_vanilla.json (REGENERATED) | + 6 tables: `gate_base_pool` / `gate_bp_ptrs` / `floor_breakpoints` (bank $01 rule, copied into bank $76 by the compiler), `encounter_rate_mod` / `encounter_rate_data` / `encounter_counter_seeds` (bank $16, the editor's steps estimate) | `--selftest` PASS (28 tables) |
| simulator/sweep_ttk.py | skips the new `_generator` key of encounters.json | — |
| patches/bank_001.asm, patches/wram.asm, patches/game.asm, tools/verify_integrity.py | the same-size LoadNextDungeonFloor fork + the five reader forks; `wEncListBuf` ($D11E, 26 B from wCustomPool); `bank_076.asm` included; PATCH_NEW_FILES / SELFTEST_TOOLS | verifier PASS; pin `dbc4dee9…` (patched) |
| editor2/core/templates/bank_076_head.asm (NEW, pinned `2f0634f5…`) + emitter `enc76` → patches/bank_076.asm | EncResolve + the project's lists / room variant lists / gate plans + the vanilla rule's byte copies (PROJECT_COMPILER §2.30) | test_compiler `test_encounters_s114` / `test_encounters_rom` |
| editor2/core/encounters.py (NEW) | the model (`Model`, `resolve`, `check`, `vanilla_number`, `simulate_battle`, `real_chances`, `group_odds`, `steps_between`) + `emit_bank_076` | census; test_compiler |
| editor2/core/encounters_doc.py (NEW), document.py | `EncountersMixin` (usage, lists, list detail, threat rows for P3.15, setters for lists / rooms / gate plans / variants) | test_compiler (doc API), test_app |
| editor2/core/gamedata.py | `LIST_KEYS`, `apply_list_fields`, `check_list` (shared by gamedata.encounters and the project's lists), `Gamedata.list_eid` | test_compiler (S103 cases unchanged) |
| editor2/core/monsters.py, gates.py, validators.py, emitters.py | live list usage for "where met" / the pool dialog; GATE_KEYS += encounters, room mode 'own'; validation + accounting for bank $76 (TEMPLATE_SIZE 241); RoomEncTable `[1, $FF, 0]` for own-list rooms; `enc76` registered | test_compiler |
| editor2/app/encounters_tab.py (NEW), main.py, rooms/gate_panel.py, rooms/inspector.py | the Encounters tab (EDITOR_DESIGN §5.5 "As built S114"); Rooms tab shows "its own list" | test_app |
| editor2/help/59_encounters.md (NEW), 00_start.md, 52_monsters.md, 55_game_data.md, 90_limits.md, _revision.md; `EDITOR_REVISION` = 'S114' | help | test_app |
| editor2/tests/test_compiler.py (pin `dbc4dee9…` patched, S114 tests), test_app.py (S114 block) | tests | 818/818 --rom; test_app + --rom PASS |
| tools/audit_mapid_range.py → extracted/mapid_range_audit.json (REGENERATED) | the 9 wMapID sites added S100-S114 (left NEEDS_REVIEW, selftest FAIL since S100) adjudicated — CROSSBANK_ROOMS "mapID ≥$80 readiness audit" S114 note | `--selftest` PASS (clean 58, patched 75) |
| patches/bank_041.asm (regions regenerated from the example project) | the committed name / text regions had drifted from the compiler's output for the example (name pointer bytes at $41:$46E9-$4735 — pre-S114): with them regenerated the verifier's hand-staged patched build == the pin again (`dbc4dee9…`, the S63 "compat == hand tree" property) | verifier PASS, `/tmp/verify_patched.gbc` == pin |

## S115 rows (ROADMAP NG1: new gates 32-95)

| Tool / data | What | Verified |
|---|---|---|
| tools/census_encounters.py → extracted/encounter_census.json (REGENERATED) | + the project's NEW gates (every floor of each `custom.gates[]` entry 32-95; their value = `Model.vanilla`, the source gate's walk); `_generator` names S115 | example 633 + 15,192 (the committed file, pin `c8995d91…`), demo with new gate 32: 636 + 15,264, 0 mismatches; negative control mismatches |
| patches/bank_016.asm, patches/wram.asm | entry 5's two row readers → same-size `call GateRowPtr` (+ nops / `inc hl` ×4); `GateRowPtr` in the free tail ($7CFD); `wGateRowBuf` ($D138, 8 B from wCustomPool) | verifier PASS; test_compiler `test_new_gates_rom`; stub sweep gates 0-255 (scratch) |
| editor2/core/templates/bank_076_head.asm (re-pinned `94cb8ece…`) + `enc76` → patches/bank_076.asm | entry 1 `NewGateRowCopy`; `EncVanillaNumber` walks a new gate's source; data `NEW_GATE_LEN` / `NewGateRows` / `NewGateSource` (PROJECT_COMPILER §2.31) | test_compiler `test_new_gates_s115` / `_rom` |
| editor2/core/gates.py, project.py, validators.py, encounters.py, encounters_doc.py, emitters.py, world.py | new-gate helpers + `GatesMixin` (`new_gate`, `delete_gate`, `add_gate_entrance`, `gate_entrances`, `all_gates`, `gate_name`); `gate_configs` rows for 32-95; insert rules on new gates; entrance / no-entrance / vanilla-boss validators; `Model.vanilla`; `gates16` keeps 32 rows; the World graph skips gate entrances; TEMPLATE_SIZE $76 = 296 | test_compiler |
| editor2/app/gates_tab.py, rooms/tab.py, rooms/inspector.py, rooms/object_panels.py, rooms/canvas.py, rooms/gate_panel.py, encounters_tab.py | Gates tab New gate… / Rename… / Delete + the entrance line; Rooms tab More ▾ "Gate entrance here…" (+ the hole picture), the Gate entrance panel and canvas label; new gates on the Encounters tab and in the Inside-gates names | test_app (S115 block) |
| editor2/help/60_gates.md ("New gates"), 59_encounters.md, 00_start.md, 90_limits.md, _revision.md; `EDITOR_REVISION` = 'S115' | help | test_app |
| editor2/tests/test_compiler.py (pin `c8995d91…` patched; S115 tests), test_app.py (S115 block) | tests | 844/844 --rom; test_app + --rom PASS; test_canvas --rom PASS |

## S116 rows (ROADMAP P3.13b: the Music tab)

| Tool / data | What | Verified |
|---|---|---|
| dwm/sm83.py (NEW) | a complete SM83 interpreter (256 + 256 CB opcodes, flags per the opcode tables; `CPU(read, write).call(addr)`); runs the game's sound engine in the editor | tools/test_sm83.py: 498,000 SingleStepTests cases, 0 failed |
| tools/test_sm83.py (NEW) | checks dwm/sm83.py against the SingleStepTests/sm83 `v1/` JSON suite (clone it first; HALT / STOP / illegal opcodes / EI's delay skipped) | 0 failed |
| editor2/core/sound_engine.py (NEW) | `Machine`: the ROM0 sequencer on sm83 over a minimal memory map (ROM + MBC5 bank, WRAM, HRAM, sound registers with read-back masks + NR52 on-bits); `start_bgm` / `start_se` / `start_channels` / `frame()` -> register writes; `for_songs` builds a preview image (song banks + the $3FE8 table) | census below |
| editor2/core/apu_synth.py (NEW) | the APU (squares + sweep, wave, noise LFSR, frame sequencer, NR50/51, DACs, capacitor) at 32,768 Hz, box-filtered; `render`, `wav_bytes` (numpy) | pitch tracking vs PyBoy ($06/$09/$27): same notes at the same times |
| editor2/core/music_preview.py (NEW) | `Renderer` (stream any vanilla id / song channels), `song_info`, `catalog` | test_app (the Music tab renders BGM #04) |
| tools/census_sound_engine.py (NEW) | PyBoy vs the Machine at every frame-driver entry (audio RAM, HRAM, NR12/22/32/42/43/50/51 read-back, NR52 bit 2, wave RAM when the wave channel is off); vanilla mode = every sound id × wBGM + wSoundEffect; `--custom` = a patched build's project songs vs the editor PREVIEW path; `--negative`; `--json` | vanilla 170 runs × 3,000 frames identical; example + 3 DWM2 fixtures (all 31 songs, both banks, 2-5 channels) + a MIDI import (noise): 0 mismatches; negative 8/8 |
| tools/census_music_resolve.py (NEW) | stub calls of bank $71 entries 2 (`CustomRoomBGMResolve`) and 7 (`BattleBGMResolve`) of a built ROM over random game states vs `music.model_room_bgm` / `model_battle_bgm`; `--negative` | demo 3,000/3,000; rich fixture 4,000/4,000; negative 86/600 |
| tools/dump_sound_catalog.py (NEW) → extracted/sound_catalog.json (NEW) | the vanilla sound catalog (Tier A row above) | `--selftest` (verify check 5) |
| tools/song_codec.py | `emit_song_bank` / `song_bank_asm` take `bank` + `base_id` (bank $75 records from the split id) | test_compiler (S116 two-bank case); byte-identical for bank $74 |
| tools/midi_to_song.py | `convert_entry` (no library write; raises `MidiError`), `options`, `write_library`; > 3 melodic channels -> the 3 that play longest (warned) instead of an error | test_compiler (doc import: 4 melodic + drums -> 3 + noise); `--custom` census of a 6-channel MIDI |
| patches/bank_000.asm | InitBGM SAME-SIZE rewrite (custom path -> bank $71 entry 6); region `rom0_audio_master`; vanilla `$3466` table re-sectioned (`AudioMasterTable`, both trees); driver / queue comments | verifier PASS; clean `1ca6579…` |
| patches/bank_051.asm | LoadBattle's music pick SAME-SIZE (28 B) -> bank $71 entry 7 | test_compiler `test_music_rom`; PyBoy battles |
| patches/game.asm, tools/verify_integrity.py | `bank_075.asm` included; PATCH_NEW_FILES += bank_075.asm; SELFTEST += dump_sound_catalog.py | verifier PASS |
| editor2/core/templates/bank_071_head.asm (re-pinned) + `dispatch71` | entries 6 `CustomBGMStart` / 7 `BattleBGMResolve`, entry 2 gate songs; TEMPLATE_SIZE 688 | test_compiler |
| editor2/core/music.py (rewritten), emitters.py (`music75`, `audio_master`, the bank $71 music tables), project.py (`music_plan`), validators.py | the S116 plan (two banks, channel counts, gate / battle tables, $FF marks, models) | test_compiler `test_music_s116` / `test_music_rom` |
| editor2/core/music_doc.py (NEW), document.py | `MusicMixin` (catalogs, names, add / import MIDI / remove songs, room / gate / battle / fight setters, capacity) | test_compiler (doc API), test_app |
| editor2/app/music_tab.py (NEW), main.py | the Music tab (EDITOR_DESIGN §5.6 "As built S116"), `SongPlayer` (QAudioSink push mode; **S116b rewrite**: device rate + own resampler, continuous top-up, reset() on one reused sink, polled restart, `[music]` stderr lines) | test_app (S116b: fake-sink player check) |
| editor2/help/61_music.md (NEW), 00_start.md, 60_gates.md, _revision.md; `EDITOR_REVISION` = 'S116' (S116b after the player fix; 61_music.md += the `[music]` terminal line); README / main.py run line + numpy | help | test_app |
| editor2/tests/test_compiler.py (pin `7bab4921…` patched; S116 tests), test_app.py (S116 block) | tests | 874/874 --rom; test_app + --rom PASS; test_canvas --rom PASS |


## S117 rows (extended flags; ROADMAP NG2 gate swirls / cleared; ROADMAP P3.13c shops)

| Tool / data | What | Verified |
|---|---|---|
| tools/map_gate_names.py → extracted/gate_names.json (REGENERATED) | + per gate `cleared_flag` / `cleared_flags`: the flag(s) its boss room's win scripts set before the castle return (`set_flag F` … `write_ram $D92B 7`; Medal also scans room $41; Demolition $27 + $28; gate 31 none) — read by editor2/core/gates.py | `--check` (verify check 5); the flags == the 31 bosses' scripts |
| tools/extract_gamedata.py → extracted/gamedata_vanilla.json (REGENERATED) | + tables `item_info` ($03:$71DA, 44 × 12) and `shop_bazaar` / `_starry` / `_books` / `_rare` / `_gate` ($09:$476B / $4774 / $477D / $4784 / $478C); selftest: each shop list is one `$FF`-terminated id list | `--selftest` (verify check 5) |
| tools/resection_shops.py (NEW) | one-shot annotation: bank $03 `SpriteFrameDataTable` → `ItemInfoTable` 44 `db` rows (both trees; the patched copy inside region `gd_item_info`) + the bank $09 renames (`renames()`: ScreenEffectSay, ShopCountItems, ShopDrawNames, ShopDrawPrices, ShopSellPrice); builds | clean `1ca6579…` byte-perfect after the run |
| tools/resection_shops_09.py (NEW) | one-shot annotation: the bank $09 shop tables (ShopOuterStateTable, ShopMenuCursorTable, ShopMenuTable, ShopBuyStateTable, ShopBuyStockFill, ShopSellStateTable) by EXACT text-block replacement in both trees (KEY_LESSONS S117: the splice probe's `.local` trap); calls `resection_shops.renames()`; builds | clean byte-perfect; text diff = only the intended lines |
| patches/bank_000.asm | ROM0 `ComputeFlagAddress` SAME-SIZE (34 B) → bank $73 entry 21 | verifier PASS; test_compiler `test_flags_ng2_rom` (SM83 sweep 0-$1FFF, the 1,934 script flags == the original) |
| patches/bank_073.asm | entry 21 `FlagAddr`; `ExtFlagsCommit` / `ExtFlagsRestore` called from entries 5 / 6 (SRAM bank 3 "X1"); every later bank $73 byte +2 | PyBoy on the user's save (save → reload, unsaved rewind, new game) |
| patches/bank_00b.asm | `GetRoomDataPtr` after the gate test SAME-SIZE (21 B) → bank $60 entry 1 for every non-gate room | A/B old vs new over the user's project: 212 vanilla + 25 custom screens' NPC slots (only room $23 differs, by design) |
| patches/bank_050.asm | the boss-win `ld a,$0E / ld [$C8ED],a / ret` → `ld hl,$7602 / rst $10 / ret / nop` | test_compiler `test_s117_engine_rom`; PyBoy gate-32 boss win |
| patches/bank_009.asm, patches/game.asm, patches/wram.asm, tools/verify_integrity.py | the shop fill (64 B) and close tail (10 B) → bank $77 entries 0 / 1; `bank_077.asm` included (blank bank file dropped); `wExtFlags` $D140 (256 B) + `wShopID` $D240 from wCustomPool; PATCH_NEW_FILES += bank_077.asm | verifier PASS; test_compiler `test_shops_rom` (address map, ShopFill census == the original, wShopID lists, ShopClose) |
| editor2/core/templates/bank_060_head.asm (re-pinned `364ee530…`), bank_076_head.asm (re-pinned `40972da2…`), bank_077_head.asm (NEW, pinned `fb9aefd1…`) | `CustomReadInteract` for every non-gate room + `VanillaNPCExtTable` + `CopyNPCListToBuffer` ($A0/$A1); `GateBossWin`; `ShopFill` / `ShopClose`; TEMPLATE_SIZE 678 / 358 / 93 | test_compiler |
| editor2/core/project.py, validators.py, emitters.py, encounters.py, gates.py, document.py, gamedata.py, shops.py (NEW), shops_doc.py (NEW) | the flag pool + `gate:N`; `npc_conditions` / `vanilla_swirl_overrides` / `gate_clear_rows`; `_npc_cond_lines`, `VanillaNPCExtTable`, `GateClearTable`, `shops77` + `gd_item_info`; swirl / portal-redirect / `paint_swirl` helpers; `ShopsMixin` (PROJECT_COMPILER §2.32) | test_compiler `test_flags_ng2_s117`, `test_shops_s117` |
| editor2/app/shops_tab.py (NEW), main.py, rooms/tab.py, rooms/inspector.py, rooms/npc_panel.py, rooms/rules_panel.py, rooms/talk_editor.py, gates_tab.py, encounters_tab.py | the Shops tab; "Gate entrance here…" adds the swirl + paints it; "Lead this portal to another gate…"; NPC "Shopkeeper…"; `gate:N cleared` in flag pickers; the Gates tab's cleared line | test_app (S117 block) |
| editor2/help/62_shops.md (NEW), 60_gates.md, 30_flags.md, 20_npcs.md, _revision.md; `EDITOR_REVISION` = 'S117' | help | test_app |
| editor2/tests/test_compiler.py (pin `31cc5b31…` patched; S117 tests; the 26-targets list + bank $77; the gamedata unknown-section fixture now `potions`), test_app.py (S117 block) | tests | 936/936 --rom; test_app + --rom PASS (GUI build == pin); test_canvas --rom PASS |

## S117b rows (user feedback on the S117 test ROMs: shop menus in free-colour rooms, sprite limits)

| Tool / data | What | Verified |
|---|---|---|
| patches/bank_009.asm, patches/wram.asm | `LoadFld9_40fa` (the screen push, 53 B) → same-size `ld hl,$7702 / rst $10 / ret` + 48 nops; `wPushAttrOn` / `wPushAttrRow` ($D241-$D242) from wCustomPool | verifier PASS; test_compiler `test_screen_push_rom` (LoadFld9_412f keeps its address) |
| editor2/core/templates/bank_077_head.asm (re-pinned `b8af2c91…`) | entry 2 `ScreenPush` + `PushRowAttrs` / `PushAttrActive` / `PushNextCol`; `ShopClose` → `ShopBoxBottom`; TEMPLATE_SIZE 438 | `test_screen_push_rom`: 576 tile writes == the original in a vanilla / plain custom room / DMG, attrs in a free-colour room, a top box re-seated, a bottom box untouched; PyBoy (Bazaar, hall, Cities_FOUNT) |
| editor2/core/formats.py (`sprite_budget`), validators.py, app/rooms/tab.py | the sprite-limit warnings (build + the Rooms tab note) | test_compiler `test_sprite_budget_s117b`; test_app (S117 block) |
| editor2/help/20_npcs.md, 90_limits.md, _revision.md; `EDITOR_REVISION` = 'S117b' | help | test_app |
| editor2/tests/test_compiler.py (pin `110210b0…` patched; `31cc5b31…` historical), test_app.py | tests | 947/947 --rom; test_app + --rom PASS (GUI build == pin); test_canvas --rom PASS |

## S118 rows (ROADMAP P3.8 part A: the Cutscenes tab — read / show / play every scene)

| Tool / data | What | Verified |
|---|---|---|
| tools/census_cutscenes.py (NEW) → **extracted/cutscene_census.json** (NEW) | Plays EVERY vanilla script scene (the editor's catalogue, 519) in PyBoy through the Playback recipe — each map in a worker process (`--worker`, a silent worker killed after `--hang` s and the scene recorded `hung`), `--jobs 2` — and records per scene: how it started, reached / forced, ended, outcome (`battle` / `menu`), stalls (`stall_at`), the position model checked at every wait (checks / mismatches / examples). `--programs` re-measures the `$1C` movement programs; `--check` / `--selftest` = the JSON's totals == its rows and its scene list == the catalogue now (verify_integrity check 5; SKIP without the ROM) | S118 full run: 519 scenes, 514 reached (442 unforced), 417 ended, 86 battle, 0 hung, model 3,887 / 3,909 (BANK04_SCRIPT_ENGINE "Census S118") |
| tools/script_param_counts.py → extracted/script_param_counts.json (REGENERATED) | follows `rst $10` into the script banks' entries 1 / 2 (`cross_bank` reads): `$24` / `$61` = 1 param (were 0) | `--check` (verify check 5) |
| tools/verify_integrity.py | SELFTEST_TOOLS += census_cutscenes.py | PASS |
| disassembly/bank_004.asm + patches/bank_004.asm | handler labels `ScriptCmdNN_*`, `MoveProgNN_*` / `PlayerProgNN_*`, `MoveProgramsAll`, `PlayerMoveProgram`, `NpcMoveProgram`, `MoveProgCurveStep`, `FacePlayerDir1-3`, `WalkToXFrom` …; the opcode catalog comment block regenerated from script_ops; program / `$D8D7` comments | clean `1ca6579…` byte-perfect; patched pin unchanged |
| disassembly/ + patches/ bank_00c/00d/00e/00f.asm, bank_016.asm (comment), bank_056.asm (comment) | `ScriptBank0XDrawTiles` / `…DrawAttrs` (the `$24` / `$61` far-call targets); the `$F9` name-insert handler commented (`$C180 + nn`) | byte-perfect |
| editor2/core/script_ops.py (NEW) | the 102 opcodes: name, params, kind, branch / wait, doc, sentence; `SCREEN_KINDS`, `TERMINAL`, the measured `PROGRAMS` / `PLAYER_PROGRAMS` | test_app (S118); census |
| editor2/core/cutscenes.py (NEW) | vanilla scripts decoded from the ROM; project scripts via `Project` lowering (`ProjectCatalogue`, game.sym symbols); scenes (block heads that show something, path literals, `after_battle`); triggers; the actor model (`apply_step` / `actor_frames`); `Recipe` (+ `names` = insert slots) / `recipe_for` / `quiet_literals`; `Catalogue`; `CHAINS` (the intro) | census; test_app |
| editor2/core/playback.py (NEW) | `Engine`: PyBoy on a private ROM copy, cached base state per ROM / .sav / sound mode (`base_<md5>[_sav][_snd].state`), `start(recipe)` (flags / RAM / warp / settle / talk-examine-stepon from each side / arm / `head` start), auto text / YES-NO / naming / D-pad, `_name_slots`, `trace_ops` (census only), `where()` | census; test_app |
| editor2/core/playback_server.py (NEW) | the game in a child process: commands open / start / run / record / quit (JSON line in; length + JSON header + payload out); `PlaybackClient` (timeouts → `GameHung`, kill), `recipe_dict` | test_app (S118: a SIGSTOPped game is reported within 15 s, Restart works); scratch run: 800 frames + audio, record 34 PNGs |
| editor2/app/cutscenes_tab.py (NEW), main.py | the Cutscenes tab + `Recorder` (QThread → server `record`) + `PlaybackWindow` (server `run` per timer tick / per audio block) | test_app (S118 block) |
| editor2/help/63_cutscenes.md (NEW), 00_start.md, 90_limits.md, _revision.md; `EDITOR_REVISION` = 'S118' | help | test_app |
| editor2/tests/test_app.py | S118 block: the tree, the intro storyboard (121 steps), search, model picture, help words, Playback at 8× ≥ 1,500 frames on map $2F with the storyboard following, a hung game killed + Restart | PASS |
| tools/audit_mapid_range.py → extracted/mapid_range_audit.json (REGENERATED) | the three bank $04 verdict keys follow the S118 renames (`ScriptCmd17_BedroomTileSwap`, `ScriptCmd42_SaveReturnPoint`, `ScriptCmd4E_SavePosition`); JSON = the current trees (line numbers, labels) | `--selftest` still FAILS on 11 S117 shop sites (pre-existing; ROADMAP "audit_mapid_range re-adjudication", DOC_AUDIT S118) — the bank $04 sites are adjudicated |
| tools/map_monster_walkers.py → extracted/monster_walkers.json (REGENERATED, with a clean build's game.sym) | the bank $04 keys / roles follow the S118 renames; the script give paths' opcode numbers corrected (`$18` give_monster, `$29` add_monster) | diff vs the old JSON = line numbers + those names / numbers only |
| editor2/core/project.py, documentation (MONSTER_DATA, BREEDING_SYSTEM, PROJECT_COMPILER, ROOM_DATA_FORMAT, DATA_STRUCTURES, QUEST_OPCODES, known_RAM_map, ROADMAP) | the old `label4_XXXX` handler names → the S118 names (comments / references only) | grep: no stale bank $04 handler name outside SESSION_HISTORY / DOC_AUDIT |

## S118b rows (the user's first look at the Cutscenes tab)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/cutscenes.py | `Catalogue.state_hint` (room state from the story's own counter writes), `npc_actors_needed` + the NPC-count / sibling-test rules in `recipe_for` (+ `ProjectCatalogue.recipe`), `moves` (the "actors move" filter), `still_notes`, titles skip housekeeping, `apply_step` follows `$D8E3/$D8E4` (fly) and RAM writes into the NPC slots (`NPC_SLOTS`) | census; test_app (GreatTree cliff scene = state 2, egg talk not "moving") |
| editor2/core/script_ops.py | `FLY` — the fly programs $15-$18 per `$D8E3` 1-9 × `$D8E4` 0-5 (216 rows, measured) | `census_cutscenes.py --fly` reproduces it |
| tools/census_cutscenes.py → extracted/cutscene_census.json (REGENERATED) | `missing_npcs` (a step acting on an empty slot — type byte `$FF`), `ram_actors` counts big-sprite parts, `--fly` | 519 scenes, 516 reached, 0 hung, 1 missing, 3,989 / 3,998 exact |
| editor2/app/cutscenes_tab.py | ▶ Play scene / ▶ From this step (fast silent run to the selected step), the filter = `cutscenes.moves` | test_app (S118 block: from step 40 of the intro) |
| editor2/help/63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S118b' | what a scene is, the two Play buttons, room state, cloned rooms | test_app |
| editor2/tests/test_app.py | + From this step, the egg talk filter, the cliff scene's state | PASS |

## S118c rows (copies follow the game's room state; step-by-step playback)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/project.py (`step_counter_allocation` / `step_counter_game`), emitters.py (`emit_region_wram_steps`: `<label> EQU $addr`), builder.py (manifest), validators.py | `screens[k].step_counter.vanilla` — a copy's screen uses the original room's counter | test_compiler `test_clone_follows_game_s118c`; the example pin unchanged |
| editor2/core/document.py (`clone_vanilla` writes `vanilla`, `_migrate_clone_state`, `follow_game_counters` / `follows_game` / `set_follow_game`), app/rooms/rules_panel.py + tab.py | Make editable / migration on open / the Rooms toggle | test_compiler (migration); PyBoy on the user's project (copy `$6D` screen 0 follows `$D92D`) |
| editor2/core/cutscenes.py | `ProjectCatalogue`: the project's counter symbols (EQUs are not in game.sym), a following screen's state from `state_hint` | the user's copied GreatTree cliff scene plays the cliff man (PyBoy strip) |
| editor2/core/playback_server.py | `step` command (dispatch hook, save-state stack, back), `record` one picture per step (`by: 'pos'`), the hook list cleared on `run` | test_app (S118 block: Step ▸▸ ×2, Step back) |
| editor2/app/cutscenes_tab.py | Step ▸▸ / ◂ Step back, per-step pictures | test_app |
| editor2/help/10_rooms.md, 63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S118c' | help | test_app |

## S118d rows (user round: a scene reset the game; scene clicks failed on a partial install)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/cutscenes.py | `Catalogue.entry_caller` — an entry scene set up as the script that sends you there leaves the game (arrival, RAM writes, flags) | census (0 resets); PyBoy strips (`$07` @12 lands the party, no reset) |
| editor2/core/playback.py | `Engine.reset` — wGameMode 0 during a scene, logged | the old `$07` recipe → `reset` True at frame 215 |
| tools/census_cutscenes.py → extracted/cutscene_census.json (REGENERATED) | `reset` per scene + total | 519 scenes, 516 reached, 0 resets, 3,994 / 3,998 |
| editor2/tests/test_app.py | every 7th scene of the tree opens after a playback, no errors | PASS |
| editor2/help/63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S118d' | resets, scenes reached from another script | test_app |

## S118e rows (user round: the intro's positions; a global mute)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/playback.py | `newgame_state` (a new game at the moment the bedroom loads, made from power-on, cached per ROM / sound mode), `_power_on`, action `newgame` (started once the script runs), action `walkin` (`_walk_in`: stop the neighbour's entry scene, walk across the edge) | the bedtime scene == an uninterrupted new game (positions + script counter at frames 60 / 120 / 240); Warubou's scene: Terry enters through the west doorway (PyBoy strip) |
| editor2/core/cutscenes.py | `newgame_scene`, `Catalogue.gate_arrivals` (`GateFloorDataTable` $16:$70A6), `Catalogue.walk_in`, `Recipe.target` | census |
| tools/census_cutscenes.py → extracted/cutscene_census.json (REGENERATED) | `queued_moves(finish_step=)`: a walked-in player's step in progress | see BANK04 "Census" |
| editor2/app/main.py (View → Mute game playback, ⌘⇧M, QSettings `playback/mute`), app/cutscenes_tab.py (`game_muted`, `apply_mute`; trigger words for `newgame` / `head`) | the editor-wide mute, applied live | test_app (S118 block: mute on → the Sound box disabled, no audio player; off → enabled) |
| editor2/help/63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S118e' | where the player starts, the mute | test_app |

## S118f rows (every storyboard step in words)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/ram_names.py (NEW) | `RamNames`: room states from the room table, the curated script variables (BANK04 "Script variables (S118f)"), NPC slot fields, HRAM position | test_app (S118 block) |
| editor2/core/script_ops.py | sentences: RAM writes / tests / increments, flags, rooms, items, monsters, skills, music, screen types (+ 2/3/8/9/10/13), tile patches, NPC status / animation fields, the remaining ops in words | test_app: no step of any game script left as a bare address |
| editor2/core/cutscenes.py | `Catalogue.flag_desc` / `ProjectCatalogue.flag_desc` | test_app |
| editor2/app/cutscenes_tab.py | `TextCtx`: names, flags, rooms, items, enemies, skills, species, music, patches | test_app |
| disassembly/ + patches/ bank_009.asm | `ScreenEffectTable09` type comments (2 / 3 / 8 / 9 / 10 / 13) | clean byte-perfect |
| editor2/help/63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S118f' | help | test_app |

## S118g rows (names from the game only)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/cutscenes.py | `script_speaker` (an NPC's name = the speaker prefix of its own talk text), `Catalogue.room_origin` (the game's exits / scripted moves into a room); `initial_actors` takes the speaker | 1,010 vanilla NPC entries: 24 named by their text (Milayou, Pulio, King, Mick, Watabou, Warubou), 986 anonymous |
| editor2/core/playback.py | `_hero_name`: TERRY in $CA42 instead of the new-game placeholder | PyBoy: "*:Oh, Sir TERRY." (was "TERRY0000") |
| editor2/core/ram_names.py | `$C8F2` → "the hero's name"; `INFERRED` (8 variables no game code reads — $D9CD/CE, $D9E2-E5, $C96D/E — shown "meaning inferred from the scripts that use it") | text code $F6 reads $CA42; code readers grepped per address |
| editor2/app/cutscenes_tab.py | actors named by `script_speaker` (no sprite table), the "entered from" header line | test_app |
| editor2/help/63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S118g' | help | test_app |

## S119 rows (ROADMAP P3.8 parts B / c / d: the cutscene editor, copies' tile patches)

| Tool / data | What | Verified |
|---|---|---|
| tools/extract_npc_facings.py (NEW) → **extracted/npc_facing_sprites/id_XX.png + player.png, extracted/npc_facing_sprites.json** (NEW) | every NPC sprite id ($00-$7F, $E0-$E3) solo in the Castle throne room (the S91 catalog's slot, a temp ROM copy), the animation frozen (slot +$05 := $80), every facing (+$06) and step frame (+$14) drawn by the game and composed from OAM + VRAM + the CGB object palettes (transparent); the player from OAM 0-3 with his HRAM facing. 128x16 strips: down, down-step, left, left-step, up, up-step, right, right-step. JSON: `_generator`, per id drawn / object count | S119 run: 128 drawn, 4 not drawn ($68, $E1-$E3 — the S91 catalog's empty / glitch ids); eyeballed on a contact sheet; the cutscene editor's stage uses them. PyBoy-only (not a verifier selftest) |
| editor2/core/cutscene_build.py (NEW) | the cutscene compiler AND model: `Cast` (names → slot numbers per state), `Lowerer` (steps → ops + per-step state + frame timeline + problems), `lower_project` (trigger scripts, wiring, inline dialogue, `patch_data`), `analyse` (the editor), `layout_grid` / `tiles_rows` / `patch_bytes`, `describe`, `trigger_key` / `scene_prefix` / `trigger_script_id` | test_compiler `test_cutscenes_s119` (24 checks); PyBoy scratch builds (cities_fount) and the demo on the user's save |
| editor2/core/cutscene_doc.py (NEW) | the editor's data edits: new / set / duplicate / delete scene, `name_actor` (every state, same sprite + cell), `add_cast` / `move_cast` / `remove_cast` (pads keep one NPC number), `ensure_flag`, `default_player_start`, `problems` | test_app `s119_cutscene_editor` |
| editor2/app/cutscene_editor.py (NEW), editor2/app/cutscenes_tab.py | the cutscene editor (header, step tree, `Stage`, `StepForm`, preview, Build & Play) + the tab's "Your cutscenes", ＋ New cutscene, `scene_ref` / `play_cutscene`, part c `OpDialog` / `_op_target` / `edit_op` | test_app (S119 block); offscreen screenshots |
| editor2/core/project.py | calls `cutscene_build.lower_project` after the helper scripts | test_compiler |
| editor2/core/emitters.py | `patch:<name>` params → `CustomRoom<n>_Patch_<name>`; `_patch_data_lines` (bank $60) | test_compiler |
| editor2/core/templates/bank_060_head.asm + PINNED_SHA256 (re-pinned) | entries 9 / 10 `CustomDrawTiles` / `CustomDrawAttrs` (+ `CutPatchRoute` / `Param` / `Cursor` / `Draw` / `Stage` / `StageAttr`) | test_compiler --rom pin `d19259a1…` (patched); PyBoy: a custom room's patch and a Castle copy's chest drawn |
| patches/bank_004.asm | `CallBank0FForItem` / `CallBank0F_Gold`: `ld hl,$0f01/$0f02` → `$6009/$600a` (same size) | as above |
| editor2/core/document.py | `_migrate_clone_patches` (on open + Make editable); `update_npc` keeps `actor` / `cast` | PyBoy: Castle copy; test_canvas --rom |
| disassembly/bank_000.asm + patches/bank_000.asm | `CheckSoundQueueState` → `ScreenShakeTick` + comment | clean `1ca6579…` byte-perfect |
| disassembly/bank_004.asm (+ patches) , bank_00c/00d/00e/00f.asm | comments: init_dialog rule (S119), the `$24`/`$61` redirect, "measured S119" | byte-perfect |
| editor2/tests/test_compiler.py, test_app.py | S119 tests; REFERENCE_MD5 → `d19259a1…` (patched); the S118 tree indices follow the new top row | PASS |
| editor2/help/63_cutscenes.md, 00_start.md, 90_limits.md, _revision.md; `EDITOR_REVISION` = 'S119' | help | test_app |

## S120 rows (overlay guard, mapID audit, ROADMAP P3.6 dialogue, P3.7b part 2 maze floors, mop-up)

| Tool / data | What | Verified |
|---|---|---|
| tools/verify_integrity.py | check 2: the committed overlay's md5 must equal test_compiler `REFERENCE_MD5` (the S119 stale `patches/bank_060.asm` built `0591928d…`, patched, historical, and passed); check 5 += `audit_mapid_range.py`, `census_gate_floor_types.py` | PASS; negative control (the S117 bank_060 back) FAILS check 2 |
| patches/bank_060.asm (REGENERATED) | `build_project.py --project editor2/example-project --apply`, bank $60 only (the other `--apply` diffs were comment-only — the committed copies kept) | overlay == pin `d19259a1…` (patched) |
| tools/audit_mapid_range.py → extracted/mapid_range_audit.json (REGENERATED) | 12 S116-S119 sites adjudicated; 4 stale keys renamed; FAILS on a key that matches no site; band [50, 120] | selftest PASS (clean 58 / patched 82); CROSSBANK_ROOMS "S120 burn-down" |
| dwm/text.py | the "DTE" pair table replaced by the font's one-cell contractions ($65 " , $66-$71 'l 't 's 'r 'm 'y 'v 'd 'e 'c 'n 'T); + the extra glyphs ($96-$B6); S120 control names; `$EA` no longer skips 2 "parameter" bytes; PARAMS $E8 2, $E9 / $F8 / $F9 / $FB / $FC 1 | test_compiler S120 decode test |
| tools/dump_dialogue.py (`--redecode`, NEW option) → **extracted/dialogue.json (REGENERATED)** | same glyph fix + PARAMS; `--redecode` keeps the MEASURED id → (bank, address) map and re-decodes the raw bytes (no PyBoy) | 57 ids' and 85 table texts' decoded text changed (e.g. "Dn'a" → "D'ya", battle `$FC` params no longer printed); raw bytes / addresses unchanged; `--selftest` PASS |
| tools/dump_text_id_map.py → extracted/text_id_map.json (REGENERATED) | derived from the new dialogue.json | — |
| tools/refresh_script_text_comments.py --apply → disassembly/bank_00e.asm, bank_00f.asm (+2 more) | 17 previews rewritten from the corrected decode | clean `1ca6579…` byte-perfect |
| tools/census_gate_floor_types.py (NEW) → **extracted/gate_floor_types/gate_floor_types.json + ft_00-15.png (NEW)** | the three floor-type tables (rows + odds), the 32 gate rows (bytes 0-2, 7), which gates use each row, the 8 special picks, and a PICTURE of each maze floor type: PyBoy, the original ROM, a new game, gate 1 floor 1 with `A` := type at $16:$5BD2 | 16 / 16 reached (`wMapID` == type, in a gate); `--selftest` (no PyBoy) in verify check 5 |
| tools/dump_all_npcs.py → **extracted/npc_catalog.json + sprite_reference.json (REGENERATED)** | the valid-step rule of `editor2/core/vanilla.valid_steps` (tileset bank, both pointers, NPC cells < 16; the first invalid step ends the list) — the S91 phantom-step contamination is gone | 772 → 716 rows (56 phantom rows removed, none added; e.g. map $08's eight id-30 "steps"); max 8 NPCs per state (the engine cap) |
| extracted/monsters_full.json (UNCHANGED) | the generator question (PROJECT_STATE open defect): NO tool in the repo writes it — it came with the first import (`cba8952`); `randomize.py` / `dump_monsters.py` only read it | S120: all 221 monsters == the ROM's MonsterInfoTable rows (family, level cap, exp table, fly, metal, 3 skills; `female_ratio` is stored as a label) — treat as a frozen, correct input |
| editor2/core/textenc.py, scriptgen.py (`load_lead_name` $3F), project.py (`{lead}` op insertion, gate row keys), talk.py, conversation.py, cutscene_build.py, cutscenes.py (`room_recipe`, `RoomOnly`), gates.py (`ROW_KEYS`, `floor_types`, `row_settings`, `row_summary`; a `0` value is no longer dropped), music.py (≥ $80 warnings), monster_text.py (all contractions), document.py (`set_npc_shown_when`, `npc_view` + shown_when / swirl_of) | PROJECT_COMPILER §2.3 / §2.17 "S120" | test_compiler 726 (+25); --rom 1007 |
| editor2/app/rooms/talk_editor.py, conversation_dialog.py, cutscene_editor.py, npc_panel.py (`ShownWhenDialog`), inspector.py, tab.py (`_play_here`, `_npc_shown_when`), gates_tab.py (Maze floors, scrolling panel) | EDITOR_DESIGN §5.1 item 4 / §5.1b "As built S120" | test_app `s120_dialogue`, `s120_gates`; offscreen screenshots |
| disassembly/bank_056.asm (+ patches) | `TextControlCode`, `TextCodeTable` ($44CE, was misassembled code), `TextCode_E0_E6` … `TextCode_FE_VoiceOff`, `TextSpeedFrames` + `TextCode_ED_Fast` (was misassembled) | byte-perfect, labels at the measured addresses (game.sym) |
| disassembly/bank_016.asm (+ patches) | `SpecialRoomTable` ($5C32, was misassembled code) + `SpecialRoom0_Treasure` … `SpecialRoom7_Conveyor` | byte-perfect |
| disassembly/bank_000.asm (+ patches) | comment: the voice blip read (`$C840`) | byte-perfect |
| editor2/help/20_npcs.md, 40_conversations.md, 56_dialogue.md, 60_gates.md, 63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S120' | help | test_app |

## S120b rows (the hero's default name "MILLY")

| Tool / data | What | Verified |
|---|---|---|
| patches/bank_04f.asm | the font's hero-name tiles `$D3-$D6` (`$4F:$4D40`, 64 B; the INCBIN `;TERRY` replaced by `db` rows drawing "MILLY"; same size, outside the `gd_family_icons` region) | pin `97659a4a…` (patched); diff vs `d19259a1…` = those bytes + the header checksum; PyBoy: the Castle naming box offers MILLY, "King:Oh MILLY!" (the user's project) |
| editor2/core/textenc.py `PATCHED_GLYPHS` | the same 4 tiles for every preview (`glyph_2bpp`) — the previews read the ORIGINAL ROM | test_compiler `test_hero_default_s120b` (source) + `--rom` (built ROM) |
| editor2/core/playback.py `_hero_name` | a new game's hero name = the 4 tiles + `$F0` × 4 (what accepting the default leaves — measured), was "TERRY" as 5 letters | DOC_AUDIT S120b |
| editor2/tests/test_compiler.py | `REFERENCE_MD5` → `97659a4a…` (patched); `test_hero_default_s120b` | 730 / --rom PASS |
| editor2/help/20_npcs.md, talk_editor.py tooltip, `_revision.md`; `EDITOR_REVISION` = 'S120b' | the hero's name: ≤ 4 letters, default MILLY | test_app |

## S121 rows (the Milly hook, ROADMAP P3.16 + E7)

| Tool / data | What | Verified |
|---|---|---|
| tools/dump_map_table.py + extracted/map_table.json (regenerated together) | an exit pointer `$FFFF` = "no exits" (was rejected → maps `$08` / `$5D` / `$5E` had 0 steps; now 9 / 5 / 4); `exit_data` [], `exit_ptr_flat` None | only those three rooms changed; room_connections.json unchanged; test_canvas all-clones (copies of `$08` / `$5D` / `$5E`) |
| editor2/core/milly.py, milly_doc.py, templates/bank_079_head.asm, app/milly_dialog.py | the Milly hook (PROJECT_COMPILER §2.34) | test_compiler `test_milly_hook_s121` / `test_milly_rom`; test_app `s121_milly`; PyBoy (PROJECT_STATE S121) |
| patches/bank_00e.asm (NEW in the overlay), bank_001 / bank_004 / bank_006 / bank_009 / bank_04f.asm regions, bank_079.asm (NEW, `hooks79`), wram.asm (`wMillyLayout`), game.asm (`INCLUDE "bank_079.asm"`) | the hook's regions (vanilla text when off) | verify_integrity (PATCH_FILES / PATCH_NEW_FILES += bank_00e / bank_079); pin `e43e5f58…` (patched) |
| patches/bank_071.asm + templates/bank_071_head.asm | entry 8 `TextSpriteMode`, room flag bit 1 (`text_keeps_sprites`) | re-pinned; test_compiler --rom |
| editor2/core/cutscene_build.py | `name_hero` step; `_then_next` | test_compiler; PyBoy (the naming screen offers MILLY) |
| editor2/core/textenc.py | `MILLY_GLYPHS`, `PATCHED_GLYPHS` filled by `use_hero_glyphs` (hook on only) | test_compiler, test_app |
| editor2/core/document.py | `clone_vanilla`: `text_keeps_sprites` for `$08` / `$5D`, no animation handler for `$08` | test_canvas all-clones |
| dwm/sprite_bank.py | `DEFAULT_OVERFLOW_BANKS` without `$79` (now the story-hook bank) | — |
| tools/audit_mapid_range.py | `TextSpriteMode#0` BOUNDED | selftest PASS (clean 58 / patched 83) |
| disassembly/ + patches/ banks $00 / $01 / $04 / $05 / $06 / $09 / $0E | comments: `SaveHLBC` text-box rule, the player draw + `LoadFieldTilesDMA`, `data_4137`, the NPC tables, the opener's $08/$5D test, the icon entry, the bedroom tail | clean `1ca6579…` byte-perfect |
| editor2/help/64_milly_hook.md (NEW), 63_cutscenes.md, _revision.md; `EDITOR_REVISION` = 'S121' | help | test_app |

## S121 r3 rows (the move-screen check, the roots naming option)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/project.py `move_screen_problem` / `vanilla_screens` | a move / helper / conversation warp to a screen the room lacks stops the build | test_compiler (S121 r3); PyBoy: SBOSS screen 12 = crash, screen 4 = fine |
| editor2/core/milly.py `ROOTS_TEXT_ASK` / `ROOTS_TEXT_AFTER` / `set_naming`, milly_doc.py `set_roots_naming` | the naming screen between Warubou's lines | test_compiler, test_app; PyBoy end to end |
| editor2/app/milly_dialog.py, cutscene_editor.py (`dest_screens`) | screen lists of the chosen room; "Warubou asks her name" | test_app |

## S122 rows (ROADMAP P3.7b part 2: gate themes as room tilesets, the maze model, NG2 residual a)

| Tool / data | What | Verified |
|---|---|---|
| tools/census_maze.py + extracted/maze_pieces.json (generated together) | the maze model vs the game: `floors` (PyBoy hooks `$16:$605B` entry / `$16:$63AE` after the item list's `$FF`, the routine re-run in place by setting PC; sizes 3-15, RNG seeded per run), `screens` (rendered screens vs the model, pixel), `freeze_probe` (size 2, seed `$8192` → an empty grid, the game spins), `carve_sweep`, `--negative` (a broken piece table must fail), `--selftest` (in verify_integrity SELFTEST_TOOLS). Writes the piece catalogue (254 screens), 27 game-recorded sample floors, the census numbers | floors 4,000 / 0 mismatches; screens 64 / 0; negative control fails; selftest PASS |
| editor2/core/maze.py | `MazeRom` — tables, cell → screen grids (tiles + attr), theme sheet / palette words, `carve` / `generate` / placements bit-exact (`rng_step`, `div8`, `div16` = the ROM's Div8x8 / Div16x8To16), `pieces()` (254), `metatiles()` (15); `theme_of_origin`, `theme_palette_rows`, `THEME_NAMES`, `MazeHang` (spin cap) | census_maze.py; test_compiler `test_maze_s122` (the JSON's samples) |
| editor2/app/rooms/maze_dialog.py (NEW) | **Maze screen…**: theme combo, ↑↓←→ filter + "exactly these sides", pattern screens, picture list → (cell, mode) | test_app `s122_gate_themes` |
| editor2/core/document.py, render_project.py, gates.py, app/rooms/tab.py, tileset_dialog.py | theme rooms (`new_room(gate_theme=)`, `set_room_tileset('gate')`, `use_theme_palette`, `stamp_maze_screen`, theme vocab, `VocabReleaseWouldHelp` + the GUI prompt, the theme's own stairs) | test_compiler, test_app; PyBoy `verify_theme` 4 / 4 + the demo walk 3 / 3 screens == the preview |
| tools/map_gate_names.py + extracted/gate_names.json (regenerated together) | `win_tails` per gate: the vanilla boss script's ops after `write_ram $D92B 7` (ops `$00-$03`, `$12-$14`; deduplicated, addresses relative to the start) | 20 / 20 PyBoy GateBossWin stub calls == the tail model (gates 0, 1, 2, 5, 23) |
| editor2/core/templates/bank_076_head.asm + patches/bank_076.asm, encounters.py, project.py, validators.py | `GateClearTable` 6-byte rows + `RunWinTail`; `TEMPLATE_SIZE[0x76]` 460; template sha `65e12e5b…` | test_compiler --rom; regression pin `bd0652da…` (patched) |
| editor2/core/gamedata.py, app/encounters_tab.py | maze size 3-15 (error / spin range) | test_compiler |
| disassembly/ + patches/ banks $00 / $01 / $06 / $07 / $16 / $17 | labels + comments: the maze routines / tables (`MazeBuildFloor` … `MazePlacements`), `TileAtPixel` (was `WaitInputRelease`), `ScreenOriginTable` re-sectioned as `db`, `GateAttrTable_A/B` comments | clean `1ca6579…` byte-perfect |
| editor2/help/12_gate_themes.md (NEW), 10_rooms.md, 59_encounters.md, 60_gates.md, 90_limits.md, _revision.md; `EDITOR_REVISION` = 'S122' | help | test_app |
## S123 rows (ROADMAP NG3: worlds, NPC colours, the Vanish step)

| Tool / data | What | Verified |
|---|---|---|
| editor2/core/worlds.py (NEW) | `WorldsMixin`: worlds (new / start / rooms / saving / swirl / entrance / music / delete / report) and `make_boss` | test_compiler `test_worlds_s123` / `test_worlds_rom`; test_app `s123_worlds` |
| editor2/core/gates.py, project.py, emitters.py, validators.py, conversation.py, document.py | the `world` / `cleared_swirl` keys, world start rows, world saving, NPC `colour` → `$A2`, the `vanish` step, `_validate_worlds`, `TEMPLATE_SIZE[0x60]` 1273 | test_compiler (+ --rom) |
| editor2/core/templates/bank_060_head.asm + patches/bank_060.asm, patches/bank_006.asm, patches/wram.asm | `$A2` in `CopyNPCListToBuffer`, `NpcColourRecord`, entry 11 `NpcColourDraw`; `NPCDrawSlot` → entry 11; `wNpcColour` | PyBoy (OAM attr per slot, the swirl in palette 1); regression pin `e93b23b5…` (patched) |
| editor2/app/world_tab.py (Worlds panel), app/rooms/boss_dialog.py (NEW), npc_panel.py, conversation_dialog.py, canvas.py, inspector.py, tab.py, gate_panel.py, rules_panel.py, gates_tab.py | the GUI (EDITOR_DESIGN §5.1 "Worlds (S123)") | test_app `s123_worlds` |
| editor2/core/templates/bank_060_head.asm entry 12 + patches/bank_00b.asm (S123 r2) | `CustomDescentFeel`: the S41 in-gate transition feel for Stairs down only; a custom room's gate entrance runs the vanilla portal whirl | PyBoy: the `$C905` ladder + sound of room $24's portal == the Rift Gate Hall portal; a world-room Stairs down still `$10-$17`; the demo re-walked end to end; pin `6b0738c1…` (patched) |
| editor2/app/rooms/cell_picker.py (NEW, S123 r3) + world_tab.py `PortalDialog` / *The way in*, canvas markers P / W↓, `Document.world_portals` / `remove_world_entrance` | cells picked on the room picture (New world…, the landing, Add portal…) | test_app `s123_worlds` (r3 block) |
| editor2/core/render_project.py `common_blocks` + tools/render_rooms.py `_common_sheet` (S123 r3) | BG ids `$80-$AF` drawn from sheet `$29:$1D` (every room) | PyBoy: `$8800-$8AFF` == `$29:$1D` in 6 rooms; the roots room preview == the game frame, 0 px differ |
| tools/audit_mapid_range.py | new sites `CopyNPCListToBuffer#0` COPY, `NpcColourDraw#0` CP_UNSIGNED (CROSSBANK_ROOMS "S123 sites") | selftest PASS |
| editor2/help/65_worlds.md, 11_doors.md, 13_tilesets.md, 14_import_art.md (NEW) + 00/10/20/30/40/59/60/70/80/90, _revision.md; `EDITOR_REVISION` = 'S123' | help | test_app |

## S124 rows (ROADMAP P3.14a: the flag index, the Progression & Flags tab)

No extracted/ data added or regenerated (the index reads the ROM through
`editor2/core/cutscenes.Catalogue` and `extracted/dialogue.json` / `gate_names.json`).

| File | What | Verified by |
|------|------|-------------|
| editor2/core/flag_index.py (NEW) | every flag of a project and every place that touches it (uses, triggers, problems; the original game's scripts + code); `compiler_coverage`; CLI `python3 -m editor2.core.flag_index <project> [--rom ROM]` | test_compiler `test_flag_index_s124` (6 fixtures, every site, nothing missed); the user's project (S124: 342 flags, 76 triggers, 21 problems) |
| editor2/core/project.py `number_flags` / `quest_flag_entries` / `FLAG_AUTO_RANGES` / `GAME_SHARED_FLAGS` | one flag numbering for the compiler and the editor; new flags skip `$0158` | test_compiler (pinning / rename change no generated byte); REFERENCE_MD5 unchanged |
| editor2/core/document.py flag methods (`flag_numbers`, `add_flag` fixed numbers, `rename_flag`, `delete_flag`, `set_flag_comment`, `renumber_flag`, `_migrate_pin_flags`) | fixed flag numbers; rename everywhere | test_compiler + test_app `s124_progression` |
| editor2/app/flags_tab.py (NEW) + main.py `navigate_to`, rooms/tab.py `open_node` (6-tuple), encounters_tab.py `show_room_battles` / `show_gate_battles` | the tab (EDITOR_DESIGN §5.7 "As built S124") | test_app `s124_progression` |
| editor2/app/place_panel.py (NEW, r3) + flags_tab.py splitter, rooms/tab.py vanilla state + **Name…**, rooms/npc_panel.py name row, rooms/canvas.py name tags, cutscenes_tab.py `_actors` | the place panel; your NPC names everywhere (EDITOR_DESIGN §5.7 r3) | test_app `s124r3_places` ($0080 → GreatTree screen 12 state 1 (1, 6); named; Open → that screen / state / NPC) |
| editor2/core/npc_names.py (NEW, r3) + `Document.name_npc`, flag_index `Use.places` / `_game_who`, cutscenes.py `ProjectCatalogue.npcs` (+`actor`) | `custom._editor.npc_names` (editor data); places of every use | test_compiler `test_flag_index_s124` r3 checks (places of `$0080`; naming = no generated byte) |
| disassembly/ + patches/ bank_009.asm `GateListClearedFlags` / `GateListClearedByte` / `GateListUnlockFlags` (re-sectioned), bank_004 `ScriptCmd33_GiveGold` (renamed) + `$56` / `$5F` / `$60` comments, bank_000 `CompareGold` comment, bank_012 `$0007` / `$0050+n` comments | annotation (Iron Rule 6) | clean build `1ca6579…`; text diff = the intended lines |

## S125 rows (ROADMAP P3.14d1: the hub)

No extracted/ data added or regenerated.

| File | What | Verified by |
|------|------|-------------|
| editor2/core/templates/bank_071_head.asm (+ patches/bank_071.asm regenerated) | entry 9 `HubWarp` (HubTable walk; the vanilla Castle writes when the hub is the Castle / unset); re-pinned `28d988db…`; `TEMPLATE_SIZE[0x71]` 865 | test_compiler `test_hub_rom` (MiniSM83 runs HubWarp from the ROM: no hub, a hub room, the Castle rule); regression pin `c326fc96…` (patched) |
| patches/bank_050.asm (`$6559`, `$64AF`), bank_006.asm (`$6A39`), bank_007.asm (`$5030`), patches/wram.asm (`wHubReason` $D2EF + `HUB_*`) | the four engine Castle sends → entry 9, same size | `test_hub_rom` (bytes vs the original, labels unmoved); PyBoy on the user's save |
| editor2/core/project.py (`hub_rules`, `hub_warp_ops`, `_hub_anchor`, `HUB_REASONS`, `heal` step, `dest: "hub"`), emitters.py `_hub_table`, cutscene_build.py (`ARRIVALS`, `trigger.arrival`, `hub_reveal_ops`, `hub_default_ops`, the `heal` / hub `move` steps), scriptgen.py (`refresh_party` alias), validators.py (hub warnings, `TEMPLATE_SIZE`), flag_index.py (kind `hub`), conversation.py (`heal`), script_ops.py (`$27` doc) | the compiler (PROJECT_COMPILER §2.38) | test_compiler `test_hub_s125` + `test_flag_index_s124` (the `hub` site) |
| editor2/core/hub_doc.py (NEW) | `HubMixin` — the hub rules for the editor + Add the arrival scenes | test_compiler `test_hub_s125` (doc block); test_app `s125_hub` |
| editor2/app/world_tab.py (`HubBox`, `HubRuleDialog`), cutscene_editor.py (Arrival home, Heal, home destination), rooms/conversation_dialog.py (Home, Heal), rooms/canvas.py (H marker), main.py (`navigate_to` worlds), milly_dialog.py | the GUI (EDITOR_DESIGN §5.8 "Hub (S125)") | test_app `s125_hub` |
| disassembly/ + patches/ bank $01 `IteratePartySlots20`, disassembly banks $06 / $07 / $50 (the four sends) | comments (the heal; what reaches each send) | clean `1ca6579…` byte-perfect |
| editor2/help/66_hub.md (NEW) + 00/30/40/63/65/90, _revision.md; `EDITOR_REVISION` = 'S125' | help | test_app |

## S126 rows (ROADMAP P3.14e1: service NPCs)
Data added: `extracted/service_lines.json` (NEW, tool + data together); `extracted/mapid_range_audit.json` regenerated (`--json`: the bank $77 `ServiceOpenTiles` site, CP_UNSIGNED).

| File | What | Verified by |
|------|------|-------------|
| tools/extract_service_lines.py (NEW) → extracted/service_lines.json | the seven text blocks + the medal table (Tier A row above) | `--selftest` in verify_integrity check 5 (SELFTEST_TOOLS) |
| tools/audit_mapid_range.py | key `("bank_077.asm", "ServiceOpenTiles", 0)` = CP_UNSIGNED | its selftest (clean 58 / patched 86) |
| editor2/core/templates/bank_077_head.asm (+ patches/bank_077.asm regenerated) | entries 3 `SayText`, 4 `ServiceCloseBox`, 5 `ServiceCloseTiles`, 6 `ServiceOpenTiles`; `ScreenPush` palette-7 rules; re-pinned `4c9f5998…`; `TEMPLATE_SIZE[0x77]` 684; **r2**: `ServiceTilesBack` sets `$FFD4` := `$80`, re-pinned `cfe0dba0…`, 688 | test_compiler `test_services_rom` (MiniSM83 runs SayText / the push from the ROM); PyBoy on the user's save |
| editor2/core/templates/bank_071_head.asm (+ patches/bank_071.asm) | `CustomAnimSource` pauses during `AnimPauseTypes`; re-pinned `b3588b7a…`; `TEMPLATE_SIZE[0x71]` 908 | test_services_rom; PyBoy (animated room) |
| patches/bank_009.asm, bank_00a.asm, bank_012.asm, wram.asm | the say helpers → `SayAny09/0A/12`; `ScreenPush0A/12` → bank $77; the close tails (10 B each); `FarmScreenOpen` / `EggScreenOpen`; two farm ids base-relative; the medal readers on `MedalRewardTable` / `MEDAL_REWARD_COUNT`; `wServiceTileSave` / `wServiceTileSaved` / `wServiceLines` (carved from `wCustomPool`) | test_compiler (byte checks, labels unmoved); regression pin `0b12d0df…` (patched; `288d29e2…` before r2) |
| editor2/core/services.py (NEW), project.py, shops.py, emitters.py (`gd_medal_rewards`), gamedata.py (`medals`), validators.py, flag_index.py (kind `service`) | the compiler (PROJECT_COMPILER §2.39) | test_compiler `test_services_s126`, `test_flag_index_s124` (the `s126` fixture) |
| editor2/core/services_doc.py (NEW) | `ServicesMixin` — the Services model | test_app `s126_services` |
| editor2/app/services_tab.py (NEW), rooms/service_dialog.py (NEW), rooms/npc_panel.py (Service…), rooms/tab.py (`_npc_service`, the shop lines picker), main.py | the GUI (EDITOR_DESIGN §5.6c) | test_app `s126_services` |
| disassembly/ + patches/ banks $09 / $0A / $12 | labels `VaultScreen`, `GateListScreen`, `FarmScreen`, `LibraryScreen`, `NamerScreen`, `MedalScreen`, `EggAppraiserScreen`, `ScreenPush0A/12`, `ScreenEffectSay0A/12` (misnomers fixed), `MedalRewardTable` re-sectioned; comments at the tile-slot writes and the close tails | clean `1ca6579…` byte-perfect |
| editor2/help/67_services.md (NEW) + 00 / 20 / 62 / 90, _revision.md; `EDITOR_REVISION` = 'S126r2' | help | test_app |
| disassembly/ + patches/ bank $12 `$44A7`, bank $0A `$4481` / `$4C33` / `$69C3` (r2) | comments: the `$FFD4` writers | clean `1ca6579…` byte-perfect |

## S127 rows (ROADMAP P3.14e2: breeding in the project's rooms)
Data changed: `extracted/service_lines.json` regenerated (+ kinds `grandpa`, `breeder`: 9 blocks, 181 lines; tool + data together); `extracted/mapid_range_audit.json` regenerated (`--json`: `CF2WarpCommitDrain`, `BreedClose`, CP_UNSIGNED; clean 58 / patched 88).

| File | What | Verified by |
|------|------|-------------|
| tools/extract_service_lines.py → extracted/service_lines.json | kinds `grandpa` (bank $0A, `$06F0`, 32 lines) and `breeder` (`$0600`, 10 lines); per-kind say ranges (`_rngs`) | `--selftest` in verify_integrity check 5 |
| tools/audit_mapid_range.py | keys `("bank_073.asm", "CF2WarpCommitDrain", 0)`, `("bank_077.asm", "BreedClose", 0)` = CP_UNSIGNED | its selftest (clean 58 / patched 88) |
| editor2/core/templates/bank_077_head.asm (+ patches/bank_077.asm regenerated) | entries 7 `BreedClose`, 8 `BreedSlotEID`, 9 `PartyAvgLevel`, 10 `ScriptCommand` + `BreedRoll` + the pool data; re-pinned `b70c1cd6…`; `TEMPLATE_SIZE[0x77]` 1107 | test_compiler `test_breeders_rom` (MiniSM83: BreedRoll == the model on 120 players, PartyAvgLevel, BreedSlotEID); PyBoy on the user's save |
| editor2/core/templates/bank_071_head.asm (+ patches/bank_071.asm) | `CustomGateInsert` `GATE_ANY` + `ScaledChance` / `ScaledChanceTable`; re-pinned `7c371e82…`; `TEMPLATE_SIZE[0x71]` 951 | `test_breeders_rom` (ScaledChance); PyBoy (50 / 84 at a 57 % row value) |
| editor2/core/templates/bank_060_head.asm (+ patches/bank_060.asm) | `CustomDrawTiles` op `$24 $FFxx` → bank $77 entry 10; re-pinned `56a5321a…`; `TEMPLATE_SIZE[0x60]` 1306 | test_breeders_rom; PyBoy (the mate's name in the question) |
| patches/bank_00a.asm, bank_014.asm, bank_073.asm, wram.asm | the three type 5/6/11 close tails → `$7707` (same size); `LoadEnemyStatsExt` slot rows `$0F00+k`; the commit clears the slots; `wBreedLast` / `wBreedSlots` / `wBreedVals` / `wBreedMask` / `wBreedStep` (carved from `wCustomPool`) | test_compiler (byte sites); regression pin `a7dc3e71…` (patched; `0b12d0df…` before) |
| editor2/core/breeders.py (NEW), services.py (kinds `grandpa` / `breeder`, `FIXED_LINES`), project.py (`lower_talk` / `lower_entries`, `gate: "any"`, `chance_by_level`), emitters.py, shops.py, validators.py, gates.py (`rule_chance`, `chance_text`), flag_index.py (kinds `breeder`, `breed_pool`), script_ops.py (op `$42` param = enemy) | the compiler (PROJECT_COMPILER §2.40) | test_compiler `test_breeders_s127` (22 checks), `test_flag_index_s124` (the `s127` fixture) |
| editor2/core/breeders_doc.py (NEW), document.py, services_doc.py | `BreedersMixin` — breeder options, pools, the Try-it preview | test_app `s127_breeding` |
| editor2/app/services_tab.py (Breeding pools page), rooms/service_dialog.py (the breeder group), rooms/tab.py, gates_tab.py (every gate, chance by level) | the GUI (EDITOR_DESIGN §5.6c S127) | test_app `s127_breeding` |
| disassembly/ + patches/ bank $04 (`ScriptCmd42/43/44/4E/4F/50`), bank $0A (`label442d`, `label4ad3`, `LoadFldA_4ba2`, `label4bc3`, `label573e`, `label6966`) | comments: the breeding ops / screens / confirms (Iron Rule 6) | clean `1ca6579…` byte-perfect |
| editor2/help/68_breeding_npcs.md (NEW) + 00 / 20 / 30 / 60 / 67 / 90, _revision.md; `EDITOR_REVISION` = 'S127' | help | test_app |
| editor2/core/breeders_doc.py (r2: `fit_boxes`, `_migrate_service_words`, `mate_species` / `mate_stats` / `mate_for` / `mate_info`, `set_breeder_options` mate {species, level}), services_doc.py (first-visit text wrapped), document.py (the migration call), app/rooms/service_dialog.py (a monster at a level you choose; no line dropped), help 68_breeding_npcs.md; `EDITOR_REVISION` = 'S127r2' | S127 r2 — the user's two reports | test_compiler `test_breeders_s127_r2` (10 checks); test_app `s127_breeding` (CatFly at level 25, long words); PyBoy (Rosa's CatFly Lv 33 staged as species 47 level 33) |
| editor2/core/templates/bank_077_head.asm (+ patches/bank_077.asm) | S127 r3: `BreedClose` → `ShopBoxBottom` in custom rooms; re-pinned; `TEMPLATE_SIZE[0x77]` 1110 | test_compiler `test_breeders_s127_r3`; regression pin `5d350ba9…` (patched; `a7dc3e71…` before); PyBoy (the user's $6B: NO / YES-B / afterwards, a Grandpa from the lower half) |
| editor2/core/breeders.py (`_bottom`), shops_doc.py (greeting fitted), breeders_doc.py (migration covers shop greetings), app/rooms/talk_editor.py (`BoxList(header=)`, `GameTextField`), rooms/service_dialog.py, rooms/tab.py (Shopkeeper greeting), services_tab.py (medal reward preview), skills_tab.py (battle message preview); `EDITOR_REVISION` = 'S127r3' | S127 r3 — the box at the bottom; the game text rule | test_compiler `test_breeders_s127_r3`; test_app `s127r3_game_text_rule` + the S126 / S127 / S117 dialog tests |
| editor2/core/breeders.py (a breeder's `first_time`), app/rooms/service_dialog.py (first visit for every kind, shown while ticked), app/rooms/talk_editor.py (removed boxes hidden + unparented), help 68, `EDITOR_REVISION` = 'S127r4' | S127 r4 — the user's two questions | test_compiler `test_breeders_s127_r4`; test_app `s127r3_game_text_rule` (one editor per field); PyBoy scratch build (first visit, then the first words) |

## S128 rows (ROADMAP P3.14e3: your arena)
Data changed: `extracted/service_lines.json` regenerated (+ kind `arena`: bank $09, base `$0710`, 7 lines → 10 blocks, 188 lines; tool + data together); `extracted/mapid_range_audit.json` regenerated (clean 58, patched 84; tool + data together).

| File | What | Verified by |
|------|------|-------------|
| tools/extract_service_lines.py → extracted/service_lines.json | kind `arena` (screen 4, bank $09, `$0710`, 7 lines) | `--selftest` in verify_integrity |
| tools/audit_mapid_range.py → extracted/mapid_range_audit.json | keys `ArenaMapID#0`, `ArenaLossWarp50#0`, `ArenaMarkClasses#0` = CP_UNSIGNED; `BattleBGMResolve` re-keyed | its selftest (clean 58 / patched 84) |
| patches/bank_000/001/003/007/009/050/051/06e.asm | ROM0 `ArenaMapID` / `ArenaAlias`; the arena-keyed sites → calls; `ArenaMarkClasses` (bank $6E entry 1) + region `arena_rooms`; `ArenaRefuse09`; `ArenaLossWarp50`; `ArenaScriptType50/51` | test_your_arena_rom; PyBoy (the user's save) |
| editor2/core/templates/bank_071_head.asm (+ patches/bank_071.asm) | `BattleBGMResolve` → `call ArenaMapID`; re-pinned `bb4151d2…`; TEMPLATE_SIZE unchanged | test_compiler pins |
| editor2/core/your_arena.py (NEW), your_arena_doc.py (NEW), project.py, services.py, validators.py, emitters.py, flag_index.py, render_project.py (`vanilla_steps` `$FFFF`), document.py (`clone_vanilla` shared layouts; `_migrate_shared_flags`), project.py `number_flags` (S128 r2) | the compiler + model | test_compiler `test_your_arena_s128` / `_rom` + the flag tests |
| editor2/app/arena_tab.py, services_tab.py, main.py | ★ Your arena page + "In your arena" per class; Monster Grandpa's match label | test_app `s128_arena` |
| editor2/example-project/project.json | the quest flags written in (`$015A` / `$0159`, S128 r2) | test_app (open = no change) |
| patches/bank_060.asm (regenerated, `build_project.py --apply`) | the example's quest flag `dw $0158` → `dw $015A` (three rules); the overlay builds the pin `3a9c38fb…` (patched) | verify_integrity check 2 |
| disassembly/ + patches/ banks $01 $03 $04 $07 $09 $50 $51 | comments at every arena site; group 9 = Monster Grandpa's match | clean rebuild `1ca6579…` |
| editor2/help/69_your_arena.md (NEW) + 00 / 30 / 53 / 90, _revision.md; `EDITOR_REVISION` = 'S128' | help | test_app |

## S128 r3 rows (the Milly arena figure; connect any exit)

| File | What | Verified by |
|------|------|-------------|
| patches/bank_00b.asm | `jr_00b_48ba` → `call MillyE0Type`; `MillyE0Type` in room entry 0's dead tileset-select bytes (same size; only its own label moved) | test_your_arena_rom (run with the flag clear / set); PyBoy on the user's save (both arenas); REFERENCE_MD5 `fe5fa80a…` (patched) |
| disassembly/bank_00b.asm | comments at `jr_00b_48ba` and the dead bytes | clean rebuild `1ca6579…` |
| editor2/core/doors.py (`plain_exits`, `plain_exit_end`, `exit_to_door`, `connect_ends`, `twin_of` in link / unlink / move / remove), project.py (`_unlinked_door`) | plain exits → doors | test_compiler `test_connect_ends_s128r3` |
| editor2/app/rooms/door_dialog.py, tab.py, canvas.py | double-click a plain exit → *Exit — connect both ends*; "Your rooms' exits" in the list; the second cell drawn / dragged as the door | test_app `s128_arena` |
| editor2/help/11_doors.md, 64_milly_hook.md, _revision.md; `EDITOR_REVISION` = 'S128r3' | help | test_app |

## S129 rows (ROADMAP P3.14b / c / d: story checks, commands, the story spine, quests, music by flag, shop item sets, locked exits)
Data changed: `extracted/mapid_range_audit.json` regenerated (clean 58, patched 85; tool + data together).

| File | What | Verified by |
|------|------|-------------|
| tools/audit_mapid_range.py → extracted/mapid_range_audit.json | `CustomRoomBGMResolve` re-keyed: #1 BOUNDED (the `.noRule` reload), #2 CP_UNSIGNED (the S101 `cp $61`) | its selftest (clean 58 / patched 85) |
| patches/bank_073.asm, patches/wram.asm | `FlagAddr`: `D == $18` → bank $77 entry 11 `StoryCheck`, `wStoryFlag` (`.story`, `.mask`, `STORY_FLAG_HI`); `wStoryFlag` `$D509`, `wCustomPool` from `$D50A` | test_story_rom; PyBoy (the user's save) |
| editor2/core/templates/bank_077_head.asm (+ patches/bank_077.asm) | entry 11 `StoryCheck` + 12 kinds, `StoryCommand` (op `$24 $FF01+`), `ShopSetPick`; re-pinned `eb0f0997…`, TEMPLATE_SIZE 1788 | test_story_rom; test_compiler pins |
| editor2/core/templates/bank_071_head.asm (+ patches/bank_071.asm) | `MusicRulePick` + `TermsHold71`, the room / gate rule calls; re-pinned `cbd0cdec…`, TEMPLATE_SIZE 1070 | test_story_rom; PyBoy |
| editor2/core/story.py (NEW), story_doc.py (NEW), project.py (checks as virtual flags, `story_command`, `resolve_flag_write`, the new steps, quests lowering, legacy `npc_hide` / `npc_show` fix), conversation.py, cutscene_build.py, music.py, shops.py, validators.py, flag_index.py, document.py | the compiler + model (PROJECT_COMPILER §2.42) | test_compiler `test_story_s129`, `test_quests_s129`, `test_story_rom` |
| editor2/app/story_widgets.py (NEW), flags_tab.py (story checks group, Story page), music_tab.py, shops_tab.py, cutscene_editor.py, encounters_tab.py (`FlagTerms` New story check…), rooms/conversation_dialog.py, rooms/tab.py, rooms/npc_panel.py, rooms/object_panels.py, rooms/rules_panel.py, rooms/talk_editor.py | the editor (EDITOR_DESIGN §5.7 "Story (S129)") | test_app `s129_story` |
| editor2/example-project/project.json | checks `has_2_medals` / `vault_rich`, the mini medal quest (NPC (2, 5) in the medal vault, flags `$015B` / `$015C`), milestone | test_compiler, verify_integrity check 2 |
| patches/bank_060.asm (regenerated, `build_project.py --apply`) | the example's quest talk + the legacy guardian's `npc_write` hide / show; the overlay builds the pin `7d136455…` (patched) | verify_integrity check 2 |
| disassembly/bank_000.asm, bank_004.asm | comments: `ComputeFlagAddress` (the patched route, virtual flags), `ScriptCmd26_ReloadRoom` (measured) | clean rebuild `1ca6579…` |
| editor2/help/71_story_quests.md (NEW) + 00 / 11 / 20 / 30 / 40 / 61 / 62 / 63 / 90, _revision.md; `EDITOR_REVISION` = 'S129' | help | test_app |
| examples/s129_story_demo/ (NEW: project.json + assets/ + build_demo.py) | the S129 test ROM's project in editor format (user S129: "commit current custom quest stuff in editor format … for cross-referencing"): the user's my-dwm-hack_21 + STORY HALL / VAULT ANNEX / the Cities_FOUNT DEMO NPC; `build_demo.py <base project.json> <out project.json>` = the Document-API calls that made it (checks, spine, quest, by progress, lock, music rules, item set, gold) | both build `ca502753…` (patched) = the test ROM; opens in the editor with no migration (round-trips) |

## S130 rows (every battle skill — the ten skill families; the raising model)
Owning prose: BATTLE_SKILL_SYSTEM §15.11 (families, registry), MONSTER_DATA "Raising a monster
(S130)" (raising). Every family rig is a copy of the S85 loop rig (`measure_battle.py`, or the F7
schedule rig) with its own waypoints; all corpora were captured on the user's real save (u22
build + `field.state`). Validator totals are the merged tree's (all 0 mismatches).

| File | What | Verified by |
|------|------|-------------|
| `simulator/battle.py` (S130 registry) | the skill-effect registries the families plug into: ACTION_HANDLERS, CORE_OVERRIDES, POST_CALC, ACTOR_HOOKS, PHASE9_HOOKS, VICTIM_HOOKS, BOSS_GATE_IN_HANDLER, SELF_GATED, COMMIT_TARGETS, TARGET_RESOLVERS, OWN_TARGET_GATES, RERESOLVE_PICKERS, CRIT_STAGE, POST_ACTION_HOOKS, COMMIT_ROLL, INTERCEPT_HOOKS, POST_HIT_HOOKS, POST_VICTIM_HOOKS, POST_SWEEP_HOOKS, KO_HOOKS (table: BATTLE_SKILL_SYSTEM §15.11); `act_mp_spend` / `mp_veto_exempt` (the driver now spends MP), `actor_walk()` (the dragon re-run), helper slots 3/7 in `side_victims` / `quake_victims`; `miss_gate` SideStep fall-through and `guard_redirect` capability fixed | every validator below + the pre-existing ones (s85 6614, s86 802, s89 426, s88 2824 / 3083 / 3422, damage 13 categories, order 143, ai 26/26, rules 240, obedience 889, pacing KS 0.042 / 0.038) — all 0 |
| `simulator/skillfx/__init__.py` | imports every family module on `import simulator.battle` (sorted) | — |
| `simulator/skillfx/f1_status.py` | F1 status appliers + one-shot compulsions (32 handlers, the hit helpers + ladders, `BOSS_GATE_IN_HANDLER`) | `validate_f1.py` 52970 / 0 |
| `simulator/skillfx/f23_phys.py` | F2/F3 single-hit physical variants, Ramming/Kamikaze/TwinSlash tails, Sacrifice sweep + caster roll, Vacuum (`vacuum_base`), MegaMagic, breath extras (37 handlers, `SELF_GATED`, POST_CALC 70 Beserker) | `validate_f23_phys.py` 10049 / 0 |
| `simulator/skillfx/f4_charge.py` | F4 crit stage (per-species tables), post-calc stage (POST_CALC 10), ChargeUP/SuckAir/Focus/TwinHits/ALLCHANGE/Massacre/EvilSlash/HighJump, the `$DB42` tension roll (`COMMIT_ROLL`) | `validate_f4.py` 100051 / 0 |
| `simulator/skillfx/f5_heal.py` | F5 heals, revives, cures, MP drain / MP0 / RESTOREMP, LifeChain, LifeSong, the bank $58 target rows (`COMMIT_TARGETS` / `TARGET_RESOLVERS`) | `validate_f5.py` 9573 / 0 |
| `simulator/skillfx/f6_defence.py` | F6 defence levels (POST_CALC 80), BladeD counter, SuckAll / Cover / Dodge / TailWind / MagicBack interception + reflection, TakeMagic, Imitate (INTERCEPT / POST_HIT / POST_VICTIM / POST_SWEEP hooks) | `validate_f6.py` 19542 / 0 |
| `simulator/skillfx/f7_stats.py` | F7 DEF/AGL movers + caps, Surge, UltraDown machine, Transform's stat copy (`transform_stats`), SickLick's DEF part | `validate_f7.py` 7667 / 0 |
| `simulator/skillfx/f8_multihit.py` | F8 multi-hit loop: BiAttack, QuadHits, CallHelp, YellHelp, RainSlash, the `$714C` 8-slot walk (METEOR), continuation + re-pick, `OWN_TARGET_GATES`, `RERESOLVE_PICKERS` | `validate_f8_multihit.py` 19817 / 0 |
| `simulator/skillfx/f9_meta.py` | F9 summons (helpers in slots 3/7), Chance, CALLHOROR/Smashed, RUN, BeDragon/CHGDRAGON, Transform's res/skill copy, the KO reload (`KO_HOOKS`); `pacing.py` helper / option-list commit, `ai_rules.py` summon veto | `validate_f9.py` 9139 / 0 |
| `simulator/skillfx/f10_dispel.py` + `simulator/ai_rules.py` `f10_rules()` | F10 DeMagic / ThickFog / FILTHZONE machine, the seal, `DISPEL_HOOKS`; the DeMagic/ThickFog cat-2 pass conditions (used when `BattleView` has `skills` / `dd0b`, supplied by pacing via `b.ext['f10_optlists']`) | `validate_f10.py` 1335 / 0; `validate_f10_rules.py` 332 / 0 (validate_rules unchanged 240 / 0) |
| `simulator/damage.py` `SPELL_LADDER` | skill id → (rtype, ladder) for the record cores, MOVED here from `validate_damage.py` so the round driver applies it (validators import it) | validate_damage 13 categories 0 |
| `simulator/measure_f1.py` + `simulator/measure_f1_campaign.py` → `simulator/f1_status_events.json.gz` | F1 rig (new: `--eres/--pres` res pokes, `--rpoke` round pokes inside the round_start hook, `--force SLOT:SKILL:TARGET`, `--php3/--pmp3`; compact corpus = full board only on round_start) + its recipe (115 battles, 718 rounds, 65,213 events, ~40 MB uncompressed) | `simulator/validate_f1.py` (also 0 on the six legacy corpora) |
| `simulator/measure_f23_phys.py` + `simulator/measure_f23_phys_plan.py` → `simulator/f23_phys_events.json.gz` | F2/F3 rig (`--q` queues, `--hp/--mp/--st/--res/--lvl/--db8b/--atk/--dfn/--agl` per-slot pokes, `--keep`, `--rounds`) + plan (86 battles, 17,376 events) | `simulator/validate_f23_phys.py` |
| `simulator/measure_f4.py` + `simulator/measure_f4_plan.py` → `simulator/f4_events.json.gz` | F4 rig (adds `--db42` / `--db42rng v` (post-step RNG1 at the tension rolls), `--aib` (AI bases each command phase), `--critrng` / `--dc3c` (forced crit RNG, species rows), `--stinit`, `--lean`) + plan (162 battles, 198,455 events, 3.6 MB packed) | `simulator/validate_f4.py` |
| `simulator/measure_f5.py` + `simulator/f5_corpus_recipe.py` → `simulator/f5_events.json` | F5 rig (`--set SLOT:FIELD=VAL` init pokes incl. `dead=1`, `--q SLOT=SKILL[:TARGET]` any-slot forcing, `--qrounds N`) + recipe (201 scenarios, 12,223 events) | `simulator/validate_f5.py` |
| `simulator/measure_f6.py` → `simulator/f6_events.json.gz` | F6 rig = the F7 schedule rig + interception waypoints (`--ram ADDR=val`; `F6_TRACE=1`, `F6_NOHOOK=tag,…` to bisect a stall; runaway-hook guard). Recipe in the rig's header (54 battles, 37,774 events incl. 13 natural-AI) | `simulator/validate_f6.py` |
| `simulator/measure_f7.py` → `simulator/f7_events.json` | F7 schedule rig: `--sched SLOT:skill@target,…` per round (`-` = engine), `--keep`, `--poke SLOT:field=val`, `--res`, `--st`, `--db42 SLOT=val` (each command frame), `--rounds`. Recipe in the header (37 battles, 7,829 events) | `simulator/validate_f7.py` |
| `simulator/measure_f8_multihit.py` → `simulator/f8_events.json` + `simulator/f8_idle_pools.json` | F8 rig (adds `--eskills/--etargets/--ehps/--elvl`, `--pdd0b`, `--eres6/--pres6`, `--f8trim`; waypoints `$52:$7041` continuation, `$642C` re-pick, the multi-hit handlers, helper damage) — 61 battles, 446 actions, 1,289 passes; idle pools `mh_post_hit` / `mh_refetch` / `mh_call_msg` / `mh_pre_snap`. Recipe below (the rig's header points at the session notes, which are not in the tree) | `simulator/validate_f8_multihit.py` |
| `simulator/measure_f9.py` → `simulator/f9_events.json.gz` | F9 rig (the F8 rig + `--force-rounds`, `--pslot`, `--hskill/--htarget` / `--ehskill/--ehtarget` (helper slots 3/7), `--pmpall`, `--estat/--pstat atk=,dfn=,…`, `--poke`, `--pskill1/--ptarget1/--force1-rounds`, `--sched/--esched R:SK:T[:SLOT]`, `--prefill/--erefill`) — 76 battles, 94,131 events. Recipe below (same note as F8) | `simulator/validate_f9.py` |
| `simulator/measure_f10.py` + `simulator/f10_corpus_recipe.md` → `simulator/f10_events.json.gz` | F10 rig = the F7 rig + the dispel-machine waypoints (`--stp ROUND:SLOT:off=val`, `--side ROUND:SIDE=val`, applied at `$D9EC` 4/5 only) + recipe (30 battles) | `simulator/validate_f10.py` |
| `simulator/measure_f10_rules.py` + `simulator/f10_rules_recipe.py` → `simulator/f10_rules_events.json.gz` | AI-chain rig (`--elist` option lists, `--poke`, `--sched`) + a seeded recipe generator (`random.Random(130)`, 28 battles) | `simulator/validate_f10_rules.py` |
| `simulator/measure_command.py` → `simulator/command_events.json.gz` | S130 P3.15b player-ORDER rig: gives the party its orders through the REAL battle menu (joypad: PLAN → tactic list → COMMAND → ATK/SKIL/DEF → skill page/row → target cursor; `--order R:spec` with `atk@T` / `def` / `sk:ID@T` and `X\|Y` alternatives, `FIGHT` rounds), natural enemy AI; pokes into the RECORD before the battle (`--wld`, `--bases`, `--tactic`, `--pskills`) and at init (`--php/--pmp/--ehp/--emp/--st/--db73`); waypoints = the S85 round loop + the menu writes (`m_skill/m_target/m_mark/m_msg`), the bank $57 commit (`ai_s0/band_in/decide_in/carry/nocarry/pers/cmd_keep/direct/ai_post`), `qfetch` ($58:$5498), `tension_in`, `daze`, `battle_end`. 56 battles / 29,794 events; recipe in the rig's header | `simulator/validate_command.py` |
| `simulator/validate_command.py` | replays the corpus with the recorded orders as the planner: menu normalisation + refusals (`pacing.menu_order`), the gate under tactic 3, personality drift, the disobedient pick + its target service, the incapacitated commits, the $DB42 tension rolls, FIGHT-round tactic-3 commits, and every round end-to-end through `battle.simulate_round` (oracle idle; enemy scoring-row picks taken from the engine) — 6411 checks, 0 mismatches (`-c` coverage) | BATTLE_SKILL_SYSTEM §15.10.7b |
| `simulator/skillfx/cmd_orders.py` | Daze $98 (the disobedient loaf: MISS step + message, self row at commit and act) | `validate_command.py` |
| `simulator/raising.py` | the raising model: `create` / gains / `learn_scan` / `apply_gains` / `level_up` / `grow_*` / `breed` / `pedigree_k` / `birth` / `GameRNG` (MONSTER_DATA "Raising a monster (S130)") | `tools/census_raising.py` |
| `tools/census_raising.py` → `extracted/raising_census.json` | boots a ROM to the title in PyBoy and stub-calls the real routines with wRNG1/2 pinned before every call (create `$1402`, gains `$1302`, the learn loop around `$0605`, `ApplyLevelUp` `$510D`, breed `$1600`, birth), comparing every record byte the model predicts; `--rom`, `--project`, `--quick`, `--out`. Original ROM: create 962, level-ups 5,073 (675 learned, 484 past max level), breed 400 + 400 + 400 births, order control 921 — 0 mismatches (also 0 on the user's my-dwm-hack_22 build and the example project). **Verifier check 5** runs `--selftest` (the saved census is clean + a quick re-run) | its selftest |
| `editor2/core/balance.py` | the Balance service (ROADMAP P3.15a): how hard each key fight is, as the level a typical team of that point in the story needs to win 90 % / 50 % of the time (casual / strong rolled teams), gate dives at two walk bounds, the per-fight cache, what-if enemy overrides, the anchor reader — PROJECT_COMPILER §2.43 | test_compiler `test_balance_s130`; the anchor selftest re-derives fights |
| `simulator/planner.py` (S130 r2) | the player's orders: `make_planner(records, …)` → `planner(b, s)` (greedy expected value, every option tried on a board copy through `battle.simulate_round`, 3 common RNG draws; `.values`, `.threat`) — PROJECT_COMPILER §2.43 "player" | test_compiler `test_balance_player_s130` (MetalCut vs metal, heals a dying ally, deterministic, board untouched) |
| `editor2/core/kits.py` (S130 r2) | the player profile's skill KIT per story step: `step_pool`, `allowed_skills` (learn rows checked against the raised member), `kit_team`, `evaluate_kit`, `optimize_kit` (local search, `KIT_BUDGET`), `step_kit`, `describe` | test_compiler `test_balance_player_s130` |
| `editor2/core/dive.py` | battles per maze floor from `extracted/dive_census.json` (`battles_per_floor`, `floor_steps`, `steps_between`, …; the ROM only as a fallback) — GATE_GENERATION §4.4 | `tools/census_dive.py --selftest` |
| `tools/census_dive.py` → `extracted/dive_census.json` | 1,000 generated floors per maze size 3-15 (maze.MazeRom == the game) → shortest walk arrival → stairs, reachable cells, expected battles per (size, floor type, rate code); `--measure` = the PyBoy joypad walk of 12 floors / 11 types / codes 2-4 on the original ROM (every drain == the model). **Verifier check 5** runs `--selftest` (40 floors × 13 sizes + 24 battle cells re-derived) | its selftest; PyBoy 12/12 floors |
| `editor2/core/savefile.py` | a battery save's roster and party (SRAM offsets `$01C7` count, `$01C8` list, slots `$01FB + s*$95`, FX1 slots 20-39 at `$3124`) → `simulator.raising.Monster` | PyBoy WRAM after CONTINUE on the user's save (u22): every field equal; test_compiler `test_balance_s130` |
| `tools/build_balance_anchor.py` → `extracted/balance_vanilla.json` | the original game's difficulty curve, read-only: every story fight × {casual, strong} (l90, l50, the evaluation at l90 or 99) + every gate's dives × {direct, sweep}, from `balance.py` on BattleData(None), stable seeds, every CPU core by default (`--jobs N`); with the player profile ~5 h on 2 cores; RESUMABLE (S130 r2): each finished unit is appended to `balance_vanilla.json.partial` (tagged with SIM_VERSION + the raising digest) and a re-run continues; the Balance tab's **Build original-game numbers** button runs it locally (QProcess, Stop = SIGTERM ends the pool); `--only casual|strong|player`. `--selftest` SKIPs (exit 0) while a current-version `.partial` exists and the JSON is older. The S130.7 JSON in the tree was built on the user's M3 Max (~30 s per gate) and re-checked here (selftest OK). **Verifier check 5** runs `--selftest` (coverage, SIM_VERSION + raising digest, 3 fights + 1 dive re-derived == the JSON) | its selftest |
| `editor2/app/balance_tab.py` + `editor2/help/72_balance.md` | the Balance tab (Story curve / Team / Fight; EDITOR_DESIGN §5.9 as built S130) | test_app `s130_balance` |
| `editor2/core/encounters.py` `steps_between` (S130 fix) | the mean of counter // drain + 1 over the counter table (was counter / drain — one step short; GATE_GENERATION §4.4) | test_compiler S114/S130 check |

**F8 corpus recipe** (each line is `measure_f8_multihit.py NAME EID --frames 12000 <flags> --f8trim
--out simulator/f8_events.json --maxev 5000`, in this order; ROM u22.gbc, state `field.state`):

```
bi_p1 7 --skill 0x50 --php 400 --pmp 250 --ehp 900 --skip 0
bi_p3 7 --ecount 3 --skill 0x50 --php 400 --pmp 250 --ehps 300,900,900 --skip 3
bi_p3b 7 --ecount 3 --skill 0x50 --target 5 --php 400 --pmp 250 --ehps 900,300,700 --skip 7
bi_p3c 7 --ecount 3 --skill 0x50 --php 400 --pmp 250 --ehps 350,350,350 --skip 11
quad_p1 7 --skill 0x51 --php 400 --pmp 250 --ehp 1800 --skip 0
quad_p3 7 --ecount 3 --skill 0x51 --php 400 --pmp 250 --ehps 300,300,1500 --skip 5
quad_p3b 7 --ecount 3 --skill 0x51 --php 400 --pmp 250 --ehps 600,900,900 --skip 13 --pdd0b 0
quad_p2 7 --ecount 2 --skill 0x51 --php 400 --pmp 250 --ehps 250,1200 --skip 17
ch_p1 7 --skill 0x52 --php 400 --pmp 250 --ehp 900 --skip 0
ch_p1b 7 --skill 0x52 --php 400 --pmp 250 --ehp 900 --skip 21
ch_p3 7 --ecount 3 --skill 0x52 --php 400 --pmp 250 --ehps 600,100,600 --skip 5
ch_p3b 7 --ecount 3 --skill 0x52 --php 400 --pmp 250 --ehps 90,90,90 --skip 9
yh_p1 7 --skill 0x53 --php 400 --pmp 250 --ehp 900 --skip 0
yh_p1b 7 --skill 0x53 --php 400 --pmp 250 --ehp 900 --skip 31
yh_p3 7 --ecount 3 --skill 0x53 --php 400 --pmp 250 --ehps 120,600,200 --skip 3
rain_p1 7 --skill 0x57 --php 400 --pmp 250 --ehp 900 --skip 0
rain_p3 7 --ecount 3 --skill 0x57 --php 400 --pmp 250 --ehps 200,900,900 --skip 3
rain_p3b 7 --ecount 3 --skill 0x57 --target 5 --php 400 --pmp 250 --ehps 900,250,900 --skip 7
rain_p3c 7 --ecount 3 --skill 0x57 --php 400 --pmp 250 --ehps 900,250,600 --skip 15
meteor_p 7 --ecount 3 --skill 0xaf --php 400 --pmp 250 --ehps 300,300,300 --skip 0
meteor_p5 7 --ecount 3 --skill 0xaf --target 5 --php 400 --pmp 250 --ehps 300,300,300 --skip 4
bigsleep_p 7 --ecount 2 --skill 0xa7 --php 400 --pmp 250 --ehps 300,300 --skip 0
mp0_p 7 --ecount 3 --skill 0xa8 --php 400 --pmp 250 --ehps 300,300,300 --skip 0
bi_e1 55 --eskill 0x50 --ehps 999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 0 --frames 9000
bi_e3 101 --ecount 3 --eskills 0x50,0x50,0x50 --etargets 2,2,1 --ehps 999,999,999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 3 --frames 9000
quad_e1 55 --eskill 0x51 --ehps 999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 0 --frames 9000
quad_e3 101 --ecount 3 --eskills 0x51,0x51,0x51 --ehps 999,999,999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 5 --frames 9000
ch_e1 55 --eskill 0x52 --ehps 999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 0 --frames 9000
ch_e3 55 --ecount 3 --eskills 0x52,0x52,0x52 --ehps 999,999,999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 7 --frames 9000
yh_e1 55 --eskill 0x53 --ehps 999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 0 --frames 9000
yh_e3 101 --ecount 3 --eskills 0x53,0x53,0x53 --ehps 999,999,999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 9 --frames 9000
rain_e1 101 --eskill 0x57 --ehps 999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 0 --frames 9000
rain_e3 55 --ecount 3 --eskills 0x57,0x57,0x57 --etargets 1,0,2 --ehps 999,999,999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 11 --frames 9000
meteor_e 55 --ecount 2 --eskill 0xaf --ehps 999,999 --emp 200 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 0 --frames 9000
bi_dodge 55 --skill 0x50 --php 400 --pmp 250 --ehps 999 --est 7=0x04 --skip 0
quad_dodge 55 --ecount 2 --skill 0x51 --php 400 --pmp 250 --ehps 999,999 --est 7=0x04 --skip 2
rain_dodge 55 --ecount 3 --skill 0x57 --php 400 --pmp 250 --ehps 999,999,999 --est 7=0x04 --skip 4
bi_surr 55 --skill 0x50 --php 400 --pmp 250 --ehps 999 --pst 3=0x02 --skip 6
quad_surr 55 --ecount 2 --skill 0x51 --php 400 --pmp 250 --ehps 999,999 --pst 3=0x02 --skip 8
bi_iron 55 --skill 0x50 --php 400 --pmp 250 --ehps 999 --est 7=0x80 --skip 0
ch_iron 55 --skill 0x52 --php 400 --pmp 250 --ehps 999 --est 7=0xc0 --skip 0
yh_iron 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --est 7=0xc0 --skip 13
ch_p1c 7 --skill 0x52 --php 400 --pmp 250 --ehp 900 --skip 41
ch_p1d 7 --skill 0x52 --php 400 --pmp 250 --ehp 900 --skip 57
ch_p3c 7 --ecount 3 --skill 0x52 --php 400 --pmp 250 --ehps 300,300,300 --skip 63
yh_p3b 7 --ecount 3 --skill 0x53 --php 400 --pmp 250 --ehps 300,300,300 --skip 71
bi_sleep 55 --skill 0x50 --php 400 --pmp 250 --ehps 999 --est 2=0x8c --skip 0
quad_sleep 55 --ecount 2 --skill 0x51 --php 400 --pmp 250 --ehps 999,999 --est 2=0x8c --skip 3
rain_sleep 55 --ecount 3 --skill 0x57 --php 400 --pmp 250 --ehps 999,999,999 --est 2=0x8c --skip 5
ch_sleep 55 --skill 0x52 --php 400 --pmp 250 --ehps 999 --est 2=0x8c --skip 7
yh_sleep 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --est 2=0x8c --skip 9
quad_sleep_e 101 --eskill 0x51 --emp 200 --ehps 999 --skill 0x2b --target 0 --php 400 --pmp 250 --pst 2=0x8c --skip 11
bi_block 55 --skill 0x50 --php 400 --pmp 250 --ehps 999 --est 6=0x04 --skip 13
ch_res1 55 --skill 0x52 --php 400 --pmp 250 --ehps 999 --eres6 0x10 --skip 15
ch_res2 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --eres6 0x20 --skip 17
ch_res3 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --eres6 0x30 --skip 19
ch_res1g 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --eres6 0x10 --est 5=0x40 --skip 21
ch_res2a 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --eres6 0x20 --est 5=0x80 --skip 23
yh_eres 101 --eskill 0x53 --emp 200 --ehps 999 --skill 0x2b --target 0 --php 400 --pmp 250 --pres6 0x20 --skip 25
meteor_e3 55 --ecount 3 --eskills 0xaf,0x50,0x50 --etargets 1,0,0 --emp 200 --ehps 999,999,999 --skill 0x2b --target 0 --php 400 --pmp 250 --skip 27
meteor_p6 55 --ecount 3 --skill 0xaf --target 6 --php 400 --pmp 250 --ehps 300,300,300 --skip 29
quad_sleep2 55 --skill 0x51 --php 400 --pmp 250 --ehps 999 --est 2=0x8c --skip 31
yh_sleep2 55 --skill 0x53 --php 400 --pmp 250 --ehps 999 --est 2=0x8c --skip 33
quad_sleep_e2 101 --eskill 0x51 --emp 200 --ehps 999 --skill 0x2b --target 0 --php 400 --pmp 250 --pst 2=0x8c --skip 35 --frames 6000
```

**F9 corpus recipe** (`python3 simulator/measure_f9.py NAME EID FLAGS --out <file>` on u22.gbc +
field.state, one JSON per battle, merged in this order; the tags `calcdef_in roll_in final_54e7
status_in status_roll statchance_in hit_path miss_path curse_stage miss_pass helper_dmg h_biattack
h_callhelp h_rainslash h_meteor h_bigsleep h_mp0 dm_tail h_demagic tf_copy dragon_form h_bedragon
h_transform guard_redir` are dropped before gzip):

```
p_tatsu_a 7 --ecount 3 --skill 0x84 --target 0 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000
p_tatsu_b 7 --ecount 3 --skill 0x84 --target 0 --force-rounds 3 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 23
p_diago_a 7 --ecount 3 --skill 0x85 --target 0 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 7
p_diago_b 7 --ecount 3 --skill 0x85 --target 0 --force-rounds 3 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 31
p_samsi_a 7 --ecount 3 --skill 0x86 --target 0 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 13
p_samsi_b 7 --ecount 3 --skill 0x86 --target 0 --force-rounds 3 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 37
p_bazoo_a 7 --ecount 3 --skill 0x87 --target 0 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 19
p_bazoo_b 7 --ecount 3 --skill 0x87 --target 0 --force-rounds 3 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 41
p_call1 7 --ecount 2 --skill 0x84 --target 0 --force-rounds 2 --pskill1 0x87 --force1-rounds 3 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 3000 --frames 60000 --skip 43
e_tatsu_a 7 --ecount 3 --eskill 0x84 --etarget 4 --force-rounds 2 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 3
e_tatsu_b 7 --ecount 3 --eskill 0x84 --etarget 4 --force-rounds 3 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 29
e_diago_a 7 --ecount 3 --eskill 0x85 --etarget 4 --force-rounds 2 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 5
e_diago_b 7 --ecount 3 --eskill 0x85 --etarget 4 --force-rounds 3 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 33
e_samsi_a 7 --ecount 3 --eskill 0x86 --etarget 4 --force-rounds 2 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 9
e_samsi_b 7 --ecount 3 --eskill 0x86 --etarget 4 --force-rounds 3 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 47
e_bazoo_a 7 --ecount 3 --eskill 0x87 --etarget 4 --force-rounds 2 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 11
e_bazoo_b 7 --ecount 3 --eskill 0x87 --etarget 4 --force-rounds 3 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 51
e_call1 7 --ecount 1 --eskill 0x85 --etarget 4 --force-rounds 3 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 53
p_quake 7 --ecount 3 --skill 0x84 --target 0 --force-rounds 1 --pskill1 0xe6 --ptarget1 4 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=150 --maxev 2500 --frames 60000 --skip 2
p_wipe 7 --ecount 3 --skill 0x87 --target 0 --force-rounds 3 --php 300 --ehp 999 --pmpall 300 --pstat atk=40,hp=120 --estat dfn=300,atk=400 --maxev 3000 --frames 60000 --skip 57
p_ch_b1 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000
p_ch_b2 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --skip 61
p_ch_w1 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 5
p_ch_w2 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 67
p_ch_w3 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 71
p_ch_w4 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 73
p_ch_w5 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 79
p_ch_w6 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 83
e_ch_b1 7 --ecount 3 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --skip 3
e_ch_w1 7 --ecount 3 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 0 --skip 9
e_ch_w2 7 --ecount 3 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 0 --skip 89
p_dragon_a 7 --ecount 3 --sched 1:0xd5:0,3:0xd5:0 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 3000 --frames 60000
p_dragon_b 7 --ecount 3 --sched 1:0xd5:0,2:0x80:0 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 3000 --frames 60000 --skip 17
p_dragon_c 7 --ecount 2 --sched 1:0xd5:0,2:0xd5:0,3:0xd5:0,4:0xd5:0 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 3000 --frames 60000 --skip 29
e_dragon_a 7 --ecount 3 --esched 1:0xd5:4 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 4
e_dragon_b 7 --ecount 3 --esched 1:0xd5:4,3:0xd5:4,5:0xd5:4 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 21
e_dragon_c 7 --ecount 1 --esched 1:0xd5:4,2:0xd5:4,3:0xd5:4 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --poke 0xDD0F=0 --maxev 3000 --frames 60000 --skip 27
p_tf_a 7 --ecount 3 --sched 1:0x29:4 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 3000 --frames 60000
p_tf_b 7 --ecount 3 --sched 1:0x29:5,2:0x81:0,3:0x81:0 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=60 --maxev 3000 --frames 60000 --skip 13
p_tf_h 7 --ecount 2 --esched 1:0x87:4 --sched 2:0x29:7 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=60 --maxev 3000 --frames 60000 --skip 15
e_tf_a 7 --ecount 3 --esched 1:0x29:0 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 6
e_tf_b 7 --ecount 3 --esched 1:0x29:2,2:0x29:1:5 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 3000 --frames 60000 --skip 25
e_tf_c 7 --ecount 2 --esched 1:0x29:1 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --poke 0xDD0F=0 --maxev 3000 --frames 60000 --skip 35
p_run_a 7 --ecount 3 --sched 1:0xdb:0 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 1500 --frames 40000
p_run_b 7 --ecount 3 --sched 2:0xdb:0 --pskill1 0xdb --force1-rounds 1 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 1500 --frames 40000 --skip 9
e_run_a 7 --ecount 3 --esched 1:0xdb:4 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 1500 --frames 40000 --skip 2
e_run_b 7 --ecount 3 --eskills 0xdb,0xdb,0xdb --etargets 4,5,6 --force-rounds 1 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 1500 --frames 40000 --skip 8
e_run_w 7 --ecount 3 --esched 1:0xdb:4 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 1500 --frames 40000 --db73 0 --skip 12
p_smash_b 7 --ecount 3 --skill 0xa4 --target 5 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 1500 --frames 40000
p_smash_w 7 --ecount 3 --skill 0xa4 --target 4 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 1500 --frames 40000 --db73 0 --skip 3
p_smash_h 7 --ecount 2 --esched 1:0x86:4 --sched 2:0xa4:4,3:0xa2:4 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=60 --maxev 2500 --frames 50000 --skip 15
p_horror_w 7 --ecount 3 --skill 0xa2 --target 4 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --maxev 1500 --frames 40000 --db73 0
p_horror_g 7 --ecount 3 --skill 0xa2 --target 5 --force-rounds 2 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=100 --poke 0xDD20=0xFF --maxev 1500 --frames 40000 --skip 7
e_smash_w 7 --ecount 3 --eskill 0xa4 --etarget 1 --force-rounds 2 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 1500 --frames 40000 --db73 0
e_horror_w 7 --ecount 3 --eskill 0xa2 --etarget 0 --force-rounds 2 --emp 200 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 1500 --frames 40000 --db73 0 --skip 5
p_ch_w7 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 97
p_ch_w8 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 101
p_ch_w9 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 107
p_ch_w10 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 109
p_ch_w11 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 113
p_ch_w12 7 --ecount 3 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 127
p_ch_h1 7 --ecount 2 --esched 1:0x84:4 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --emp 200 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 131
p_ch_h2 7 --ecount 2 --esched 1:0x86:4 --skill 0x39 --target 4 --pskill1 0x39 --prefill 999 --php 999 --ehp 999 --pmpall 999 --emp 200 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 0 --skip 137
e_ch_h1 7 --ecount 3 --sched 1:0x85:0 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 0 --skip 139
p_tf_k 7 --ecount 3 --sched 1:0x29:4,2:0x29:5 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=200 --maxev 3000 --frames 60000 --skip 149
p_helper_tf 7 --ecount 2 --sched 1:0x86:0,2:0x29:4:3 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=60 --maxev 3000 --frames 60000 --skip 151
p_chh0 7 --ecount 3 --esched 1:0x84:4 --sched 2:0x39:4,3:0x39:4,4:0x39:4,5:0x39:4,6:0x39:4,7:0x39:4,8:0x39:4,9:0x39:4,10:0x39:4,11:0x39:4,12:0x39:4,13:0x39:4,14:0x39:4,15:0x39:4,16:0x39:4,17:0x39:4,18:0x39:4,19:0x39:4,20:0x39:4,21:0x39:4,22:0x39:4,23:0x39:4,24:0x39:4,25:0x39:4,26:0x39:4,27:0x39:4,28:0x39:4,29:0x39:4,30:0x39:4,31:0x39:4,32:0x39:4,33:0x39:4,34:0x39:4,35:0x39:4,36:0x39:4,37:0x39:4,38:0x39:4,39:0x39:4,40:0x39:4,41:0x39:4,42:0x39:4,43:0x39:4,44:0x39:4 --pskill1 0x39 --force1-rounds 45 --prefill 999 --php 999 --ehp 999 --pmpall 999 --emp 200 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 1 --skip 157
p_chh1 7 --ecount 3 --esched 1:0x86:4 --sched 2:0x39:4,3:0x39:4,4:0x39:4,5:0x39:4,6:0x39:4,7:0x39:4,8:0x39:4,9:0x39:4,10:0x39:4,11:0x39:4,12:0x39:4,13:0x39:4,14:0x39:4,15:0x39:4,16:0x39:4,17:0x39:4,18:0x39:4,19:0x39:4,20:0x39:4,21:0x39:4,22:0x39:4,23:0x39:4,24:0x39:4,25:0x39:4,26:0x39:4,27:0x39:4,28:0x39:4,29:0x39:4,30:0x39:4,31:0x39:4,32:0x39:4,33:0x39:4,34:0x39:4,35:0x39:4,36:0x39:4,37:0x39:4,38:0x39:4,39:0x39:4,40:0x39:4,41:0x39:4,42:0x39:4,43:0x39:4,44:0x39:4 --pskill1 0x39 --force1-rounds 45 --prefill 999 --php 999 --ehp 999 --pmpall 999 --emp 200 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 1 --skip 163
p_chh2 7 --ecount 3 --esched 1:0x87:4 --sched 2:0x39:4,3:0x39:4,4:0x39:4,5:0x39:4,6:0x39:4,7:0x39:4,8:0x39:4,9:0x39:4,10:0x39:4,11:0x39:4,12:0x39:4,13:0x39:4,14:0x39:4,15:0x39:4,16:0x39:4,17:0x39:4,18:0x39:4,19:0x39:4,20:0x39:4,21:0x39:4,22:0x39:4,23:0x39:4,24:0x39:4,25:0x39:4,26:0x39:4,27:0x39:4,28:0x39:4,29:0x39:4,30:0x39:4,31:0x39:4,32:0x39:4,33:0x39:4,34:0x39:4,35:0x39:4,36:0x39:4,37:0x39:4,38:0x39:4,39:0x39:4,40:0x39:4,41:0x39:4,42:0x39:4,43:0x39:4,44:0x39:4 --pskill1 0x39 --force1-rounds 45 --prefill 999 --php 999 --ehp 999 --pmpall 999 --emp 200 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 1 --skip 167
p_chh3 7 --ecount 3 --esched 1:0x85:4 --sched 2:0x39:4,3:0x39:4,4:0x39:4,5:0x39:4,6:0x39:4,7:0x39:4,8:0x39:4,9:0x39:4,10:0x39:4,11:0x39:4,12:0x39:4,13:0x39:4,14:0x39:4,15:0x39:4,16:0x39:4,17:0x39:4,18:0x39:4,19:0x39:4,20:0x39:4,21:0x39:4,22:0x39:4,23:0x39:4,24:0x39:4,25:0x39:4,26:0x39:4,27:0x39:4,28:0x39:4,29:0x39:4,30:0x39:4,31:0x39:4,32:0x39:4,33:0x39:4,34:0x39:4,35:0x39:4,36:0x39:4,37:0x39:4,38:0x39:4,39:0x39:4,40:0x39:4,41:0x39:4,42:0x39:4,43:0x39:4,44:0x39:4 --pskill1 0x39 --force1-rounds 45 --prefill 999 --php 999 --ehp 999 --pmpall 999 --emp 200 --pstat atk=40 --estat dfn=300,atk=100 --maxev 4000 --frames 90000 --db73 1 --skip 173
e_chh0 7 --ecount 3 --sched 1:0x84:0 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 0 --skip 179
e_chh1 7 --ecount 3 --sched 1:0x86:0 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 1 --skip 181
e_chh2 7 --ecount 3 --sched 1:0x87:0 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 0 --skip 191
e_chh3 7 --ecount 3 --sched 1:0x85:0 --eskills 0x39,0x39,0x39 --etargets 0,0,0 --erefill 999 --emp 999 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=300 --estat dfn=300 --maxev 4000 --frames 90000 --db73 1 --skip 193
n_hargon 203 --ecount 1 --php 999 --ehp 999 --pmpall 300 --pstat atk=40,dfn=400,hp=999 --estat dfn=300 --maxev 4000 --frames 90000
p_tf_surge 7 --ecount 3 --sched 1:0x29:1,2:0x81:0,3:0x81:0,4:0x2b:0 --php 999 --ehp 999 --pmpall 300 --pstat atk=40 --estat dfn=300,atk=60 --maxev 2500 --frames 50000
```
