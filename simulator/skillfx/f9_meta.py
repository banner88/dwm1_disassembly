"""S130 F9 — combatant-changing and meta skills (BATTLE_SKILL_SYSTEM §15.11
F9). Every function names the engine routine it models; the corpus is
simulator/f9_events.json(.gz) (simulator/measure_f9.py on the user's save,
u22.gbc) and the replay is simulator/validate_f9.py.

Skills (id: bank $52 handler; bank $58 target row; effect):
  $84 TatsuCall / $85 DiagoCall / $86 SamsiCall / $87 BazooCall
        SkillTatsuCall $4BD0 (row $63D6 = self): one BattleRNG step, then
        side byte $DB00/$DB01 bit2 set -> msg $BB (once per side, the bit
        survives phase 9); RNG1 >= $C0 -> msg $CB; else set bit2 and
        LoadBattle_6648 -> bank $51 entry 5-8 writes a FIXED helper into
        slot (side|3): stats, level, $DD0B, WLD $FF, AI bases 250, the
        option list $DC64, the packed res $DD28; then the 8 status bytes
        $DB02+8s.. := 0, $DD1B := 0, $DC3C := id+$54 (species 216-219).
        $DD13 stays $FF: the helper first acts NEXT round (the command
        phase re-arms every live slot — f5_heal.rearm_revived).
  $39 Chance   SkillChance $4616 -> $53 entry 3 ($4D7E): one step per roll,
        RNG1&$0F: 0 -> $A9, 1 -> $A3, n -> $A0+n; a boss battle ($DB73!=0)
        re-rolls ids whose record +9 bit1 is clear; a non-link caster at
        slot >= 3 re-rolls $A2/$A4. The id is written to the queue, the bank
        $58 row of the NEW id resolves the target ($DD69 := 0 around it) and
        the act machine restarts at state 1 (target fetch, iron gate, MISS
        machine, handler) — no MP / veto / re-resolve for the outcome.
  $A2 CALLHOROR / $A4 Smashed   SkillSmashed $4EF9 (no boss gate): target
        HP := 0, SkillRUN on it. Then $53 entry 15 ($6BE2) walks: the next
        live slot up to 6 gets the handler again WITHOUT target fetch / MISS
        machine; at 6 Smashed stops, CALLHOROR wraps to slot 0 where party
        slots only get message $AA; slot 3 ends the walk.
  $DB RUN / $A1 RUN   SkillRUN $4E3A (row $6367 self): own $DD1B := $FF; a
        slot >= 4 (enemy, or a helper 7) then goes through bank $51 entry 3:
        reload from source (helper: side bit2 cleared instead), HP := 0, MP
        clamp, status wipe (see flee()).
  $D5 BeDragon / $AA CHGDRAGON   SkillBeDragon $4E0E (row $6367 self), act
        state 4 ($52:$6D0A): SetHLBattle_6684 -> bank $51 entry 9 (FIXED
        dragon: level 50, MaxHP 999, MaxMP 300, ATK 300, DEF/AGL/INT 200 —
        HP and MP untouched; res; option list {$5E,$62,$80}), own +3 bit4,
        then TransformActionRewrite_7ab5 (NO step, RNG1&3): queue :=
        {$3A,$5E,$62,$80}[RNG1&3]; $3A targets opp base + (RNG1&3), a dead
        candidate walks (c&3)-1 in ABSOLUTE slots (0 -> 2); others target
        the opposing base; $D9ED := 0 re-runs the whole per-actor pipeline
        for the same actor this turn (gates, curse, dupconv, veto, act).
  $29 Transform   (F7 owns the stat copy, f7_stats.transform_stats) +
        TransformCopyStats_5f5e's tail: res := the target's SOURCE res
        (SetupBattle_52d8 -> LoadBattle_6a75), option list := the target's
        SOURCE skills (SetupBattle_5325: party record 8 / enemy row 4; $DB
        ends the list) with record tags; enemy caster: $C1CA[a&3] := target.
        Row $58:$4ED8: $DD0B==0 uniform opposing ($642C), else argmax of
        MaxHP+MaxMP over the opposing base..base+2 (ties -> later slot).
  KO (bank $51 entry 15): every non-helper slot is RELOADED from its source
        (party record / enemy row: MaxHP, MaxMP, ATK, DEF, AGL, INT, level,
        res, skills; an enemy also MP; party MP clamped to MaxMP) — this is
        also the transform / dragon revert; a helper slot is not reloaded:
        $DD1B := $FF (gone for good) and its side's summon bit2 is cleared.
        DeMagic's state-4 tail for a dragon caster ($52:$7A49 -> $7A5F) is
        NOT reached in practice (DeMagic ends in its own bank $53 entry-11
        machine; 3 dragon casts, $7A49 never hit). A DeMagic that sweeps a
        dragon / transformed TARGET clears its +3 and reloads its stats/
        level/skills (not its res) — F10's machine (measured).
  Helper SOURCE (GetBase*, Transform into a helper): enemy_stats row
        $0100|$DC3C = 472-475 (Orochi/Trumpeter/Snapper/HornBeet), not the
        helper's own row (measured).
  AI: AIRuleVetoSummonActive_6757 (simulator/ai_rules.py) vetoes $84-$87
        while the side's summon is alive.
  $A6 ALLCHANGE (SkillALLCHANGE $4F35: own base..base+2 live -> +3 bit3) and
        $A9 ECHO (message) are registered with setdefault (owners F4/F6).

Helper slots 3 / 7 (engine sites, byte-read + measured): the group victim
loop ($52:$719C) and the quake sweep ceiling are slot 3/7 -> sweeps hit a
live helper (battle.side_victims / quake_victims); every SINGLE-target
picker (front-weighted $441B, uniform $63EC, dead redirect $47E8, side wipe
$76C8, rows $62BF/$62CD) scans 3 slots -> a helper is never single-targeted
and does not keep its side alive.
"""
import json
import os

