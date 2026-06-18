# Gate-Entry Freeze — Root Cause & Fix

> **TL;DR.** Walking into *any* gate from a fresh game froze the patched ROM. The
> cause was a custom-room script-divert hook in bank `$04` that tested the **script
> map-type** (`wScriptMapType`) instead of the **room map-type** (`wMapID`). Gate
> world hardcodes `wScriptMapType = $70`, which is `≥ $6B`, so the hook mistook the
> gate's script for a custom-room script and diverted it into bank `$60` — reading
> garbage and hanging the floor transition. A second, related defect made the same
> hook an infinite loop for map-types `$40–$6A`. Fixed by routing the divert decision
> through a new bank-`$60` entry (`GateAwareDispatch`) that keys off `wMapID`. The
> clean disassembly is untouched; the fix is two patch files.

---

## Symptom

- On a **fresh new game** (no save dependency), entering Gate of Beginning floor 1
  froze immediately — black/stuck screen, before any monster or interaction.
- Reproduced on every patched build going back several sessions, including the
  recorded "known-good" test ROM `065943f6` (which had only ever been confirmed for
  the *library*, never for walking into a real gate).
- At the freeze, `PC = $02e2` — the ROM0 main wait loop spinning on `$C88E` (the
  screen-transition flag), which never got set. `ReadStepBlock` (`$0B:$4239`) polled
  every frame with `wInGateworld = $01`, `wMapID = $0D`. The CPU was *idling*, not
  trapped in a tight loop: the floor-entry script had bailed and the transition never
  completed.

## Why it hid for so long

The custom-room system was always exercised by **warping into custom rooms from
GreatTree**, never by **walking into a real gate from a fresh game**. The two paths
share the bank-`$04` script dispatcher, but only the real-gate path feeds it the
`$70` script map-type that trips the bug. The first full fresh-game playthrough was
the first time the faulty path ran. **This is a latent pre-existing regression, not a
fault of any recent (breeding B1–B7 or Spirit/B9) work.**

## The investigation (what was ruled out)

A multi-session bisection cleared everything else before landing on bank `$04`:

| Suspect | Verdict | How |
|---|---|---|
| Spirit/B9 family reassignment | cleared | Reverting families to vanilla still froze |
| Spirit/B9 library (`bank_012`) + icon (`bank_04f`) | cleared | Vanilla `bank_012` still froze; `bank_012` not on gate path |
| Breeding (B1–B7) | cleared | Breeding-only ROM entered gates fine; bank-`$16` edits don't touch the gate tables `$70A6/$7896/$7A96` |
| Bank-`$16` gate-step reader (`LoadFloorDataPointer`, entry 9) | cleared | Byte-identical to vanilla |
| `ReadStepBlock` gate branch (`$0B:$4239`) | cleared | Byte-identical to vanilla (label rename only) |
| mapID-clamp intercepts (`MapIDClampForPalette/Dispatch`, `CustomGFXMapID`) | cleared | All `ret` raw mapID for `< $6B`; gate rooms are below that |
| **Bank-`$04` script-dispatch hook** | **CULPRIT** | Breakpoint `$04:$720d` fires on gate entry with `A = $70` |

## Root cause (the mechanism)

Bank `$04`'s `MapTypeDispatch` routes the room-entry/NPC script to a script bank by
map-type: `<$06`→`$0C`, `<$20`→`$0D`, `<$40`→`$0E`, **`≥$40`→`$0F`** (gates,
labyrinth, arena, post-game). Gate world deliberately sets `wScriptMapType = $70`
(see `bank_001`, the gate-world room-entry path), so it correctly belongs in the
bank-`$0F` bucket.

The custom-room work added a hook at `DispatchBank0F` (`$04:$720d`) → handler
`DispatchBank0F_Ext` (`$04:$7fd8`) intended to divert *custom rooms* to bank `$60`:

```
DispatchBank0F_Ext:          ; the BUGGY version
    cp CUSTOM_ROOM_START      ; $6B  — tests A = wScriptMapType
    jp c, DispatchBank0F      ; (A) re-enters the overwritten $720d hook → infinite loop
    ld hl, $6004              ; (B) A ≥ $6B → divert to bank $60 (custom script reader)
    rst $10
    ret
```

