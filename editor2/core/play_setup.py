"""play_setup.py — the game state "Play here" starts with (S132; no Qt).

User S132: "Really need a 'play this room' with either flags + monsters
imported from a save OR set manually or generated according to thresholds (ie
have a vanilla slide scale you can put yourself on, and ideally make a separate
slide scale for romhack). Then you immediately enter room from editor." The
romhack scale: "follow gates naturally. Just like balance tab".

A SETUP (a plain dict, kept per project in the editor's settings):
    {'source': 'newgame' | 'sav' | 'story' | 'project' | 'manual',
     'sav': path, 'step': i (story / project), 'extra_gate': n | None,
     'level': None (= the level the step needs) | n, 'profile': 'player'|'strong'|'casual',
     'seed': k (reroll), 'party': [{'species', 'level', 'skills': [ids] | None,
     'plus'}] (manual), 'flags_on': [...], 'flags_off': [...]}

`resolve(setup, project, repo)` -> {'flags_set', 'flags_clear', 'ram', 'team'
[Monster], 'records' [149 B], 'base_sav', 'notes', 'label'} — what the Playback
engine needs (cutscenes.Recipe flags / ram + Engine.start(records=…)).

The story state is the game's own scripts run by `story_state.state_at`
(measured equal to PyBoy, tools/census_story_state.py); the team is the
Balance service's (`balance.team_for`: the 'player' kit of the step — the
original game's from the anchor, a project's from its cache — at the level the
step's hardest fight needs, l90 of the anchor / the project cache; else a
'strong' roll), each monster raised by simulator/raising.py (== the game,
census_raising.py). A record is a party record the engine made (the starter
grant, playback.Engine.STARTER) with the species and every raising field
replaced: the bytes the game reads (MONSTER_DATA "Party Monster Structure").
"""

import os
import random

from . import balance as B
from . import story_state as SS

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SOURCES = ('newgame', 'sav', 'story', 'project', 'manual')
SOURCE_LABELS = {'newgame': 'A new game (no monsters, no story)',
                 'sav': 'My save file (its flags, party and farm)',
                 'story': 'A story point of the original game',
                 'project': 'A story point of my project',
                 'manual': 'Set by hand'}


def default_setup():
    return {'source': 'story', 'sav': None, 'step': 0, 'extra_gate': None, 'level': None,
            'profile': 'player', 'seed': 0, 'party': [], 'flags_on': [], 'flags_off': []}


# ------------------------------------------------------------ the records
def party_record(mon, T, nickname=None):
    """A 149-byte party record of simulator Monster `mon`."""
    from .monster_text import encode_name, NICK_MAX, MonsterTextError
    from .playback import Engine
    # the engine's starter record (148 B in playback — one short in its
    # resistance block, which is rewritten below): the bytes kept are the in-use
    # flag +$00 and the master name +$0C-$14
    r = bytearray((bytes(Engine.STARTER) + bytes(0x95))[:0x95])
    sp = int(mon.species)
    r[0x09] = sp
    info = T.info.get(sp) if isinstance(T.info, dict) else (T.info[sp] if sp < len(T.info) else None)
    if info is not None:
        r[0x0A] = info[0]                         # family
    r[0x0B] = 1 if mon.female else 0
    nick = (nickname or mon.name or 'Mon').replace(' ', '')
    nick = ''.join(c for c in nick if c.isalnum())[:NICK_MAX] or 'Mon'
    try:
        nb = encode_name(nick, 'nickname', 1, NICK_MAX)
    except MonsterTextError:
        nb = encode_name('Mon', 'nickname', 1, NICK_MAX)
    r[0x01:0x09] = (nb + b'\xF0' * 8)[:8]
    r[0x15] = r[0x16] = 0xFF                      # not bred (no pedigree)
    for i in range(0x17, 0x29):
        r[i] = 0
    sk = [int(s) & 0xFF for s in mon.skills][:8]
    r[0x29:0x31] = bytes(sk + [0xFF] * (8 - len(sk)))
    q = [int(s) & 0xFF for s in mon.queue][:25]
    r[0x31:0x4A] = bytes(q + [0xFF] * (25 - len(q)))
    r[0x4A] = 0                                   # status
    r[0x4B] = int(mon.level) & 0xFF
    r[0x4C] = int(mon.cap) & 0xFF
    e = int(mon.exp) & 0xFFFFFF
    r[0x4D], r[0x4E], r[0x4F] = e & 0xFF, (e >> 8) & 0xFF, e >> 16
    mhp, mmp, atk, df, agl, it = (int(x) & 0xFFFF for x in mon.stats)

    def w(o, v):
        r[o], r[o + 1] = v & 0xFF, (v >> 8) & 0xFF
    w(0x50, mhp)
    w(0x52, mhp)
    w(0x54, mmp)
    w(0x56, mmp)
    w(0x58, atk)
    w(0x5A, df)
    w(0x5C, agl)
    w(0x5E, it)
    w(0x60, int(mon.wld) & 0xFFFF)
    r[0x62] = int(mon.plus) & 0xFF
    r[0x63] = 0                                   # not an egg
    r[0x64:0x68] = bytes(int(a) & 0xFF for a in list(mon.ai)[:4])
    res = [int(x) & 0xFF for x in mon.res][:27]
    r[0x68:0x83] = bytes(res + [0] * (27 - len(res)))
    for i in range(0x83, 0x95):
        r[i] = 0
    return bytes(r)