from .. import battle as B
from .. import damage as D
from . import f7_stats as F7

rng_step, rng1, rng2 = B.rng_step, B.rng1, B.rng2

TATSU, DIAGO, SAMSI, BAZOO = 0x84, 0x85, 0x86, 0x87
SUMMONS = (TATSU, DIAGO, SAMSI, BAZOO)
CHANCE, TRANSFORM, RUN, CONF_RUN = 0x39, 0x29, 0xDB, 0xA1
BEDRAGON, CHGDRAGON = 0xD5, 0xAA
CALLHOROR, HEALUSALL, SMASHED, FILTHZONE = 0xA2, 0xA3, 0xA4, 0xA5
ALLCHANGE, ECHO, DEMAGIC = 0xA6, 0xA9, 0x80
ATTACK = 0x3A

# bank $51 entries 5-8 (byte-read: the `ld a,$xx` literals of $4D16/$4E5E/
# $4FAA/$50F6; measured: every field equals the slot after summon_done).
# BazooCall writes HP $02BC = 700 but MaxHP $01BC = 444 (a ROM typo: HP >
# MaxHP until the first heal clamps it; measured both sides).
HELPERS = {
    TATSU: dict(species=216, level=30, hp=200, maxhp=200, mp=100, maxmp=100, atk=180,
                dfn=150, agl=80, int=150, dd0b=1,
                res=[0x16, 0xB5, 0x55, 0x54, 0x15, 0x55, 0x54],
                opts=[(3, 0x2C), (1, 0x5A), (3, 0x88)]),
    DIAGO: dict(species=217, level=40, hp=300, maxhp=300, mp=200, maxmp=200, atk=210,
                dfn=160, agl=120, int=100, dd0b=1,
                res=[0x3A, 0x05, 0x64, 0x54, 0x31, 0x55, 0x84],
                opts=[(2, 0x25), (1, 0x5E), (2, 0x7A)]),
    SAMSI: dict(species=218, level=50, hp=450, maxhp=450, mp=200, maxmp=200, atk=250,
                dfn=190, agl=150, int=200, dd0b=2,
                res=[0x19, 0xC6, 0xB5, 0x44, 0x19, 0x55, 0x54],
                opts=[(1, 0x40), (1, 0x55), (1, 0x57)]),
    BAZOO: dict(species=219, level=60, hp=700, maxhp=444, mp=400, maxmp=400, atk=350,
                dfn=300, agl=100, int=250, dd0b=2,
                res=[0x1A, 0x6F, 0xFA, 0xA9, 0x1E, 0xAA, 0xA8],
                opts=[(1, 0x62), (1, 0x64), (2, 0x80)]),
}
# The helper's SOURCE (bank $57 GetBase* / SetupBattle_52d8 / _5325 for a
# slot with &3 == 3): wTempEnemyStatsId := $0100 | $DC3C, i.e. enemy_stats
# row 256 + species = 472 Orochi / 473 Trumpeter / 474 Snapper / 475
# HornBeet — NOT the helper's own row 344-347 (a ROM quirk; measured: a
# Transform into a summoned Bazoo copied HornBeet's 380/190/240/250/300,
# its species res and skills {$67,$72,$93}). Sap/Upper caps and Surge on a
# helper therefore key on these rows too.
HELPER_SOURCE_ROW = {TATSU: 472, DIAGO: 473, SAMSI: 474, BAZOO: 475}
HELPER_AI_BASES = (250, 250, 250, 250)        # $DC44/$DC4C/$DC54/$DC5C := $FA
HELPER_FAMILY = 9                              # species 216-219: family Boss

