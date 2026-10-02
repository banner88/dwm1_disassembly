"""skills.py — the SKILLS as project data beyond S103's three tables (ROADMAP
P3.11, S110; PROJECT_COMPILER §2.26; BATTLE_SKILL_SYSTEM §7 "Field map — S110
reader census").

`gamedata.skills.<id>` (ids 0-221, the vanilla skills) already held `mp`,
`learn` and `record` (S103, editor2/core/gamedata.py). S110 adds, in the same
per-skill object:

  "skills": {
    "0":  {"name": "Flare", "description": ["Burns one foe", "with a small", "fireball"],
           "looks_like": 3,                 # play Firebal's animation + sounds
           "mp": 3, "record": {"party_min": 20}},
    "43": {"description": ["Heals a lot"]}
  }

What the game stores (ROM-verified S110, extract_gamedata --selftest):
  * NAME — bank $41 text mode 6 (SkillNamePtrTable $4539, 256 words): one
    $F0-terminated string per skill 0-221, then the empty string ids 222-255
    share, back to back in id order at $628E-$69F1 (1,892 B). Every reader
    goes through the table (each SkillName_ label is referenced once).
  * DESCRIPTION — the SKIL-menu info box: bank $56 SkillDescPtrTable ($6667,
    256 words, text mode 1 of SkillDescModeTable $664B): ids 0-150 / 213-218
    own a string, 151-212 share SkillDesc_Blank, 219-255 SkillDesc_None;
    strings at $502F-$664A in id order (5,660 B). <= 3 lines of <= 18 cells.
  * PRESENTATION — the animation / flash / cast sound are a script chosen by
    skill id in bank $5f (12 reads, all through GetPresentId since S49) and
    the hit sounds by skill id in bank $55 (one read, SfxPresentId since
    S110). `looks_like` = the id those reads see (StockPresentTable /
    StockSfxTable; identity = vanilla). The effect, the message, the damage and
    the targeting stay the skill's own.

Regions (no edits = the original bytes in every one):
  gd_skill_names        bank $41 SkillNameStrings          1,892 B
  gd_skill_desc         bank $56 SkillDescStrings          5,660 B
  gd_skill_desc_ptrs    bank $56 SkillDescPtrTable rows 0-221 (444 B)
  gd_skill_desc_extra   bank $56 free pad ($7291)          2,993 B fixed
  gd_present_proxy_5f   bank $5f StockPresentTable           222 B
  gd_present_proxy_55   bank $55 StockSfxTable               222 B
Names that no longer fit their block go to the shared bank-$41 extents
(species.TEXT_EXTENTS, with the new species' names and S108's spills);
descriptions to gd_skill_desc_extra (with the own descriptions of ids that
share an empty one).
"""

import json
import os
import re

from . import monster_text as MT

N_IDS = 222
NAME_MAX = 9                        # vanilla max (Blazemore, Infermost …)
DESC_LINES, DESC_CELLS = 3, 18
NAME_BLOCK = (0x628E, 0x69F2)       # bank $41 [lo, hi)
DESC_BLOCK = (0x502F, 0x664B)       # bank $56 [lo, hi)
DESC_EXTRA = 2993                   # gd_skill_desc_extra (fixed size)
BLANK_LABEL, NONE_LABEL = 'SkillDesc_Blank', 'SkillDesc_None'

# ---------------------------------------------------------------------------
# what every field / bit does (the S110 reader census; one source for the
# Skills tab tooltips, the help topic and PROJECT_COMPILER §2.26)
# ---------------------------------------------------------------------------

KIND_LABEL = {'skill': 'skill', 'internal': 'battle action / boss move',
              'item_effect': 'battle item'}

TARGET_MODES = [   # (value, label) — the named set the editor offers
    (0x11, 'one foe'), (0x12, 'all foes'), (0x21, 'one ally'),
    (0x22, 'all allies'), (0x41, 'the user itself')]
