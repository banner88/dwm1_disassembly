"""S130 F10 — dispel and field: DeMagic $80, ThickFog $83, FILTHZONE $A5
(BATTLE_SKILL_SYSTEM §15.11 F10).

Byte sources (decoded S130 and measured on the real save, corpus
simulator/f10_events.json.gz, validator simulator/validate_f10.py; the AI
side is ai_rules.f10_rules, validator simulator/validate_f10_rules.py):

* Handler `SkillDeMagic_ThickFog` ($52:$4BA1, shared by all three ids) only
  sets `$D9ED := 3`, `$D9EE := 0`. It runs after the ordinary per-victim MISS
  machine (one RNG step; the records have flags7 = flags8 = 0, so it never
  misses, dodges or is blocked) on the ONE resolved target.
* Act state 3 (`BtlActState_6e2b`) sends $80/$83/$A5 to bank $53 entry 11,
  `DispelMachine_60b3`: a dw table on `$D9EE`, one sub-state per frame. It
  uses no RNG. Starting at the resolved target t it walks t, t+1, ... until
  `t & 3 == 2` — i.e. FORWARD from the target to the end of its side (a
  DeMagic aimed at slot 5 leaves slot 4 untouched) — then the side's helper
  slot (t & 4) | 3, then the side bytes:

  s0 `DispelSlotCheck_60c9`  dead/absent slot ($DD1B != 0) -> s5
  s1 `DispelStrip_60dd`      +3 &= $30, +4 &= $C8, +5 &= $3F, +7: if +7 & $C0
                             (iron) then $DD13[t] := 3 and +7 := $11 (the
                             write uses A after the $DD13 pointer arithmetic
                             clobbered it: $DD & $33 — measured), else
                             +7 &= $33; shifted +8 ($DB08+8t) &= $3D, +9 bit2 off
                             (msg $AC)
  s2 `DispelClearP4_6132`    +4 := 0 (msg $D9 when it was non-zero)
  s3 `DispelRevertTest_6152` +3 (now only bits 4/5 = transformed) non-zero ->
                             +3 := 0 and `DispelRevertStats_626b` (msg $AD) ->
                             s4; else `DispelBaseDefAgl_647c` -> s5
  s4 `DispelRevertTail_617e` sprite reload, $C1CD[t] &= $80, $DD13[t] := 3,
                             $C1CA[t & 3] := $FF
  s5 `DispelNextTarget_61c2` t & 3 == 2 -> t := (t & 4) | 3, s6; else t += 1, s0
  s6 `DispelHelper_61e3`     live helper -> `DispelDismissHelper_650c`:
                             $DD1B := $FF, $DD13 := $FF, +2..+9 := 0 (msg $D8)
  s7 `DispelSideBytes_620b`  $DB00 and $DB01 bit3 (spell seal) off; the
                             target side's byte &= $10. ThickFog/FILTHZONE:
                             set bit3 of BOTH bytes, and when the caster's side
                             differs from the target's, t := caster side base
                             and the machine runs AGAIN from s0 on the
                             caster's own side (caster included).
  s8                         $D9ED += 3 (act state 6).

* `DispelRevertStats_626b`: skills $DC64 restored (bank $51 entry 10), then
  for an enemy (non-link, t >= 4) the enemy_stats row, else the party record:
  level, MaxHP, MaxMP, ATK, DEF, AGL, INT and the four AI weights
  ($DC44/$DC54/$DC4C/$DC5C) := source; HP := min(HP, MaxHP), MP := min(MP,
  MaxMP). The resistance array $DD28 is NOT restored. The party path writes
  the level and AI weights at index 2t (engine bug, see `revert`).
* `DispelBaseDefAgl_647c`: DEF and AGL := source (the record or the row —
  raised OR lowered), enemy: shifted +8 &= $3F. ATK/INT/HP untouched.
* NOT what FAMILIES.md said: `$53:$650C` does not restore stats; it removes the
  helper (4th) slot.
* The seal: $DB00/$DB01 bit3 survives phase 9 (it clears bits 4/6 only) — only
  s7 of a later dispel lifts it. A flags7-bit6 spell of a sealed side is vetoed
  at act time ($1F, battle.act_mp_veto) and PAYS its MP (SaveBtlC_4b4f, floor
  0) unless the actor's $DD0B == 2 (LoadBtlC_490a re-decides first) — the
  battle.py `# S130 F10` line. The AI also vetoes ThickFog / flags7-bit6
  spells for a sealed own side ($45F2 tail, ai_rules).
* Act-time target ($DD0B != 0 casters re-resolve through bank $58): $80 ->
  `Jump_058_62bf` (first live opposite slot), $83/$A5 -> `$62FD` (first live
  opposite slot incl. the helper) — RERESOLVE_PICKERS below. A $DD0B == 0 /
  player-commanded caster keeps its queued target (any side).

Board mapping: the source stats are `Board.base` (battle-start values = the
bank $57 / record / row source, measured by F7); the source level / party AI
bases are snapshot on first use (`sources`). The shifted pair of slot
7 lives outside Board.st: $DB40 = b.ext['f7_db40'] (F7's key), $DB41 =
b.ext['f10_db41'].

Hook for families that keep state OUTSIDE b.st / the stat arrays:
`DISPEL_HOOKS.append(fn)`, fn(b, event, slot) with event in
  'strip'   after slot's byte strip (s1)          — e.g. F4/F6 mirrors of +4/+8/+9
  'revert'  after a transform revert (s3/s4)      — F9: skills, $C1CA/$C1CD,
                                                    species/form, AI weights
  'base'    after the DEF/AGL reset (s3, no revert)
  'dismiss' after a helper slot was removed (s6)  — F9 helper bookkeeping
  'side'    after the side-byte write (s7); slot = the target side base (0/4)
The bytes themselves are already exact here; hooks only resync derived state.
"""
from .. import battle as B

