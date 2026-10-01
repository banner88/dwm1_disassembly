"""arena.py — the ARENA as project data: `gamedata.arena` (ROADMAP P3.10b, S109;
PROJECT_COMPILER §2.25; SIDEQUEST_MAP "Arena / gate-boss ROSTER format").

What the game stores (ROM-verified S67 + S109, PyBoy-measured on the user's save):
  * the TEAMS are not a table: match m of group g fights the enemy-stats rows
    EID = $E0 + 9*g + 3*m + slot (slot 0-2) — ArenaBattleSetup (script opcode
    $1F, bank $04) at the lobby, LoadArenaEnemyStats (bank $50) between
    matches. Groups 0-7 = classes G F E D C B A S, 8 = Starry Night; group 9 =
    the King, whose EIDs the code overrides with $01E1-$01E3 (one match). So a
    team member is edited as its enemy row (`gamedata.enemies.<eid>`, the
    existing section — species, level, stats, skills, AI weights …).
  * the MASTER standing for each match in the Arena Battle room:
    ArenaMasterSpriteTable ($04:$5E22, 30 x [draw id, is_monster]) and the
    bank-$50 copy for matches 2-3 (ArenaMasterSpriteTable50 $50:$6778, 27 rows,
    no King). is_monster 0 = an NPC sprite id (the room's sheet resolver, ROM0
    $2ADF), 1 = a monster drawn like its follower (draw id = species + $10).
  * the ENTRY FEE of each class: ArenaClassFeeTable ($09:$5D23, 8 words G..S),
    shown, checked and paid in the bank $09 class menu (ArenaClassMenu).
  * the TEAM SIZE (new S109, engine bank $6E ArenaTeamFixup): 1-3 monsters per
    match (ArenaTeamSizeTable, 30 bytes; 3 = vanilla). Size n fights slots
    0..n-1; the others are not loaded and not drawn.

Schema (sparse; group keys G F E D C B A S StarryNight King; match keys "0"-"2",
King "0" only; every field optional):

  "arena": {
    "G": {"fee": 20, "matches": {"0": {"size": 1, "master": {"person": "0x0B"}},
                                 "2": {"master": {"monster": 41}}}},
    "King": {"matches": {"0": {"size": 2}}}
  }

Regions (no `arena` = the original bytes in every one):
  gd_arena_masters_04  bank $04 ArenaMasterSpriteTable   60 B
  gd_arena_masters_50  bank $50 ArenaMasterSpriteTable50 54 B (= rows 0-26)
  gd_arena_fees        bank $09 ArenaClassFeeTable       16 B
  gd_arena_team_sizes  bank $6E ArenaTeamSizeTable       30 B (hand patch bank_06e)

Checks (ERROR): unknown groups / matches / fields, a fee outside 0-65535 or on
Starry Night / the King, a size outside 1-3, a master that is not one person id
of the NPC sprite catalog (normal) / vanilla master id or one monster (0-214, a
declared new species), species 215-220 (Iron Rule 8: not monsters; 217-220 hang
the room — ROOM_DATA_FORMAT "Monster NPCs"), a team member (a used slot) of
species 215-220. WARN: species 239 (draw id species+$10 = $FF = "no sprite" in
the room resolver) as a team member.
"""

import json
import os

GROUPS = ['G', 'F', 'E', 'D', 'C', 'B', 'A', 'S', 'StarryNight', 'King']
GROUP_LABEL = {'StarryNight': 'Starry Night', 'King': 'King (Master Monster Tamer)'}
CLASSES = GROUPS[:8]
KING = 9
STARRY = 8
ROWS = 30                      # 10 groups x 3 matches (ArenaTeamSizeTable / masters)
ROWS_50 = 27                   # the bank-$50 copy has no King rows
PROTECTED = range(215, 221)    # PROJECT_STATE Iron Rule 8
NO_DRAW_SPECIES = 239          # species + $10 = $FF = the resolver's "no sprite"


class ArenaError(ValueError):
    pass


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def group_label(gi):
    g = GROUPS[gi]
    return GROUP_LABEL.get(g, f'{g} class')