# bank $51 entry 9 ($524A, byte-read + measured): the dragon form.
DRAGON = dict(level=50, maxhp=999, maxmp=300, atk=300, dfn=200, agl=200, int=200,
              res=[0x2A, 0xAA, 0xA9, 0x69, 0x4F, 0xAA, 0x5A],
              opts=[(1, 0x5E), (1, 0x62), (2, 0x80)])
TF_TABLE = (ATTACK, 0x5E, 0x62, 0x80)         # TransformActionTable_7aff

STATS = ('maxhp', 'maxmp', 'atk', 'dfn', 'agl', 'int')

_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_ENEMY_ROWS = None


def _enemy_row(eid):
    global _ENEMY_ROWS
    if _ENEMY_ROWS is None:
        try:
            rows = json.load(open(os.path.join(_ROOT, 'extracted', 'enemy_stats.json')))
            _ENEMY_ROWS = {r['enemy_stats_id']: r for r in rows}
        except (OSError, ValueError):
            _ENEMY_ROWS = {}
    return _ENEMY_ROWS.get(eid)


def _species_res(species_id):
    """Packed $DD28 bytes of a species (pacing.pack_res over monsters_full)."""
    from .. import pacing as P                     # lazy: pacing imports battle
    global _SPECIES
    if _SPECIES is None:
        _SPECIES = P.load_species()
    sp = _SPECIES.get(species_id)
    return P.pack_res(sp['resistances']) if sp else [0] * 7


_SPECIES = None


def helper_source(sk):
    """(base dict, skills, res) of a helper's source row (HELPER_SOURCE_ROW)."""
    row = _enemy_row(HELPER_SOURCE_ROW[sk])
    base = dict(maxhp=row['hp'], maxmp=row['mp'], atk=row['atk'], dfn=row['def'],
                agl=row['agl'], int=row['int'])
    return base, list(row['skills']), _species_res(row['species_id'])


def _ext(b, key):
    return b.ext.setdefault(key, {})


def _tag(records, sk):
    rec = records.get(sk) if records else None
    return ((rec['battle_record']['fields']['effect_category'] >> 4) & 0xF) if rec else 1


# --------------------------------------------------------------------------
# option lists ($DC64) and source data
# --------------------------------------------------------------------------
def opts_of(b, s):
    """The slot's CURRENT option list override ($DC64+16s) when the engine
    rewrote it (helper load, Transform, dragon form), else None (the
    pacing movepool applies)."""
    return b.ext.get('f9_opts', {}).get(s)


def source_skills(b, s):
    """SetupBattle_5325: the slot's SOURCE skill ids — party record (8),
    enemy row (4, by $DA03+2k), helper row (its summon list)."""
    src = b.ext.get('f9_src_skills', {}).get(s)
    if src is not None:
        return list(src)
    if s in (3, 7):
        hk = b.ext.get('f9_helper', {}).get(s)
        return helper_source(hk)[1] if hk in HELPERS else []
    if s < 3 or b.link:
        ps = getattr(b, 'party_skills', None)
        if ps and s < len(ps) and ps[s]:
            return list(ps[s])
        return []
    row = _enemy_row(b.eid[s - 4]) if 0 <= s - 4 < len(b.eid) else None
    return list(row['skills']) if row else []


def skills_to_opts(skills, records):
    """The TransformCopyStats_5f5e copy loop: up to 8 {tag, skill}; a $DB
    (RUN) or $FF entry ends the list (LoadBattle_6077 turns $DB into $FF);
    tag = record +1 high nibble (bank $54 entry 0)."""
    out = []
    for sk in skills[:8]:
        if sk in (0xFF, 0xDB) or sk is None:
            break
        out.append((_tag(records, sk), sk))
    return out


def source_res(b, s):
    """SetupBattle_52d8 -> LoadBattle_6a75: the slot's SOURCE packed res
    (species / record), = its battle-start $DD28 bytes unless the slot
    itself changed form (then the saved original)."""
    saved = b.ext.get('f9_src_res', {}).get(s)
    if saved is not None:
        return list(saved)
    hk = b.ext.get('f9_helper', {}).get(s) if s in (3, 7) else None
    if hk in HELPERS:
        return list(helper_source(hk)[2])
    return list(b.res[s * 7:s * 7 + 7])


