# DWM1 Monster Data — Complete Technical Reference

## Monster Info Table (Bank $03:$4461)

**Loader**: `Call_003_4446` (entry 1), reads species from `$DA31`, copies 43 bytes to `$DA33`

221 entries × 43 bytes each:

| Offset | Size | Field | Values |
|--------|------|-------|--------|
| $00 | 1 | Family | 0=Slime, 1=Dragon, 2=Beast, 3=Flying, 4=Plant, 5=Bug, 6=Devil, 7=Zombie, 8=Material, 9=Boss |
| $01 | 1 | Level cap | Max level when raised (e.g., 45 for DrakSlime) |
| $02 | 1 | Exp table index | Selects from growth curves at bank $13:$41E6 |
| $03 | 1 | Female ratio | 0=0%, 1≈10%, 2=50%, 3≈84% |
| $04 | 1 | Can fly | 1=floating/flying sprite (WingSlime, Dracky, ghosts, etc.) |
| $05 | 1 | Metal body | 1=only Metaly, Metabble, MetalKing |
| $06 | 1 | Skill 1 ID | See bank $41:$628E for skill names |
| $07 | 1 | Skill 2 ID | |
| $08 | 1 | Skill 3 ID | |
| $09 | 1 | HP growth | Curve index for growth table at bank $13:$6706 |
| $0A | 1 | MP growth | |
| $0B | 1 | ATK growth | Gets bonus scaling via `Call_013_4163` |
| $0C | 1 | DEF growth | |
| $0D | 1 | AGL growth | |
| $0E | 1 | INT growth | |
| $0F-$29 | 27 | Resistances | Values: 0=weak, 1=some resist, 2=normal, 3=immune |
| $2A | 1 | Tier/rank | 0=starter, 3-6=normal, 7=endgame boss |

### Resistance Type Ordering (26 types + 1 unused, FAQ-confirmed)

Verified against community FAQ data — 100% match across all tested monsters.
Values: 0=weak/no resistance, 1=some resist, 2=normal, 3=strong/immune.

| Index | Offset | Letter | Type | Skills |
|-------|--------|--------|------|--------|
| 0 | $0F | A | Fire | Blaze/more/most, FireSlash, BigBang |
| 1 | $10 | B | Heat | Firebal/bane/bolt, LavaStaff |
| 2 | $11 | C | Explosion | Bang/Boom/Explodet |
| 3 | $12 | D | Wind | Infernos/more/most, VacuSlash, MultiCut |
| 4 | $13 | E | Lightning | Bolt/Zap/Thordain, BoltSlash, Lightning, Hellblast |
| 5 | $14 | F | Ice | IceBolt/SnowStorm/Blizzard, IceSlash |
| 6 | $15 | G | Accuracy | Surround, SandStorm, Radiant |
| 7 | $16 | H | Sleep | Sleep, NapAttack, SleepAir |
| 8 | $17 | I | Death | Beat/Defeat, K.O.Dance, EerieLite, UltraDown |
| 9 | $18 | J | MP | RobMagic/TakeMagic, OddDance, RobDance |
| 10 | $19 | K | SpellBlock | StopSpell, MistStaff |
| 11 | $1A | L | Confusion | PanicAll, PaniDance |
| 12 | $1B | M | DefDown | Sap, SickLick |
| 13 | $1C | N | AglDown | Slow |
| 14 | $1D | O | Sacrifice | Sacrifice, Ramming, Kamikaze |
| 15 | $1E | P | MegaMagic | MegaMagic |
| 16 | $1F | Q | FireBreath | FireAir/BlazeAir/Scorching/WhiteFire |
| 17 | $20 | R | IceBreath | FrigidAir/IceAir/IceStorm/WhiteAir |
| 18 | $21 | S | Poison | PoisonHit, PoisonGas, PoisonAir, BadMeat |
| 19 | $22 | T | Paralyze | Paralyze, PalsyAir |
| 20 | $23 | U | Curse | Curse |
| 21 | $24 | V | MissATurn | LureDance, LushLicks, LegSweep, BigTrip, WarCry |
| 22 | $25 | W | DanceBlock | DanceShut |
| 23 | $26 | X | BreathBlock | MouthShut |
| 24 | $27 | Y | Aid | CallHelp, YellHelp, RockThrow |
| 25 | $28 | Z | GigaSlash | GigaSlash |
| 26 | $29 | - | (unused, always 0) | — |


## Stat Growth System (Bank $13)

**Entry 0** (`label13_4009`): Level-up stat calculation

1. Reads species from party struct offset `$CACA` → `$DA31`
2. Loads monster info via bank $03 entry 1
3. Each of 6 growth bytes (HP/MP/ATK/DEF/AGL/INT) indexes into growth table at `$13:$6706`
4. Growth table: 99 entries per curve, each giving the stat increment for that level
5. HP and ATK get additional bonus scaling via `Call_013_4163`

## Enemy Stats Table (Bank $14:$4C1D)

**Loader**: `Call_014_4849`, reads EID from `$DA12/$DA13`, copies 25 bytes to `$DA18`

487 entries × 25 bytes each:

| Offset | Size | Field |
|--------|------|-------|
| +0 | 1 | Species ID |
| +1 | 2 | EXP reward (16-bit LE, summed across defeated enemies) |
| +3 | 1 | Joinability (0=always joins, 5=standard, 7=never joins → $DB85) |
| +4 | 1 | Level |
| +5 | 2 | HP (LE) |
| +7 | 2 | MP (LE) |
| +9 | 2 | ATK (LE) |
| +11 | 2 | DEF (LE) |
| +13 | 2 | AGL (LE) |
| +15 | 2 | INT (LE) |
| +17 | 4 | AI weights |
| +21 | 4 | Skills ($FF = none) |

### Starter Monster ("Slib") — enemy-stats EID 1 (verified S36, confirmed in-game)

The starting monster is **enemy-stats entry 1** (`$14:$4C36`, flat `0x50C36`): a
dedicated always-join (joinability `$00`) Lv1 Slime, structurally distinct from
the wild Slime (EID 2, joinability `$02`, HP 8). Default fields: species `$08`,
Lv1, HP 30, MP 0, ATK 10, DEF 6, AGL 5, INT 1.

**Grant path**: the Castle (map-type `$00`) intro script reaches
`add_monster enemy=$0001` at `$0C:$42D6` by falling through an `if_flag_set`
cascade that all fail on a fresh save. The last gate is `if_flag_set $0002`;
immediately after the grant the script does `set_flag $0002`, so the starter is
given **exactly once** at new game. The `add_monster` opcode (`$29`, handler
`$04:$5F9A`) writes the EID to `$DA12/$DA13`, finds the first empty `$CAC1` slot,
and builds the monster via `LoadEnemyStats(EID 1)` → `label14_40b4` (`$14:$40B4`).
The grant block is annotated in `disassembly/bank_00c.asm` at
`Bank0C_ScriptAddr_4270:` (labels/comments only; byte-perfect).

**Editing the starter**: change enemy-stats entry 1. Species and level transfer
*exactly*. The six stats (HP/MP/ATK/DEF/AGL/INT) transfer as the **base**, then
receive the standard creation roll (see Party Monster Structure) — each displayed
stat is 80–100% of the field value, re-rolled per new game. Confirmed in-game by
swapping EID 1 → SkyDragon, Lv25, HP-field 599: the starter appeared as a
SkyDragon Lv25 with HP 566 (∈ 479–599) and Slime-tier ATK 8 / DEF 5 straight from
entry 1's fields — proving the stats derive from the entry, not the species
growth curve. EID 1 is starter-only (no encounter pool or boss references it), so
edits are isolated to the starter.

## Boss Table (Bank $14:$4897)

32 gates × 4 bytes. Preceded by 1 non-boss redirect entry at $4893.

| Offset | Size | Field |
|--------|------|-------|
| +0 | 2 | Fight EID (16-bit LE) |
| +2 | 2 | Join EID (16-bit LE) |

Used by `label14_4869` (entry 6) to redirect a fight EID to its join EID after defeat.

## Party Monster Structure

Base at `$CAC1` for monster index 0, `$95` (149) bytes per slot, 20 slots.
Index function: `Call_000_223b` — `HL = field_base + index × $95`