DEMAGIC, THICKFOG, FILTHZONE = 0x80, 0x83, 0xA5
DISPEL_IDS = (DEMAGIC, THICKFOG, FILTHZONE)
FIELD_IDS = (THICKFOG, FILTHZONE)
SEAL = 0x08                    # $DB00/$DB01 bit3: the side's spells are sealed

DISPEL_HOOKS = []


def _hooks(b, event, slot):
    for fn in DISPEL_HOOKS:
        fn(b, event, slot)


# --------------------------------------------------------------------------
# the shifted pair +8/+9 ($DB08+8t / $DB09+8t; slot 7 -> $DB40/$DB41)
# --------------------------------------------------------------------------
def get8(b, t, k):
    i = 8 * t + k
    if i < 64:
        return b.st[i]
    return b.ext.get('f7_db40' if k == 8 else 'f10_db41', 0)


def set8(b, t, k, v):
    i = 8 * t + k
    if i < 64:
        b.st[i] = v & 0xFF
    else:
        b.ext['f7_db40' if k == 8 else 'f10_db41'] = v & 0xFF


# --------------------------------------------------------------------------
# the sub-states (one slot)
# --------------------------------------------------------------------------
def strip(b, t):
    """DispelStrip_60dd ($53:$60DD), exact byte ops on slot t."""
    b.set_stb(t, 3, b.stb(t, 3) & 0x30)
    b.set_stb(t, 4, b.stb(t, 4) & 0xC8)
    b.set_stb(t, 5, b.stb(t, 5) & 0x3F)
    v7 = b.stb(t, 7)
    if v7 & 0xC0:
        b.dd13[t] = 3
        v7 = 0xDD             # A = H of the $DD13+t pointer (the clobber)
    b.set_stb(t, 7, v7 & 0x33)
    set8(b, t, 8, get8(b, t, 8) & 0x3D)
    set8(b, t, 9, get8(b, t, 9) & 0xFB)
    _hooks(b, 'strip', t)


def sources(b):
    """The battle-start level / party AI bases (what DispelRevertStats_626b
    re-reads from the record or the row). Snapshot on first use — before any
    dispel can have rewritten them; a validator may preset b.ext['f10_src']."""
    src = b.ext.get('f10_src')
    if src is None:
        src = b.ext['f10_src'] = dict(level=list(b.level),
                                      bases=list(getattr(b, 'party_bases', [None] * 3)))
    return src


