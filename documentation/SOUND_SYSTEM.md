# SOUND SYSTEM — engine, song table, sequence format (M1, S61)

Everything here was verified against `disassembly/bank_000.asm` and ROM bytes
in S61 unless marked *(unverified)*. Tool: `tools/enumerate_songs.py`
(enumerates all sounds, walks every stream to termination, decodes tracks).
Status: **M1 complete. M2 (byte-identical round-trip) NOT started — the
*(unverified)* items below are M2's checklist.**

## 1. Architecture (all in ROM0 — the "$08 audio bank" claim was wrong)

The sequence engine lives entirely in **ROM0 $3331–$3AB2** (region), driven
from VBlank. Bank $08's `LoadAudP` is only the SGB packet path. The old
ROADMAP claim that song data lives in banks `$61 $62 $63 $65 $66 $68 $78 $7b
$7d` is **FALSE** (those banks hold sparse non-audio data, graphics-like;
falsified S61). Audio data lives in banks **$1C, $1D, $1E** only.

Flow per frame (VBlank, `bank_000.asm`):
```
VBlankProcessAudio -> ProcessBGMQueue   consume wBGM ($C8B4) / wSoundEffect
                                        queue vars ($FF = empty, $9D = skip)
SaveBankAndAudioState                   per-frame driver: for each of 6 virtual
                                        channels: copy 26B state -> HRAM
                                        $FFE4-$FFFD, tick, copy back
```

Starting a sound: `SetBGM` ($1AE1) just stores to `wBGM`; next VBlank
`InitBGM` ($1AE5) runs `AudioProcess` ($3477) 2–4 times (`AudioUpdate1x/2x/3x`
$3474/$3471/$346E chain into it). **Each call increments the sound id
`$DE24`**, so a multi-channel sound = CONSECUTIVE sound ids, one per channel.
Default BGM = 3 channels (`AudioUpdate2x` path); id $27 = 4 channels
(`AudioUpdate3x`); the `InitBGMAlt` list ($3A,$3F,$47,$49,$4B,$4D,$4F,$5D,$9D)
= 2 channels; sound effects use `LoadSE`'s own per-id channel-count lists.

## 2. Master sound table @ ROM0 $3466 (the M3 hook point)

Rows of 4 bytes `[base_id, ptr_lo, ptr_hi, bank]`, sentinel base `$FF`:

| ids | records at |
|-----|-----------|
| $00–$20 | $1C:$4001 |
| $21–$36 | $1D:$4001 |
| $37–$9D | $1E:$4001 |

Lookup (`AudioProcess`): scan rows for the first `base > id`, use the
PREVIOUS row; record = `bank:ptr + (id-base)*4`. The table pointer is a
3-byte `ld hl, $3466` immediate inside `AudioProcess` — **M3 extends the id
space by copying the table elsewhere in ROM0 + adding a row + repointing
this one operand** (table must stay in ROM0: it's read before the bank
switch). Ids $9E–$FC are free ($FF = queue-empty sentinel, $9D = skip
sentinel; both must stay unused).

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
| +8 | $EC | note length remaining (ticks) |
| +9 | $ED | pulse: duty/period byte, wave: wave-instrument id ($FF = unset) |
| +$0A/$0B | $EE/$EF | loop counters A/B (cmd $Bn) |
| +$0C/$0D | $F0/$F1 | effect rate / effect param (cmd $Cn; wave out-level) |
| +$0E | $F2 | frequency-write throttle *(semantics partly unverified)* |
| +$0F | $F3 | pitch-slide amount (signed, cmd $Dn/$En) |
| +$10/$11 | $F4/$F5 | pitch-slide period reload/counter |
| +$12/$13 | $F6/$F7 | last freq-lo guard / NR-4 retrigger+pan byte |
| +$14/$1A→$FE? | $F8,$FE | loop mark position (cmd $FD) lo/hi *(offsets unverified — confirm in M2)* |
| +$16/$17 | $FA/$FB | tick length reload / tick countdown (frames per tick, from $A3) |
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
| `nn ll` (nn<$A0) | note: low nibble semitone 0–11 (≥$0C = rest/key-off), high nibble = octave downshift (freq >> n); `ll` = length in ticks. Noise ch: nn = raw index into noise table $37C5 (<$10), $1F = rest |
| `A0 xx` | set envelope `$EB = swap(xx)` + retrigger via `AudioCommandHandler` ($3AB3) *(handler internals unverified)* |
| `A1 xx` | instrument: wave ch = load 16B wave `$316E + xx*16` → $FF30; pulse = xx → $ED |
| `A2 xx` | pulse: duty (xx rrca×2 & $C0 → $E9); wave: xx → $F1 out-level |
| `A3 xx` | tempo/groove: bit7=0: `(xx&$0F)*2` → $FA/$FB frames-per-tick, bits4–6 → $E5 groove, sets $E5 bit7; bit7=1: clear gate |
| `A5 xx` | $F9 pan/enable ctl (xx=$01 swaps current) *(unverified)* |
| `A6 xx` | write xx to NR50 (master volume) |
| `A7 xx` | rest: xx → $EC, no retrigger, keeps NR51 mask |
| `A8 xx` | xx → $FC *(unverified fx)* |
| `AE xx` | xx&$10 → $E9 bit4: select alternate tuning half (+12 entries into pitch table) |
| `AF xx` | xx&$0F → $E9 low nibble: per-frame pitch-slide rate |
| other `Ax xx` | **2-byte no-op** (falls through to skip) — this is why DWM2's extra `$AC` is safe to feed this engine |
| `Bn xx` (n=1–F) | loop: repeat-count n on counter A (xx=0 → $EE) or B (xx≠0 → $EF); while count remains, next `$FC`/mark-return is taken, else skipped |
| `B0 FC lo hi` | unconditional jump to pair index hi:lo (3 bytes; safe: next fetch recomputes address from pos) — also appears as bare `FC lo hi` |
| `Cn xx` | effect (gate/vol shape): n<<4 → $F0, xx → $F1, gated on $EB low nibble = 0 *(exact audible effect unverified)* |
| `Dn xx` | pitch slide UP: rate n → $F3, xx → $F4/$F5 period |
| `En xx` | pitch slide DOWN: rate −n → $F3, xx → $F4/$F5 period |
| `FD xx` | set loop mark = current pos → $F8/$FE (param ignored) |
| `FF` | channel end: pos := $FFFF, sweep off |