| Offset | Size | Field |
|--------|------|-------|
| $00 | 1 | In-use flag |
| $09 | 1 | Species ID |
| $0A | 1 | Family |
| $4B | 1 | Level |
| $4C | 1 | Level cap |
| $4D | 3 | Experience (24-bit) |
| $50 | 2 | HP (16-bit) |
| $52 | 2 | MP |
| $54 | 2 | ATK |
| $56 | 2 | DEF |
| $58 | 2 | AGL |
| $5A | 2 | INT |
| $62 | 1 | Plus value |
| $68 | 27 | Resistances |

**Stat creation roll (verified S36)**: when a monster is built from enemy stats
(`label14_40b4`, `$14:$40B4`), each of the six stats is scaled by `SaveEnem_4821`
— multiply the base by a random factor of `205..256`, then `>>8` (i.e. **80–100%
of the base, rolled independently per stat**). Species and level are copied
verbatim. The growth/personality value (the "WLD"-style field) is set to a
species-derived base ±2 (RNG). This is why a freshly-granted monster's displayed
stats sit slightly below the enemy-stats field values and vary between new games.

## Name Tables (Bank $41)

- **Monster names**: Pointer table at `$41:$4339` (256 × 2 bytes), strings at `$41:$5B1F`
- **Skill names**: Names at `$41:$628E`, 256 entries, `$F0` terminated

## Boss Join System (Bank $54:$55BB)

The join/no-join decision is made by `$54:fn$07` (`$54:$55BB`), called at the end
of the post-battle level-up processing loop.

**Decision logic**: `$DB85` (per-enemy joinability flag):
- Value `$07` = non-joinable (standard wild encounters)
- Any other value = recruitable via RNG probability
- Story bosses have `$DB85 = $00` and join through the natural probability path

**Post-battle state machine** (`$D9EC`): 15-state dispatch at `$50:$5F3A`, gated by `$DB73`.
Key states:
- `$0A`: Post-battle setup — experience calc, party processing init
- `$0B`: Level-up check loop — check each monster, route to display or join
- `$0C`: Level-up display per monster
- `$0D`: Join dispatcher — if `$DD61 ≠ $FF`, load EID and call join handler
- `$0E`: Post-join cleanup

**Boss redirect**: Bank $14 entry 6 (`$14:$4869`) remaps fight EIDs to join EIDs
using the redirect table at `$14:$4893`. When a boss fight ends, the fight EID
is looked up and replaced with the join EID (the monster stats for what joins).

**Key RAM for join system**:

| Address | Purpose |
|---------|---------|
| `$D9EC` | Post-battle state index (15 states) |
| `$DB55` | Post-battle flag (always 0 for bosses) |
| `$DB73` | Post-battle gate flag ($FF = skip dispatch) |
| `$DB85` | Joinability: $07=no, other=yes (RNG-based) |
| `$DD61` | Join candidate species ($FF = none) |
| `$DD6B` | Copy of $DB55 |

### Per-gate force-join hack (editor-only; verified S36; NOT in patches/)

The legacy hex editor can force normally-non-joinable (`$DB85 = $07`) monsters to
join at chosen gates via a raw-byte hook. The hook sites and resolver were
verified correct at the byte level (decoded from `$54:$55BB` onward):

- `$54:$55D5` — the `cp $07 / jr z` non-joinable early-exit. NOP'd (`00 00`) so
  `$07` monsters no longer skip the decision. (This only affects tier-7; the
  branch never fired for other tiers, so tiers 0–6 are untouched.)
- `$54:$5604` — `call $5683` (the join-result processor) redirected to
  `call $7FC8` (`CD C8 7F`).
- Resolver at `$54:$7FC8` (lives in the free zero padding `$7FC8–$7FFF`): it
  calls `$5683` first and **honors its result** for tiers 0–6 and for non-flagged
  tier-7 (normal behavior preserved); only when tier `== 7` **and**
  `table[wGateID] == 1` does it `scf` (force join). Note `$5683` itself rejects
  tier-7 (`cp $07 → carry clear`), which is exactly why both the NOP *and* the
  redirect are required. Per-gate flag table = 32 bytes at `$54:$7FE0`.

**Brittleness (must be resolved before any port to `patches/`):**
1. **`wGateID` (`$C935`) is overloaded.** The arena (`bank_055`) sets it to `0`;
   gate-entry (`bank_016`) sets it to `wMapID`. The resolver indexes
   `table[wGateID]` unconditionally, so (a) a flagged gate 0 can leak force-join
   into arena tier-7 fights, and (b) the table is keyed by `wMapID`, **not** the
   "gate ID 0–31" ordering the editor UI assumes — if those numberings differ,
   the wrong gates force-join. Confirm `wGateID` at the join check in SameBoy
   (watchpoint on `$C935` read at `$7FD2`) before trusting table alignment.
2. **Range:** `wMapID > 31` reads past the 32-byte table (stays in-bank, wrong
   byte).
3. **Semantics:** tier-7 monsters have no `join_eid` redirect (the boss redirect,
   bank $14 entry 6, only applies to *designed* join monsters), so force-joining a
   boss yields its **raw battle species at battle level** — potentially
   overpowered with no proper growth.

No misassembly exists here — `bank_054.asm` is correctly assembled and already
annotated; the hack itself is editor-only and was never ported to `patches/`.

## Data Files

- `extracted/monsters_full.json` — all 221 monsters with labeled fields
- `extracted/enemy_stats.json` — all 487 enemy stat entries
- `extracted/breeding_complete.json` — complete breeding data (both tables)

## Monster sprite graphics system (verified Session 21; tooling + annotation Session 22)

Reverse-engineered and proven in-game via battle-sprite swaps (Session 21 Dracky →
DWM2 "clam"; Session 22 Dracky → Anteater via the generalised tool, user-confirmed
in SameBoy). GFX-1 (tile system: annotate + tool) is **DONE** (Session 22); GFX-2
(palette + recolour) and GFX-3 (follower swap) remain in ROADMAP. The disassembly is
annotated with labels/comments only — build stays `1ca6579…`.

**Tooling (Session 22 — the editor's graphics asset layer).**
- `dwm/sprite_codec.py` — the SINGLE LZ codec for tiles AND sprites (no second copy
  of the format). `decode()` is byte-exact (matches the game and the legacy
  `tools/decompress_tiles.py`); `encode()`/`encode_safe()` produce valid, compact
  streams (greedy) or self-contained literal streams (`literal_only=True`);
  `tiles_to_indices`/`indices_to_tiles` convert 2bpp↔index grids;
  `gfxid_stream_offset`/`read_stream` resolve+read a gfx-ID. Round-trip contract:
  `decode(encode(x))==x` (verified on all 442 monster streams). It does **NOT**
  promise byte-identical re-encode of a vanilla stream — LZ is many-to-one and the
  editor never re-emits originals; do not "fix" this.
- `tools/extract_monster_sprites.py` → `extracted/monster_sprites.json` — decodes
  every monster's battle + follower sprite to a manifest (species → gfx-ID, bank,
  index, stream addr/len, tile count, grid, decoded tile bytes hex), `--png` for
  images. Count is a parameter (`--count`, default 221) — no hard 221 wall.
- `tools/build_sprite_swap.py` — species-agnostic battle swap (`--species 78|Dracky`,
  `--png`/`--payload`/`--probe`, `--literal`): resolve gfx-ID → encode → place in the
  bank's trailing free space → repoint the pointer-table entry. Same-bank/same-size
  repoint (zero shift); clean tree stays byte-perfect. LIMITS: free-space placement
  currently knows bank `$36` only (`BANK_FREE_ANCHOR`) — a cross-bank allocator is the
  editor-backend follow-up; PNG import is heuristic.
- `tools/resection_battle_gfx_table.py` — re-sectioned the battle gfx-ID table (below).

**Addressing.** Every graphic = a 2-byte **gfx-ID = `(bank<<8)|index`** (high byte
= ROM bank, low = index). Resolver `DecompressTileLayout` @ `$00:$1627` switches to
`bank` and reads a per-bank pointer table at **`$<bank>:$4001 + index*2`** → a
compressed stream in `$4000–$7FFF`.

