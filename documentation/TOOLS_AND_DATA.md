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
| wram_usage.json | audit_wram.py | S54; REGENERATED S55 (curated arrays added: attr staging $C200, screen staging $C300 ×$200, battle tile buffer $C500, audio channels $DD80-$DE2B, battle stat tables — gaps 51→34; the S54 relocation candidates $C20D/$C42B were FALSE, see KEY_LESSONS S55). Selftest re-pinned S55: buffers still class-B (accepted legacy), relocated labels at $DE74 clean, audio ceiling pinned. Regenerate with the tool; not ROM-derived alone (also parses docs + patches). REGENERATED S56: curated staging pseudo-slot entry added ($D665-$D78E, monster-array indices $14/$15); gaps 34→31; selftest re-pinned (staging extent). |
| monster_walkers.json | map_monster_walkers.py | **NEW (S56, CF1).** The monster-array access map: all 44 `ld [$cac0],a` writer sites + 60 register/stride walkers classified (party-only / all-slot / farm-write / single-slot / staging), membership semantics, exp-share model, roster mutation path table, staging pseudo-slots. Self-checking: writer-set drift or missing labels abort. Owning prose: MONSTER_DATA "Party/farm boundary semantics". |
| songs.json | enumerate_songs.py | **NEW (S61, M1).** Full sound enumeration: 86 sounds / 158 channel streams from the master table @ ROM0 $3466 (banks $1C/$1D/$1E), each stream statically walked to termination (zero overruns), with per-channel slot/hw/seq/extent/header. Owning prose: SOUND_SYSTEM.md. |
| monsters_full.json | dump_monsters.py | 221 monsters, all 43 fields. Verified identical. |
| encounters.json | dump_encounters.py | 32 gates / 125 pools. Verified identical. |
| boss_table.json | dump_boss_table.py | $4897 table, 32 gates. Verified identical. |
| all_exits.json | dump_all_exits.py | Verified identical. |
| enemy_stats.json | dump_enemy_stats.py | **RECONCILED this session.** Full 25-byte layout now decoded: +1..2 exp LE16, +3 joinability, +17..20 ai_weights, +21..24 skills. 487/487 match. |
| ~~skills.json~~ | ~~dump_skills.py~~ | **RETIRED S59 — file DELETED, do not recreate.** Superseded by `skill_records.json`. It read the skill function table as 256 entries; the table is 222 (ids $00–$DD, $52:$4011..$41CC, 444 B), ending where the first handler begins (`SkillBlaze` @ $52:$41CD, bytes `CD FF 5B` = `call $5BFF`). The extra **34** ids (222–255, not 33) were that handler's CODE decoded as pointers — hence blank names and bogus `$FFCD`/`$CD5B`/`$E7CD` addresses. All readers ported to `skill_records.json` S59: `gen_skill_table_db.py`, `gen_enemy_stats_db.py`, `gen_monster_db.py` (the pre-S59 note claiming `gen_name_tables_db.py` was the sole reader was backwards — that tool declared the path but never opened it; the dead constant is gone). `dump_skills.py` is now an inert documented tombstone (exits non-zero). |
| skill_records.json | gen_skill_records.py | **NEW (S44).** 222 records ($00–$DD), the editor source of truth. Per skill: name, `kind` (155 skill / 37 item_effect / 30 internal), mp_cost (ALL=999), handler + shared-handler group, learn block ($06:$50E0), prereqs, family code, monster/enemy usage; `_generator` key lists all 6 source addrs. Round-trip proven by `build_skill_tables.py --selftest` (function/MP/learn tables re-emit byte-identical). |
| skill_id_bucket_map.json | map_skill_id_buckets.py | **NEW (S48).** The de-aliasing FOUNDATION for S2d: every place the battle engine buckets the working skill id (`$db8a`, 254 reads / 9 banks), classified (equality/range/table-index) with per-gate verdicts for a custom id (`≥ $DE`); the verified fork points (record `$54:$4013` keystone, function, MP, sound, anim, name, learn-req); the high-range special gates; the full cast pipeline (production→consumption); the byte-neutral fork feasibility proof; and the SameBoy hardware-verification block. Self-checking: the tool re-derives the load-bearing anchors from the ROM and aborts on drift. See BATTLE_SKILL_SYSTEM.md §12. |
| text_id_map.json | dump_text_id_map.py | **NEW GENERATOR this session.** 2,061 entries (vs 2,067 committed). All 2,061 are structurally identical (id/bank/index/addr). 6 "missing" are zero-padding junk the old generator decoded as "0000…" — exclusion is strictly more correct. Text decoding improved (proper charmap, DTE, control codes). |
| map_table.json | dump_map_table.py | **REWRITTEN this session.** Fixed TWO bugs: (1) interact/exit label swap (DOC_AUDIT A.11), (2) screen enumerator stopped at first $FFFF hole, dropping a third of rooms (exits 541→812, NPCs 961→1320). Ground-truth verified (GreatTree→Well exit found). |
| exit_table.json | dump_map_table.py | Regenerated with fixed semantics (trigger coords, dest_map_type, spawn). |
| room_connections.json | dump_map_table.py | Regenerated with fixed connection graph. 262→361 connected rooms. |
| all_scripts.json | dump_all_scripts.py | **BRANCH-FOLLOWING added this session.** Follows 9 branch opcodes ($00/$01/$0E/$14/$15/$27/$28/$2C/$37) via work-queue. 732 scripts, 810 unique WriteRAM locations (was 482 linear-only; ROM ground truth 866 after false positives = 93.5% coverage). 56 unreached WriteRAMs are in alternate dispatch paths (entry 1/2 tables). Canonical room names from editor/editor.py (96 entries). New `branch_targets` field per script. |
| event_flags_complete.json | analyze_event_flags.py | **REWRITTEN this session.** Now reads all_scripts.json (branch-following) instead of linear ROM scan. 328 flags, 298 with sets (was 92). 29 check-only anomalies (was 219). Includes collision zones, SRAM boundary. |
| breeding_tables.json | build_breeding.py | **NEW (Session 13, B1 keystone).** Round-trip-faithful decode of BOTH vanilla breeding tables (special $16:$4B30 825×5; family $16:$4974 222 pairs). `--selftest` proves re-emission is byte-identical to the ROM. Independently reconciled with hand-authored breeding_complete.json (825/825 + 197/197, 0 diffs). Name-annotated; `_generator` stamped. |
| monster_sprites.json | extract_monster_sprites.py | **NEW (Session 22, GFX-1); REGENERATED Session 23 (all 221 — the shipped copy was a 3-monster subset, a data defect now fixed).** All 221 monsters' battle + follower sprites: species → gfx-ID, bank, index, stream addr/len, declen, tile count, grid, and decoded 2bpp tile bytes (hex, regenerable without PNGs). Count-parameterised (`--count`). Decoded via `dwm/sprite_codec.py`; `--png` writes images to `extracted/monster_sprites/`. |
| monster_palettes.json | extract_monster_palettes.py | **NEW (Session 23, GFX-2).** All 221 per-species BATTLE palettes from `MonsterBattlePalettes` `$17:$62FD` (8 B/species, 4 RGB555 `[c0, c1=$6bff backdrop, c2, c3=$0000 black]`). Recolour via `build_sprite_swap.py --palette`. |
| follower_layouts.json | extract_monster_follower_layouts.py | **REGENERATED & REPLACED Session 25 (GFX-4).** Now the COMPLETE **155 distinct follower layouts** decoded from the REAL species-indexed dispatch (`$10/$11:$407f`), incl. the 3-entry small/blob layouts the S24 brute-force scan dropped (old count 118). Per layout: six frames as `{dy,dx,tile,xflip}`, sharing classification, usage count, canonical `$10/$11` example level-2 addr. *(Supersedes the S24 `extract_follower_layouts.py` output; that tool is retained but its bank-`$05` example addrs are the ObjTest-viewer path, not the follower path.)* |
| monster_follower_layouts.json | extract_monster_follower_layouts.py | **NEW (Session 25, GFX-4).** Every species (0–220) → `{bank, l1_index, l1_addr, l2_addr, attr_base, layout_id, sharing}`, traced through the real follower dispatch (`$ffc7=species+$10` → bank `$10`/`$11` `$407f` level-1 table). `--selftest` reproduces the Healer (sp9, sharing) + DarkDrium (sp214, non-sharing) anchors byte-for-byte and confirms all 215 collectible species map. |
| library_layouts.json | resection_library_tables.py --dump-json | **NEW (Session 27, Phase D).** All **29** bank-`$12` monster-library / family-tab menu window-draw layouts (contiguous run `$710c..$7b9b`) decoded to `{addr, label, pos, length, ld_de_ref, rows[]}`. `$d8`=newline, `$d9`=terminator; rows are literal tile ids. 7 layouts are direct `ld de,$imm` entry points (`ld_de_ref:true`); incl. the 380-B `$79c6` 18×20 full-screen view. Same tool re-sections the asm (labels-only, build stays `1ca6579…`). |

