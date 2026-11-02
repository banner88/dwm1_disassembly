"""S162 demo (ROADMAP E17 note "Project enemy rows"): THE VOLLEY HALL on the user's project.

The original game has a rule for enemy GROUP spells and breaths (the 77 skills of bank $53
GroupDupSkillList_4ee4: Firebal, Bang, the breaths, the dances …): when another enemy acted
before it in the round, a "holding" enemy's group spell becomes a plain Attack. The game
gives that rule to 181 of its 486 rows (its early wild rows and random battles 0-4; never a
boss or an arena fighter) through a one-byte-a-row table — and a PROJECT enemy row (EID 519
and up) read past the end of that table into code, so whether it held back was an accident
(3,259 of 3,321 project EIDs read non-zero). Since S162 every project row has its own
setting, "holds back group spells" (progression.enemies[].holds_group_spells; a copy of an
original row keeps that row's), read by bank $53 DupConvFlag53 through bank $6B entry 2.

  * THE VOLLEY HALL (a new room, two screens, gate look 9):
      screen 0: the VOLLEY GUIDE (what this is; YES = back to the city), the HOLDING PAIR
        (two Bang imps that hold back: about one Bang a round, the second one attacks), the
        CASTING PAIR (the same two imps, not holding back: two Bangs in many rounds).
      screen 1: the FAR PAIR — the same holding imps as rows 690+ of the project, which sit
        in a BATTLE BANK ($80+; the project gets ~690 spare rows for it), so the far rows'
        setting is read past bank $6B's own rows too; the FAR CASTERS — their casting twins.

Way in: the VOLLEY GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s162_volley_demo/build_demo.py <base project.json> <out project.json>

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
SPARE_ROWS = 690                     # pushes the FAR rows past bank $6B (battles.plan)


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


# ---- the enemy rows ---------------------------------------------------------------------------
BANG, EYEBALL, DRACKY = 6, 135, 78


def imp(name, holds):
    # INT 100: the AI's middle mode ($DD0B = 1 — the top mode, INT 181+, always casts)
    # HP / DEF high: the fight lasts rounds enough to count the Bangs (a strong party too)
    return d.add_enemy(copy_eid=2, name=name, species=EYEBALL, level=15, hp=900, mp=250,
                       atk=30, **{'def': 250}, agl=40, int=100, joinability=7,
                       ai_weights=[250, 30, 30, 0], skills=[BANG],
                       **({'holds_group_spells': True} if holds else {}))


holder = imp('Holding imp', True)
caster = imp('Casting imp', False)
for k in range(SPARE_ROWS):
    d.add_enemy(copy_eid=2, name=f'Volley spare {k}')
far_holder = imp('Far holder', True)
far_caster = imp('Far caster', False)

# ---- THE VOLLEY HALL: two screens in a row ----------------------------------------------------
hall_id = d.new_room('VOLLEY HALL', 0, r, gate_theme=9)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lid = d.unique_layout_id(f'{hall_id}_s1')
d.add_layout(lid, tiles=[list(row) for row in d.layout(lay0)['tiles']],
             attr=[list(row) for row in d.layout(lay0)['attr']])
d.add_screen(d.room(hall_id), 1, {'id': lid})
for k, l_ in enumerate((lay0, lid)):
    walls(l_)
    paint(l_, 9 if k == 0 else 0, 4, FLOOR)            # the way between the two screens
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 3, 0x0B, [{'ask': B(
    'THE VOLLEY HALL. Two enemies, both with Bang. A HOLDING enemy\'s group spell becomes '
    'a plain attack when the other enemy already acted that round. A CASTING enemy always '
    'casts. Have your monsters DEF for a few rounds and count the Bangs. Back to the city?',
    choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Count the Bangs!')}]}], 'volley_guide')


def pair(key, x, y, intro, row, name):
    return npc(hall_id, key, x, y, 0xF0, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': [row, row]}},
                 {'say': B('Well fought!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=EYEBALL)


pair('0', 5, 5, 'We are the HOLDING PAIR. We hold back: one Bang a round, the other '
     'of us attacks.', holder, 'volley_holding')
pair('0', 7, 2, 'We are the CASTING PAIR. We never hold back: two Bangs in a round.',
     caster, 'volley_casting')
pair('1', 3, 3, 'We are the FAR PAIR: holding imps kept in a far bank of the ROM. We hold '
     'back too.', far_holder, 'volley_far_holding')
pair('1', 6, 5, 'We are the FAR CASTERS, in the far bank too. We never hold back.',
     far_caster, 'volley_far_casting')

# ---- the way in: the VOLLEY GUIDE in Cities_FOUNT --------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the VOLLEY GUIDE. To the VOLLEY HALL, '
                                                 'where enemies hold back group spells?',
                                                 choice=True),
                                       'yes': [go_to(hall_mid, 4, 4)],
                                       'no': [{'say': B('Another time.')}]}], 'volley_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'rows', holder, caster, far_holder, far_caster)