**Stream format.** 3-byte header `[declen_lo, declen_hi, runmark]`, then an LZ body
(decompressor `WaitDMATransfer $00:$1577` → `TextScrollWindow`): byte≠runmark =
literal; byte==runmark = back-ref (next 2 bytes → offset `b0|((b1>>4)&0xF)<<8`,
ABSOLUTE into output base `$ac/$ad`; count `(b1&0xF)+4`, ext if low-nibble `$F`).
Back-refs index a **shared VRAM tile pool pre-loaded before the per-monster stream**,
so a single stream does NOT decode standalone (Dracky's battle stream ≈ 9 on-disk
bytes → 576 decompressed). **Swap lever:** a body with no runmark byte = pure literal
copy = self-contained, ignoring the shared pool. (Gotcha: fill the WHOLE tile field
with the backdrop index, not just the sprite footprint, or the surround renders as
palette index 0.)

**Species → gfx-ID tables (VERIFIED).**
- Battle: `SetFld_466d` (bank `$07`, ~line 1008) reads species (`$caca`), indexes
  **`MonsterBattleGfxTable` @ `$00:$2B9F`** by `species*2`, DMAs to VRAM **`$8B00`**.
  Dracky (sp 78) → **`$3627`** (bank `$36` idx `$27`; 576 B / 36 tiles / 48×48;
  runmark `$02`; word at ROM0 `$2C3B`). 221 entries, banks `$2F,$32–$36`.
  **Re-sectioned Session 22**: this table was misassembled by mgbdis (fake
  instructions; 23 hallucinated labels cross-referenced from banks
  `$07/$09/$12/$21/$2C/$32–$36/$40/$61`). `tools/resection_battle_gfx_table.py`
  rebuilds it as a labeled `dw`/`db` block, anchored between real symbol-map labels
  (`Data_2B91`..`TileRotatePadding`), emitting exact ROM bytes and preserving all 23
  cross-refs at their addresses — build stays `1ca6579…`. (See KEY_LESSONS "Session 22".)
- Follower: `ScreenTransDataTable` @ `$01:$49DF`, loader `GetActiveMonsterStatus` @
  `$01:$4986`, index `(species+$10)*2`; family-shared 2nd load via `$01:$4BAD`.
  Dracky → **`$383E`** (bank `$38` idx `$3E`; 256 B / 16 tiles). The follower load does
  TWO DMAs — the species sprite + a family-shared block (`$4BAD`); the 16-tile stream
  holds the full walk-animation frame set (engine cycles frames; not per-frame gfx-IDs).
  *(Follower extraction is wired in `extract_monster_sprites.py`. The frame→direction
  layout — once "not yet pinned" — is now fully solved; see "Follower / walking-sprite
  render system" below.)*

### Follower / walking-sprite render system (SOLVED Session 24 — GFX-3)

A monster's overworld follower is **two independent layers**: the **art** (16 tiles, the
gfx-ID stream above) and the **layout** (a metasprite program that arranges those tiles into
the four facings × two walk frames). They are orthogonal — same art + different layout =
different-looking walk; this is the key to the editor.

**Render engine — `SaveScr_40cd` @ `$04:$40cd`** (GBC variant of ROM0 `$0d91`). The follower
path: `AdjustGateFloorIndex` (`$01:$5938`) sets `$ffc7` (sprite-type), `$ffc9` (tile base
`$20`/`$30`/`$40` for party slot 0/1/2), reads the movement-trail record for facing, then
far-calls `$0402` (`NPCSpriteLoadAlt`) → `SaveScr_40cd`. The engine walks a metasprite list:

- **Entry = 4 bytes `(dy, dx, tile_offset, attr)`**, list terminated by `$80`.
- Final OAM **tile = `tile_offset + [$ffc9]`** (so `tile_offset` is 0–15 within the 16-tile block).
- Final OAM **attr = `[$ffca] XOR attr`** — **X-flip = bit5 (`$20`)**. Head-mirror is encoded as
  two entries sharing a `tile_offset`, one with the flip bit toggled.
- Selection: two-level pointer table indexed by **sprite-type `$ffc7`** then **frame/direction
  `$ffc8`**. `$ffc7 = [$ca91] = GetActiveMonsterStatus` (`$01` if bit7 of `[$cb0b]`, else
  `[$caca]+$10`). **`[$caca]` is the monster's SPECIES** (party struct base `$cac1` + offset
  `$09`) — NOT a separate "sprite-class" byte (a pre-GFX-4 doc error). So `$ffc7 = species+$10`,
  and the layout is selected by species directly.

**OBJ transparency (critical, opposite of battle):** for OBJ sprites **colour index 0 is
hardware-transparent**. Empty/background pixels of a follower MUST be idx0 (the battle path
instead used a BG backdrop on idx1). The 8 global OBJ palettes (4×RGB555 each) live at
**`$17:$5615`**; per-monster slot assignment is dynamic (NPC OAM code), so a calibration ROM
can force colours by overwriting these 8 palettes (`build_sprite_swap` numbered-ROM `--palette`).

**Layouts are PER-MONSTER, not universal — 118 distinct layouts.** `tools/extract_follower_layouts.py`
walks the frame-pointer tables in banks `$05`/`$10`/`$11` and dedupes them into
`extracted/follower_layouts.json`. Each layout gives, per facing×walk-frame, the four
`(position, tile 0–15, flip)` tuples. Two classes:

- **Non-sharing (76 layouts, 202 sprite types):** down/up/side use disjoint tile sets — *any*
  distinct front/back/profile art renders perfectly. The two workhorse layouts (41 + 30 types)
  are of this kind. **This is the editor's default for imports.**
- **Sharing (42 layouts, 58 types):** up and side reuse the same VRAM tiles (e.g. Healer:
  tile `5` is both up-head-left and side top-left; `A`/`C` are both up-legs and side bottom).
  Tile-efficient and invisible on a radially-symmetric blob, but a directional sprite forced
  into it shows the borrowed tiles.

**Measured anchors** (numbered-tile calibration, both matched the extracted data exactly):
Healer = a sharing layout (`$05:$4bae`); DarkDrium (sp214) = a non-sharing layout (`$05:$45b4`):
down `0,0^,1,2`/`0,0^,3,4`, right `5,6,7,8`/`5,6,9,A`, up `B,B^,C,D`/`B,B^,E,F`. The blue-dragon
walk-sprite import rendered **perfectly in all four directions on DarkDrium's layout** —
user-confirmed in SameBoy. (A symmetric blob masks layout errors; a directional monster
exposes them — see KEY_LESSONS "Session 24".)

**Monster → layout dispatch (SOLVED Session 25 — GFX-4).** The follower render is dispatched
via bank `$04` entry 2 (`NPCInteractDispatch`), routed by `$ffc7` magnitude: `$10–$8F` → bank
`$10` entry 0, `≥$90` → bank `$11` entry 0 (monster followers are always `≥$10`, so the bank-`$04`
`$401d` table is for plain NPCs only). Bank `$10`/`$11` entry 0 does `ld de,$407f ; call $0d91`, so:

- **Level-1 layout table = `$10:$407f` (species 0–127) / `$11:$407f` (species 128+)** — a fixed
  address, 128 `dw` entries each, indexed by `species` (bank $10) or `species-$80` (bank $11). Each
  entry points to that species' **level-2** table (six frame pointers). *(The pre-GFX-4 docs said
  these were "not at $4000, must be located" and pointed at bank `$05`. Bank `$05` is a DIFFERENT
  render path — the ObjTest monster viewer — whose `$407f`-style table happens to share layout
  signatures; the real follower path is `$10`/`$11`. Verified by reproducing the Healer + DarkDrium
  anchors byte-for-byte through `$10`/`$11`.)*
- **Per-species attr/palette table** — read by `HramScr2_406e`/`HramUnk11_406e` as
  `[base + adjusted-$ffc7]` and **OR-ed into `$ffca`**. The base DIFFERS per bank because the
  level-1 pointer table length differs: **bank `$10` = `$417f`** (128 entries, species 0–127, after
  the 256-byte pointer table `$407f`–`$417e`); **bank `$11` = `$412d`** (only **87** entries, species
  128–214, after the shorter 174-byte pointer table `$407f`–`$412c`). *(Pre-this-fix docs wrongly listed
  `$417f` for both — bank `$11`'s real attr base is `$412d`; the level-2 layout tables then start at
  `$11:$4184`.)* **Attr byte bits: bit6 (`$40`) = OBJ Y-flip, bit5 (`$20`) = OBJ X-flip, low 3 bits =
  one of the 8 OBJ palettes (`$17:$5615`).** This is the follower palette **and** flip knob.