TARGET_HINT = ("Who the skill is aimed at. The battle menu asks for a target only "
               "for 'one …'; an 'all …' skill is applied to every monster on that side "
               "in turn. Changing the SIDE of a skill (foe ↔ ally) rarely makes sense: "
               "its effect code was written for one side.")

AI_TAGS = [(1, 'attack'), (2, 'status / weaken'), (3, 'heal / support')]
AI_TAG_HINT = ("Which of the three plans the monster AI files this skill under "
               "(record +1, high half). The AI first picks a plan (attack, status, "
               "heal) and then a skill of that plan, so a heal filed as 'attack' is "
               "chosen when the AI wants to attack.")
AI_WEIGHT_HINT = ("How much the enemy / tactics AI likes this skill (record +3, "
                  "0-255; added to its plan's score). 0 = it is never the AI's "
                  "reason to pick a plan. Only the AI reads it.")
AI_ELEMENT_HINT = ("The resistance the AI assumes this skill tests (record +5). The AI "
                   "avoids targets that resist it. Only the AI reads it — the damage "
                   "itself uses the element the skill's effect code chooses.")
AI_DAMAGE_HINT = ("The AI's 'does this deal damage' class (record +6): none, spell, "
                  "breath. Only the AI reads it.")
DAMAGE_CLASSES = [(0, 'none'), (4, 'spell damage'), (5, 'breath damage')]
MP_HINT = ("MP cost. The game keeps it twice: the battle charges record +4 "
           "(0-255) and the field menu shows / charges the $07 table — the editor "
           "writes both. 'All MP' (Farewell, MegaMagic) is code, not a number.")
POWER_HINT = ("Damage or healing the skill rolls: min to max. Party monsters "
              "and enemies use separate pairs (enemy Blaze is weaker than yours). "
              "Some skills ignore these and compute their effect in code "
              "(BATTLE_SKILL_SYSTEM 'power field is BLIND').")
LOOKS_HINT = ("Play another skill's animation, screen flash and sounds. The effect, "
              "the message, the damage and the targets stay this skill's own. Every "
              "original skill can lend its look (measured: none stalls a battle); a look "
              "made for the other side may show nothing, a summon's only blinks the screen.")