# ------------------------------------------------------------ the story
def _data(project, repo):
    return B.BattleData(project, repo=repo)


def project_points(tl, project_data):
    """The romhack scale: the timeline's positions (the project's gates at the
    game's places, as on the Balance tab) + each NEW gate / world right after
    the gate it was copied from. [(key, label)], key = (step, extra gate|None)."""
    extra = {}
    for g in ((project_data.get('custom') or {}).get('gates') or []):
        gid = g.get('gate', g.get('id'))
        if gid is None or int(gid) < 32:
            continue
        src = g.get('copy_of')
        name = g.get('name') or f'Gate {gid}'
        kind = 'World' if g.get('world') else 'New gate'
        extra.setdefault(int(src) if src is not None else None, []).append((int(gid), f'{kind}: {name}'))
    out = []
    for s in tl.steps:
        out.append(((s['index'], None), s['label'] + ('  (post-game)' if s['postgame'] else '')))
        if s['kind'] == 'gate':
            for gid, lab in extra.get(s['id'], []):
                out.append(((s['index'] + 1, gid), lab))
    for gid, lab in extra.get(None, []):
        out.append(((len(tl.steps), gid), lab + ' (no source gate)'))
    return out


def step_level(tl, step, anchor=None, cache=None, data=None, profile='player'):
    """The team level a step needs (its hardest fight's l90): the project's
    cached numbers, else the original game's anchor at the same position."""
    lv = []
    if step >= len(tl.steps):
        step = len(tl.steps) - 1
    for k in tl.steps[step]['fights']:
        v = None
        if cache is not None and data is not None:
            try:
                fp = B.fight_fingerprint(data, tl, tl.fights[k], profile, step)
                got = cache.get(fp)
                v = (got or {}).get('l90') if isinstance(got, dict) else None
            except Exception:                                    # noqa: BLE001
                v = None
        if v is None and anchor:
            v = ((anchor.get('fights', {}).get(k) or {}).get(profile) or {}).get('l90')
        if v is not None:
            lv.append(v)
    if not lv:
        return None
    return min(99, max(lv))


def story_team(data, tl, step, level, profile='player', seed=0, cache=None):
    """[Monster] x 3 for the step at that level."""
    step = min(step, len(tl.steps) - 1)
    if profile == 'player':
        kit = B.get_kit(data, tl, step, cache=cache, compute=False)
        if kit:
            from . import kits as KT
            return KT.kit_team(data, tl, step, kit, level, seed, 130), 'the step\'s player kit'
        profile = 'strong'
    rng = random.Random(B._seed(130 + seed, step, level, profile))
    return B.roll_team(data, tl, step, level, rng, profile), f'a {profile} roll'


def manual_team(data, party):
    out = []
    for i, p in enumerate(party or []):
        if p.get('species') is None:
            continue
        m = B.custom_member(data, int(p['species']), int(p.get('level') or 1),
                            skills=p.get('skills'), plus=int(p.get('plus') or 0), seed=130 + i)
        m.name = data.T.names.get(m.species, f'#{m.species}') if hasattr(data.T, 'names') and \
            isinstance(data.T.names, dict) else m.name
        out.append(m)
    return out[:3]