- `tools/extract_monster_follower_layouts.py` walks these tables → `extracted/monster_follower_layouts.json`
  (every species → `bank, l1_index, l1_addr, l2_addr, attr_base, layout_id, sharing`) and regenerates
  the complete `follower_layouts.json` (**155 layouts**, not the old 118 — the S24 brute-force scan
  required exactly-4-entry frames and silently dropped ~15 small/blob monsters that use 3-entry frames).

**Follower-art table has EIGHT copies (Session 25).** The per-species follower gfx-ID table is
duplicated once per UI context: overworld `ScreenTransDataTable` (`$01:$49DF`, indexed `species+$10`)
plus copies in banks `$06 $07 $09 $0b $12`(library) `$18`(menu/`TextDataPtrLookup` `$4123`, indexed
`species`) `$59`. The layout (`$407f`) and attr (`$10:$417f` / `$11:$412d`) tables are single/shared. A complete
follower-art swap must repoint the species in **all eight** copies — GFX-3 repointed only `$01`,
which is why a swapped monster kept its old art in the menu/library.

**NEW species (id ≥ 215) followers — overshoot is the whole problem (`tools/build_new_species_follower.py`,
user-confirmed v7).** A brand-new species like Gorbunok (224) has no row in ANY of these tables, and
`species-$80 = 96` overshoots every bank-`$11` table (87 real entries, indices 0–86 = species 128–214).
Three independent overshoots, each handled:
- **gfx-ID (art):** the 8 art-table readers are *forked* — patch the 8-byte add-base (`7D C6 lo 6F 7C CE hi 67`)
  to `call <resolver>` that returns `HL=&GidWord` ($7e00 overflow stream) for id ≥ threshold, else the
  normal add-base. All eight contexts (overworld + menu + library + …) must be forked or that screen
  shows stale/overshoot art.
- **overworld art loader = `GetActiveMonsterStatus` (`$01:$4986`)** — loads the 3 party followers' art to
  VRAM tiles `$20/$30/$40` and returns `$ffc7=species+$10` into `$ca91/$ca92/$ca93`. A prior placeholder
  patch (`ReadActiveMonsterByteSpeciesClamped`) clamped species ≥ 224 → 214 *before* this read to dodge a
  garbage-gfx crash; that silently defeated the `$01` fork (overworld always showed DarkDrium). Fix: narrow
  the clamp to ≥ 225 (`cp $e0` → `cp $e1`).
- **layout level-1:** write the species' `$11:$407f + (species-$80)*2` slot (e.g. `$413f` for 224) to a
  clean layout-0 level-2 table (Armorpion's `$4184` is the proven layout-0 — its DOWN-a is `0,1,2,3` at
  `TL,TR,BL,BR` with no flips, matching `pack_png_layout0`). This write lands in the attr-table/early-layout
  region and is part of the overshoot, not a free slot.
- **attr (palette + FLIP) — the subtle one:** `HramUnk11_406e` reads `[$412d + (species-$80)]`; for 224 that
  is `$418d`, **inside Armorpion's level-2 layout**, where the byte is `$41`. That single garbage byte caused
  BOTH cosmetic bugs: **bit6 (`$40`) = the OBJ Y-flip bit** → every follower tile rendered upside-down in
  place (head stays top/tail stays bottom, but each tile mirrored — the OAM builder `SaveScr_40cd` does
  `attr = [$ffca] XOR entry_attr`, so a Y-flip in the base attr flips all tiles); and **low 3 bits = 1 →
  OBJ palette 1 = green.** `$418d` is live Armorpion data and cannot be written, so the attr READ is forked:
  redirect `HramUnk11_406e` (`$11:$406e` → free `$11:$792d`) so id 224 gets a clean attr, then the art is
  stored **un-flipped** and renders upright in the correct palette.
- **The clean attr is `[$ffca] = ([$ffca] & $B8) | palette` — mask `$B8`, NOT `$98`.** This is surgical and
  the distinction matters: `$ffca` is the **engine's** base attr, and the engine sets **bit5 ($20 = X-flip)
  every frame for the LEFT facing** (layout-0 LEFT and RIGHT share the SIDE frames; LEFT is produced by a
  global X-flip carried in `[$ffca]` bit5, which the original `[$ffca] |= attr` preserved). The fork must
  clear ONLY the genuinely-garbage bits — **bit6 (Y-flip) + low3 (palette)** = mask `$B8 = 1011_1000` — and
  **preserve bit5**. The earlier `$98 = 1001_1000` mask also cleared bit5, which wiped the engine's
  left-facing flip → the follower faced RIGHT while walking LEFT (up/down/right were fine because their
  `[$ffca]` bit5 is already 0). *(Lesson: an index that overshoots a table doesn't just give wrong data —
  if the stray byte's bit6/bit5 are set it injects a hardware flip, so "upside-down sprite" and "wrong
  palette" can be the same root cause; and when you sanitise the base attr, touch ONLY the garbage bits —
  never the X-flip the engine drives for direction.)*


**Reassignment primitive (`tools/build_follower_reassign.py`).** To restyle a monster's follower:
(1) repoint its level-1 entry (`$10`/`$11:$407f + idx*2`) to a clean non-sharing layout's level-2
table (same-bank only — the level-2 pointer is dereferenced with the routed bank mapped, so a
bank-$10 species can't point at a bank-$11 table); (2) repoint all 8 art copies to the new art
(clone an existing monster's gfx-ID, or place a custom 16-tile stream cross-bank via the GFX-2/3
overflow allocator and point all 8 at it); (3) set the attr byte for the palette. This is NOT a
`[$caca]` edit — `[$caca]` is the species and can't be changed to restyle. Layout 0 (`$10:$4e33`,
used by Dragon sp28 + 13 others) is the editor's default non-sharing import target: tiles 0–3 =
DOWN-a, 4–7 = SIDE-a, 8–11 = SIDE-b, 12–15 = UP-a (down_B/up_B auto-mirror; LEFT = right X-flipped).
USER-CONFIRMED in SameBoy: Healer→Dragon clone and Dracky→custom blue-dragon (imported art),
correct in all directions and consistent across overworld + menu + library.

**Pool dependency (Session 22).** All 221 battle streams (and 174/221 followers) use
back-references that read below their own output start — i.e. into the shared VRAM
pool. Standalone extraction decodes those as zero-fill; in practice the meaningful
refs are self-covered, so extracted sprites render correctly (Slime/Dracky/Anteater
verified). But a CROSS-monster transplant must encode the new art **self-contained**
(`--literal`) — otherwise it inherits whatever pool state the *target* monster loads,
not the source's. The swap tool defaults handle this.

**Monster battle palette system (SOLVED Session 23).**

> **Tracing trap (S22 note, promoted from the archive):** the `SetGBCPalette`
> calls in bank `$07` (~lines 2460/2609) are SCENE palettes (warp/gate id `$03`),
> **not** the monster's — don't be misled when re-tracing. The per-monster
> selection question those S22 notes chased was answered in S23 (this section);
> the `$07` display-init family read at `$cacb` remains an un-pinned curiosity —
> harmless, the palette does not come from it.
 Tiles only pick a palette
INDEX (0-3); the colours come from a separate CGB subsystem. The enemy monster renders
as **BG tiles on BG palette slot 4** (SameBoy-confirmed: tilemap attr `---04`; the live
BG colour buffer is `$c797`, slot 4 = `$c7b7`; uploaded to BCPD by bank `$17` entry 8).
The per-species colours live in a ROM table **`MonsterBattlePalettes` @ `$17:$62FD`**
(historically mislabeled `RoomAttrDataBlocks`), **8 bytes/species = 4 RGB555 LE colours
`[c0, c1=$6bff backdrop(forced), c2, c3=$0000 black]`** (only c0/c2 vary per monster).
It is loaded by **bank `$17` entry 6** (`label17_41d0` / far-call `$1706`): `$c81e` =
palette index (= species) `×8 + base`, `$c81f` = destination CGB slot; the monster
battle display calls it with index=species, slot=4. Verified: Dracky sp78 @ `$656d`
= `007b 6bff 2a97 0000` (red/gold/black), Slime sp8 @ `$633d` = `5c0f 6bff 7ea0 0000`
(blue) — both match the SameBoy palette viewer exactly.