# (record offset, bit, key, label, hint) — bits some code READS
FLAG_BITS = [
    (7, 0, 'f7_guard_cut', 'cut by Defence / StrongD',
     "A target guarding with Defence takes half, with StrongD a tenth."),
    (7, 1, 'f7_surround', 'misses under Surround',
     "A caster under Surround misses it 62.5 % of the time (and 37.5 % more under "
     "the status +7 blur)."),
    (7, 3, 'f7_keep_target', 'keeps its target',
     "The target chosen when the turn was planned is kept; without it a 'smart' "
     "monster re-aims at act time."),
    (7, 4, 'f7_breath', 'breath',
     "A breath: sealed by MouthShut ('its mouth is bound shut'), reflected by "
     "TailWind, absorbed by SuckAll; the fire/ice breaths are boosted by SuckAir. "
     "Breaths 'spit' instead of 'cast'."),
    (7, 5, 'f7_dance', 'dance',
     "A dance: sealed by DanceShut ('the dance is blocked'); 'dances' instead of "
     "'casts'."),
    (7, 6, 'f7_spell', 'spell',
     "A spell: sealed by StopSpell, broken by a spell-breaking field; 'casts'."),
    (7, 7, 'f7_physical', 'physical contact',
     "A blow: cannot reach a monster in the air (HighJump), halved by BladeD, a "
     "target may grab an ally as a shield."),
    (8, 0, 'f8_reflect', 'reflected by MagicBack / Bounce',
     "A wall of light (MagicBack, Bounce) on the target turns it back."),
    (8, 1, 'f8_cover', 'redirected by Cover / Guardian',
     "An ally protecting the target (Cover, Guardian) takes it instead."),
    (8, 2, 'f8_iron', 'stopped by Ironize',
     "A target turned to iron (Ironize) is not affected; the action fails."),
    (8, 4, 'f8_critical', 'can be a critical hit',
     "May land a critical hit (or a pitiful one); a caster with ChargeUP armed "
     "'attacks with full force'."),
    (8, 5, 'f8_twinhits', 'doubled by TwinHits',
     "Twice the damage while the caster is under TwinHits."),
    (8, 6, 'f8_chargeup', 'boosted by ChargeUP',
     "Two to two-and-a-half times the damage while ChargeUP is armed."),
    (8, 7, 'f8_dodge', 'can be dodged',
     "The target may dodge: 50 % under Dodge / SideStep, else by its agility."),
    (9, 0, 'f9_takemagic', 'TakeMagic soaks its MP',
     "A target with TakeMagic gains the MP this skill cost."),
    (9, 2, 'f9_imitate', 'Imitate turns it back',
     "A target with Imitate 'gets even': the skill is sent back."),
    (9, 3, 'f9_snap', 'can snap confusion',
     "A landed hit may bring a confused target back to its senses."),
    (9, 4, 'f9_followup', 'follow-up action',
     "May be a monster's second action in a turn (the extra-action status; its "
     "setter was not found in the ROM and it was never seen in 11,000 measured "
     "battle events)."),
    (9, 5, 'f9_no_reach', "can't reach the air",
     "'But it doesn't reach X!' against a monster in the air (HighJump)."),
]
# bits / bytes NO code reads (S110 census) — shown, not edited
DEAD = [(0, None, "record +0 — a serial number; nothing in the game reads it"),
        (1, 'lo', "record +1, low half — nothing reads it (the high half is the AI plan)"),
        (7, 2, "flags7 bit2 — nothing reads it"),
        (8, 3, "flags8 bit3 — nothing reads it"),
        (9, 1, "flags9 bit1 — read only for the confusion 'meta' actions (allowed in a "
               "boss battle); an ordinary skill ignores it"),
        (9, 6, "flags9 bit6 — nothing reads it"),
        (9, 7, "flags9 bit7 — nothing reads it (no skill sets it)"),
        (10, None, "record +10 — read for battle ITEMS only (1 = cannot be used in battle)")]


class SkillError(ValueError):
    pass


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


_VAN = {}


def vanilla(repo_root=None):
    """{'names': [222 bytes], 'descs': [222 bytes], 'desc_shared': {id: 'blank'|
    'none'}, 'records': {id: record dict}} — no ROM needed."""
    repo = repo_root or _repo()
    if repo not in _VAN:
        v = json.load(open(os.path.join(repo, 'extracted', 'gamedata_vanilla.json')))
        st = v['skill_text']
        recs = {}
        try:
            for r in json.load(open(os.path.join(repo, 'extracted',
                                                 'skill_records.json')))['records']:
                recs[int(r['id'])] = r
        except (OSError, ValueError, KeyError):
            pass
        _VAN[repo] = {'names': [bytes.fromhex(h) for h in st['names']],
                      'descs': [bytes.fromhex(h) for h in st['descs']],
                      'desc_shared': {int(k): x for k, x in st['desc_shared'].items()},
                      'raw': [bytes.fromhex(r) for r in v['tables']['skill_records']['rows']],
                      'mp': [int.from_bytes(bytes.fromhex(r), 'little')
                             for r in v['tables']['skill_mp']['rows']],
                      'records': recs}
    return _VAN[repo]


def kind(sid, repo_root=None):
    r = vanilla(repo_root)['records'].get(sid) or {}
    return r.get('kind', 'skill')


def side(target_mode):
    """'foe' | 'ally' | 'self' | 'other' from a record +2 value."""
    if target_mode & 0x40:
        return 'self'
    if target_mode & 0x10:
        return 'foe'
    if target_mode & 0x20:
        return 'ally'
    return 'other'


def vanilla_name(sid, repo_root=None):
    return MT.decode(vanilla(repo_root)['names'][sid]) if 0 <= sid < N_IDS else ''


# ---------------------------------------------------------------------------
# resolve gamedata.skills.<id>.{name, description, looks_like}
# ---------------------------------------------------------------------------

TEXT_KEYS = ('name', 'description', 'looks_like', 'sounds_like')


