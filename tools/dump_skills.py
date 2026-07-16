"""LEGACY (retired S59) — do not use. Superseded by tools/gen_skill_records.py.

This tool used to write extracted/skills.json, which was RETIRED in S59 and is
no longer present in the repo. Its replacement is extracted/skill_records.json
(generator: tools/gen_skill_records.py, S44 schema), which every consumer now
reads.

Why it was retired
------------------
This dumper read 256 entries from the skill name/function tables. The skill
function table at $52:$4011 is only 222 entries (ids $00..$DD, 444 bytes,
$4011..$41CC). It ends where the first handler begins — SkillBlaze @ $52:$41CD,
whose opening bytes are CD FF 5B (`call $5BFF`). Reading 256 entries therefore
overran 68 bytes of handler CODE and decoded it as pointers, producing 34
garbage records (ids 222-255: blank names, bogus $FFCD / $CD5B / $E7CD
"addresses"). skill_records.json stops correctly at 221.

This file is kept as a tombstone rather than deleted so that a future session
does not re-derive the same 256-entry mistake. It is deliberately inert: running
it exits non-zero instead of recreating the retired file (the project has
already been bitten once by a legacy dumper silently resurrecting a deleted
extracted/ file — see PROJECT_STATE "Open defects", dump_monsters.py).

See: documentation/TOOLS_AND_DATA.md, documentation/BATTLE_SKILL_SYSTEM.md.
"""
import sys

sys.exit(
    "tools/dump_skills.py is LEGACY (retired S59) and does nothing.\n"
    "extracted/skills.json no longer exists; it read the 222-entry skill\n"
    "function table as 256 entries and emitted 34 garbage records.\n"
    "Use: python3 tools/gen_skill_records.py  ->  extracted/skill_records.json"
)
