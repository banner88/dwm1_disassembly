# TOOLS & EXTRACTED DATA — Audited Manifest

Audited 2026-06-13. Method: regenerated dumps against the original ROM,
diffed vs committed JSON, dry-ran every generator, traced every JSON to
its writer/readers. 62 tools, 37 JSON files.

---

## 1. extracted/ — JSON inventory

### Tier A — Regenerable & verified fresh
Regen produces identical output to committed file. Safe to re-run.
| File | Generator | Notes |
|------|-----------|-------|
| monsters_full.json | dump_monsters.py | 221 monsters, all 43 fields. Verified identical. |
| encounters.json | dump_encounters.py | 32 gates / 125 pools. Verified identical. |
| boss_table.json | dump_boss_table.py | $4897 table, 32 gates. Verified identical. |
| all_exits.json | dump_all_exits.py | Verified identical. |
| enemy_stats.json | dump_enemy_stats.py | **RECONCILED this session.** Full 25-byte layout now decoded: +1..2 exp LE16, +3 joinability, +17..20 ai_weights, +21..24 skills. 487/487 match. |
| skills.json | dump_skills.py | **NEW GENERATOR this session.** 256 skills from SkillNamePtrTable ($41:$4539) + SkillFunctionTable ($52:$4011). 223 real skills match; 33 diffs are unused slots (empty names, same function addrs). Consumers (gen_skill_table_db, gen_monster_db) produce byte-identical asm. |
| text_id_map.json | dump_text_id_map.py | **NEW GENERATOR this session.** 2,061 entries (vs 2,067 committed). All 2,061 are structurally identical (id/bank/index/addr). 6 "missing" are zero-padding junk the old generator decoded as "0000…" — exclusion is strictly more correct. Text decoding improved (proper charmap, DTE, control codes). |
| map_table.json | dump_map_table.py | **REWRITTEN this session.** Fixed TWO bugs: (1) interact/exit label swap (DOC_AUDIT A.11), (2) screen enumerator stopped at first $FFFF hole, dropping a third of rooms (exits 541→812, NPCs 961→1320). Ground-truth verified (GreatTree→Well exit found). |
| exit_table.json | dump_map_table.py | Regenerated with fixed semantics (trigger coords, dest_map_type, spawn). |
| room_connections.json | dump_map_table.py | Regenerated with fixed connection graph. 262→361 connected rooms. |
| all_scripts.json | dump_all_scripts.py | **BRANCH-FOLLOWING added this session.** Follows 9 branch opcodes ($00/$01/$0E/$14/$15/$27/$28/$2C/$37) via work-queue. 732 scripts, 810 unique WriteRAM locations (was 482 linear-only; ROM ground truth 866 after false positives = 93.5% coverage). 56 unreached WriteRAMs are in alternate dispatch paths (entry 1/2 tables). Canonical room names from editor/editor.py (96 entries). New `branch_targets` field per script. |
| event_flags_complete.json | analyze_event_flags.py | **REWRITTEN this session.** Now reads all_scripts.json (branch-following) instead of linear ROM scan. 328 flags, 298 with sets (was 92). 29 check-only anomalies (was 219). Includes collision zones, SRAM boundary. |
| breeding_tables.json | build_breeding.py | **NEW (Session 13, B1 keystone).** Round-trip-faithful decode of BOTH vanilla breeding tables (special $16:$4B30 825×5; family $16:$4974 222 pairs). `--selftest` proves re-emission is byte-identical to the ROM. Independently reconciled with hand-authored breeding_complete.json (825/825 + 197/197, 0 diffs). Name-annotated; `_generator` stamped. |

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
| custom_layouts/room_6b_medalman.json | 20×16 tile grid for Room $6B — user-designed MedalMan tileset room (v28, current) | tile_layout_compiler.py → bank_064.asm |

### Tier S — Stable analysis output (generator not in repo; data is ROM-derived and unchanging)
| File | Contents | Used by |
|------|----------|---------|
| crossbank_calls.json | 1,028 cross-bank calls + dispatch tables (all 105 banks) | reference |
| room_palettes.json | 81 room palette sets (raw GBC palette values) | render_rooms.py |
| decoded_text.json | Per-bank decoded text ($42–$4E) | gen_bank41_remaining_db.py |

### Tier L — Legacy / superseded (safe to delete)
| File | Why |
|------|-----|
| monsters.json | Old schema, superseded by monsters_full.json |
| event_flags.json (1 KB) | Superseded by event_flags_complete.json (146 KB) |
| edits.json | Legacy Streamlit-editor patch store; frozen editor |

Everything else (all_text, all_transitions, transitions, npc_catalog,
npc_with_text, npc_text_mapping, free_space, gate_names, orphan_pointers,
pointer_tables, routing_table, screen_counts, sprite_reference,
text_blobs): regenerable from named dumpers; not
freshness-tested this session — verify before relying on one for the
editor (snapshot → regen → diff).

## 2. tools/ — classification (62 files)

### Guardrail
`verify_integrity.py` — run at every session start/end.

### Core pipeline (editor sits on these)
`compile_script.py` (✅ --test passes) · `decompile_script.py` (✅) ·
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
`gen_script_banks.py` · `render_rooms.py` · `dwm/` package ·
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

### Prototype editor (towards_editor/)
`DWM1_Multi_Tileset_Editor.html` — standalone HTML file (open in browser).
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
`dump_monster_names` `dump_steps` `dump_bank` `dump_skills`(✅ new)
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
join, useful for editor; do NOT archive)

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