def _gd(prj_or_data):
    data = getattr(prj_or_data, 'data', prj_or_data) or {}
    return (data.get('gamedata') or {}).get('skills') or {}


def _int(v, what):
    try:
        if isinstance(v, bool):
            raise ValueError
        if isinstance(v, str):
            s = v.strip()
            return int(s[1:], 16) if s.startswith('$') else int(s, 0)
        return int(v)
    except (TypeError, ValueError):
        raise SkillError(f"{what}: {v!r} is not a number")


def target_mode_of(prj_or_data, sid, repo_root=None):
    """The skill's EFFECTIVE record +2 (a project record edit, else vanilla)."""
    e = _gd(prj_or_data).get(str(sid)) or {}
    rec = e.get('record') or {}
    if 'target_mode' in rec:
        try:
            return _int(rec['target_mode'], 'target_mode') & 0xFF
        except SkillError:
            pass
    return vanilla(repo_root)['raw'][sid][2]


def resolve(prj_or_data, repo_root=None):
    """-> {sid: {'name': bytes|None, 'desc': bytes|None, 'looks': id|None}}
    (only what differs from the original game). Raises SkillError."""
    sk = _gd(prj_or_data)
    if not isinstance(sk, dict):
        raise SkillError("gamedata.skills: must be an object keyed by skill id")
    repo = repo_root or getattr(prj_or_data, 'repo_root', None)
    van = vanilla(repo)
    out = {}
    for k, e in sk.items():
        if str(k).startswith('_') or not isinstance(e, dict):
            continue
        if not any(x in e for x in TEXT_KEYS):
            continue
        what = f"gamedata.skills.{k}"
        sid = _int(k, what)
        if sid >= N_IDS:
            continue                    # S111: custom skills = custom_skills.py
        if sid < 0:
            raise SkillError(f"{what}: not a skill id")
        r = {'name': None, 'desc': None, 'looks': None, 'sounds': None}
        if 'name' in e:
            try:
                b = MT.encode_name(e['name'], what + '.name', 1, NAME_MAX)
            except MT.MonsterTextError as x:
                raise SkillError(str(x))
            r['name'] = b if b != van['names'][sid] else None
        if 'description' in e:
            d = e['description']
            if d in (None, '', []):
                b = b''
            else:
                try:
                    b = MT.encode_desc(d, what + '.description')
                except MT.MonsterTextError as x:
                    raise SkillError(str(x).replace('library page', 'SKIL box'))
            r['desc'] = b if b != van['descs'][sid] else None
        if 'looks_like' in e and e['looks_like'] is not None:
            x = _int(e['looks_like'], what + '.looks_like')
            if not 0 <= x < N_IDS:
                raise SkillError(f"{what}.looks_like {x}: a vanilla skill id 0-{N_IDS - 1}")
            check_looks(prj_or_data, sid, x, what, repo)
            r['looks'] = x if x != sid else None
        if 'sounds_like' in e and e['sounds_like'] is not None:
            # S111: the sounds alone (bank $55 StockSfxTable); default = looks_like
            x = _int(e['sounds_like'], what + '.sounds_like')
            if not 0 <= x < N_IDS:
                raise SkillError(f"{what}.sounds_like {x}: a vanilla skill id 0-{N_IDS - 1}")
            r['sounds'] = x if x != sid else None
        if any(v is not None for v in r.values()):
            out[sid] = r
    return out


# Lending a look (S110, MEASURED — extracted/skill_present_census.json,
# tools/census_skill_present.py): every one of the 222 vanilla skills lent its
# presentation to party one-foe / all-foes / one-ally / all-allies / self
# borrowers and to an enemy caster's attack and self-heal (1,554 PyBoy rig
# battles on the user's save): the battle never stalled (longest frozen action
# machine 157 frames), the borrower always acted. So nothing is REFUSED unless
# the census measured a stall; a look made for the other side, or a summon's,
# is only WARNED about (it may show nothing / play on the other side — the
# summons' "animation" is the summoned monster, drawn by the combatant display
# and waited for by THEIR id at $53:$5B07). The S74 note "HealMore's look
# stalls" was the custom-skill path (bank $72 / the cast-anim slot), not this.
SUMMONS = set(range(0x84, 0x88))