Note frequency table: **ROM0 $3A53**, 12+12 words (normal + alt half via
$E9 bit4, offset +$18 bytes). Noise period table: **$37C5** (16 bytes).
Wave instruments: **$316E**, 16 bytes each, ≥16 instruments.

## 6. Enumeration result (tools/enumerate_songs.py; extracted/songs.json)

86 sounds, 158 channel streams, **every stream terminates (end or loop),
zero overruns**, streams tile banks $1C/$1D/$1E contiguously. 21 sounds are
BGM-slot music (2–4 channels), the rest jingles/SEs. Selected BGM starts:
$06 (first BGM, 3ch), $27 (only 4ch BGM, noise channel), $37/$3A/$3C…
short pieces in $1E. Custom-room NPC currently sets BGM $1E (Arena) —
`patches/bank_060.asm` `CustomRoom0_NPC02`.

## 7. DWM2 cross-compatibility (S61, from user-supplied GBS rip `DMG-BQLJ-JPN.gbs`)

DWM2 (Cobi's Journey JP) runs an **evolved sibling of the same engine**:
- ~1.8 KB of byte-identical code/data runs incl. the **note pitch table
  (identical)** and the **wave instrument table (all 16 slots identical)**.
- Same master-table algorithm (table @ GBS $3DC2; DWM2 audio banks
  $40–$43), same 4-byte records, same 2-byte-pair stream format, same
  song-start convention (first BGM = id $06).
- Driver-side changes: channel state grew 26→32 bytes; new stream commands
  exist (seen: `$AC`, a countdown/repeat fx) — unknown `$Ax` are 2-byte
  no-ops to DWM1's interpreter, so DWM2 data degrades gracefully.

**DWM2 BGM #06** (user's target; GBS song-map index 5 → internal id $16):
3 channels, `$40:$67EF` (pulse1, 692 B) / `$40:$6C5F` (pulse2, 578 B) /
`$40:$70BF` (wave, 492 B) = **1,762 bytes total**, all streams terminate,
wave ids used = 3/9/11 (byte-identical in DWM1). **Direct port judged
feasible**: relocatable streams + 12 bytes of records + master-table
extension (§2) + fix headers/`$AC` if SameBoy playback shows artifacts.

## 8. M2/M3 implications

- M2 round-trip: decode→re-emit banks $1C–$1E byte-identical; the
  *(unverified)* rows above are exactly what M2 must nail (envelope handler,
  $A5/$A8/$Cn semantics, state +$14/+$1A layout).
- **Song sources (user requirement, S61): BOTH DWM2 tracks AND MIDI files.**
  M2's decoded-song spec is therefore the common intermediate format:
  `DWM2 GBS/ROM → extractor → spec` and `MIDI → converter → spec`, then one
  `spec → (records + streams)` compiler for both. DWM2 side stays
  extraction-only (walk streams via the shared format; no further DWM2
  driver RE). MIDI side: quantize to the tick grid ($A3 tempo), map melodic
  voices to pulse1/pulse2 + bass/lead to wave, drums to noise, clamp pitches
  to the 12-semitone × octave-shift model.
- M3 authoring: new ids ≥ $9E; records+streams in a free bank; ROM0 patch =
  relocated master table + one repointed `ld hl` operand; then either
  script `SetBGM new_id` or the room-BGM path. DWM2 imports need a
  channel-count entry decision (3ch default path needs NO InitBGM change).
