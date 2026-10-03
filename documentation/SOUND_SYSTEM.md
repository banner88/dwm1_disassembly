# SOUND SYSTEM — engine, song table, sequence format (M1, S61)

Everything here was verified against `disassembly/bank_000.asm` and ROM bytes
in S61/S62 unless marked *(unverified)*. Tool: `tools/enumerate_songs.py`
(enumerates all sounds, walks every stream to termination, decodes tracks).
Status: M1-M3c complete (S61-S64); **S116 (ROADMAP P3.13b): the editor RUNS this
engine (§9), InitBGM starts a project song's own channel count, a second song
bank, gate songs and battle songs (§10).** The remaining *(unverified)* items
are the audible meaning of `$A5`/`$A8`/`$Cn` — no longer needed for authoring or
preview (the editor executes the handlers; §9).

## 1. Architecture (all in ROM0 — the "$08 audio bank" claim was wrong)

The sequence engine lives entirely in **ROM0 $3331–$3AB2** (region), driven
from VBlank. Bank $08's `LoadAudP` is only the SGB packet path. The old
ROADMAP claim that song data lives in banks `$61 $62 $63 $65 $66 $68 $78 $7b
$7d` is **FALSE** (those banks hold sparse non-audio data, graphics-like;
falsified S61). Audio data lives in banks **$1C, $1D, $1E** only.

Flow per frame (VBlank, `bank_000.asm`):
```
SaveBankAndAudioState                   per-frame driver: for each of 6 virtual
                                        channels: copy 26B state -> HRAM
                                        $FFE4-$FFFD, tick, copy back
VBlankProcessAudio -> ProcessBGMQueue   consume wBGM ($C8B7) / wSoundEffect
                                        ($C8B8) queue vars ($FF = empty,
                                        $9D = skip)
```
**Order + lag frames (measured S116, tools/census_sound_engine.py):** the driver
runs FIRST, then the queue — a request made during frame n starts in that
frame's queue pass and sounds from the driver tick of frame n+1. The driver is
also called from `VBlankReentry` on lag frames (bank_000 ~line 719) without a
queue pass, so music keeps time when the main loop runs late. (The S61 text
said wBGM = $C8B4: wrong — game.sym `wBGM` = **$C8B7**; DOC_AUDIT S116.)