def matches(gi):
    """How many matches group gi fights (the King: one)."""
    return 1 if gi == KING else 3


def eid(gi, m, slot):
    """The enemy-stats row of (group, match, slot) — the game's formula."""
    if gi == KING:
        return 0x1E1 + slot
    return 0xE0 + 9 * gi + 3 * m + slot


def index(gi, m):
    return 3 * gi + m


_VAN = {}


def vanilla(repo_root=None):
    """{'masters': [(draw, is_monster)] x 30, 'fees': [8]} from
    extracted/gamedata_vanilla.json (S109 tables arena_masters / arena_fees)."""
    repo = repo_root or _repo()
    if repo not in _VAN:
        v = json.load(open(os.path.join(repo, 'extracted', 'gamedata_vanilla.json')))
        t = v['tables']
        masters = [tuple(bytes.fromhex(r)) for r in t['arena_masters']['rows']]
        fees = [int.from_bytes(bytes.fromhex(r), 'little') for r in t['arena_fees']['rows']]
        _VAN[repo] = {'masters': masters, 'fees': fees}
    return _VAN[repo]


_CAT = {}


def person_ids(repo_root=None):
    """NPC sprite ids a master may be: the S91 catalog's 'normal' ids below
    $E0 + the ids vanilla masters use. ($E0-$E3 are special only as an NPC
    entry's OWN sprite byte — bank $0B Call_00b_4839 tests them before the
    display-list branch; a display entry's draw id goes straight to the sheet
    table, so the player / party shapes are not available to a master.)"""
    repo = repo_root or _repo()
    if repo not in _CAT:
        ids = set()
        try:
            d = json.load(open(os.path.join(repo, 'extracted', 'npc_sprite_catalog.json')))
            for k, v in d.get('sprites', {}).items():
                if v.get('category') == 'normal' and int(k, 16) < 0xE0:
                    ids.add(int(k, 16))
        except (OSError, ValueError):
            pass
        ids |= {d for d, f in vanilla(repo)['masters'] if not f}
        _CAT[repo] = ids
    return _CAT[repo]


def _int(v, what):
    try:
        if isinstance(v, str):
            s = v.strip()
            return int(s[1:], 16) if s.startswith('$') else int(s, 0)
        if isinstance(v, bool):
            raise ValueError
        return int(v)
    except (TypeError, ValueError):
        raise ArenaError(f"{what}: {v!r} is not a number")