def _save_source(b, s):
    """Before a form change overwrites slot s: remember its source res and
    level (the KO reload and the DeMagic self-revert restore them)."""
    _ext(b, 'f9_src_res').setdefault(s, list(b.res[s * 7:s * 7 + 7]))
    _ext(b, 'f9_src_level').setdefault(s, b.level[s])


# --------------------------------------------------------------------------
# TatsuCall family
# --------------------------------------------------------------------------
def side_byte(a):
    """$DB00 (party) / $DB01 (enemy): `wBattleAttackerIdx rrca rrca and 1`."""
    return (a >> 2) & 1


def summon(b, a, sk, state):
    """SkillTatsuCall $52:$4BD0. One BattleRNG step FIRST (also on the
    'already summoned' path), then the side bit2 check ($BB), RNG1 >= $C0
    ($CB), else the helper load. Returns (outcome, slot|None, state) with
    outcome 'used' | 'fail' | 'done'."""
    state = rng_step(state)
    sb = side_byte(a)
    if b.st[sb] & 0x04:
        return 'used', None, state
    if rng1(state) >= 0xC0:
        return 'fail', None, state
    b.st[sb] |= 0x04
    s = (a & 4) | 3
    load_helper(b, s, sk)
    return 'done', s, state


def load_helper(b, s, sk):
    """LoadBattle_6648 -> bank $51 entry 5-8 ($DB4C := side|3) + the
    handler tail: db8b/$DB93 := 0, level, HP/MaxHP/MP/MaxMP/ATK/DEF/AGL/INT,
    $DD0B, WLD word $00FF, AI bases $FA x4, $DC64 = 3 {tag, skill}, $DD28
    res; status $DB02+8s..$DB09+8s := 0; $DD1B := 0; $DC3C := id+$54."""
    h = HELPERS[sk]
    b.db8b[s] = 0
    b.level[s] = h['level']
    for k in ('hp', 'maxhp', 'mp', 'maxmp', 'atk', 'dfn', 'agl', 'int'):
        getattr(b, k)[s] = h[k]
    b.dd0b[s] = h['dd0b']
    b.res[s * 7:s * 7 + 7] = list(h['res'])
    for k in range(s * 8 + 2, min(s * 8 + 10, 64)):
        b.st[k] = 0
    if s == 7:
        b.ext['f7_db40'] = 0                     # $DB40/$DB41 (slot 7's shifted pair)
    b.dd1b[s] = 0
    b.species[s] = h['species']
    b.family[s] = HELPER_FAMILY
    base = helper_source(sk)[0]
    for k in STATS:
        b.base[k][s] = base[k]
    _ext(b, 'f9_helper')[s] = sk
    _ext(b, 'f9_opts')[s] = list(h['opts'])
    _ext(b, 'f9_ai_bases')[s] = HELPER_AI_BASES
    _ext(b, 'f9_wld')[s] = 0xFF
    for d in ('f9_src_res', 'f9_src_level', 'f9_src_skills'):
        b.ext.get(d, {}).pop(s, None)


def summon_action(ctx):
    """$84-$87: row $63D6 writes the caster as the target; the act machine
    runs the MISS machine on the caster (one step; the record never misses),
    then the handler (summon)."""
    def body(c, v, div, state):
        out, s, state = summon(c.b, c.a, c.sk, state)
        c.log.append((c.a, 'summon', (out, s)))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.a, 1)])


# --------------------------------------------------------------------------
# Chance
# --------------------------------------------------------------------------
def chance_allowed(b, a, mid, records):
    """The $4D7E re-roll guards: boss battle ($DB73 != 0) -> record +9 bit1
    must be set; non-link caster at slot >= 3 (`cp $03` — a party helper
    counts) -> $A2/$A4 re-rolled."""
    if b.db73:
        rec = records.get(mid) if records else None
        f9 = rec['battle_record']['fields']['flags9'] if rec else 0
        if not (f9 & 0x02):
            return False
    if not b.link and a >= 3 and mid in (CALLHOROR, SMASHED):
        return False
    return True


def chance_roll_id(state):
    """One picker roll from the stepped RNG: RNG1&$0F 0 -> $A9, 1 -> $A3,
    else $A0+n ($A3/$A9 doubled; $A0/$A1 unreachable)."""
    n = rng1(state) & 0x0F
    return 0xA9 if n == 0 else (0xA3 if n == 1 else 0xA0 + n)


def chance_pick(b, a, state, records):
    """$53:$4D7E: repeat {one LoadBtlC_4e33 step, map, guards}. Returns
    (id, rolls, state)."""
    rolls = 0
    for _ in range(4096):
        state = rng_step(state)
        rolls += 1
        mid = chance_roll_id(state)
        if chance_allowed(b, a, mid, records):
            return mid, rolls, state
    return ECHO, rolls, state                     # unreachable: $A3/$A9 always pass