| species_slot_map.json | map_species_slots.py | **S28 (N1).** The 256-slot species-ID map: per id → occupancy class (real 0–214 / special 215–219 / empty 220–223 / free 224–255) + per-table presence. Self-checking anchors. |
| library_grouping.json | build_library_table.py | **S19 (B7), re-owned S30.** The build-time family→members grouping table emitted into bank $12 free space; owns the 3 unseen-marker sites ($E0→$FE). Inputs: spirit_family.json + new_species.json. `--selftest` proves vanilla parity. |
| battle_animations.json | decode_battle_animations.py | **S47 (S2c-anim).** All 45 battle-effect animations decoded (routine ids, side-table params, $0d = no visual); emulator-verified renderer model. See BATTLE_SKILL_SYSTEM §11. |
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
| breeding_family_defaults.json | B4 family-default overrides: positional `{result,p1,p2}` list applied in place to `$16:$4974` (offspring species == slot). Includes the shadow avoid-list inline. | tools/build_breeding.py --emit-family → patches/bank_016.asm |
| breeding_special.json | B5 full special-table spec: `base:"rom"` + in-place `overrides` (edit any base entry, by `index` or by parent `match`) + `appends` (new entries past 824). The SINGLE authored source for the whole special table; bank `$16` stays vanilla. | tools/build_breeding.py --emit-special → patches/bank_069.asm |
| breeding_family_reassign.json | B6 family reassignment spec: `{id,name,from,to}` list of same-size family-byte edits ($03:$4461+$00). `from` is validated == vanilla at build time. | tools/build_family_reassign.py --emit → patches/bank_003.asm |
| custom_layouts/room_6b_medalman.json | 20×16 tile grid for Room $6B — user-designed MedalMan tileset room (v28) | tile_layout_compiler.py → bank_064.asm |
| *(Room $6B current = gate-tile room)* | **S39:** Room $6B is now the Gate-of-Beginning maze-tileset room (gfx-ID `$280D`), authored directly in **`tools/build_gate_room.py`** (no JSON) → `patches/bank_064.asm`. Sandy island: ocean-wall border, 2×2 tree/dune/pit metatiles, per-position palette. Builds the v5 ROM. See GATE_GENERATION.md §7.2–7.3. | tools/build_gate_room.py → bank_064.asm |
| family_icons.json | S20: the 10 vanilla family ICON tiles ($4F:$4110-$41A0, text bytes $10-$19) decoded as 8×8 grids + the free $1A slot + the authored Spirit icon (Variants A/B). Round-trip safe (decode→encode == ROM). `_generator` stamped. | tools/build_family_icon.py → patches/bank_04f.asm |
| new_species.json | Phase-N authored spec (normalized/stamped by build_new_species.py): first_free_id 224, high bank $6A, per-species info/stats/encounter/name blocks. G3 (ROADMAP) will fold ALL Gorbunok artifacts into this schema. | tools/build_new_species.py → patches/bank_003/006a/014/001.asm |
| spirit_family.json | B6 authored spec: Spirit-family reassignment list (`{id,name,from,to}`), `from` validated vs vanilla. | build_family_reassign.py, build_library_table.py |
| skill_faq.json | **EXTERNAL ground truth** (community skill FAQ, transcribed — `_source`, deliberately NOT `_generator`): per-skill MP/target/learn/family data used to validate S44/S46 decodes. | build_skill_faq.py (writer); gen_skill_records.py + docs (validation) |
| npc_names.json | Hand-curated naming reference: sprite/type names, NPC labels, room-name overrides. No generator by design. | dump_all_npcs.py, editor tooling |