def _census(repo):
    """{donor: {'name', 'runs': {borrower: {'result', 'gap', 'acts'}}}} from
    extracted/skill_present_census.json; {} when absent."""
    try:
        d = json.load(open(os.path.join(repo or _repo(), 'extracted',
                                        'skill_present_census.json')))
        return {int(k): v for k, v in d.get('results', {}).items()}
    except (OSError, ValueError):
        return {}


def lend_problem(prj_or_data, sid, donor, repo_root=None):
    """Why `donor` CANNOT lend its look to `sid` (None = it can): only a
    measured stall."""
    if donor == sid:
        return None
    c = _census(repo_root).get(donor)
    if c:
        bad = [k for k, r in c.get('runs', {}).items() if r.get('result') != 'ok']
        if bad:
            return (f"{vanilla_name(donor, repo_root)}'s look did not finish when borrowed "
                    f"(measured: {', '.join(bad)})")
    return None


def lend_warning(prj_or_data, sid, donor, repo_root=None):
    """A look that works but may not show as hoped (None = no remark)."""
    if donor == sid:
        return None
    if donor in SUMMONS:
        return (f"{vanilla_name(donor, repo_root)} is a summon: its animation is the summoned "
                "monster, so borrowed it shows only the screen blink")
    a = side(target_mode_of(prj_or_data, sid, repo_root))
    b = side(vanilla(repo_root)['raw'][donor][2])
    if a != b:
        who = {'foe': 'the foes', 'ally': 'allies', 'self': 'its user', 'other': 'a field'}
        return (f"{vanilla_name(donor, repo_root)}'s look was made for a skill aimed at "
                f"{who.get(b, b)}, this one is aimed at {who.get(a, a)}: it may show nothing "
                "or play on the other side (it never stalls — measured)")
    return None


def check_looks(prj_or_data, sid, donor, what, repo_root=None):
    p = lend_problem(prj_or_data, sid, donor, repo_root)
    if p:
        raise SkillError(f"{what}.looks_like {donor}: {p}")


def effective(prj_or_data, repo_root=None):
    van = vanilla(repo_root or getattr(prj_or_data, 'repo_root', None))
    names, descs = list(van['names']), list(van['descs'])
    looks = list(range(N_IDS))
    sounds = list(range(N_IDS))
    own = set()                                   # ids that get their OWN desc string
    for sid, r in resolve(prj_or_data, repo_root).items():
        if r['name'] is not None:
            names[sid] = r['name']
        if r['desc'] is not None:
            descs[sid] = r['desc']
            if sid in van['desc_shared']:
                own.add(sid)
        if r['looks'] is not None:
            looks[sid] = r['looks']
            sounds[sid] = r['looks']
        if r.get('sounds') is not None:
            sounds[sid] = r['sounds']
    return {'names': names, 'descs': descs, 'looks': looks, 'sounds': sounds, 'own_desc': own}


def name_text(prj_or_data, sid, repo_root=None):
    """The skill name a player sees (project rename or the original)."""
    try:
        e = effective(prj_or_data, repo_root)
    except SkillError:
        e = vanilla(repo_root or getattr(prj_or_data, 'repo_root', None))
    return MT.decode(e['names'][sid]) if 0 <= sid < N_IDS else ''


def names(prj_or_data, repo_root=None):
    """{id: displayed name} for the 222 vanilla skills."""
    try:
        e = effective(prj_or_data, repo_root)
    except SkillError:
        e = vanilla(repo_root or getattr(prj_or_data, 'repo_root', None))
    return {i: MT.decode(e['names'][i]) for i in range(N_IDS)}


# ---------------------------------------------------------------------------
# labels (= the clean disassembly's; stable whatever the text says)
# ---------------------------------------------------------------------------

def _tag(bs):
    return re.sub(r'[^A-Za-z0-9]', '', MT.decode(bs))