**Recolour** = a same-size 8-byte edit of one species' entry (per-species, no bleed;
same-size in bank `$17` → Iron-Rule-2 safe). `tools/build_sprite_swap.py --palette`
does it; `extracted/monster_palettes.json` (`tools/extract_monster_palettes.py`) has
all 221. Note `SetGBCPalette($04)` (banks `$02/$13/$50`) is the constant battle-palette
REFRESH, not the colour source; `FuncFld_6942`'s `ld h,$04` is tile streaming, not a
slot — both were misleading earlier leads (KEY_LESSONS "Session 23").

**NEW species battle sprite (id ≥ 224) — the gfx/palette ASYMMETRY (G2, baked into `patches/`).**
The two battle tables behave *oppositely* at the top of the id range, and this is the whole
lesson:
- **Gfx table `MonsterBattleGfxTable` @ `$00:$2B9F` has a REAL slot for every id 0–255.**
  Ids 216–255 are uniform `$320f` padding ("Durran" placeholder), so giving id 224 real art is a
  **same-size 2-byte repoint** of its slot (`$2b9f + 224*2 = $2d5f`: `$320f`→`$7e01`) — **no fork.**
  (In a clean re-section this slot is a `dw`; in the pre-re-section `patches/bank_000.asm` the region
  is mgbdis-misassembled as `ld/rrca` and must be re-expressed as `db` for the edit — bytes identical
  except the one word.) The art itself is a stream in overflow bank `$7e` (here index 1 = `$7e01`,
  sharing the bank with the follower at index 0 = `$7e00`).
- **Palette table `MonsterBattlePalettes` @ `$17:$62FD` does NOT.** It is 8 B/species and runs out at
  216; `$62fd + 224*8 = $69fd` **overshoots into `PaletteColorData`.** So a new-species battle palette
  needs a **fork**, not a table write: `label17_41d0`'s add-base is intercepted byte-neutral
  (`call HighBattlePal` + 5 `nop`) and the resolver (placed in bank `$17`'s filler tail, no shift —
  Iron-Rule-2) returns a custom 8-byte palette for H≥`$07` (species*8 ≥ `$700` ⇔ id ≥ 224), else the
  vanilla `$62fd + species*8`. The id-224 dragon palette is `67 4d ff 6b ff 7f 00 00` =
  `[c0=$4d67 royal-blue, c1=$6bff cream backdrop, c2=$7fff white, c3=$0000 black]`. The 48×48 4-colour
  convention still applies: idx1 is the forced backdrop, so only **idx0/idx2/idx3** are body colours
  (the 4-colour dragon art merges its two blues into one body index).
  Tooling: `tools/bake_follower_overflow.py --battle-art/--battle-spec` emits the stream + prints the
  gfx-ID and palette; spec at `examples/follower_swap/gorbunok_battle.json` (bbox + color_map + palette).
  Editor takeaway: a battle recolour/reskin for an EXISTING species is a table edit at `$2b9f`/`$62fd`;
  for a NEW species the gfx is still a table edit but the palette must branch through `HighBattlePal`.

**Cross-bank sprite swap (Session 23).** `dwm/sprite_bank.py` places encoded streams
into the reserved overflow banks (`$7E–$7F`, then `$7C/$7A/$79`; EDITOR_DESIGN §8) with
a pointer table at `$4001`, and `tools/build_sprite_swap.py` repoints the species→gfx-ID
entry — works for ANY of the 221 monsters regardless of which bank their original art is
in (the resolver reads `$<bank>:$4001+index*2` with no bank gating). `--relocate` copies
a monster's existing stream unchanged (lossless regression proof); `--png`/`--payload`
import new art (literal/self-contained). `--palette` recolours in the same run. DWM2
clam→Dracky (battle + purple palette) user-confirmed in SameBoy, including inside a
custom room with random encounters and with Dracky reassigned to the Spirit family.

**Disassembly label errors (noted; battle table FIXED Session 22):** `bank_038.asm`
header "gate dungeon tileset J" also holds follower sprites; `bank_036.asm` "Cross-bank
dispatch table" is actually the gfx pointer table (Entry-N comments added). A prior
`$382E` battle guess (from unreferenced scan-tables `$07:$6E14`/`$09:$6B10`) is bogus —
`$382E` is a dungeon tile.

## Species ID geography (256 slots) + add-new-species architecture (Phase N, Session 28)

Species IDs are a **single byte** → hard ceiling of 256 slots. Data tool:
`tools/map_species_slots.py` → `extracted/species_slot_map.json` (decodes all 256
name slots from `$41:$4339`, classifies each, self-aborts on ROM drift).

**Slot map (verified this session):**

| Range | Count | Status | Notes |
|-------|-------|--------|-------|
| 0–214 | 215 | real monsters | normal species |
| 215–219 | 5 | **special** | 215 `TERRY?` (one-off enemy, fightable, NOT breedable); 216–219 `Tatsu`/`Diago`/`Samsi`/`Bazoo` (summon-skill byproducts only). Bespoke per-id handling in code (see gates below). |
| 220–223 | 4 | empty/phantom | empty names (220/221/222 share one `$F0`-only name ptr at `$41:$6287`); info table stops at 220. |
| **224–255** | **32** | **FREE** | usable for NEW species — every top-range classifier routes ≥224 to "normal". |

**First free id = 224 (`$E0`). Budget = 32 new species.** Going beyond 32 needs
16-bit species IDs everywhere (`$DA31`, `[$caca]`, …) — a much larger arc; avoid.

**Architecture = "high-table + single forked loader, vanilla 0–220 byte-identical".**
Each per-species table has ONE arithmetic indexer; fork it as `if id < 224 → vanilla,
else → free-bank high-table indexed (id−224)`. Verified single indexers:

| Table | Addr | Entry | Indexer | Note |
|-------|------|-------|---------|------|
| Monster info | `$03:$4461` | 43 B | `$03:SaveMon_4446` (MonsterInfoCopy) | ONLY indexer; all 16 consumer banks read the `$DA33` copy. |
| Enemy stats | `$14:$4C1D` | 25 B | `$14:LoadEnemyStats` | EID is **16-bit** (`$DA12`/`$DA13` → `Mul16x8To24`) → no 256 wall on the battle side; new fight/join entries can append past 487. |

**Tables with headroom (no fork — just populate the slot):** name ptrs `$41:$4339`
(256-wide), follower layout/attr dispatch `$10:$407f`/`$417f` (128 entries) + `$11:$407f`/`$412d` (87 entries).
**Shared (no per-species work):** growth curves `$13` (selected by a curve index stored
inside the info entry, not by species).

**N6 — RESOLVED (S31): the 4 "top-range gates" are NOT species gates.** The S28
slot-map hand-decoded four `cp`-ladder sites and flagged them for N6 to confirm they
treat species ≥224 as normal. Confirmed by tracing the operand: **all four read
`$db8a`, and `$db8a` holds a battle skill/effect/animation id — never a species id.**
It is written ONLY from constants and skill-table lookups (`ld a,$2f` / `$3a` / `$01`
/ `$00` etc.), never from a monster's species byte. So a new SPECIES id 224 cannot
flow into any of them; they are false positives for the new-monster checklist and
need **no patch**. Detail per site:
- `bank_05f.asm ~1680` — `$d5/$d6/$da/$dd/$de/$df/$e0` ladder on `$db8a` (effect id),
  clears 6 B @ `$DA82`; ladder ends `cp $e0/jr c/ret`, so any value ≥`$e0` falls
  through to `ret` (already safe even if it *were* reachable).
- `bank_057.asm ~5773` — `cp $dd/ret nz` on `$db8a`; a battle-effect special-case.
- `bank_058.asm ~658` (`SaveBtlFX_43ff`) — equality on `$db8a` (217/221) → load
  `$5203`; effect-animation dispatch.
- `bank_052.asm ~3510` — `$db8a` bucketed into the skill engine (`SkillFunctionTable`
  @ `$4011`); `ld a,$1b` is a skill-fn index, not a species.
The ~40 OTHER `cp $dd`/`cp $de` hits repo-wide are also FALSE POSITIVES — replicated
interrupt boilerplate (`rst $28/ei/ret c/cp $dd/ldh [rIE]`) and misassembled data in
high banks. **Net: Phase N needs no species-gate patch.** (See DOC_AUDIT.md.)

### Species-indexed table overshoot registry (the new-monster checklist)

**There is no global "monster count":** different systems size their per-species
tables differently and NONE bounds-check. For a new id `N`, any table with
`entries ≤ N` overshoots (`base + N*stride` reads whatever follows). Two remedies:
(1) if the table already has a slot for `N` (≥256-wide), just write it; (2) else
fork the **reader** (byte-neutral) to resolve id≥`N` to valid data in free space —
never clamp/gate to hide the miss. Verified status for id 224:

| System | Table | Addr | Entries | id224 | Status (S30) |
|--------|-------|------|---------|-------|--------------|
| Monster info | — | `$03:$4461` | 221 | overshoot | **forked** (`SaveMon_4446`/`label443f`, zero-shift, id≥224 → bank `$6A` high table); tool `build_new_species.py` → `patches/bank_06a.asm` |
| Enemy stats | — | `$14:$4C1D` | 487 | overshoot | **no fork needed** — EID is 16-bit, so a new entry placed in bank `$14` trailing free at EID×25+`$4C1D` is read directly. EID 518 → `$14:$7EB3`. tool `build_new_species.py` → `patches/bank_014.asm` |
| Wild encounters | `EncounterPoolData` | `$01:$6AAE` | 128 pools×26 B | n/a | **same-size pool edit (NOT a fork)** — fill an empty slot (EID 0/wt 0) with the new species' EID(+10,×2)+weight(+20). Gorbunok → pool 0 slot 3 = EID 518 wt 1. tool `build_new_species.py` → `patches/bank_001.asm` (in-place, Iron-Rule-2 safe) |
| Name | `MonsterNamePtrTable` | `$41:$4339` | **256** | OK | slot written ("Gorbunok" @ `$41:$7E46`); `patches/bank_041.asm` |
| Detail line 1 (name) | mode-0 | `$4D:$400B` | **256** | OK | no change |
| Detail line 2 (desc) | mode-1 | `$4D:$420B` | **215** | **overshoot→freeze** | **forked** `HighDetailTextFork`; id224→`$60BC` *(Dracky placeholder)* |
| Breeding family recipe | `FamilyRecipeTable` | `$16:$4974` | **222** | overshoot | **forked** `FamilyRecipeResolve` (`patches/bank_016.asm`). S32: id224 → `db $04,$2a` (Snaily+BattleRex) so the encyclopedia shows the recipe icons. NOTE: the *icons* render, but the lineage parent **names** still show "?????" — that text is a SEPARATE overshoot (modes 0/1, below) |
| Battle sprite gfx | `MonsterBattleGfxTable` | `$00:$2B9F` | 256 | **slot exists** | **G2 (S35), baked into `patches/`:** `$2d5f` `$320f`→`$7e01` (same-size 2-byte repoint, no fork); dragon battle stream = overflow `$7e01`; palette via `HighBattlePal` fork in bank `$17` (`$62fd` overshoots, needs fork). User-confirmed. |
| Follower gfx (walking) | follower gfx-ID copies | `$01/$06/$07/$09/$0b/$12/$18/$59` | — | overshoot | S32: `$0b` forked in `patches/` (`FollowerArtResolve0b`, hatch-crash fix). **Real follower ART now integrated** via `build_new_species_follower.py` (W.png → gid `$7e00`, layout `$4184`, attr palette 2, all 8 contexts repointed/forked + `$01` clamp lifted) — user-confirmed. **Now BAKED into `patches/` as id-indexed tables (G1, S34)**, so the bare patched build shows the real dragon. **Battle sprite also baked (G2, S35) — `$7e01` + palette fork.** |
| Default nickname + "take X with you" | `FamilyCodePtrTable` (mode 7) | `$41:$4739` | **215** | overshoot→"SkyBell" | **FIXED S32** — id224 overshot into `ItemName[9]`="SkyBell". `LoadModeBaseRedirect` (16 B in `$00F0` ROM0 padding, `patches/bank_000.asm`) redirects mode-7 id≥224 to a new-species SHORT-name table (`$7E39`→`$41:$7FF9`) holding the first-4 name ("Gorb"). Generic; gated on `$4739` so all other text byte-identical |
| Lineage parent NAMES (library detail, line 1) | mode-0 `$400b` (bank `$4d` entry 2) | `$4d:$400b` | **256** | un-authored slot→"?????" | **DONE (S38)** — `LoadItem_6456` (`$12:$6456`) renders line 1 via bank `$4d` entry 2 → entry 0 (`call SetB4d_43b9`) → `HighDetailTextFork`, mode 0 indexed by the **offspring** id. Slot 224 was the vanilla shared "?????    ?????" placeholder @ `$53C4` (NOT an overshoot; 256-wide, slot un-authored, shared w/ 220/225). Fixed by wiring `HighModeTable4D` mode-0 → `HighMode0Ptrs` → `GorbunokRecipeLine` "Snaily   BattleRex" (`patches/bank_04d.asm`); two 9-char fields to match vanilla recipe format. id≥224-gated. User-confirmed SameBoy. |
| Library tab | `LibFamilyPtrTable` (custom) | `$12` | by family | — | id224 listed under Slime; **tool-owned** — `build_library_table.py --new-species` reads `new_species.json` (family from clone+override) + moves the unseen-marker `$E0`→`$FE` (id 224 now a real species; see BREEDING_SYSTEM "Walker contract") |

The text engine multiplies the risk: detail/name text uses the mode×species double
indirection (`SaveBankAndSwitch $092F`; see TEXT_SYSTEM.md), and **each mode's
per-species table has its own count** (bank `$4D` mode0=256, mode1=**215**; bank
`$41` mode5=256, mode7 `FamilyCodePtrTable`=**215**). A new screen rendering a new
species through a *different* mode must re-check that mode's size.

**Not yet exercised for new species (check when touched):** status/party text via a
`$4D`/`$41` mode not yet touched; per-species skill-name text; save round-trip at the
new id range. *(S32 cleared: breeding as a result — `SpecialRecipeTable` append, works;
default-nickname/narration mode-7 overshoot — fixed. Newly OPEN: lineage parent-name
line-1 un-authored placeholder, above — string staged, wiring TODO.)*

### Fork-seam annotations in clean disassembly (S33 — labels/comments only)

The display-side fork seams are now commented at their clean anchors (build stays
`1ca6579…`; every referenced label sym-verified to its address). Two corrections were
baked into source while doing this:

* **`$41` text config list — selectors by mode.** ROM0 `SaveBankAndSwitch` (`$00:$092F`)
  / `TextHandler_0940` (`$00:$0940`) compute `table = [$4007 + mode*2]`, then
  `string = [table + id*2]` (`mode = [$c822]`, `id = [$c823]`). Reading the `$41:$4007`
  config list: mode 5 → `$4339` MonsterNamePtrTable (256), mode 6 → `$4539` SkillNamePtrTable,
  mode 7 → `$4739` FamilyCodePtrTable (215, the 2-letter default-nick), **mode 8 → `$48E7`
  ItemNamePtrTable**, mode 9 → `$493F` ItemDescPtrTable, mode 10 → `$4997` Personality,
  **mode 11 → `$49CD` MiscTextPtrTable (NOT item names)**. *(Correction: an earlier note
  said "mode 11 = ItemNamePtrTable" — the config table makes it mode 8. The item-render
  path's selector should still be SameBoy-confirmed via `[$c822]`; the config fact stands.)*
* **`$4739` overshoot bound.** The table has exactly 215 entries (species 0–214), so it
  structurally overshoots at **id ≥ 215** (into `ItemNamePtrTable`); the `LoadModeBaseRedirect`
  fork gates `cp $e0` so it only covers **id ≥ 224**. Ids 215–223 are phantom/never-rendered
  and deliberately left to overshoot. *(Supersedes the looser "overshoots for id≥224".)*
* **`FamilyCodePtrTable` name is legacy/misleading** (kept for ref-stability; the nickname
  fork gates on the literal `$4739`, not the label). It is the SPECIES-indexed 2-letter
  default-nickname table, not a family table; the 215 `FamilyCode_NNN` string labels are
  likewise legacy.

**The 8 follower gfx-ID copies — add-base sites (one comment each, `[n/8]`).** A complete
art swap / new-species follower must repoint ALL 8 (layout `$10/$11:$407f` + attr are
single/shared; these 8 gfx-ID tables are per-UI-context copies). Bank `$12`'s copy is the
same `ItemSlotPtrTable` the lineage parent-icon loader uses. The mgbdis default labels are
misleading (they are NOT NPC-pos / tile-ref / save-slot data):

| # | Bank | add-base addr | table label (legacy) | base | index |
|---|------|---------------|----------------------|------|-------|
| 1 | `$01` | `$49a7` | `ScreenTransDataTable` | `$49df` | species+$10 |
| 2 | `$06` | `$4d7e` | `MapNPCPosDataTable` | `$4dcc` | species+$10 |
| 3 | `$07` | `$66b8` | `TileRefLookupTable` | `$6e14` | species+$10 |
| 4 | `$09` | `$61fb` | `FieldPtrLookupTable` | `$6b10` | species+$10 |
| 5 | `$0b` | `$490f` | `SpritePtrTable_4974` | `$4974` | species+$10 (forked in patches: `FollowerArtResolve0b`) |
| 6 | `$12` | `$65de` | `ItemSlotPtrTable` | `$65f2` | species+$10 (= lineage parent-icon table; `CmpItem_65cb`) |
| 7 | `$18` | `$40bf` | `TextDataPtrLookup` | `$4123` | raw species |
| 8 | `$59` | `$42ca` | `SaveSlotPtrTable` | `$4363` | raw species |

*(Note: `build_new_species_follower.py` lists bank `$18` reader-base as `$4103` — that is
operand−`$20` bookkeeping for its `species+$10` scan logic, not a code address; the actual
`add LOW/adc HIGH` operand is `$4123` = `TextDataPtrLookup`.)*

**Lineage render chain (bank `$12`).** `LoadItem_65a8` resolves the recipe via
`ld hl,$1601; rst $10` (bank `$16` entry 1 = `FamilyRecipeResolve` in the patched build) then
loads two parent icons through `CmpItem_65cb` (→ `ItemSlotPtrTable[species+$10]`).
`LoadItem_6456` far-calls bank `$4D` entry 2 (`$4d02`) to render the two lineage text lines —
mode 0 line 1 (parent names, `$4D:$400B`, 256-wide) and mode 1 line 2 (desc, `$4D:$420B`, 215,
already forked `HighDetailTextFork`); slot 224 of mode-0 is the vanilla `"?????"` placeholder
(the open lineage parent-name sub-item).

**Breeding parent seam (bank `$16`, cross-ref only).** `LoadBrd_45ff`/`LoadBrd_45d5` convert
each parent species → family code via `ld hl,$0301; rst $10` (bank `$03` entry 1 monster-info
load = the `SaveMon_4446` path, forked for id≥224), which is what lets a NEW species resolve a
real family when used as a breeding parent. The breeding-determination internals proper
(`LoadBrd_4653` special/plus, `LoadBrd_45d5/45ff` family scan, special→family→pedigree
precedence) are left for a breeding-mechanics pass.

### Fork-seam annotations in clean disassembly (S38 — the DATA-TABLE seams)

The S33 pass (above) covered the DISPLAY seams; S38 finishes the **data-table** seams
(labels/comments only, build `1ca6579…`, integrity 4/4). Each anchor in clean disassembly now
documents its Phase-N fork/append behaviour and cross-refs the owning patch + tool:

* **Monster info (`bank_003` `label443f`/`SaveMon_4446`).** The SINGLE `$4461+id*43` indexer; all
  16 consumers read the `$DA33` copy, so this is the one fork point. Patched build: `cp $e0` →
  `ld hl,$6a00; rst $10` → `NewSpeciesInfoCopy` (bank `$6A` high table). Also reached as bank `$03`
  ENTRY 1 by breeding's `$0301` parent-family loads (so a new species resolves a real family as a
  parent). Table is 221 entries → id≥221 overshoots into code; fork the READER, don't extend.
* **Enemy stats (`bank_014` `LoadEnemyStats` + new label `EnemyStatsTrailingFree` @ `$7EAD`).**
  16-bit EID (`$DA12/$DA13` → `Mul16x8To24`) ⇒ **NO 256 ceiling, no fork**: an entry appended in the
  trailing free run `$7EAD..$7FFF` (339 × `$00`) is addressed directly at `EID*25+$4C1D`. KEY GOTCHA
  recorded at the anchor: the 487-entry table ends at `$7BAC`, but `$7BAC..$7EAC` is CODE, so EIDs
  487–517 are **unusable**; the first grid-aligned slot at/after `$7EAD` is **EID 518** (`$7EB3`) —
  which is why Gorbunok (species 224) = EID 518. `EnemyStatsTrailingFree` sym-verified to `14:7ead`.
* **Wild encounters (`bank_001` `EncounterPool_000`).** 5 EID slots (+`$0A`, 5×2 LE) + 5 weights
  (+`$14`); an UNUSED slot = EID `$0000`/wt 0. A new species fills a provably-empty slot — a
  same-size, in-place edit (Iron-Rule-2 safe, no shift), NOT a reader fork. Gorbunok → pool 0 slot 3.
* **Breeding recipe display (`bank_016` `label16_485c`, entry 1) + the `$0301` parent seam.** Entry 1
  reads `FamilyRecipeTable[p1*2]` → the offspring's parent pair (icons) with NO bounds check; the
  222-entry table overshoots at id≥222, so the patched build does `call FamilyRecipeResolve` (DISPLAY
  fork only — RESULTS are authored in the bank `$69` special-table append). The two `$0301` calls in
  the determination chain are annotated as the parent→family resolution that routes through the forked
  bank-`$03` info loader. *(The determination internals proper remain for a breeding-mechanics pass.)*

### Lineage parent-name line (S38 — patch, user-confirmed)

The library/encyclopedia lineage line-1 is **mode 0** of bank `$4d`'s text table (`$400b`), the
2-parent recipe line ("P1" + "P2" as two 9-char fields, e.g. slot 200 "Servant  GreatDrak"). It is
NOT the monster name (that is mode 5 / `$41:$4339`). For id≥224 the render routes
`LoadItem_6456` → bank `$4d` entry 2 (`call SetB4d_43b9`) → `HighDetailTextFork` → `HighModeTable4D`.
Slot 224 of vanilla `$400b` is the shared "?????    ?????" placeholder (`$53C4`). S38 wires
`HighModeTable4D` mode-0 → `HighMode0Ptrs` (`dw GorbunokRecipeLine`, base = `HighMode0Ptrs - $01C0`
so `[base+224*2]` = the entry), and `GorbunokRecipeLine` = `"Snaily   BattleRex"` in the correct
two-9-char-field format (the S32-staged single-space string was mis-columned). `patches/bank_04d.asm`;
id≥224-gated so ids 0–223 byte-identical. Built-ROM verified `[mode0base+224*2]→GorbunokRecipeLine`.

## Party/farm boundary semantics + monster-array access map (CF1, S56)

The complete access map for the party/storage monster array — the gating RE
for the Cold Farm arc (CF2/CF3). Machine-readable twin:
`extracted/monster_walkers.json` (generator `tools/map_monster_walkers.py`,
self-checking against the source). Everything below was read from the
disassembly this session; addresses are vanilla.

### Membership model (the headline answer)

Party membership is **dual-represented and NOT positional**:

1. **Per-record in-use flag at +$00**: `$00` = empty, `$01` = farm/storage,
   `$02` = party member. This tri-state is what the battle engine trusts
   (exp shares fork on `cp $02` in the exp walker `$50:$61E2`).
2. **Party order list**: `$CA8D` = party count (0-3); `$CA8E-$CA90` = three
   slot indices into the 20-slot array (`$FF` = empty entry). This is what
   UI ordering, battle position mapping, and script party access use.

Party members can sit at ANY array index; the list points at them. The two
representations are synced by the **canonicalizer `ReadPartySlotInfo`
(`$01:$46F6`, bank $01 dispatch entry 5, 22 call sites across 8 banks — the
standard "roster changed" epilogue)**, which: clears list entries pointing at
empty slots (+ shifts the list up), normalizes every occupied flag to `$01`,
re-marks listed slots `$02` (`RetIfSlotInvalid $01:$480D`), **compacts the
array** (149-byte record swaps toward slot 0 via `SaveRegsAndSetupDE
$01:$4819`, using an old→new index map built at `$C0D8`), remaps the list
through that map, recounts `$CA8D`, and reloads follower art (entry 6).
Because of the compaction, occupied slots are contiguous from slot 0 after
any canonicalize — but party members are NOT necessarily slots 0-2.

The inverse direction exists too: the party drop/pick commit
(`$0A:~$6DE6`) rebuilds the LIST from the FLAGS over a 4-entry working set
(3 party + candidate at `$C0D8-$C0DB`), then canonicalizes and reloads
battle data (`$0105` + `$0103`).