def _first_live(b, base, n=3):
    for s in range(base, base + n):
        if b.valid(s):
            return s
    return None


def chance_target(b, a, mid):
    """Bank $58 entry 8 for the NEW id ($DD69 = 0): $62BF first live
    opposing (3 scanned, none -> base); $62CD first live own (none -> base);
    $62FD ($A2/$A5) first live opposing scanning base..base+3; $635F own
    base; $6367 self."""
    opp, own = (a & 4) ^ 4, a & 4
    if mid in (CALLHOROR, FILTHZONE):
        t = _first_live(b, opp, 4)
        return opp if t is None else t
    if mid in (HEALUSALL, ALLCHANGE, 0xAE):
        t = _first_live(b, own)
        return own if t is None else t
    if mid == 0xAD:
        return own
    if mid in (ECHO, CHGDRAGON):
        return a
    t = _first_live(b, opp)                       # $A4 $A7 $A8 $AB $AC $AF
    return opp if t is None else t


def run_outcome(ctx, mid, t):
    """The act machine from state 1 with the new id: target fetch (queue
    byte), the Cover/Guardian redirect, the iron pre-gate, then the id's
    handler (or the generic per-victim path)."""
    b, a = ctx.b, ctx.a
    rec = ctx.records.get(mid) if ctx.records else None
    f = rec['battle_record']['fields'] if rec else {}
    core = B.damage_core(mid, rec)
    b.queue[a * 2] = mid
    b.queue[a * 2 + 1] = t
    gt = B.guard_redirect(b, t, f.get('flags8', 0))
    if gt != t:
        ctx.log.append((a, 'guarded', t, gt))
        b.queue[a * 2 + 1] = gt
        t = gt
    if (f.get('target_mode') != 18 and mid not in B.OWN_TARGET_GATES
            and B.target_unreachable(b, t, f.get('flags8', 0), mid)):
        ctx.log.append((a, 'unreachable', t))
        return ctx.state
    c2 = B.ActionCtx(b=b, a=a, sk=mid, rec=rec, f=f, core=core, t=t, qt=t,
                     state=ctx.state, records=ctx.records, log=ctx.log, idle=ctx.idle,
                     real_sk=mid)
    h = B.ACTION_HANDLERS.get(mid)
    state = h(c2) if h is not None else B.default_victims(c2)
    ctx.state = state
    return state


def chance_action(ctx):
    """$39 Chance: row $63D6 (self) -> the MISS machine on the caster (one
    step), the handler's picker, then the outcome's act machine."""
    b, a = ctx.b, ctx.a
    holder = {}

    def body(c, v, div, state):
        state = c.idle(state, 'pre_target')
        mid, rolls, state = chance_pick(b, a, state, c.records)
        holder['mid'] = mid
        c.log.append((a, 'chance', (mid, rolls)))
        return 'done', None, state
    state = B.default_victims(ctx, body, victims=[(a, 1)])
    mid = holder.get('mid')
    if mid is None:
        return state
    t = chance_target(b, a, mid)
    ctx.state = ctx.idle(state, 'pre_target')
    state = run_outcome(ctx, mid, t)
    clear_own8_bit0(b, a)
    return state


def clear_own8_bit0(b, a):
    """The action's end ($52:$7085 path) leaves the caster's $DB08+8a bit0
    (the CALLEVIL / CallHelp continuation flag) clear: measured 9/9 Chance ->
    CALLEVIL casts — set during the sweep, clear at the next actor fetch.
    (Applied here for the Chance outcome; f23's own CALLEVIL path keeps it —
    see S130_F9_NOTES open items.)"""
    i = (a + 1) * 8
    if i < 64:
        b.st[i] &= 0xFE


# --------------------------------------------------------------------------
# Smashed / CALLHOROR / RUN
# --------------------------------------------------------------------------
def flee(b, s):
    """SkillRUN $4E3A with slot s as the attacker: $DD1B := $FF. A slot >= 4
    (`cp $04`, no link test) also clears its $DC33 record and runs
    BattleTarget_7242 -> bank $51 entry 3 ($4BE8): a helper slot (&3 == 3)
    clears its side's summon bit2 (the side may summon again); any other
    slot is reloaded from its source (LoadBtlS_44a9); then
    KOStatusWipe_4c26: HP := 0, MP := min(MP, MaxMP), status +2..+9 := 0
    ($DD1B stays $FF). Measured: a fled enemy shows HP 0 and its row's
    MaxHP/MaxMP/DEF; a fled party monster keeps its HP."""
    b.dd1b[s] = 0xFF
    if s < 4:
        return
    if (s & 3) == 3:
        b.st[side_byte(s)] &= ~0x04 & 0xFF
    b.hp[s] = 0
    B.ko_wipe(b, s)                                # KO_HOOKS reload (non-helper) + wipe
    if b.mp[s] > b.maxmp[s]:
        b.mp[s] = b.maxmp[s]


