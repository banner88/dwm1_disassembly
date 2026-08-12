"""DWM1 battle-status model — traced from banks $50/$53 and measured with
/home/claude/trace/trace_status.py-style captures, S79.  Owning prose:
BATTLE_SKILL_SYSTEM §15.9.

Per-combatant status block: 8 bytes at $DB00 + slot*8 (slots 0-2 party,
4-6 enemy).  Byte roles (offsets within the block):

  +2  main afflictions:
        bit0  POISON        (PoisonHit $67 / PoisonGas $6C; sets $01)
        bit1  heavy DoT     (the $E2/MaxHP-6 class; phase-9 handles it;
                             applying skill not yet identified — open)
        bits3:2  SLEEP counter (see sleep_wake)
        bit4  CONFUSION     (PanicAll $19; sets $10) -> forced random
              action via LoadBattle_7ab5: action from table $52:$7AFF
              {$3A attack, $5E, $62, $80}, RNG1&3; if attack, random
              opposite-side target (RNG1&3 walked to a live slot)
        bit5  CURSE         (Curse $6F; sets $20) -> 25%/turn (RNG1 < $40)
              self-hit via bank $53 entry 2; can kill (HP==0 -> KO state)
        bit6  PARALYZE      (Paralyze $69; sets $40) -> forced action $13
              every turn (no wake counter observed; boss gate blocks the
              application in db73==1 battles)
        bit7  ASLEEP flag   (Sleep $15/SleepAll $16/SleepAir $6A set
              $8C = flag + counter 3)
  +3  secondary:
        bit0  STOPSPELL     (StopSpell $17; $01)  no counter observed
        bit1  SURROUND      (Surround $18; $02)   no counter observed
        bit4/bit5  transformed (Transform $29 sets bit4; CHGDRAGON $AA /
              BeDragon $D5 set bit5 — action-machine state 2 specials)
        bit6  DanceShut     ($91; $40)
        bit7  MouthShut     ($92; $80)
  +5  ladder modifiers + one-shot compulsions:
        bit6  guard ladder row (the harder-to-hit rows in §15.3)
        bit7  amplify ladder row
        bits0-5  ONE-SHOT forced actions, consumed (cleared) when the
              victim's turn comes up (bank $53 $4594-$45C8):
              bit0->act $12, bit1->act $14 (LureDance $78 sets $02 —
              measured: compelled once, then cleared), bit2->act $16,
              bit3->act $15, bit4->act $17, bit5->act $18
  +7  packed $C0-class turn counters, decremented in phase-9 sub 2 and
      gating action $11 at bank $53 $4566 — applying skills not yet
      identified (open; candidates: scare/lick-class enemy sillies)

Turn-gate order for the ACTOR (bank $53 entry 0, $4558-$45C8):
  $DB07&$C0 -> action $11;  +2 bit6 -> $13 (paralyzed);
  +2 bit7 -> sleep_wake();  then the +5 bits0-5 one-shots;
  then +2 bit5 curse roll;  then +2 bit4 confusion rewrite.

End-of-round DoT (battle phase 9, bank $50 $6B5E — the $DB02 low bits):
  bit0 poison: base = MaxHP/16, text $E1; if base >= 10:
       base = RNG16/6 + 10   (RNG16 = (RNG2<<8|RNG1) of the moment)
  bit1 heavy:  base = MaxHP/6, text $E2; if base >= 30:
       base = RNG16/11 + 30
  applied with floor-at-zero; KO -> join-candidate/side-wipe handling.
"""

MASK = 0xFFFF

# +2 bits
POISON, HEAVY_DOT, CONFUSION, CURSE, PARALYZE, ASLEEP = (
    0x01, 0x02, 0x10, 0x20, 0x40, 0x80)
SLEEP_COUNT_MASK = 0x0C
SLEEP_APPLY_VALUE = 0x8C          # measured constant: flag + counter 3

# +3 bits
STOPSPELL, SURROUND, DANCESHUT, MOUTHSHUT = 0x01, 0x02, 0x40, 0x80

# sleep wake thresholds by counter (bank $53 $4AEB): wake iff RNG1 <= t
SLEEP_WAKE_T = {0x0C: 0x60, 0x08: 0xA0, 0x04: 0xE0, 0x00: 0xFF}


def rng1(state):
    return (state >> 8) & 0xFF


def sleep_wake(byte2, state):
    """$53:$4AEB, exact. Input: the +2 byte with bit7 set; the CURRENT RNG
    state (no step consumed). Returns (new_byte2, awake: bool).
    Wake iff RNG1 <= threshold {count 3: $60 (37.9%), 2: $A0 (62.9%),
    1: $E0 (88.0%), 0: always}; else the 2-bit counter decrements
    (floor 0) and the actor is forced to the 'asleep' action $0F."""
    t = SLEEP_WAKE_T[byte2 & SLEEP_COUNT_MASK]
    if rng1(state) <= t:
        return byte2 & 0x73, True          # clears bit7 + counter
    cnt = byte2 & SLEEP_COUNT_MASK
    if cnt:
        cnt -= 4
    return (byte2 & 0xF3) | cnt, False


def curse_triggers(state):
    """+2 bit5: RNG1 < $40 -> the 25% self-hit fires this turn."""
    return rng1(state) < 0x40


def confusion_action(state, attacker_idx, alive):
    """LoadBattle_7ab5: RNG1&3 indexes {$3A,$5E,$62,$80}; if the pick is
    $3A the target starts at (opposite side base) + RNG1&3 and walks DOWN
    to a live slot.  QUIRK (literal $52:$7AE5): when the candidate's low
    bits hit 0 the walk continues at absolute slot 2 — the side bit is
    dropped, so a confused attacker's wrap can cross onto the OTHER side
    (e.g. enemy-side 4 -> party 2 -> 1 -> 0).  `alive` = set of live
    combatant indices. Returns (action, target|None)."""
    table = (0x3A, 0x5E, 0x62, 0x80)
    act = table[rng1(state) & 3]
    if act != 0x3A:
        return act, None
    base = (attacker_idx & 4) ^ 4
    t = base + (rng1(state) & 3)
    while t not in alive:
        if (t & 3) == 0:
            t = 2
        else:
            t -= 1
    return act, t


def poison_tick(maxhp, state):
    """Phase-9 bit0 DoT: MaxHP/16, capped-rerolled at >= 10."""
    base = maxhp >> 4
    if base >= 10:
        r16 = ((state & 0xFF) << 8) | ((state >> 8) & 0xFF)  # (RNG2<<8)|RNG1
        base = r16 // 6 + 10
    return max(base, 1)


def heavy_dot_tick(maxhp, state):
    """Phase-9 bit1 DoT: MaxHP/6, capped-rerolled at >= 30."""
    base = maxhp // 6
    if base >= 30:
        r16 = ((state & 0xFF) << 8) | ((state >> 8) & 0xFF)
        base = r16 // 11 + 30
    return max(base, 1)