Starting a sound: `SetBGM` ($1AE1) just stores to `wBGM`; next VBlank
`InitBGM` ($1AE5) runs `AudioProcess` (**$33D2** — the S61 "$3477" was a
transcription slip, sym-verified S63; same for the update chain:
`AudioUpdate1x/2x/3x` = **$33CF/$33CC/$33C9**, not $3474/$3471/$346E)
2–4 times. **Each call increments the sound id
`$DE24`**, so a multi-channel sound = CONSECUTIVE sound ids, one per channel.
Default BGM = 3 channels (`AudioUpdate2x` path); id $27 = 4 channels
(`AudioUpdate3x`); the `InitBGMAlt` list ($3A,$3F,$47,$49,$4B,$4D,$4F,$5D,$9D)
= 2 channels; sound effects use `LoadSE`'s own per-id channel-count lists.
InitBGM first runs `InitAudioSystem` (every channel state dead = $FF at +0 and
+$19, NR52 $80, NR51 0, NR50 $77) and stores the id in wCurrPlayingBGM ($C8B5).
**Patched (S116):** InitBGM is a SAME-SIZE rewrite (71 B, $1AE5-$1B2B, so
PlaySoundEffect stays at $1B2C): the 2-channel chain is a 9-byte table scan
(`InitBGMTwoChannelIds`, identical result for every id < $9E) and ids >= $9E
far-call bank $71 entry 6 `CustomBGMStart`: `CustomBGMChanTable[id - $9E]`
consecutive ids (1-6 — a project song's own channel count), 3 when the byte is 0
(not a song's first id — the old behaviour). The developer sound test (bank $55
`BGM_IDS` / `SE_IDS`) is the game's own music-vs-effects split.

## 2. Master sound table — vanilla @ ROM0 $3466; **extended copy @ $3FE8 (M3a, S63)**

Rows of 4 bytes `[base_id, ptr_lo, ptr_hi, bank]`, sentinel base `$FF`.
**Patched tree (S63):** `AudioProcess`'s single `ld hl, $3466` operand
(instruction @ $33D8) is repointed to **`AudioMasterTableExt` @ ROM0 $3FE8**
(patches/bank_000.asm) — the vanilla 13-byte table @ $3466 cannot grow in
place (live code hard against both ends) and remains in ROM, unreferenced.
The $3FE8 24-byte slot was freed by merging the byte-identical
`MapIDClampForDispatch`/`MapIDClampForPalette` twins and deleting dead
`CustomGFXMapID` (both now @ $3BC2; see DOC_AUDIT S63). Rows 1–3 are
byte-identical to vanilla; one future row (a second song bank) fits in the
slot's filler before the table must relocate again. **S116: that row is used —
the rows are the compiler region `rom0_audio_master`** (editor2/core/music.py):
row 4 `[$9E, $4001, $74]`, row 5 `[split, $4001, $75]` when songs spill (songs
fill bank $74 in first-id order; the first that no longer fits starts bank $75
and is the split), sentinel, $FF filler to 24 B. Bank $75's records are indexed
from the split: `$75:$4001 + (id - split)*4`. The vanilla 13-byte table @ $3466
is re-sectioned as `AudioMasterTable` (db rows) in both trees (S116).

| ids | records at | |
|-----|-----------|---|
| $00–$20 | $1C:$4001 | vanilla |
| $21–$36 | $1D:$4001 | vanilla |
| $37–$9D | $1E:$4001 | vanilla |
| **$9E–$FC** | **$74:$4001** | **custom song bank (patches/bank_074.asm, S63)** |
| **split–$FC** | **$75:$4001** | **S116: the second custom song bank (patches/bank_075.asm) — a 5th row, only when the project's songs pass bank $74's 16,000 stream bytes** |

Bank $74 layout (vanilla audio-bank convention; generated by
`song_codec.py emit-song-bank` from `extracted/custom_songs.json`): $4000
bank byte; $4001–$417C **fixed 95-slot record area** ($00 = unassigned id —
never dispatch an unassigned id); streams tile from $4180 (fixed record
area ⇒ adding songs never relocates existing streams).

Lookup (`AudioProcess`): scan rows for the first `base > id`, use the
PREVIOUS row; record = `bank:ptr + (id-base)*4`. The table must stay in
ROM0: it's read before the bank switch. Ids $FD–$FE stay unused by
decision; $FF = queue-empty sentinel, $9D = skip sentinel.

Bank-switch convention: bank low byte -> `[$2100]`, `(bank>>5)&3` ->
`[$4100]`; current bank read back from `[$4000]` (every bank stores its own
number at $4000).

## 3. Per-id channel record (4 bytes @ bank:$4001 + (id-base)*4)

`[state_slot, hw_channel, seq_lo, seq_hi]`
- `state_slot` ∈ {$00,$1A,$34,$4E,$68,$82}: offset of the channel's 26-byte
  state block at `$DD80`. Convention: $00/$1A = SE pair, $34/$4E/$68/$82 =
  BGM pulse1/pulse2/wave/noise. (Sound id 0 = 6-channel all-silence.)
- `hw_channel` 0–3 = pulse1/pulse2/wave/noise (also NR51 mask class:
  $EE/$DD/$BB/$77 applied to `$DE1D`).
- `seq` = pointer to the stream **in the same bank as the record**.

## 4. Channel state (26 bytes @ $DD80+slot ↔ HRAM $FFE4–$FFFD while ticking)

| state ofs | HRAM | meaning |
|-----------|------|---------|
| +0 | $E4 | stream position LOW (pair index). 0 = just-initialized (parse in-stream header next tick); with +$19, $FFFF = channel dead |
| +1 | $E5 | low nibble = hw channel; bit7 = key gate; bits 4–6 = groove select (set by cmd $A3) |
| +2/+3 | $E6/$E7 | seq base pointer |
| +4 | $E8 | data bank |
| +5 | $E9 | bits7–6 duty; bit4 = alt-tuning select; low nibble = per-frame pitch-slide rate |
| +6 | $EA | pitch-slide accumulator |
| +7 | $EB | envelope (stored SWAPPED) |
| +8 | $EC | note length remaining — **FRAMES** (~59.73/s), decremented unconditionally every frame by the per-frame driver (instruction-verified S64; the S61 "ticks" reading is falsified — DOC_AUDIT S64) |
| +9 | $ED | pulse: duty/period byte, wave: wave-instrument id ($FF = unset) |
| +$0A/$0B | $EE/$EF | loop counters A/B (cmd $Bn) |
| +$0C/$0D | $F0/$F1 | effect rate / effect param (cmd $Cn; wave out-level) |
| +$0E | $F2 | frequency-write throttle *(semantics partly unverified)* |
| +$0F | $F3 | pitch-slide amount (signed, cmd $Dn/$En) |
| +$10/$11 | $F4/$F5 | pitch-slide period reload/counter |
| +$12/$13 | $F6/$F7 | last freq-lo guard / NR-4 retrigger+pan byte |
| +$14/+$1A | $F8,$FE | loop mark position (cmd $FD) lo/hi — CONFIRMED S62 at instruction level |
| +$16/$17 | $FA/$FB | groove-step period reload / countdown (from $A3). Gates ONLY the groove stepper in `AudioProcessChannel` (~ROM0 $3937: `ret nz` while $FB>0); it does NOT scale note lengths — $EC decrements every frame regardless (S64, instruction-verified: both branches of the $FB check at the $EC countdown fall into `dec [hl]`) |
| +$18 | $FC | cmd $A8 value *(unverified fx)* |
| +$19 | $FD | stream position HIGH |

Address of current pair = `seq_base + pos*2` (`add hl,hl` in the fetch at
$35EA) — **positions are PAIR indices, so all in-stream jump targets are
relative to the stream base: streams are freely relocatable.** Initial pos
= 2 (skips the 4-byte in-stream header).

In-stream header (4 bytes at seq+0): b0 low nibble -> $E9 low (slide rate);
b1 -> duty bits of $E9 (pulse) or $F1 out-level (wave); b2 swapped -> $EB
envelope; b3 -> $ED duty/wave id.

## 5. Stream command set (2-byte pairs unless noted)

| pair | meaning |
|------|---------|
| `nn ll` (nn<$A0) | note: low nibble semitone 0–11 (≥$0C = rest/key-off); high nibble n shifts the pitch-table PERIOD right (`P>>n`) which RAISES the pitch n octaves (freq = 131072/(P>>n); semitone 0, n=0 = 65.4 Hz = **C2 = MIDI 36** — S64, from `AudioLoadNoteB` + the $3A53 table values; S61's "octave downshift" phrasing described the period, not the pitch). `ll` = length in **FRAMES** (§4). Noise ch: nn = raw index into noise table $37C5 (<$10), $1F = rest |
| `A0 xx` | set envelope `$EB = swap(xx)` + retrigger via `AudioCommandHandler` ($3AB3) *(handler internals unverified)* |
| `A1 xx` | instrument: wave ch = load 16B wave `$316E + xx*16` → $FF30; pulse = xx → $ED |
| `A2 xx` | pulse: duty (xx rrca×2 & $C0 → $E9); wave: xx → $F1 out-level |
| `A3 xx` | groove ctl (NOT tempo — lengths are frames, §4): bit7=0: `(xx&$0F)*2` → $FA/$FB groove-step period, bits4–6 → $E5 groove row select, **sets $E5 bit7 (groove ON)**; bit7=1: `$E5 &= $0F` (groove OFF). Groove rows @ ROM0 $3B83 (8×16 signed steps added to the freq via $F6) are ALL live vibrato/detune shapes — there is no all-zero row, so `$A3 $80` is the only deterministic "straight" form (S64; tools/midi_to_song.py emits it) |
| `A5 xx` | $F9 pan/enable ctl (xx=$01 swaps current) *(unverified)* |
| `A6 xx` | write xx to NR50 (master volume) |
| `A7 xx` | hold: xx → $EC with NO retrigger and NR51 mask kept — the sounding note simply continues, so this is the tie/extension primitive (midi_to_song.py chains it for notes >255 frames) |
| `A8 xx` | xx → $FC *(unverified fx)* |
| `AE xx` | xx&$10 → $E9 bit4: select alternate tuning half (+12 entries into pitch table) |
| `AF xx` | xx&$0F → $E9 low nibble: per-frame pitch-slide rate |
| other `Ax xx`, `$F0–$FB xx`, `$FE xx` | **2-byte no-op** (AudioCheckFD chain falls to AudioIncHLLoop). NOTE (S62): DWM2's `$AC` is NOT merely tolerated — its target pair would be executed as a bogus command; DWM2 data must be TRANSLATED, not fed raw (§7) |
| `Bn xx` (n=1–F, xx≠$FC) | counted MARK loop: counter A (xx=$00 → $EE) or B (xx≠0 → $EF); while counting, return to the mark ($F8/$FE); total passes = n+1. **Elapse asymmetry (S62, instruction-verified):** $EE elapse continues at the next pair; $EF elapse does pos+1 — it SKIPS the following pair (this skip exists for the jump form below; vanilla only ever uses xx=$00 or $FC, so mark loops never hit it) |
| `Bn FC lo hi` (4 B = 2 pairs) | counted JUMP loop: the engine inspects the Bn's OWN param at `AudioCheckFC`; $FC → jump to pair index hi:lo read from the NEXT pair; counter B ($EF); total passes = n+1; on elapse pos+1 skips the (lo,hi) pair — landing exactly after the construct. `B0 FC lo hi` = unconditional jump. **There is NO standalone 3-byte `$FC` token** (S61's reading, falsified S62 — DOC_AUDIT): top-level $FC is a 2-byte no-op and never occurs in real data |
| `B0 xx` (xx≠$FC) | unconditional mark-return (no counter) |
| `Cn xx` | effect (gate/vol shape): n<<4 → $F0, xx → $F1, gated on $EB low nibble = 0 *(exact audible effect unverified)* |
| `Dn xx` | pitch slide UP: rate n → $F3, xx → $F4/$F5 period |
| `En xx` | pitch slide DOWN: rate −n → $F3, xx → $F4/$F5 period |
| `FD xx` | set loop mark = current pos (the pair AFTER this one) → $F8/$FE = state +$14/+$1A (CONFIRMED S62); param ignored by DWM1 — DWM2 uses it as a mark-SLOT selector (§7) |
| `FF` | channel end: pos := $FFFF, sweep off |

Note frequency table: **ROM0 $3A53**, 12+12 words (normal + alt half via
$E9 bit4, offset +$18 bytes). Noise period table: **$37C5** (16 bytes).
Wave instruments: **$316E**, 16 bytes each, ≥16 instruments.

## 6. Enumeration result (tools/enumerate_songs.py; extracted/songs.json)

86 sounds, 158 channel streams, **every stream terminates (end or loop),
zero overruns**, streams tile banks $1C/$1D/$1E contiguously. 21 sounds are
BGM-slot music (2–4 channels), the rest jingles/SEs. Selected BGM starts:
$06 (first BGM, 3ch), $27 (only 4ch BGM, noise channel), $37/$3A/$3C…
short pieces in $1E. (An S61 claim that a custom-room NPC "currently sets
BGM $1E" was FALSE — the script existed but no NPC entity was wired to it;
falsified + fixed S62, see DOC_AUDIT. Since S62 the room-$6B screen-0 NPC at
metatile (5,6) runs `CustomRoom0_NPC02` = SetBGM **$9E**, the DWM2 port.)

**Battle-animation sound cues (S112, BATTLE_SKILL_SYSTEM §11.9).** The 45 animation
timelines cue 35 sound effects by `($FD, id)` pairs, ids $70-$9B (the ids between them
are the second channels of two-channel effects); bank $02 `SeqApplyStep` calls ROM0
`PlaySoundEffect` with the id and reads the next pair in the same tick (a cue takes no time). `tools/render_anim_sounds.py` records each from the original
ROM's engine in PyBoy → `extracted/anim_sounds/sfx_XX.wav` (the editor's preview sounds).