def remove(b, t):
    """SkillSmashed $4EF9: target HP := 0, then SkillRUN with the target as
    attacker. $DD13 is not touched; no KO processing (apply skipped,
    jr_052_6d70)."""
    b.hp[t] = 0
    flee(b, t)


def smashed_walk(b, sk, t):
    """$53 entry 15 ($6BE2) after each removal, literal (byte wrap): returns
    the later victims (handler re-entered at $D9EE=$0B: no MISS machine,
    no iron gate). 3 ends; 6 ends Smashed, CALLHOROR wraps to 0; slots
    below 3 only get msg $AA."""
    out = []
    cur = t
    for _ in range(600):
        if cur == 3:
            break
        if cur == 6:
            if sk == SMASHED:
                break
            cur = 0
            if not b.valid(0):
                continue
            cur = 1                                # msg $AA on slot 0
            continue
        if cur < 3:
            cur += 1                               # msg $AA (live) / skip (dead)
            continue
        cur = (cur + 1) & 0xFF
        if b.valid(cur):
            out.append(cur)
            remove(b, cur)
    return out


def smashed_action(ctx):
    """$A2 / $A4: the first victim through the target fetch, iron pre-gate
    and MISS machine (one step); the rest by the entry-15 walk."""
    b, a, sk, t = ctx.b, ctx.a, ctx.sk, ctx.t
    if t is None or not b.valid(t):
        return ctx.state
    if B.target_unreachable(b, t, ctx.f.get('flags8', 0), sk):
        ctx.log.append((a, 'unreachable', t))
        return ctx.state

    def body(c, v, div, state):
        remove(c.b, v)
        rest = smashed_walk(c.b, sk, v)
        c.log.append((a, 'removed', [v] + rest))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(t, 1)])


def run_action(ctx):
    """$DB RUN: row $6367 self, MISS machine on the caster, SkillRUN."""
    def body(c, v, div, state):
        flee(c.b, c.a)
        c.log.append((c.a, 'flee', None))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.a, 1)])


# --------------------------------------------------------------------------
# BeDragon / CHGDRAGON
# --------------------------------------------------------------------------
def dragon_form(b, a):
    """SetHLBattle_6684 -> bank $51 entry 9 ($524A): level 50, MaxHP 999,
    MaxMP 300, ATK 300, DEF/AGL/INT 200 (HP and MP NOT written), the option
    list {$5E,$62,$80} (+ 5 x {0,$FF}), res; then own +3 bit4 ($52:$6D17)."""
    _save_source(b, a)
    b.level[a] = DRAGON['level']
    for k in STATS:
        getattr(b, k)[a] = DRAGON[k]
    b.res[a * 7:a * 7 + 7] = list(DRAGON['res'])
    _ext(b, 'f9_opts')[a] = list(DRAGON['opts'])
    b.set_stb(a, 3, b.stb(a, 3) | 0x10)


def dragon_rewrite(b, a, state):
    """TransformActionRewrite_7ab5 (NO step): queue := TF_TABLE[RNG1&3];
    $3A: candidate = opposing base + (RNG1&3); while not live: c&3 != 0 ->
    (c&3)-1 (ABSOLUTE slot), else 2 (the `or 3 / dec` cycle); other ids:
    the opposing base. Returns (skill, target)."""
    k = rng1(state) & 3
    sk = TF_TABLE[k]
    base = (a & 4) ^ 4
    if sk != ATTACK:
        tgt = base
    else:
        c = base + k
        for _ in range(64):
            if b.valid(c):
                break
            c = (c & 3) - 1 if (c & 3) else 2
        tgt = c
    b.queue[a * 2] = sk
    b.queue[a * 2 + 1] = tgt
    return sk, tgt


def dragon_action(ctx):
    """$D5 / $AA: MISS machine on the caster, the handler (msg), act state 4:
    the form change, then the rewrite and a RE-RUN of the actor's whole
    per-actor pipeline this turn (b.ext['f9_rerun'], battle.actor_walk)."""
    def body(c, v, div, state):
        dragon_form(c.b, c.a)
        state = c.idle(state, 'pre_target')
        sk, tgt = dragon_rewrite(c.b, c.a, state)
        c.b.ext['f9_rerun'] = c.a
        c.log.append((c.a, 'dragon', (sk, tgt)))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.a, 1)])