### Tier S — Stable analysis output (generator not in repo; data is ROM-derived and unchanging)
| File | Contents | Used by |
|------|----------|---------|
| crossbank_calls.json | 1,028 cross-bank calls + dispatch tables (all 105 banks) | reference |
| room_palettes.json | 81 room palette sets (raw GBC palette values) | render_rooms.py |
| decoded_text.json | Per-bank decoded text ($42–$4E) | gen_bank41_remaining_db.py |

### Tier L — Legacy / superseded (safe to delete)
| File | Why |
|------|-----|
| monsters.json | Old schema, superseded by monsters_full.json. **Already absent before S51** (stale queue row). ⚠️ `dump_monsters.py` still WRITES this legacy schema when run — and reads monsters_full for names, so the Tier-A "monsters_full ← dump_monsters" attribution is suspect (open defect, PROJECT_STATE). |
| event_flags.json | Superseded by event_flags_complete.json. **Was already absent** (untracked at HEAD; stale Tier-L row, verified S51). |
| edits.json | Legacy Streamlit-editor patch store. **Was already absent** (untracked at HEAD; stale Tier-L row, verified S51 — legacy tools already tolerate absence). |
| breeding_extra_recipes.json | B3 append path, superseded by B5. **DELETED S51** (was tracked → recoverable from git; content = one self-described capacity-proof TEST recipe, BattleRex×MadCat→DracoLord, archived in SESSION_HISTORY B3); `build_breeding.py --emit-relocation` is marked LEGACY and tolerates absence (emits base table only). |