def _write_byte_array(b, arr, idx, val):
    """A byte write to $DB9B (level) / an AI-weight array at index idx as the
    engine addresses it: idx 0-7 = that array's own slot; the party path's
    doubled index can run past it (link battles, t >= 4): $DB9B+8.. aliases
    the HP words $DBA3.. (code-read; recorded literally), the weight arrays
    alias the next array (kept in b.ext['f10_aiw'] by address)."""
    if arr == 'level':
        if idx < 8:
            b.level[idx] = val & 0xFF
        else:
            k = idx - 8                       # $DBA3 + k: HP word k>>1, lo/hi byte
            w = b.hp[k >> 1]
            b.hp[k >> 1] = (w & 0xFF00) | val if not k & 1 else (w & 0xFF) | (val << 8)
        return
    b.ext.setdefault('f10_aiw', {})[(arr, idx)] = val


def revert(b, t):
    """DispelRevertStats_626b + DispelRevertTail_617e: the source stats come
    back (Board.base), HP/MP clamped to the new maxima; $DD13[t] := 3 (the
    reverted monster loses this round's action). Skills ($DC64, bank $51
    entry 10) / $C1CA/$C1CD / the sprite are F9 state (DISPEL_HOOKS
    'revert'); the resistances are left as they are (engine, measured).

    ENGINE BUG (measured tf_p*): the PARTY path (LoadBtlC_62f1: non-link
    t < 4, or any slot in a link battle) writes the source LEVEL and the four
    AI weights ($DC44 cat1 / $DC4C cat2 / $DC54 cat3 / $DC5C w3) through
    CalcBtlC_6546, which doubles the index (the word-array helper): they land
    on slot 2t. Reverting party slot 1 gives slot 2 slot 1's level and AI
    bases; slot 2 -> ENEMY slot 4 (b.ext['f10_enemy_bases'][4], read by
    pacing's enemy commit). The enemy path (CalcBtlC_63c7) indexes them right
    (a no-op: the row values never change)."""
    bs = b.base
    src = sources(b)
    for k in ('maxhp', 'maxmp', 'atk', 'dfn', 'agl', 'int'):
        getattr(b, k)[t] = bs[k][t]
    if b.link or t < 4:
        j = 2 * t
        lvl = src['level'][t] if t < len(src['level']) else b.level[t]
        # S130 F10/F9 merge: a slot whose form F9 changed (CHGDRAGON / BeDragon level 50)
        # before the first dispel: its source level is F9's saved pre-form level
        lvl = b.ext.get('f9_src_level', {}).get(t, lvl)
        _write_byte_array(b, 'level', j, lvl)
        pb = src['bases'][t] if t < len(src['bases']) else None
        if pb is not None:
            if j < 3 and hasattr(b, 'party_bases'):
                b.party_bases[j] = tuple(pb)
            elif 4 <= j < 7:
                b.ext.setdefault('f10_enemy_bases', {})[j] = tuple(pb)
            for n, arr in enumerate(('dc44', 'dc4c', 'dc54', 'dc5c')):
                _write_byte_array(b, arr, j, pb[n])
    if b.maxhp[t] < b.hp[t]:
        b.hp[t] = b.maxhp[t]
    if b.maxmp[t] < b.mp[t]:
        b.mp[t] = b.maxmp[t]
    b.dd13[t] = 3
    # S130 F10/F9 merge: bank $51 entry 10 rebuilds $DC64 from the SOURCE skills —
    # drop F9's form/Transform option-list override (measured p_ch_h1: dragon -> own list)
    b.ext.get('f9_opts', {}).pop(t, None)
    _hooks(b, 'revert', t)


