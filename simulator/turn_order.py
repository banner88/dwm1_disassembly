"""DWM1 turn-order model — traced from bank $58 (TurnOrderBuild, ~$54D1),
S79. Differentially validated by simulator/validate_order.py against
measure_order.py captures.

Pipeline per round (battle phase $05, bank $58 entry 0 machine):
  1. Enemy AI fills the action queue $DCEC for combatants 4-6 (separate
     machine; not modelled here — S79/S80 AI arc).
  2. TurnOrderBuild ($58:$54D1):
       for slot e in 0..7, present (CheckMonsterSlot) and $DD13[e]==2:
         one GenerateRNG step ($00:$12D0: state16 = state*5 + $1357,
         state = (RNG1<<8)|RNG2)
         key = agl_key(AGL16[e], rng)                [SaveBtlFX_5662]
         action tweaks (see below)
         floor: if key < 2 : key = 2                 [$58:$553B]
         act-first class: key += $0600               [SetBtlFX_56cf]
       keys appended to $DB61 (u16 x8), ids to $DB4C, in slot order.
  3. Bubble sort descending, shrinking bound d=8..1, adjacent pairs
     (e, e+1) for e in 0..d-1 — NOTE the literal engine compares pair
     (7,8) on the first pass, touching bytes beyond the 8-entry array
     ($DB71/$DB72 keys, $DB54 id). Swap condition: next >= current
     (ties DO swap; 8 even passes restore original order for stable
     ties in practice — modelled literally, not by that argument).
  4. Compact non-$FF ids into $DB79; $DB82=0. Bank $53 entry 0 then
     consumes $DB79[$DB82++] per action, skipping dead actors.

agl_key (SaveBtlFX_5662):
  agl = max(AGL16, 1)
  span = 1 + agl//4 + agl//16
  r    = rand mod' span, where rand = ((RNG2 & 3) << 8) | RNG1 taken
         AFTER the step, and mod' is repeated subtraction that exits on
         EQUAL as well: r in [0, span]; r == span iff rand is a nonzero
         multiple of span; r == 0 iff rand == 0.
  key  = agl - span + r        (range [agl-span, agl])
  action $55 SquallHit: key += $0200 here AND +$0200 again in the main
    loop (LoadBtlFX_55b9) = +$0400 total ("attacks first").
  action $56 PsycheUp: key = 0 here; the floor then makes it 2; the main
    loop (SetBtlFX_55be) finally forces key = $0001 (acts LAST).

Act-first class (+$0600, SetBtlFX_56cf): queued action in
  {$2A Ironize, $7F Imitate, $88 Cover, $89 Guardian, $8C Dodge,
   $8D Defence, $8E StrongD, $8F SuckAll, $90 BladeD, $DC IRONIZE} —
the defensive/interception skills resolve before everything.

Link battles add a peer sentinel (id $10, key $0200) when $DB77 != $FF —
modelled but untested (no link rig).
"""

MASK = 0xFFFF

ACT_FIRST = {0x2A, 0x7F, 0x88, 0x89, 0x8C, 0x8D, 0x8E, 0x8F, 0x90, 0xDC}
SQUALLHIT = 0x55
PSYCHEUP = 0x56


def rng_step(state):
    return (state * 5 + 0x1357) & MASK


def agl_key(agl16, state):
    """One combatant's raw order key. `state` is the RNG state BEFORE the
    combatant's GenerateRNG step. Returns (key, new_state) with the $55/$56
    in-helper tweak applied (the +$0200-more / floor / final-$0001 and the
    +$0600 class happen in build_keys)."""
    state = rng_step(state)
    rng1, rng2 = (state >> 8) & 0xFF, state & 0xFF
    agl = agl16 if agl16 != 0 else 1
    span = 1 + (agl >> 2) + (agl >> 4)
    rand = ((rng2 & 3) << 8) | rng1
    # repeated subtraction, exit on equal-or-below: r in [0, span]
    r = rand
    while r > span:
        r -= span
    # r == span stays (engine exits the loop on z without subtracting)
    key = (agl - span + r) & MASK
    return key, state


def build_keys(slots, state):
    """slots: list of (slot_index, agl16, action) for combatants that are
    present AND $DD13==2, in slot order. Returns (entries, state) where
    entries = [(slot, key)] in insertion order, keys final (all tweaks)."""
    entries = []
    for slot, agl16, action in slots:
        key, state = agl_key(agl16, state)
        if action == SQUALLHIT:
            key = (key + 0x0200) & MASK
        elif action == PSYCHEUP:
            key = 0
        if key < 2:
            key = 2
        if action in ACT_FIRST:
            key = (key + 0x0600) & MASK
        elif action == SQUALLHIT:
            key = (key + 0x0200) & MASK
        elif action == PSYCHEUP:
            key = 0x0001
        entries.append((slot, key))
    return entries, state


def sort_order(entries, ninth_key=0, ninth_id=0xFF):
    """Literal bubble sort of the engine ($58:$55C2): 9-wide array (8 slots
    + the out-of-bounds pair $DB71/$DB72+$DB54), descending, shrinking
    bound, swap when next >= current (ties swap). Returns the compacted
    order list (engine's $DB79) and the final ninth (key, id) pair."""
    keys = [k for _, k in entries] + [0] * (8 - len(entries)) + [ninth_key]
    ids = [s for s, _ in entries] + [0xFF] * (8 - len(entries)) + [ninth_id]
    d = 8
    while d > 0:
        for e in range(d):
            if keys[e + 1] >= keys[e]:
                keys[e], keys[e + 1] = keys[e + 1], keys[e]
                ids[e], ids[e + 1] = ids[e + 1], ids[e]
        d -= 1
    order = [i for i in ids[:8] if i != 0xFF]
    return order, (keys[8], ids[8])


def round_order(slots, state, ninth_key=0, ninth_id=0xFF):
    """Full round: keys + sort. Returns (order, entries, state)."""
    entries, state = build_keys(slots, state)
    order, _ = sort_order(entries, ninth_key, ninth_id)
    return order, entries, state
