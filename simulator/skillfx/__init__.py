"""S130 skill families — the engine's remaining battle-skill handlers, one
module per family (BATTLE_SKILL_SYSTEM §15.11). Each module registers into
simulator/battle.py's registries (ACTION_HANDLERS, CORE_OVERRIDES, POST_CALC,
ACTOR_HOOKS, PHASE9_HOOKS, VICTIM_HOOKS) on import; battle.py imports this
package last. Every module names its byte source and its validation corpus."""
import importlib
import os
import pkgutil

for _m in sorted(m.name for m in pkgutil.iter_modules([os.path.dirname(__file__)])):
    importlib.import_module(f'{__name__}.{_m}')