def base_def_agl(b, t):
    """DispelBaseDefAgl_647c: DEF/AGL := source (record or row); an enemy
    (non-link, t >= 3) also gets shifted +8 &= $3F; slot 3/7 returns early."""
    if (t & 3) == 3:
        return
    b.dfn[t] = b.base['dfn'][t]
    b.agl[t] = b.base['agl'][t]
    if not b.link and t >= 3:
        set8(b, t, 8, get8(b, t, 8) & 0x3F)
    _hooks(b, 'base', t)


def dismiss(b, t):
    """DispelDismissHelper_650c: the helper leaves ($DD1B := $FF, $DD13 :=
    $FF) and its +2..+9 are zeroed."""
    b.dd1b[t] = 0xFF
    b.dd13[t] = 0xFF
    for k in range(2, 8):
        b.set_stb(t, k, 0)
    set8(b, t, 8, 0)
    set8(b, t, 9, 0)
    _hooks(b, 'dismiss', t)


def dispel_slot(b, t, log=None):
    """s0-s4 for one slot of the walk. Returns the path taken."""
    if not b.valid(t):
        return 'skip'
    strip(b, t)
    b.set_stb(t, 4, 0)                       # s2
    if b.stb(t, 3):                          # s3
        b.set_stb(t, 3, 0)
        revert(b, t)
        return 'revert'
    base_def_agl(b, t)
    return 'base'


def dispel_machine(b, a, t, sk, log=None):
    """DispelMachine_60b3 from the resolved target t. Returns the list of
    (slot, path) visits in engine order (validator / log)."""
    visits = []
    sources(b)
    while True:
        while True:                          # s0..s5
            if t < 8:
                visits.append((t, dispel_slot(b, t)))
            else:
                visits.append((t, 'skip'))
            if (t & 3) == 2:
                t = (t & 4) | 3
                break
            t += 1
        if b.valid(t):                       # s6
            dismiss(b, t)
            visits.append((t, 'dismiss'))
        b.st[0] &= ~SEAL & 0xFF              # s7
        b.st[1] &= ~SEAL & 0xFF
        side = 1 if t >= 4 else 0
        b.st[side] &= 0x10
        _hooks(b, 'side', side * 4)
        if sk in FIELD_IDS:
            b.st[0] |= SEAL
            b.st[1] |= SEAL
            if (a & 4) != (t & 4):
                t = a & 4
                continue
        break
    b.side_seal = [(b.st[0] >> 3) & 1, (b.st[1] >> 3) & 1]
    if log is not None:
        log.append((a, 'f10', (sk, visits)))
    return visits


# --------------------------------------------------------------------------
# round-driver wiring
# --------------------------------------------------------------------------
def handler(ctx):
    """ACTION_HANDLERS entry for $80/$83/$A5: the MISS machine on the one
    resolved target (one RNG step, always passes), the handler, then the
    entry-11 machine (no RNG) — modelled as one step at the handler."""
    def body(c, v, div, state):
        dispel_machine(c.b, c.a, v, c.sk, c.log)
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.t, 1)])


def pick_demagic(b, a, state):
    """Bank $58 row of $80 (`Jump_058_62bf` -> LoadBtlFX_62d9): the first
    live slot of the caster's OPPOSITE side, scanning base..base+2; none ->
    the base. Used by the act-time re-resolve ($DD0B != 0 casters)."""
    base = (a & 4) ^ 4
    for s in range(base, base + 3):
        if b.valid(s):
            return s, state
    return base, state


def pick_field(b, a, state):
    """Bank $58 row of $83/$A5 (`$62FD`, the $DD69 == 0 path): the first
    live slot of the opposite side scanning base..base+3 (the helper slot
    included); none -> the base (the $632A fallback, all-dead edge only)."""
    base = (a & 4) ^ 4
    for s in range(base, base + 4):
        if b.valid(s):
            return s, state
    return base, state


for _sk in DISPEL_IDS:
    B.ACTION_HANDLERS[_sk] = handler
    B.CORE_OVERRIDES[_sk] = 'dispel'
B.RERESOLVE_PICKERS[DEMAGIC] = pick_demagic
B.RERESOLVE_PICKERS[THICKFOG] = pick_field
B.RERESOLVE_PICKERS[FILTHZONE] = pick_field