# --------------------------------------------------------------------------
# Transform (non-stat part) and the reverts
# --------------------------------------------------------------------------
def transform_copy(b, a, t, records):
    """TransformCopyStats_5f5e after the stat copy (F7): res := the target's
    source res; $DC64 := the target's source skills (record tags)."""
    src_res = source_res(b, t)
    opts = skills_to_opts(source_skills(b, t), records)
    if t != a:
        _save_source(b, a)
    b.res[a * 7:a * 7 + 7] = src_res
    if t == a:
        b.ext.get('f9_opts', {}).pop(a, None)     # own source list: the movepool again
        if a in (3, 7) and a in b.ext.get('f9_helper', {}):
            _ext(b, 'f9_opts')[a] = opts
    else:
        _ext(b, 'f9_opts')[a] = opts


def transform_action(ctx):
    """$29 Transform: SkillTransform $446C (both F7 markers), act state 5:
    F7 stat copy + own +3 bit5, then the res/skill copy; a non-link enemy
    caster records the target in $C1CA[a&3]."""
    def body(c, v, div, state):
        b = c.b
        F7.transform_mark(b, c.a)
        F7.transform_stats(b, c.a, v)
        transform_copy(b, c.a, v, c.records)
        if not b.link and c.a >= 4 and c.a != 7:
            _ext(b, 'f9_c1ca')[c.a & 3] = v
        c.log.append((c.a, 'transform', v))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.t, 1)])


def transform_pick(b, a, state):
    """Bank $58 row $4ED8 for Transform: $DD0B == 0 -> uniform opposing
    ($642C, one step); else score = MaxHP + MaxMP (current values, 0 for a
    non-live slot) over opp base, base+1, base+2; a later slot wins ties."""
    if b.dd0b[a] == 0:
        return B.uniform_side_pick(b, (a & 4) ^ 4, state)
    base = (a & 4) ^ 4
    best, best_s = None, base
    for s in range(base, base + 3):
        sc = (b.maxhp[s] + b.maxmp[s]) if b.valid(s) else 0
        if best is None or sc >= best:
            best, best_s = sc, s
    return best_s, state


def revert_slot(b, s, records, level=True, intel=True):
    """Restore slot s from its source (bank $57 base, saved res/level, its
    own skill list)."""
    for k in STATS:
        if k == 'int' and not intel:
            continue
        getattr(b, k)[s] = b.base[k][s]
    src = b.ext.get('f9_src_res', {}).pop(s, None)
    if src is not None:
        b.res[s * 7:s * 7 + 7] = src
    lv = b.ext.get('f9_src_level', {}).pop(s, None)
    if level and lv is not None:
        b.level[s] = lv
    elif lv is not None:
        _ext(b, 'f9_src_level')[s] = lv
    if s in (3, 7) and s in b.ext.get('f9_helper', {}):
        _ext(b, 'f9_opts')[s] = list(HELPERS[b.ext['f9_helper'][s]]['opts'])
    else:
        b.ext.get('f9_opts', {}).pop(s, None)


def ko_revert(b, t):
    """KO_HOOKS: the KO state's slot reload (bank $51 entry 15 ->
    LoadBtlS_44a9 with wBattlePostFlag = 1; skipped for helper slots 3/7)
    re-reads EVERY KO'd slot from its source — measured on transformed,
    dragon and plainly rig-poked slots:
      party (LoadBtlS_44cb): MaxHP/MaxMP/ATK/DEF/AGL/INT/level from the
        record, res, skill list with tags; HP and MP are skipped;
      enemy (LoadEnemyStatsForBattle): the row's MaxHP/MP/MaxMP/ATK/DEF/
        AGL/INT/level, res; only the 4 SKILL bytes of $DC64 are rewritten —
        the tag bytes keep whatever the slot held (a KO'd dragon keeps tags
        1,1,2 on the row skills).
    Then KOStatusWipe_4c26: HP := 0, MP := min(MP, MaxMP) (CmpHLvsBC), the
    status bytes (battle.ko_wipe). No-op without a known source (bare
    event boards: b.base all zero)."""
    if (t & 3) == 3:
        # the helper branch of the KO state (bank $51 entry 15, jr_051_53d6):
        # NO reload; $DD1B := $FF (gone, not revivable) and the side's summon
        # bit2 is CLEARED (the side may summon again) — measured both sides.
        if t in b.ext.get('f9_helper', {}):
            b.dd1b[t] = 0xFF
            b.st[side_byte(t)] &= ~0x04 & 0xFF
            if b.mp[t] > b.maxmp[t]:
                b.mp[t] = b.maxmp[t]
        return
    if not any(b.base[k][t] for k in STATS):
        return
    enemy = t >= 4 and not b.link
    cur = opts_of(b, t)
    revert_slot(b, t, None)
    if enemy:
        b.mp[t] = b.base['maxmp'][t]               # the row's MP (measured 1 -> 9, 999 -> 9)
    if enemy and cur is not None:
        full = list(cur) + [(0, 0xFF)] * (8 - len(cur))
        src = (source_skills(b, t) + [0xFF] * 4)[:4]
        for i in range(4):
            full[i] = (full[i][0], src[i])
        out = []
        for tg, sk in full:
            if sk == 0xFF:
                break
            out.append((tg, sk))
        _ext(b, 'f9_opts')[t] = out
    if b.mp[t] > b.maxmp[t]:
        b.mp[t] = b.maxmp[t]