`$DA15-$DA17` = battle-position → slot cache, filled from the party list at
battle setup (`$51:LoadBtlS_40d1` via bank $01 entry 7). `$DA12-$DA14` =
give/creation parameter block (EID lo/hi, target slot).

### Record fields established this session

| Offset | Size | Field | Evidence |
|--------|------|-------|----------|
| +$00 | 1 | In-use/side flag: $00 empty / $01 farm / $02 party | exp walker fork; canonicalizer writes; drop/pick flips |
| +$0C | 9 | Nickname (the old "+$14 Name data 1 B" row was the LAST byte of this field) | status render reads `$CACD`; farm detail copies 9 B to `$CA42` scratch |
| +$29 | 8 | $FF-terminated ID list A (semantics UNVERIFIED — sanitized by `ScanPartySlotTable`) | `$01:$46A5` walks it |
| +$31 | 25 | $FF-terminated ID list B (semantics UNVERIFIED — same sanitizer, compacted in place) | `$01:$46BE` |
| +$4A | 1 | Battle status byte; **bit7 = KO/incapacitated** (excluded from exp + eligible-count; bulk-cleared post-battle/heal) | exp walker; `CmpBtl_62dd`; `IteratePartySlots20` clears |
| +$63 | 1 | **Egg flag** ($01 = egg) | set by egg-receive `$12:jr_012_6c0a` + builder sub-cmd $5E (`$14:Jump_014_4586`); exp walker skips ≠0; egg/non-egg menu filters test it |

### Battle exp distribution (vanilla, `$50:$61E2`)

Total battle exp lives in `$DD23-$DD25` (24-bit). Eligible party count b =
listed members that are not `$FF` and not KO'd (+$4A bit7). Then ONE walk
over all 20 slots pays out:

- flag `$02` (party): + total/b (rounding quirk: b=3 → +1, b=1 → −1, b=2 exact)
- flag `$01` (farm): + **total/16 each** (computed once at walker head)
- skipped entirely: empty, egg (+$63≠0), KO'd party member, level 99 (`$63`),
  level ≥ cap (+$4C)
- clamp at 9,999,999 (`$98967F`)

Level-ups then run in a separate state: party list members FIRST
(`$CA8E/8F/90` through `CmpBtl_6383`), then the all-20 scan `jr_050_6318`
(so farm monsters level immediately post-battle in vanilla). Bank $13
entries: 0 = next-level threshold fetch → HRAM `$D5-$D7`, 1 = snap exp to
level, 2 = apply level-up stat gains ($C8D0 = hit-cap flag).

**Cold Farm consequence**: the party/farm fork ALREADY exists at exactly one
site each for exp (the `cp $02` in the walker) and leveling (the all-20 scan
after the party list). CF2's "party-only + pending-exp accumulator" is a
retarget of these two sites, not new plumbing.

### Staging pseudo-slots $14/$15 ($D665/$D6FA) — NEW

`GetMonsterDataPtr` masks with `$7F`, so indices $14/$15 address two
149-byte pseudo-slots immediately after slot 19 ($D665-$D6F9, $D6FA-$D78E).
They are inside the `$C8EA-$D9E9` save image. Uses found:

- **Breeding**: both parents are copied to slots 20/21 and DELETED from the
  array before bank $16 runs; breeding math indexes parents as `field+$0BA4`
  and `+$0BA4+$95` (`$16:SaveBrd_41ff`). Two-parent flow at `$0A:~$5877`;
  NPC-mate flow at `$0A:~$4F00` (mate synthesized from EID `$C8F7/8`
  directly into slot 21). Offspring is inserted later at first-empty by
  `$16:jr_016_402d`, which persists the chosen slot in **`$CA40`** for the
  script-side finalizer (`$04:label4_64c2`). Breeding force-saves
  (`SaveGameState`) and warps to gate 8 (Starry Shrine).
- **Link trade**: send = copy → slot 20 + delete (`$15:jr_015_5aa5` head);
  receive = staged monster in slot 21 → seen-bit set for its species →
  traded-away slot deleted → canonicalize → staged record copied into slot
  19 → canonicalize again → forced partial SRAM saves (`$18:~$4C50`,
  anti-clone: party list + seen bits + whole array via `SavePartyToSRAM`).
- **Menus**: bank $15 initializes slot 20 as scratch (`$CAC0:=$14`,
  `$D665:=0`) and views slot 21 (`$CAC0:=$15`) for the incoming-trade
  preview. Bank $03's link viewer navigates slot indices up to `$16` (BCD).

### Roster mutation paths (create/delete/move)

All record creation funnels through the bank $14 builder `label14_40b4`
(`$1402` dispatch; zero-fills the slot, $FF-fills the +$29/+$31 lists,
copies enemy-stats-derived fields, rolls stats 80-100%, sets in-use `$01`):

| Path | Where | Behavior |
|------|-------|----------|
| Script give $29 | `$04:label4_5c14` | first-empty → `$DA14` → build; if `$CA8D`<3 ALSO appends to party list (`$CA8D`++) |
| Script give $28 | `$04:label4_5f9a` | first-empty → build; storage only |
| Egg receive | `$12:jr_012_6c0a` | first-empty → build → +$63:=1; EID pair from table `$12:$6D2B` by egg id (event flags $0050-$0057) |
| Battle join | `$51:SetBtlS_63e8` scan + `$50:jr_050_63ea` (fight→join EID via boss redirect `$1406`) | first-empty → build → party-list append if room → canonicalize |
| Breeding offspring | `$16:jr_016_402d` (+`$CA40` persist) | first-empty → zero-fill → bank $16 fills |
| Debug spawner | `$55:SaveB55_53f6` | first-empty-style build (debug menus) |
| Release ("part with") | `$12:~$63E0` | in-use:=0 + canonicalize |
| Trade send | `$15:jr_015_5aa5` | copy → slot 20, in-use:=0 |
| Trade receive | `$18:~$4C50` | slot 21 → slot 19 insert + forced saves |
| Sleep | `$12:SetItem_5fde` init (`$CA41` bit7 gate, zero `$B124` ×$BA4) + transfer loops; scanned by bank $07 | one-way WRAM→SRAM archival |
| Compaction | `$01:ReadPartySlotInfo` | records MOVE between slots on every canonicalize |

Breeding guardrails (`$0A:~$538C`): parent level ≥ 10; if `$CA8D`==2 both
selected parents must be flag `$02` — the party can never be emptied.

### Walker classification summary

44 `ld [$CAC0], a` writer sites (the S55 count — each heads an access path)
+ 60 register/stride walkers, all classified in
`extracted/monster_walkers.json`: totals all-slot=50, single-slot=29,
farm-write=12, party-only=8, staging=5. The dominant patterns:

- **Menu banks $0A/$12/$15/$18** never iterate GetMonsterDataPtr per
  cursor move; they pre-build display lists of slot indices at `$C0D8`
  (count walker + list-build walker pairs, filtered by egg flag/mode) and
  select via `$CAC0 := $C0D8[cursor]`.
- **Single-slot readers** (326 GetMonsterDataPtr call sites) overwhelmingly
  take the slot from `[$CAC0]`; classifying the 44 writers therefore
  classifies them.
- **The only all-slot WRITERS** are the canonicalizer (compaction), the exp
  walker (+$4D adds), `IteratePartySlots20` (+$4A clears), and
  `ScanPartySlotTable` (list sanitize) — everything else mutates single
  slots chosen via `$DA14`/cursor.

### Cold Farm implications (feeds CF2/CF3)

1. Party is list+flag, not position: an SRAM farm design must either keep
   party records in WRAM and remap `$CA8E-$CA90`, or hot-swap on
   canonicalize. The canonicalizer is the single choke point for both
   representations — 22 call sites, one body.
2. The exp/level fork points are single-site (see above).
3. First-empty scans (6 creation paths) and the menu list-builder pairs are
   the farm READ/WRITE surface that must learn the new boundary; they share
   two idioms (stride scan of +$00; `$C0D8` list build), so a redirected
   helper covers them mechanically.
4. Staging slots 20/21 and their breeding/trade flows are WRAM-resident and
   save-imaged; they are independent of where farm slots live.
5. The sleep pool proves the "monsters in SRAM, scanned via EnableSRAM per
   access" pattern already ships in vanilla (bank $07/$12) — CF3 can copy
   that access discipline.