Two defects:

- **(B) Gate freeze.** The test is on `wScriptMapType`, but `wScriptMapType ≥ $6B` is
  **legitimate bank-`$0F` territory** — gate world is `$70`. So a gate's script
  (`A = $70`) was diverted into bank `$60`'s custom-room reader, which read garbage
  script data for a room that isn't custom. The room-entry script died, the transition
  never set `$C88E`, and the game fell into the idle loop forever. The custom-room
  test must key off the **room** identity (`wMapID`), the only value that is `≥ $6B`
  *exclusively* for real custom rooms (gates keep a normal `wMapID`, e.g. `$0D`).

- **(A) Infinite loop.** `$720d` had been overwritten with `jp DispatchBank0F_Ext`,
  so `jp c, DispatchBank0F` (the "normal room" branch) jumped back to `$720d` →
  `$7fd8` → `$720d` … forever, for any map-type `$40–$6A`. Introduced when the handler
  was later "optimized." Separate from the gate freeze (which takes the `≥$6B`
  branch), but equally real.

## The fix

The correct discriminator is `wMapID`, and the normal path must do the **real**
bank-`$0F` dispatch (`ld hl,$0f00; rst $10`), never re-enter the overwritten hook.
That logic needs more bytes than bank `$04`'s full, no-shift slot allows, so the
decision is delegated to a new **bank `$60` entry 6** (which has ~15 KB free) — the
same trampoline mechanism the custom-room system already uses.

**`patches/bank_004.asm`** — `DispatchBank0F_Ext` becomes a same-size (10-byte slot)
redirect, killing both the loop and the bad divert:

```
DispatchBank0F_Ext:
    ld hl, $6006              ; bank $60 entry 6: GateAwareDispatch (reads wMapID)
    rst $10
    ret
    ; (5 bytes spare in the slot, left as padding — zero byte shift)
```

**`patches/bank_060.asm`** — new entry 6, routed by `wMapID`:

```
GateAwareDispatch:
    ld a, [wMapID]            ; $C968 — the ACTUAL room map-type
    cp CUSTOM_ROOM_START      ; $6B
    jr nc, .customRoom        ; wMapID ≥ $6B → genuine custom room
    ld hl, $0f00              ; else: bank $0F entry 0 — vanilla gate/script dispatch
    rst $10
    ret
.customRoom:
    jp CustomScriptRead       ; bank $60 entry 4 logic (same bank); returns BC
```

Behaviour after the fix:

| Case | `wMapID` | Path | Result |
|---|---|---|---|
| Gate world (`wScriptMapType $70`) | `$0D` (<$6B) | bank `$0F` dispatch | **gate works** |
| Labyrinth/arena/post-game (`$40–$6A`) | `<$6B` | bank `$0F` dispatch | works, **no loop** |
| Genuine custom room | `$6B` (≥$6B) | `CustomScriptRead` | custom scripts work |

## Verification (user, SameBoy)

- Gate of Beginning: enters cleanly, no freeze.
- Custom room: NPCs/scripts work, multi-screen scrolling works, all exits work,
  random encounters in the room work.
- Breakpoint `$04:$720d` still fires on gate entry (expected) and now redirects
  cleanly to bank `$60` entry 6 → bank `$0F` (no loop, no bad divert).

## Scope / impact

- **Clean disassembly untouched** — `make` still byte-perfect `1ca6579…`.
- **Zero byte shift** in bank `$04` (the 10-byte handler slot is reused in place;
  code after it did not move). Bank `$60` only *gained* one table entry and a routine
  in free space.
- Independent of the Spirit/B9 feature work (different files/banks); it composes
  cleanly on top of this fix.

## Provenance

Latent since the custom-room script-engine work (`3d94ad9`, "NPC interactions
solved"). The infinite-loop variant was introduced when the handler was rewritten
(`d564e7e`). Every build from `3d94ad9` onward froze on a fresh-game gate entry.