Everything else (all_text, all_transitions, transitions, npc_catalog,
npc_with_text, npc_text_mapping, free_space, gate_names, orphan_pointers,
pointer_tables, routing_table, screen_counts, sprite_reference,
text_blobs): regenerable from named dumpers; not
freshness-tested this session — verify before relying on one for the
editor (snapshot → regen → diff).

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
`compress_tiles.py` / `decompress_tiles.py` (✅ roundtrip) ·
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
`extracted/follower_layouts.json` (155 layouts, incl. 3-entry blobs). `--selftest` reproduces the
Healer/DarkDrium anchors byte-for-byte + asserts 215/215 collectible coverage. Delivered WITH both JSONs) ·
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
the bytes in `patches/bank_04f.asm` at the Spirit slot. Delivered WITH `family_icons.json`. **(CORRECTED 2026-06-19: Spirit ships on byte $19/`$41A0`, overwriting vanilla ???; the free $1A/`$41B0` slot is left blank — it is not fill-immune at runtime. selftest now checks $41A0.)**
The Spirit icon insert itself is `patches/bank_04f.asm` (same-size 16-byte tile at
$41B0, zero shift; bank $4F otherwise byte-identical to vanilla).

### Builders / decoders added after the 06-13 audit (rows synced S51)
`enumerate_songs.py` — S61 (M1): sound-engine enumerator + stream decoder.
Reads the master table @ ROM0 $3466, per-id channel records, walks every
sequence stream (2-byte pairs, $FC jump follow, revisit = loop) to
termination; `--decode <id>` prints a track note-by-note; `--json` emits
`extracted/songs.json`. Engine facts it encodes are documented in
SOUND_SYSTEM.md; exit non-zero on any stream overrun. ·

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
same-size wild-encounter edit, name wiring, from new_species.json; SameBoy-proven. ·
`build_new_species_follower.py` — G1 follower-art path for ids ≥224 (all-8-copy
gfx-ID fork + attr fix); standalone TEST-ROM emitter during bring-up. ·
`bake_follower_overflow.py` — emits a sprite-overflow bank ($7E…) as a STATIC patch
file from follower art sources (the baked-into-patches/ path, vs test ROMs). ·
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
`resection_skill_tables.py` — **NEW S51**, Phase-D item (2b): converts
`SkillMPCostTable` ($07:$570C) + `SkillLearnReqTable` ($06:$50E0) from fake
instructions to labeled `dw`/`db` in BOTH trees via the probe-build method;
byte-perfect asserted; keeps outside-referenced fake-artifact labels at exact
offsets; idempotent (`--check`). ·
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
gen_encounter_db; do NOT archive) ·
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
`randomize.py` (writes monsters_full.json when run — never commit after)

## 3. Rules

1. Commit the tool with the data, same change. No exceptions.
2. Any dumper that writes extracted/ should stamp a `"_generator"` key.
3. Editor (Phase 2/3) consumes ONLY Tier A files.
