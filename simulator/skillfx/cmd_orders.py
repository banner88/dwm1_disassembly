"""S130 (P3.15b) — the player's orders (battle menu PLAN -> COMMAND), the
act-time side. The commit side (the menu, the obedience gate under tactic 3,
the personality drift, the disobedient SetBtlAI_7f5f pick) lives in
simulator/pacing.py (give_orders / command_commit); this module registers
what the round core needs. Byte source: bank $50 $4794-$4F95 (the COMMAND
sub-machine), $52:$4E0A SkillDaze, $53:$47B2 + LoadBtlC_4e01, $58:$401D row
[$98]. Measured: simulator/measure_command.py -> command_events.json.gz,
validated by simulator/validate_command.py (BATTLE_SKILL_SYSTEM §15.10.7b).

  Daze $98 — the disobedient "loaf" (SetBtlAI_7f5f when all three category
    bases are < $3F). Bank $58 row TargetSelfWrite_6367 at commit and at the
    act-time re-resolve (a disobedient actor's $DD03 has bit6 set, so the
    act-time re-resolve runs for $DD0B != 0 and lands on the actor again).
    The act runs the usual MISS step (one BattleRNG step; flags7 = 0 /
    flags8 = 4: nothing can block, miss or dodge it), then SkillDaze
    ($52:$4E0A) only sets the animation flag and prints its message: no
    other RNG, no MP, no board change. The turn is lost.
  Dead ordered target — $53:$47B2: a single-target skill (target-mode bit0)
    whose queued target died before the actor acts is NOT re-picked when
    LoadBtlC_49dc ($DD0B == 0) or LoadBtlC_4e01 ($DD72 == 0, $DD03 == 3
    and the round plan wMenu_selection == $81) says so: the action fizzles.
    $DD72 is 0 throughout the act phase, so EVERY obeyed order aimed at an
    enemy (or ally) that dies first fizzles — plain Attack included — where
    an AI actor (or a FIGHT round) re-targets. battle.keeps_dead_target.
"""
from .. import battle as B

DAZE = 0x98


def _self(b, a, sk, qt, f, state):
    return a, state


def _self_commit(b, s, state):
    return s, state


def _daze(ctx, v, div, state):
    ctx.log.append((ctx.a, 'daze', None))
    return 'done', None, state


def handler(ctx):
    return B.default_victims(ctx, _daze, victims=[(ctx.t, 1)])


B.ACTION_HANDLERS[DAZE] = handler
B.CORE_OVERRIDES[DAZE] = 'daze'
B.TARGET_RESOLVERS[DAZE] = _self
B.COMMIT_TARGETS[DAZE] = _self_commit