def resolve(setup, project=None, repo=REPO, cache=None, anchor=None):
    """What to start the game with (see the module doc)."""
    s = dict(default_setup(), **(setup or {}))
    src = s['source']
    out = {'flags_set': [], 'flags_clear': [], 'ram': {}, 'team': [], 'records': [],
           'base_sav': None, 'notes': [], 'label': SOURCE_LABELS.get(src, src), 'level': None}
    data = tl = None
    if src in ('story', 'project', 'manual'):
        data = _data(project if src != 'story' else None, repo)
        tl = B.Timeline(data)
    if src == 'sav':
        out['base_sav'] = s.get('sav')
        if not s.get('sav') or not os.path.exists(s['sav']):
            out['notes'].append('no save file chosen — a new game instead')
            out['base_sav'] = None
    elif src in ('story', 'project'):
        step = int(s.get('step') or 0)
        extra = s.get('extra_gate')
        st = SS.state_at(min(step, len(tl.steps)), repo)
        out['flags_set'] = list(st['flags_on'])
        out['ram'] = dict(st['ram'])
        lab = (tl.steps[min(step, len(tl.steps) - 1)]['label'] if step < len(tl.steps)
               else 'the end of the story')
        if src == 'project' and project is not None:
            pf = SS.project_flags(project.data, tl, step)
            if extra is not None:
                pf = [f for f in pf if f != SS.GATE_OWN_FLAG + int(extra)]
            out['flags_set'] += pf
            if pf:
                out['notes'].append(f'{len(pf)} of your gates count as cleared '
                                    f"(flags {', '.join(f'${f:04X}' for f in pf[:6])}"
                                    f"{'…' if len(pf) > 6 else ''})")
        if anchor is None:
            anchor = B.load_anchor(repo)
        lvl = s.get('level')
        if lvl is None:
            lvl = step_level(tl, min(step, len(tl.steps) - 1), anchor, cache=cache,
                             data=data, profile=s.get('profile') or 'player') or 1
        out['level'] = lvl
        team, how = story_team(data, tl, step, int(lvl), s.get('profile') or 'player',
                               int(s.get('seed') or 0), cache=cache)
        out['team'] = team
        out['label'] = f"about to do {lab}" + (f" (then {extra})" if extra else '')
        out['notes'].append(f'the party: {how} at level {lvl}')
        out['notes'].append(f"the story: {len(st['log'])} event(s) the game's scripts "
                            f"wrote — {len(out['flags_set'])} flags, {len(out['ram'])} room "
                            'states')
    elif src == 'manual':
        out['team'] = manual_team(data, s.get('party'))
    if data is not None and out['team']:
        out['records'] = [party_record(m, data.T, getattr(m, 'name', None))
                          for m in out['team']]
    # the Milly hook (S121): a project with the hook on is played as Milly with
    # her arrival scene done — $179F / $179E (EVENT_FLAGS "Reserved for the
    # Milly hook"); a save carries its own
    hook = ((getattr(project, 'data', None) or {}).get('custom') or {}).get('milly_hook') or {}
    if src != 'sav' and hook.get('enabled'):
        out['flags_set'] += [0x179F, 0x179E]
        out['notes'].append('the Milly hook is on: you play as Milly')
    on = [int(f) for f in s.get('flags_on') or []]
    off = [int(f) for f in s.get('flags_off') or []]
    out['flags_set'] = sorted((set(out['flags_set']) | set(on)) - set(off))
    out['flags_clear'] = sorted(set(off))
    return out


def team_lines(data_or_none, team):
    """['Slime Lv 12 — Blaze, Heal …'] for display."""
    out = []
    for m in team:
        sk = ', '.join(str((data_or_none.skill_names if data_or_none else {}).get(s, f'#{s}'))
                       for s in m.skills[:8]) if data_or_none else ''
        out.append(f"{m.name or ('#' + str(m.species))} Lv {m.level}"
                   + (f' +{m.plus}' if m.plus else '') + (f' — {sk}' if sk else ''))
    return out