def name_label(sid, repo_root=None):
    if sid == N_IDS:
        return 'SkillName_222_Unused_222'
    return f"SkillName_{sid:03d}_{_tag(vanilla(repo_root)['names'][sid]) or 'X'}"


def desc_label(sid, repo_root=None):
    van = vanilla(repo_root)
    if sid in van['desc_shared']:
        return BLANK_LABEL if van['desc_shared'][sid] == 'blank' else NONE_LABEL
    return f"SkillDesc_{sid:03d}_{_tag(van['names'][sid]) or 'X'}"


def own_desc_label(sid):
    """A skill that shares an empty description but gets its own text."""
    return f"SkillDescOwn_{sid:03d}"


# ---------------------------------------------------------------------------
# block layout
# ---------------------------------------------------------------------------

def _fill(items, size):
    placed, spilled, used = [], [], 0
    for label, b in items:
        if used + len(b) <= size:
            placed.append((label, b))
            used += len(b)
        else:
            spilled.append((label, b))
    return placed, spilled, used


def _desc_order(repo_root=None):
    """The vanilla string order: the owned ids 0-150, Blank, 213-218, None."""
    van = vanilla(repo_root)
    out = [s for s in range(151) if s not in van['desc_shared']]
    out.append('blank')
    out += [s for s in range(151, N_IDS) if s not in van['desc_shared']]
    out.append('none')
    return out


def layout(prj_or_data, repo_root=None):
    """-> {'names': (placed, spilled, used), 'descs': (placed, spilled, used),
    'own': [(label, bytes)]} — every string $F0-terminated."""
    repo = repo_root or getattr(prj_or_data, 'repo_root', None)
    e = effective(prj_or_data, repo)
    nm = [(name_label(s, repo), e['names'][s] + b'\xf0') for s in range(N_IDS)]
    nm.append((name_label(N_IDS), b'\xf0'))
    ds = []
    for s in _desc_order(repo):
        if s == 'blank':
            ds.append((BLANK_LABEL, b'\xf0'))
        elif s == 'none':
            ds.append((NONE_LABEL, b'\xf0'))
        else:
            ds.append((desc_label(s, repo), e['descs'][s] + b'\xf0'))
    own = [(own_desc_label(s), e['descs'][s] + b'\xf0') for s in sorted(e['own_desc'])
           if e['descs'][s]]
    return {'names': _fill(nm, NAME_BLOCK[1] - NAME_BLOCK[0]),
            'descs': _fill(ds, DESC_BLOCK[1] - DESC_BLOCK[0]),
            'own': own}


def bank41_spills(prj_or_data, repo_root=None):
    """Skill names that must go to the shared bank-$41 extents."""
    return layout(prj_or_data, repo_root)['names'][1]


def desc_extra_items(prj_or_data, repo_root=None):
    lay = layout(prj_or_data, repo_root)
    from . import custom_skills as CS          # S111: custom SKIL texts that spill
    return list(lay['descs'][1]) + list(lay['own']) + list(CS.desc_spills(prj_or_data, repo_root))


def usage(prj_or_data, repo_root=None):
    """Byte meters: {'names': (used, block), 'descs': (used, block),
    'extra': (used, DESC_EXTRA)}."""
    lay = layout(prj_or_data, repo_root)
    n_used = lay['names'][2] + sum(len(b) for _l, b in lay['names'][1])
    d_used = lay['descs'][2]
    extra = sum(len(b) for _l, b in desc_extra_items(prj_or_data, repo_root))
    return {'names': (n_used, NAME_BLOCK[1] - NAME_BLOCK[0]),
            'descs': (d_used, DESC_BLOCK[1] - DESC_BLOCK[0]),
            'extra': (extra, DESC_EXTRA)}