def _gd(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    return (data.get('gamedata') or {}).get('arena') or {}


def _new_species(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    out = set()
    for s in ((data.get('custom') or {}).get('species') or []):
        if isinstance(s, dict):
            try:
                out.add(int(s.get('id')))
            except (TypeError, ValueError):
                pass
    return out


def master_value(m, what, new_species, repo_root=None):
    """{"person": id} | {"monster": species} -> (draw id, is_monster)."""
    if not isinstance(m, dict) or len([k for k in m if not str(k).startswith('_')]) != 1 \
            or not ({'person', 'monster'} & set(m)):
        raise ArenaError(f"{what}: one of {{\"person\": <NPC sprite id>}} or "
                         "{\"monster\": <species>}")
    if 'person' in m:
        pid = _int(m['person'], what + '.person')
        if pid not in person_ids(repo_root):
            raise ArenaError(f"{what}.person ${pid:02X}: not an NPC sprite of the catalog "
                             "(extracted/npc_sprite_catalog.json, 'normal' ids)")
        return (pid, 0)
    sp = _int(m['monster'], what + '.monster')
    if sp in PROTECTED:
        raise ArenaError(f"{what}.monster {sp}: TERRY? / a summon tier / the empty slot "
                         "is not a monster (PROJECT_STATE Iron Rule 8)")
    if sp == NO_DRAW_SPECIES:
        raise ArenaError(f"{what}.monster {sp}: cannot be drawn in the arena room "
                         "(draw id = species + $10 = $FF, the 'no sprite' value)")
    if not (0 <= sp <= 214 or sp in new_species):
        raise ArenaError(f"{what}.monster {sp}: not a monster 0-214 or a new species "
                         "of the project (custom.species)")
    return ((sp + 0x10) & 0xFF, 1)


def master_spec(pair):
    """(draw, is_monster) -> the schema form."""
    d, f = pair
    return {'monster': d - 0x10} if f else {'person': f'0x{d:02X}'}


def resolve(prj_or_data, repo_root=None):
    """Validate gamedata.arena -> {'fees': [8], 'sizes': [30],
    'masters': [(draw, is_monster)] x 30, 'edited': {'fees', 'sizes', 'masters'}
    (sets of indices that differ from the original game)}. Raises ArenaError."""
    a = _gd(prj_or_data)
    repo = repo_root or getattr(prj_or_data, 'repo_root', None)
    van = vanilla(repo)
    fees, sizes, masters = list(van['fees']), [3] * ROWS, list(van['masters'])
    if not isinstance(a, dict):
        raise ArenaError("gamedata.arena: must be an object keyed by group "
                         f"({', '.join(GROUPS)})")
    new_species = _new_species(prj_or_data)
    for g, e in a.items():
        if str(g).startswith('_'):
            continue
        what = f"gamedata.arena.{g}"
        if g not in GROUPS:
            raise ArenaError(f"{what}: unknown group — {', '.join(GROUPS)}")
        gi = GROUPS.index(g)
        if not isinstance(e, dict):
            raise ArenaError(f"{what}: must be an object (fee, matches)")
        extra = {k for k in e if not str(k).startswith('_')} - {'fee', 'matches', 'comment'}
        if extra:
            raise ArenaError(f"{what}: unknown field(s) {sorted(extra)} (fee, matches)")
        if 'fee' in e:
            if gi >= STARRY:
                raise ArenaError(f"{what}.fee: only the classes G-S have an entry fee")
            v = _int(e['fee'], what + '.fee')
            if not 0 <= v <= 0xFFFF:
                raise ArenaError(f"{what}.fee {v}: 0-65535 gold (a 16-bit word)")
            fees[gi] = v
        ms = e.get('matches') or {}
        if not isinstance(ms, dict):
            raise ArenaError(f"{what}.matches: an object keyed by match \"0\"-\"2\"")
        for mk, me in ms.items():
            if str(mk).startswith('_'):
                continue
            mw = f"{what}.matches.{mk}"
            try:
                m = int(mk)
            except (TypeError, ValueError):
                raise ArenaError(f"{mw}: match keys are \"0\"-\"2\"")
            if not 0 <= m < matches(gi):
                has = 'one match ("0")' if gi == KING else 'matches "0"-"2"'
                raise ArenaError(f"{mw}: {group_label(gi)} has {has}")
            if not isinstance(me, dict):
                raise ArenaError(f"{mw}: must be an object (size, master)")
            extra = {k for k in me if not str(k).startswith('_')} - {'size', 'master', 'comment'}
            if extra:
                raise ArenaError(f"{mw}: unknown field(s) {sorted(extra)} (size, master)")
            if 'size' in me:
                n = _int(me['size'], mw + '.size')
                if not 1 <= n <= 3:
                    raise ArenaError(f"{mw}.size {n}: a team has 1-3 monsters")
                sizes[index(gi, m)] = n
            if 'master' in me:
                masters[index(gi, m)] = master_value(me['master'], mw + '.master',
                                                     new_species, repo)
    edited = {'fees': {i for i in range(8) if fees[i] != van['fees'][i]},
              'sizes': {i for i in range(ROWS) if sizes[i] != 3},
              'masters': {i for i in range(ROWS) if masters[i] != van['masters'][i]}}
    return {'fees': fees, 'sizes': sizes, 'masters': masters, 'edited': edited}


def teams(gd_model, sizes=None):
    """[(gi, m, [eid of every slot], size)] over every match the game fights."""
    out = []
    for gi in range(len(GROUPS)):
        for m in range(matches(gi)):
            n = (sizes or [3] * ROWS)[index(gi, m)]
            out.append((gi, m, [eid(gi, m, s) for s in range(3)], n))
    return out


def check(prj):
    """Validator: the section resolves and every fighting team member can be
    drawn and fought. Returns the warnings; raises ArenaError."""
    r = resolve(prj)
    warnings = []
    g = prj.gamedata()
    for gi, m, eids, n in teams(g, r['sizes']):
        for s, e in enumerate(eids[:n]):
            sp = g.enemy[e][0]
            where = f"arena {group_label(gi)}, match {m + 1}, monster {s + 1} (EID {e})"
            if sp in PROTECTED:
                raise ArenaError(f"{where}: species {sp} is TERRY? / a summon tier / the "
                                 "empty slot — not a monster (Iron Rule 8; 217-220 hang "
                                 "the arena room)")
            if sp == NO_DRAW_SPECIES:
                warnings.append(f"{where}: species {sp} is not drawn in the arena room "
                                "before the fight (draw id $FF); it still fights")
    return warnings


# ---------------------------------------------------------------------------
# emitters (one per region; `prj` = the compiler's Project)
# ---------------------------------------------------------------------------

def _names(prj):
    try:
        from . import monster_text as MT
        n = MT.effective(prj).get('names')
        from . import gamedata as G
        base = G.monster_names(getattr(prj, 'repo_root', None) or _repo())
        out = dict(base)
        if n:
            for sid in range(min(len(n), 221)):
                try:
                    out[sid] = MT.decode(n[sid])
                except Exception:
                    pass
        for s in ((prj.data.get('custom') or {}).get('species') or []):
            if isinstance(s, dict) and 'id' in s:
                out[int(s['id'])] = s.get('name', f"#{s['id']}")
        return out
    except Exception:
        return {}


def _master_comment(pair, names):
    d, f = pair
    if f:
        sp = (d - 0x10) & 0xFF
        return f"monster {sp} {names.get(sp, '')}".rstrip()
    return f"person ${d:02X}"


def _mark(edited):
    return "   ; (edited)" if edited else ""


def emit_masters(prj, rows, label):
    r = resolve(prj)
    names = _names(prj)
    out = [f"{label}:  ; [draw id, is_monster] per match; index 3*group + match"]
    for gi in range(rows // 3):
        trip = r['masters'][3 * gi:3 * gi + 3]
        bs = [b for p in trip for b in p]
        com = "; ".join(_master_comment(p, names) for p in trip)
        ed = any(3 * gi + k in r['edited']['masters'] for k in range(3))
        out.append("    db " + ", ".join(f"${b:02x}" for b in bs) +
                   f"  ; {group_label(gi)}: {com}" + _mark(ed))
    return "\n".join(out) + "\n"


def emit_masters_04(prj, warnings):
    return emit_masters(prj, ROWS, "ArenaMasterSpriteTable")


def emit_masters_50(prj, warnings):
    return emit_masters(prj, ROWS_50, "ArenaMasterSpriteTable50")


def emit_fees(prj, warnings):
    r = resolve(prj)
    out = ["ArenaClassFeeTable:"]
    for i in range(8):
        out.append(f"    dw {r['fees'][i]:5d}   ; {CLASSES[i]} class" +
                   _mark(i in r['edited']['fees']))
    return "\n".join(out) + "\n"


def emit_team_sizes(prj, warnings):
    r = resolve(prj)
    out = ["ArenaTeamSizeTable:  ; index 3*group + match; 1-3 monsters"]
    for gi in range(len(GROUPS)):
        trip = r['sizes'][3 * gi:3 * gi + 3]
        note = ' (only match 1 is fought)' if gi == KING else ''
        ed = any(3 * gi + k in r['edited']['sizes'] for k in range(3))
        out.append("    db " + ", ".join(str(x) for x in trip) +
                   f"   ; {group_label(gi)}{note}" + _mark(ed))
    return "\n".join(out) + "\n"


REGIONS = [('gd_arena_masters_04', 'patches/bank_004.asm', emit_masters_04, 0x04),
           ('gd_arena_masters_50', 'patches/bank_050.asm', emit_masters_50, 0x50),
           ('gd_arena_fees', 'patches/bank_009.asm', emit_fees, 0x09),
           ('gd_arena_team_sizes', 'patches/bank_06e.asm', emit_team_sizes, 0x6E)]
