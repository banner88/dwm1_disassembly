"""S164 demo (the ROADMAP E13 notes "combinations for new skills" + "the clone census", and the
original enemy-AI bugs as project switches): THE CONFLUX HALL on the user's project.

E13 note — a custom / new skill that "evolves from" two or more skills. Since S75 the level up
never taught one (bank $06 LearnFence06 closed code 2 — "all of 2-5 prerequisites known" — for
every custom id); S164 opened it: such a skill is a COMBINATION, learned beside its
prerequisites like FireSlash (ChargeUP + Blazemore).

  new skills  base          id    learn
  Fusion      Firebal 3     239   level 10, from Blaze AND Bang (both kept)

The original enemy AI's bugs as switches (gamedata.ai_fixes, editor2/core/ai_fixes.py): THIS
demo switches all five ON — every enemy of the demo ROM uses the fixed rules (the group-skill
+20 only against two or more foes, status skills counting each foe once, family cuts and
DeMagic looking at all three foes, real averages of ATK / DEF).

ROADMAP E14: the custom skills' names past bank $41's region come from the text banks (no
monster names displaced); Finish ($EC) evolves from Firebal at level 10 here so its name shows
in a level-up line (tools/walk_names.py).

  * THE CONFLUX HALL (a new room, two screens west to east, gate look 7):
      screen 0: the CONFLUX GUIDE (what is where; YES = back to the city), the FUSION KEEPER
        (YES = FUSER, a Healer, level 9, knows Blaze and Bang: its next level up teaches
        FUSION beside them), the TRAINING DUMMY (weak, a lot of EXP).
      screen 1: the TACTICIAN (Bang, Sleep, DeMagic, TwinSlash; the cleverest AI) and the
        WARDEN (DrakSlash, Upper, Increase, Surround) — fight them with ONE monster standing:
        under the fixed rules they cast Bang far less at a lone foe; the BASE KEEPER (YES =
        MEDIC, a Healer whose four skills are NEW skills on bases a new skill could not use
        before S164: NHeal on Heal, NTwin on TwinSlash, NCover on Cover, NHighJ on HighJump —
        the clone census on whole battles, extracted/skill_clone_census.json).

Way in: the CONFLUX GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s164_conflux_demo/build_demo.py <base project.json> <out project.json>

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


# ---- E13 note: a combination ---------------------------------------------------------------
BLAZE, BANG, FIREBAL = 0, 6, 3
FUSION = d.new_custom_skill(FIREBAL, 'Fusion')
d.set_skill_description(FUSION, ['Conflux test, from', 'Blaze AND Bang,', 'both kept, lv 10.'])
ZERO = {'hp': 0, 'mp': 0, 'atk': 0, 'def': 0, 'agl': 0, 'int': 0}
d.set_skill_learn(FUSION, {'level': 10, **ZERO, 'prereqs': [BLAZE, BANG]})

# ROADMAP E14 (S164): the custom skills' names past bank $41's 94-B region are served from the
# text banks. Finish (a built-in, $EC — its name is one of them) is made learnable here so
# tools/walk_names.py sees the name in a level-up line: it evolves from Firebal at level 10.
FINISH = 0xEC
d.set_skill_learn(FINISH, {'level': 10, **ZERO, 'prereqs': [FIREBAL]})

HEALER, BABBLE = 9, 6
fuser = d.add_enemy(copy_eid=2, name='Fuser', species=HEALER, level=9, hp=120, mp=99,
                    atk=40, **{'def': 40}, agl=40, int=99, joinability=7, skills=[BLAZE, BANG])
dummy = d.add_enemy(copy_eid=2, name='Dummy', species=BABBLE, level=1, hp=5, mp=0, atk=1,
                    **{'def': 1}, agl=1, int=1, exp=2000, joinability=7, skills=[])

# ---- the original AI's bugs: every switch ON for this demo ----------------------------------
for key in ('aoe_count', 'class_count', 'family_cut', 'demagic_scan', 'averages'):
    d.set_ai_fix(key, True)
EYEBALL, SWORDGON = 135, 27
BANG, SLEEP, DEMAGIC, TWINSLASH = 6, 21, 128, 59
DRAKSLASH, UPPER, INCREASE, SURROUND = 73, 30, 31, 24


def tactic(name, sp, skills):
    return d.add_enemy(copy_eid=2, name=name, species=sp, level=20, hp=400, mp=250, atk=120,
                       **{'def': 60}, agl=40, int=200, joinability=7, ai_weights=[30, 250, 30, 0],
                       skills=skills)


tactician = tactic('Tactician', EYEBALL, [BANG, SLEEP, DEMAGIC, TWINSLASH])
warden = tactic('Warden', SWORDGON, [DRAKSLASH, UPPER, INCREASE, SURROUND])

# ---- new skills on bases the S164 census allows (refused until S163) ------------------------
HEAL, COVER, HIGHJUMP = 43, 136, 66
NB = {}
for base, nm in ((HEAL, 'NHeal'), (TWINSLASH, 'NTwin'), (COVER, 'NCover'), (HIGHJUMP, 'NHighJ')):
    NB[base] = d.new_custom_skill(base, nm)
    d.set_skill_description(NB[base], ['Conflux test, a', 'new skill on a', 'newly allowed base'])
    d.set_skill_learn(NB[base], {'learnable': False})
medic = d.add_enemy(copy_eid=2, name='Medic', species=HEALER, level=20, hp=200, mp=200, atk=80,
                    **{'def': 60}, agl=60, int=120, joinability=7,
                    skills=[NB[HEAL], NB[TWINSLASH], NB[COVER], NB[HIGHJUMP]])

# ---- THE CONFLUX HALL: two screens in a row ------------------------------------------------
hall_id = d.new_room('CONFLUX HALL', 0, r, gate_theme=7)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lay1 = d.unique_layout_id(f'{hall_id}_s1')
d.add_layout(lay1, tiles=[list(row) for row in d.layout(lay0)['tiles']],
             attr=[list(row) for row in d.layout(lay0)['attr']])
d.add_screen(d.room(hall_id), 1, {'id': lay1})
walls(lay1)
paint(lay0, 9, 4, FLOOR)                               # the way east
paint(lay1, 0, 4, FLOOR)                               # the way west
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 3, 0x0B, [{'ask': B(
    'THE CONFLUX HALL. A new skill can now evolve from TWO skills: a monster that knows both '
    'learns it beside them, like FireSlash. Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Two streams, one river.')}]}], 'conflux_guide')
npc(hall_id, '0', 5, 4, 0x1D, [
    {'ask': B('I am the FUSION KEEPER. Take FUSER? It knows Blaze and Bang. At level 10 it '
              'learns FUSION, a new skill from both, and keeps them.', choice=True),
     'yes': [{'give_monster': {'enemy': fuser, 'to': 'party'}},
             {'say': B('Beat the TRAINING DUMMY for its level up.')}],
     'no': [{'say': B('Come back any time.')}]}], 'fusion_keeper')
npc(hall_id, '0', 8, 5, 0xF0, [
    {'ask': B('I am the TRAINING DUMMY. Beat me for EXP. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [dummy]}}, {'say': B('Oof.')}],
     'no': [{'say': B('Another time.')}]}], 'conflux_dummy', monster=BABBLE)

npc(hall_id, '1', 3, 3, 0xF0, [
    {'ask': B('I am the TACTICIAN: Bang, Sleep, DeMagic, TwinSlash. In this hall the enemy AI '
              'uses the FIXED rules: against ONE monster I seldom waste Bang. Fight?',
              choice=True),
     'yes': [{'battle': {'enemies': [tactician]}}, {'say': B('Well fought.')}],
     'no': [{'say': B('Another time.')}]}], 'conflux_tactician', monster=EYEBALL)
npc(hall_id, '1', 6, 5, 0xF0, [
    {'ask': B('I am the WARDEN: DrakSlash, Upper, Increase, Surround. My DrakSlash looks at '
              'every foe for a dragon, not just the first. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [warden]}}, {'say': B('Well fought.')}],
     'no': [{'say': B('Another time.')}]}], 'conflux_warden', monster=SWORDGON)

npc(hall_id, '1', 7, 2, 0x1D, [
    {'ask': B('I am the BASE KEEPER. Take MEDIC? Its four skills are NEW skills on Heal, '
              'TwinSlash, Cover and HighJump - bases a new skill could not use before.',
              choice=True),
     'yes': [{'give_monster': {'enemy': medic, 'to': 'party'}},
             {'say': B('Each should act exactly like the skill it is built on.')}],
     'no': [{'say': B('Come back any time.')}]}], 'conflux_base_keeper')

# ---- the way in: the CONFLUX GUIDE in Cities_FOUNT -------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the CONFLUX GUIDE. To the CONFLUX HALL, '
                                                 'where new skills evolve from two?',
                                                 choice=True),
                                       'yes': [go_to(hall_mid, 4, 5)],
                                       'no': [{'say': B('Another time.')}]}], 'conflux_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'fusion', FUSION, 'rows', fuser, dummy, tactician, warden)