def check(prj):
    """Validator: everything resolves and fits (raises SkillError); returns
    the warnings (looks that may not show as hoped)."""
    res = resolve(prj)
    need = sum(len(b) for _l, b in desc_extra_items(prj))
    if need > DESC_EXTRA:
        raise SkillError(
            f"skill descriptions: {need} B do not fit — the description block is full and "
            f"the spare room in bank $56 holds {DESC_EXTRA} B; shorten some descriptions")
    out = []
    for sid, r in res.items():
        if r['looks'] is not None:
            w = lend_warning(prj, sid, r['looks'])
            if w:
                out.append(f"gamedata.skills.{sid}.looks_like {r['looks']}: {w}")
    return out


# ---------------------------------------------------------------------------
# emitters
# ---------------------------------------------------------------------------

def _db(bs):
    return "    db " + ", ".join(f"${b:02X}" for b in bs)


def _block(placed, used, size, head, comment):
    out = list(head)
    for label, b in placed:
        out.append(f"{label}:  ; \"{comment(b)}\"")
        out.append(_db(b))
    if used < size:
        out.append(f"    ds {size - used}, $00   ; unused ({size - used} B)")
    return "\n".join(out) + "\n"


def emit_names(prj, warnings):
    placed, spilled, used = layout(prj)['names']
    head = ["SkillNameStrings:"]
    if spilled:
        head.append(f"; ({len(spilled)} name(s) placed in the ns_text_* extents: "
                    + ", ".join(l for l, _b in spilled) + ")")
    return _block(placed, used, NAME_BLOCK[1] - NAME_BLOCK[0], head, MT.decode)


def emit_descs(prj, warnings):
    placed, spilled, used = layout(prj)['descs']
    head = ["SkillDescStrings:"]
    if spilled:
        head.append(f"; ({len(spilled)} description(s) placed in gd_skill_desc_extra)")
    return _block(placed, used, DESC_BLOCK[1] - DESC_BLOCK[0], head,
                  lambda b: MT.decode(b).replace('\n', '/'))


def emit_desc_ptrs(prj, warnings):
    e = effective(prj)
    out = []
    for s in range(N_IDS):
        lab = own_desc_label(s) if (s in e['own_desc'] and e['descs'][s]) else desc_label(s)
        out.append(f"    dw {lab:<28}; [{s:3d}] {MT.decode(e['names'][s]) or '-'}")
    return "\n".join(out) + "\n"


def emit_desc_extra(prj, warnings):
    items = desc_extra_items(prj)
    out = []
    used = 0
    for label, b in items:
        out.append(f"{label}:  ; \"{MT.decode(b).replace(chr(10), '/')}\"")
        out.append(_db(b))
        used += len(b)
    out.append(f"    ds {DESC_EXTRA - used}, $00   ; free ({DESC_EXTRA - used} of {DESC_EXTRA} B)")
    return "\n".join(out) + "\n"


def _emit_looks(prj, key='looks'):
    e = effective(prj)
    out = []
    for k in range(0, N_IDS, 16):
        ids = list(range(k, min(k + 16, N_IDS)))
        row = "    db " + ", ".join(f"${e[key][i]:02X}" for i in ids) + f"   ; [{k:3d}-{ids[-1]:3d}]"
        ed = [i for i in ids if e[key][i] != i]
        if ed:
            row += f"  ; {key} like: " + ", ".join(f"{i}->{e[key][i]}" for i in ed)
        out.append(row)
    return "\n".join(out) + "\n"


def emit_present_5f(prj, warnings):
    return _emit_looks(prj)


def emit_present_55(prj, warnings):
    return _emit_looks(prj, 'sounds')       # S111: sounds_like (default = looks_like)


REGIONS = [('gd_skill_names', 'patches/bank_041.asm', emit_names, 0x41),
           ('gd_skill_desc', 'patches/bank_056.asm', emit_descs, 0x56),
           ('gd_skill_desc_ptrs', 'patches/bank_056.asm', emit_desc_ptrs, 0x56),
           ('gd_skill_desc_extra', 'patches/bank_056.asm', emit_desc_extra, 0x56),
           ('gd_present_proxy_5f', 'patches/bank_05f.asm', emit_present_5f, 0x5F),
           ('gd_present_proxy_55', 'patches/bank_055.asm', emit_present_55, 0x55)]