# --------------------------------------------------------------------------
# $A6 ALLCHANGE / $A9 ECHO (fallbacks; F4 / F6 may own them)
# --------------------------------------------------------------------------
def allchange_action(ctx):
    """SkillALLCHANGE $4F35 (after the MISS machine on its row-$62CD
    target): own base..base+2, live -> +3 bit3 (sure critical)."""
    def body(c, v, div, state):
        own = c.a & 4
        for s in range(own, own + 3):
            if c.b.valid(s):
                c.b.set_stb(s, 3, c.b.stb(s, 3) | 0x08)
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.t, 1)])


def echo_action(ctx):
    """$A9 ECHO (SkillScared $4EE3): MISS machine on the caster, message."""
    def body(c, v, div, state):
        c.log.append((c.a, 'echo', None))
        return 'done', None, state
    return B.default_victims(ctx, body, victims=[(ctx.a, 1)])


# --------------------------------------------------------------------------
# targets (bank $58 rows) for commit (pacing) and act time
# --------------------------------------------------------------------------
def _self_commit(b, s, state):
    return s, state


def _self_pick(b, a, state):
    return a, state


def _transform_commit(b, s, state):
    return transform_pick(b, s, state)


# --------------------------------------------------------------------------
# pacing: the helper / rewritten-list commit inputs
# --------------------------------------------------------------------------
def commit_inputs(b, s):
    """(option list, (c1, c2, c3) category bases) the engine's AI uses for
    slot s when F9 rewrote them: a helper (bases 250 x3, its fixed list) or
    a transformed / dragon slot (its new list; bases unchanged -> None)."""
    opts = opts_of(b, s)
    bases = b.ext.get('f9_ai_bases', {}).get(s)
    return opts, (list(bases[:3]) if bases else None)


# --------------------------------------------------------------------------
# registration
# --------------------------------------------------------------------------
for _sk in SUMMONS:
    B.ACTION_HANDLERS[_sk] = summon_action
    B.CORE_OVERRIDES[_sk] = 'summon'
    B.RERESOLVE_PICKERS[_sk] = _self_pick
    B.COMMIT_TARGETS[_sk] = _self_commit
B.ACTION_HANDLERS[CHANCE] = chance_action
B.CORE_OVERRIDES[CHANCE] = 'chance'
B.RERESOLVE_PICKERS[CHANCE] = _self_pick
B.COMMIT_TARGETS[CHANCE] = _self_commit
for _sk in (CALLHOROR, SMASHED):
    B.ACTION_HANDLERS[_sk] = smashed_action
    B.CORE_OVERRIDES[_sk] = 'remove'
for _sk in (RUN,):
    B.ACTION_HANDLERS[_sk] = run_action
    B.CORE_OVERRIDES[_sk] = 'run'
    B.RERESOLVE_PICKERS[_sk] = _self_pick
    B.COMMIT_TARGETS[_sk] = _self_commit
for _sk in (BEDRAGON, CHGDRAGON):
    B.ACTION_HANDLERS[_sk] = dragon_action
    B.CORE_OVERRIDES[_sk] = 'form'
    B.RERESOLVE_PICKERS[_sk] = _self_pick
    B.COMMIT_TARGETS[_sk] = _self_commit
B.ACTION_HANDLERS[TRANSFORM] = transform_action
B.CORE_OVERRIDES[TRANSFORM] = 'stat'
B.RERESOLVE_PICKERS[TRANSFORM] = transform_pick
B.COMMIT_TARGETS[TRANSFORM] = _transform_commit
B.ACTION_HANDLERS.setdefault(ALLCHANGE, allchange_action)
B.CORE_OVERRIDES.setdefault(ALLCHANGE, 'allchange')
B.ACTION_HANDLERS.setdefault(ECHO, echo_action)
B.CORE_OVERRIDES.setdefault(ECHO, 'msg')
B.KO_HOOKS.append(ko_revert)