## 7. DWM2 cross-compatibility (S61, from user-supplied GBS rip `DMG-BQLJ-JPN.gbs`)

DWM2 (Cobi's Journey JP) runs an **evolved sibling of the same engine**:
- ~1.8 KB of byte-identical code/data runs incl. the **note pitch table
  (identical)** and the **wave instrument table (all 16 slots identical)**.
- Same master-table algorithm (table @ GBS $3DC2; DWM2 audio banks
  $40–$43), same 4-byte records, same 2-byte-pair stream format, same
  song-start convention (first BGM = id $06).
- Driver-side changes (S62, targeted RE of the GBS driver — handlers at GBS
  $35A7/$361C/$37D8/$381A, slot resolver $3D5D, fetch $357C, header parse
  $3503):
  - **`FD slot`**: set mark[slot & $0F] = {counter := 0, pos}. **4 mark
    slots per channel**, 3 bytes each @ $DCC0 + ch*12 — vs DWM1's single
    $F8/$FE mark. Data uses params $F0/$F3 (= slots 0/3).
  - **`Bn slot` (n≥1)**: inc mark counter; while counter < n+1, jump to
    mark[slot] → the marked section plays **n+1 times** (identical total to
    DWM1's counted loops). No pair-skip on exit (unlike DWM1's $EF elapse).
  - **`B0 $Fx`**: unconditional jump to mark[x]; `B0` with param < $F0 =
    no-op.
  - **`$A4` (and `$AB`) are 2-byte no-ops in DWM2 TOO** (S64,
    instruction-verified: the DWM2 Ax dispatch is a linear equality chain —
    cp $A0,$A1,$A2,$A3,$A5,$A6,$A7,$A8,$A9,$AA($37AE),$AC($37D8),$AD,$AE,
    $AF — with NO cp $A4/$AB; unmatched values fall to the terminal default
    `inc hl / jp $358A`). So the `$A4 xx` pairs in BGM #19 (×6) are inert
    padding in BOTH engines and verbatim carriage is exact — unlike `$AA`,
    which is a real DWM2 ornament that DWM1 drops.
  - **`AC n, target`**: counted CALL — the pair AFTER `$AC` is a 16-bit LE
    *byte-offset* target (>>1 = pair index), NOT a command; saves the return
    position; the phrase plays n times. **Phrases live PAST the stream's
    `$FF` terminator** (appendix regions between streams).
  - **`AD x`**: RETURN to the saved `$AC` position (single return slot — the
    driver cannot nest calls).
  - **Headers: all 4 fields parse IDENTICALLY to DWM1** (b0 low nibble =
    slide rate, b1 = duty, b2 swapped = envelope, b3 = instrument) — carried
    verbatim in ports.
- **Raw DWM2 bytes therefore do NOT degrade gracefully in DWM1** (falsifies
  the S61 note): truncating at `$FF` loses the `$AC` appendix phrases, `$AC`
  target pairs execute as bogus commands, and slot loops collapse onto the
  single mark + hit the $EF elapse pair-skip → audible skipping/corruption
  (observed in S62 v1/v2 builds).

**DWM2 BGM #06 port (S62, SHIPPED + user-confirmed by ear):** GBS song-map
index 5 → internal id $16; sources `$40:$67EF/$6C5F/$70BF`.
`tools/song_codec.py translate_dwm2_stream()` walks the true DWM2 grammar
and emits DWM1-native tokens: `$AC` phrases INLINED at call sites (n times),
slot loops → `Bn $FC lo hi` jump form (both engines play n+1 passes),
counted loops whose body contains another counted loop UNROLLED (DWM1's
jump form shares one $EF counter; only pulse1 nested — 2 sites, depth 2).
`prove_translation()` executes the ORIGINAL bytes under DWM2 semantics and
the TRANSLATED bytes under DWM1 semantics and requires identical event
traces (passed: 1858/1566/2287 events over 2 outer loops). Result: 5,035
stream bytes. **ROM home since S63 (M3a): bank $74** — records @ $74:$4001
(ids $9E–$A0, resolved by the AudioMasterTableExt custom row), streams
$4180/$47C3/$4E28; migrated byte-identically from the S62 orphan-slot home
(`song_codec.py import-port` re-decoded the S62 blobs and static
re-trace matched the S62 event counts exactly). **Bank $1E is back to 100%
vanilla** — the S62 orphan-slot route ($419D records + $6B80 filler
streams, zero-ROM0-changes) is retired; it capped at ONE song and is
superseded by the extended table.

**DWM2 BGM #07 (S63 v5, USER-CONFIRMED):** GBS song-map index 6
→ internal id $19 (the GBS init maps song# via the byte table @ GBS
**$0FC0** — `ld hl,$0FC0 / add l / ld a,[hl]`; entry 5 = $16 re-confirms
the #06 mapping). 3 channels → DWM1 ids **$A1–$A3** (`SetBGM $A1`), 2,471
stream B in bank $74 via `song_codec.py add-gbs-song` (extract + translate
+ prove + DWM2→DWM1 slot map + library append). End-to-end proof: the
ROM-RESIDENT bytes traced under DWM1 semantics equal the original GBS
bytes under DWM2 semantics (954/645/840 events). **Uses foreign cmd `$AA`
×20** — DWM2 handler @ GBS **$37AE** read at instruction level (S63):
reads exactly one param, writes only HRAM $F2/$F3/$ED (per-channel
effect-rate/depth + $ED low-nibble merge — a vibrato/ornament class), no
position/mark/counter writes → **non-flow confirmed**, so verbatim carriage
is sound; DWM1 treats $AA as a 2-byte no-op, so the ornament is silently
dropped at those 20 sites (user ear test S63: unremarked — "Sounds great"). Wired: room $6C
screen 0 NPC (5,6) via project.json (compiler-owned route).
Residual unknowns: `$Cn`/`$A5`/`$A8` audible semantics (same family both
drivers; user ear-test clean).

## 8. M2/M3 implications

- M2 round-trip: DONE S62 (`tools/song_codec.py selftest`, byte-identical;
  spec `extracted/songs_spec.json`). Nailed: loop/jump grammar (§5 rewrite),
  mark offsets. Still *(unverified)*: $A5/$A8/$Cn audible semantics, $A0
  handler internals — cosmetic for authoring (byte carriage is exact).
- Custom-song capacity: **M3a COMPLETE S63 (user-confirmed, 2 songs live)** — the
  extended master table (§2) gives ids $9E–$FC → bank $74: 95 record slots
  (~31 three-channel songs), ~15.9 KB stream space (10,965 B free after the
  BGM #06 port). A second song bank later = one more table row (fits the
  $3FE8 slot filler) + its own bank file. The S62 orphan-slot route
  (capped at one song) is retired.
- Authoring path as built (M3b/M3c, S64): **project.json `custom.music`
  owns songs** (PROJECT_COMPILER §2.9) — `libraries` reference the
  repo-committed catalogs `extracted/dwm2_song_library.json` (ALL 31 DWM2
  songs, translated + trace-proven, 57,383 stream bytes; the GBS never
  needs re-uploading) and `extracted/midi_song_library.json`
  (`tools/midi_to_song.py` conversions); the editor2 music emitter calls
  `song_codec.song_bank_asm` → generated `patches/bank_074.asm`.
  `extracted/custom_songs.json` is RETIRED (S64; its two songs re-emit
  byte-identically from the DWM2 library — verified). Songs are normalized
  to the exact 3-channel trio at bake time: missing trio slots get a
  6-byte silent stream (InitBGM starts 3 consecutive ids, so a 2ch song
  packed before another song would otherwise start the neighbor's
  channel); >3ch sources (BGM #04 noise, 4/5ch jingles) drop extras with
  a warning — an InitBGM channel-count extension is a ROADMAP box.
  Assignment = `SetBGM first_id` from scripts AND/OR room defaults below.
- **Room→BGM derivation (traced + rebuilt S64, M3b):**
  `LoadNewBGMIdIntoA` @ $01:$432D–$4372 (70 B, single caller
  `CheckScreenLock` ← `InitFieldState` ← `GameInit` — runs on every map
  entry AND on save-load; the caller compares against `wCurrPlayingBGM`
  and `call nz, SetBGM`). Vanilla logic: `wInGateworld`≠0 → floor path
  ($34, or `RoomBGMTable[wBossMapType]` when `wCurrentFloor == wLastFloor−2` — the floor BEFORE
  the boss floor, carried into the boss floor; CORRECTED S100, PyBoy: Bazaar Gate floors 7/8/9 =
  $34/$0C/$0C — the doc used to say "on the boss floor"); else mapID
  <MAP_ITEMSP($50), ==MAP_COLISUM($52), or $5D–$60 → `RoomBGMTable
  [wMapID]`; mapID ≥$61 (incl. all custom rooms) → gate path — which is
  exactly why script `SetBGM` was transient in custom rooms. **RoomBGMTable
  = $01:$4373, 112 bytes, $70 entries (mapIDs $00–$6F; $61+ padded $34)** —
  re-sectioned from fake instructions to labeled `db` data in BOTH trees
  (clean build still 1ca6579…). The patched tree rewrites the function
  SAME-SIZE (70 B; funded −9 B by dropping the vestigial `cp $09/ret nz/
  ret` tail, the redundant second `ld a,[wMapID]`, and the `adc h/sub l`
  idiom) to call **bank $71 entry 2 `CustomRoomBGMResolve` FIRST**: E :=
  `CustomRoomBGMTable[wMapID]` (128-entry generated table; 0 = vanilla
  fallback; gate floors excluded by the resolver since wMapID is not
  room-meaningful there). Nonzero E wins for ANY mapID $00–$7F — vanilla
  and custom rooms alike — and **survives save/reload by construction**
  (the load path re-runs this same derivation; user-confirmed S64 v6:
  Library $12 → MIDI song, gate_island $6B → DWM2 BGM #07 incl. reload).
  Return-in-E per the proven rst $10 DE-return contract (KEY_LESSONS).
- **Song sources (user requirement, S61 — DELIVERED S64): DWM2 tracks,
  MIDI files, and inbuilt vanilla ids.** The decoded-song spec is the
  common intermediate: DWM2 → `song_codec.py extract-gbs-library` → catalog
  JSON; MIDI → `tools/midi_to_song.py` → catalog JSON (frame-accurate
  boundary rounding — no drift; monophonize per channel; lowest-mean-pitch
  channel auto-maps to wave; $A7 holds extend >255-frame notes; `$A3 $80`
  for deterministic straight playback; `B0 $FC` whole-song loop; decode
  round-trip checked). Vanilla ids assign directly via
  `music.room_defaults` raw values. One `spec → bytes` path
  (`song_codec.emit_song_bank`) serves all three.
- M3 authoring: new ids ≥ $9E resolve via the AudioMasterTableExt row into
  bank $74 (§2); then either script `SetBGM new_id` or the room-BGM path.
  DWM2 imports need a channel-count entry decision (3ch default path needs
  NO InitBGM change).

## 9. The editor runs this engine (S116, ROADMAP P3.13b)

**Why:** the user asked "can you not extract songs?" — every song IS extracted
(§5, songs_spec.json), but notes are not sound. Rather than re-implement the
sequencer (and guess the `$Cn`/`$A5`/`$A8` handlers), the editor EXECUTES it:

* `dwm/sm83.py` — a complete SM83 interpreter (256 + 256 CB opcodes; 498,000
  SingleStepTests cases, 0 failures: `tools/test_sm83.py`). ~1.7 M
  instructions/s in CPython.
* `editor2/core/sound_engine.py` `Machine` — ROM bank 0 + one MBC5 bank, flat
  WRAM, HRAM, the sound registers with the hardware read-back masks and NR52's
  on-bits (trigger / DAC rules — the engine reads bit 2 at every wave note,
  `AudioClearNR31`). `start_bgm(id)` = the game's InitBGM, `start_se(id)` =
  LoadSE, `start_channels(first, n)` = the S116 custom path, `frame()` = one
  `SaveBankAndAudioState` call -> the sound-register writes of that frame.
  ~1,550 instructions per frame (6 channels); ~0.06 s of CPU per second of
  music. The only foreign WRAM read is wCurrPlayingBGM ($C8B5) in InitBGM.
* `editor2/core/apu_synth.py` — the APU those writes drive (squares + sweep,
  wave, noise LFSR tables, the 512 Hz frame sequencer, NR50/NR51, DACs, the
  output capacitor), 32,768 Hz (128 cycles/sample: a frame-sequencer step is
  exactly 64 samples), each sample the exact average of the waveform over its
  128 cycles (box filter, no aliasing). ~0.05 s CPU per second; needs numpy.
* `editor2/core/music_preview.py` `Renderer` — streams any vanilla id, library
  song or project song (laid into a preview bank $74 at id $9E and started like
  the patched InitBGM starts a project song).

**Proof (`tools/census_sound_engine.py`):** PyBoy boots a ROM to the title; per
sound the driver entry (`SaveBankAndAudioState`, $3473) and the queue call
($03B3) are hooked; at the first driver entry the whole audio state (audio RAM
$DD80-$DE2F, HRAM, IO) is copied into a Machine and the request is posted in
both; then at EVERY later driver entry audio RAM, HRAM $FFE4-$FFFD, the
read-back of NR12/22/32/42/43/50/51, NR52 bit 2 and wave RAM (while the wave
channel is off — a CGB read while it plays returns the sample being played)
must be equal. The game's own requests during the run (title-screen effects)
are dropped at the queue hook. Results: **all 85 vanilla sound ids × both
request paths (wBGM and wSoundEffect) × 3,000 frames identical** (the S116
1,200-frame run: 170/170); the patched builds' project songs started by the
build's own InitBGM vs the EDITOR PREVIEW path (`--custom`: original ROM + the
build's banks $74/$75 + its master-table rows, `start_channels`): the example
(4 songs), three fixtures holding all 31 DWM2 songs across both banks with 2/3/4/5
channels, a MIDI import with a noise channel — 0 mismatches (2,400-3,000 frames
each). Negative control (DEC (HL) disabled): 8/8 mismatch.

**What remains approximate:** only the synthesis — the APU's analog side
(DAC curves, the exact capacitor, mid-VBlank write timing; writes are applied at
the frame start). Checked against PyBoy's APU by pitch tracking (the same notes
at the same times on $06/$09/$27); SameBoy stays the ground truth by ear.

**The vanilla catalog (`tools/dump_sound_catalog.py` -> extracted/sound_catalog.json):**
92 start ids (the 85 sound first ids + the room table's / scripts' / code's /
sound test's other starts, e.g. $61 = sound $60's three music channels, the
arena battle room's song): kind (music 18 / jingle 13 / effect 61, from the
sound test lists + a measured play: music = still sounding after 3 minutes),
channels + slots as started, length, the rooms (RoomBGMTable), scenes (set_bgm
scripts) and code sites using it. Battle-related: **$27** every battle, **$2B**
the Starry Night final, **$4B / $4D** the battle-start jingle (gate floors and
maps < $30 / maps $30+ outside gates, bank $13 `label13_7370`), **$02** music
off (silent channels).

## 10. Gate songs + battle songs (S116, patches; PROJECT_COMPILER §2.9)

**Room / gate (bank $71 entry 2 `CustomRoomBGMResolve`, extended):** a gate's
own song (`CustomGateBGMTable[wGateID]`, gates 0-95) replaces the gate theme
where vanilla plays it: maze floors, the special rooms ($50/$51/$53-$5C — the
vanilla derivation routes them to the gate path; they only occur in dives) and
custom rooms whose `CustomRoomBGMTable` byte is **$FF** (a gate room with no song
of its own: rooms served by a gate rule and custom boss rooms; the compiler marks
them only when some gate has a song). The floor before a VANILLA boss room keeps
the vanilla boss song; before a custom boss room with no song: the gate's song,
else $34. Unmarked custom rooms (0) are exactly the S101 behaviour (no gate
song: wGateID may be stale outside a dive).

**Battles (bank $51 `LoadBattle`, a SAME-SIZE rewrite of the 28-byte pick
$4073-$408E -> bank $71 entry 7 `BattleBGMResolve`, E = the song):** vanilla
pick first ($27; $2B in map $5D when wArenaStarryBattle == 2), then: link
battle ($C86C) = vanilla; this fight (`BattleFightBGMTable` [EID lo, EID hi,
song], the first enemy $DA03/$DA04 — set by the trigger before LoadBattle,
measured); in map $5D the Starry-final / arena settings; the room
(`CustomRoomBattleBGMTable[wMapID]`, $FF = the dive's gate); the gate
(`CustomGateBattleBGMTable`, on maze floors / special rooms / $FF rooms); a boss
fight ($DA09 == 3 — measured: the gate bosses AND conversation battles,
`talk.steps` battle) = the boss setting; every battle vanilla gives $27 = the
normal setting. 0 = not set everywhere.

**Proof:** `tools/census_music_resolve.py` stub-calls entries 2 and 7 of a built
ROM over random game states (every map class, gates with / without songs, the
floor before vanilla / custom / $80+ boss maps, fights, link, Starry 0-2,
modes 0-3) against `music.model_room_bgm` / `model_battle_bgm`: 4,000 / 4,000
on a fixture with every setting; negative control 86/600 mismatched. In-game on
the user's save (S116 demo, PyBoy): a 4-channel room song (noise alive), a
fight's own song from bank $74, a gate's floor song from bank $75 + its battle
song, the floor before the custom boss + the boss room following the gate song,
the boss fight on $2B, the Castle back on $09, a vanilla gate on $34 / $27, an
arena battle (Starry match 1) on the arena song.

