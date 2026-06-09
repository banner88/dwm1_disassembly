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

## Data Files

- `extracted/monsters_full.json` — all 221 monsters with labeled fields
- `extracted/enemy_stats.json` — all 487 enemy stat entries
- `extracted/breeding_complete.json` — complete breeding data (both tables)
