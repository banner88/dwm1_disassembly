"""S163 demo (ROADMAP E17 note "Act-time id lists"): THE ECHO HALL on the user's project.

A NEW skill runs its BASE's effect with its own record — but the original game also decides
parts of an effect by comparing the acting skill's id with fixed ids: Vivify (half HP, may
fail) vs Revive (full HP, never fails) share one routine that asks "is this Vivify?";
SickLick (the target's DEF drops) vs LushLicks; TailWind (the caster alone) vs StormWind (the whole
side); the hit ladders of Sleep and the one-shot dances; the act's routing; boss protection;
turn-order keys … A new skill matched none of those ids, so a new skill on Vivify acted as
Revive, one on SickLick as LushLicks, one on TailWind as StormWind (tools/
census_act_id_lists.py). Since S163 those reads see a new skill's BASE (the act-time base
view: banks $50 / $52 / $53 / $58, BATTLE_SKILL_SYSTEM §13.14).

  * THE ECHO HALL (a new room, one screen, gate look 11):
      the ECHO GUIDE (what this is; YES = back to the city);
      the GIFT KEEPER (YES = two Healers: ORIGINAL knows Vivify, SickLick, TailWind and
        Ahhh; ECHO knows the four NEW twins EVivify, ESickLk, ETailWd and EAhhh — the same
        bases, the same data);
      the SPARRING SLIME (YES = a fight with three sturdy slimes that barely hurt):
        cast each skill from ORIGINAL and from ECHO and compare the lines.

Also in the project (for tools/walk_actbase.py, not given to the player): the new twins of
Revive, LushLicks, StormWind, Sleep, LegSweep, Barrier, SquallHit, BeDragon, CallHelp and
TakeMagic.

Way in: the ECHO GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s163_echo_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json).
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document                       # noqa: E402
from editor2.core.render_project import ProjectRenderer          # noqa: E402
from editor2.core import textenc as T                            # noqa: E402

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)
d.vanilla = r

WALL = [0x08, 0x09, 0x18, 0x19]


def B(*paras, choice=False):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out, **({'choice': True} if choice else {})}


def paint(lid, cx, cy, mt):
    g = d.layout(lid)['tiles']
    g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1] = mt[0], mt[1]
    g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1] = mt[2], mt[3]


def walls(lid):
    for cx in range(10):
        paint(lid, cx, 0, WALL)
        paint(lid, cx, 7, WALL)
    for cy in range(8):
        paint(lid, 0, cy, WALL)
        paint(lid, 9, cy, WALL)


def entry_script(rm, rid):
    t = rm.setdefault('scripts', {})
    if '0' not in t:
        t['0'] = f'{rid}_entry'
        d.custom['scripts'].append({'id': t['0'], 'ops': [['end']]})


def npc(room_id, key, x, y, sprite, steps, name, monster=None):
    rm = d.room(room_id)
    d.add_npc(rm, key, 0, x, y, sprite, 'down', **({'monster': monster} if monster else {}))
    k = len(d.npc_entries(rm, key, 0)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, key, 0, k, script=sid)
    return sid


def go_to(mid, x=4, y=5):
    return {'move': {'dest': f'room:${mid:02X}', 'screen': 0, 'x': x, 'y': y}}


# ---- the new twins (high ids 239+) --------------------------------------------------------
TWINS = [(48, 'Vivify'), (122, 'SickLk'), (138, 'TailWd'), (112, 'Ahhh'),     # given
         (49, 'Revive'), (121, 'LushLk'), (139, 'StrmWd'), (21, 'Sleep'), (123, 'LegSwp'),
         (36, 'Barier'), (85, 'Squall'), (213, 'BeDrgn'), (82, 'CallHp'), (27, 'TakeMg')]
E = {}
for base, nm in TWINS:
    E[base] = d.new_custom_skill(base, 'E' + nm)
    d.set_skill_description(E[base], [f'Echo of skill {base}', 'a NEW skill on', 'that base.'])

VIVIFY, SICKLICK, TAILWIND, AHHH = 48, 122, 138, 112
HEALER, SLIME = 9, 0
original = d.add_enemy(copy_eid=2, name='Original', species=HEALER, level=25, hp=400, mp=400,
                       atk=40, **{'def': 60}, agl=60, int=150, joinability=7,
                       skills=[VIVIFY, SICKLICK, TAILWIND, AHHH])
echo = d.add_enemy(copy_eid=2, name='Echo', species=HEALER, level=25, hp=400, mp=400,
                   atk=40, **{'def': 60}, agl=60, int=150, joinability=7,
                   skills=[E[VIVIFY], E[SICKLICK], E[TAILWIND], E[AHHH]])
sparring = d.add_enemy(copy_eid=2, name='Spar slime', species=SLIME, level=10, hp=600, mp=0,
                       atk=12, **{'def': 30}, agl=10, int=1, joinability=7, skills=[])

# ---- THE ECHO HALL ---------------------------------------------------------------------------
hall_id = d.new_room('ECHO HALL', 0, r, gate_theme=11)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 2, 0x0B, [{'ask': B(
    'THE ECHO HALL. A new skill runs the effect of the skill it is based on. Some effects '
    'ask "which skill is this?" - Vivify or Revive, SickLick or LushLicks, TailWind or '
    'StormWind. A new skill now answers with its base. Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Listen for the echo.')}]}], 'echo_guide')
npc(hall_id, '0', 5, 4, 0x1D, [
    {'ask': B('I am the GIFT KEEPER. Take ORIGINAL and ECHO? ORIGINAL knows Vivify, '
              'SickLick, TailWind and Ahhh. ECHO knows their new twins.', choice=True),
     'yes': [{'give_monster': {'enemy': original, 'to': 'party'}},
             {'give_monster': {'enemy': echo, 'to': 'party'}},
             {'say': B('Vivify brings back half HP and can fail. SickLick drops DEF. '
                       'TailWind guards only its caster. The twins must do the same.')}],
     'no': [{'say': B('Come back any time.')}]}], 'echo_gift')
npc(hall_id, '0', 7, 6, 0x10, [
    {'ask': B('I am the SPARRING SLIME. Three of us, tough and gentle. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [sparring, sparring, sparring]}},
             {'say': B('Again any time!')}],
     'no': [{'say': B('Another time.')}]}], 'echo_spar', monster=SLIME)

# ---- the way in: the ECHO GUIDE in Cities_FOUNT ------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the ECHO GUIDE. To the ECHO HALL, where '
                                                 'new skills answer as their base?',
                                                 choice=True),
                                       'yes': [go_to(hall_mid, 4, 5)],
                                       'no': [{'say': B('Another time.')}]}], 'echo_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'twins', {k: v for k, v in E.items()},
      'rows', original, echo, sparring)
