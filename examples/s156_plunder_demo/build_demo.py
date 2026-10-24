"""S156 demo (Plunder, the buff thief): THE ROGUE HALL on the user's project.

Plunder (skill 234, S156) steals ONE buff of a foe and puts it on the user, as if
the user had cast it this round (BATTLE_SKILL_SYSTEM §13.11). It is given to the
player on a gift monster and used against the player by a sparring boss with a high
INT (the AI's rule chains run from INT 21 up; a low-INT enemy picks at random).

  * THE ROGUE HALL (a new room, two screens west to east):
      screen 0: the HALL GUIDE (what is where; YES = back to the city), the GIFT
        MASTER (YES = PLUNDERER: Plunder, Barrier, Upper, ChargeUP; the second
        question = SHIELDER: Barrier, Increase, SpeedUp, TailWind — buffs for the
        BANDIT to steal).
      screen 1: two sparring bosses — the BUFF KNIGHT (buffs itself: Upper,
        Barrier, ChargeUP, TailWind — Plunder them away) and the BANDIT (Plunder:
        it steals your monsters' buffs; with nothing to steal it just attacks).

Way in: the HALL GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s156_plunder_demo/build_demo.py <base project.json> <out project.json>

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
PLUNDER = 234
UPPER, INCREASE, SPEEDUP, BARRIER, CHARGEUP, TAILWIND = 30, 31, 35, 36, 65, 138


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


# ---- the monsters: two gifts, two sparring enemies ----------------------------------
gift_thief = d.add_enemy(copy_eid=2, name='Gift Plunderer', species=120, level=20, hp=200,
                         mp=150, atk=80, **{'def': 60}, agl=70, int=60, joinability=7,
                         skills=[PLUNDER, BARRIER, UPPER, CHARGEUP])
gift_shield = d.add_enemy(copy_eid=2, name='Gift Shielder', species=160, level=20, hp=220,
                          mp=150, atk=60, **{'def': 80}, agl=50, int=60, joinability=7,
                          skills=[BARRIER, INCREASE, SPEEDUP, TAILWIND])
boss_knight = d.add_enemy(copy_eid=2, name='Buff knight', species=149, level=15, hp=320,
                          mp=250, atk=45, **{'def': 50}, agl=40, int=200, joinability=7,
                          ai_weights=[50, 0, 250, 0],
                          skills=[UPPER, BARRIER, CHARGEUP, TAILWIND])
boss_bandit = d.add_enemy(copy_eid=2, name='Bandit', species=120, level=15, hp=320,
                          mp=250, atk=45, **{'def': 40}, agl=60, int=200, joinability=7,
                          ai_weights=[100, 0, 250, 100], skills=[PLUNDER])

# ---- THE ROGUE HALL: two screens in a row -------------------------------------------
hall_id = d.new_room('ROGUE HALL', 0, r, gate_theme=4)
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
    paint(l_, 9 if k == 0 else 0, 4, FLOOR)            # the way between the screens
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

# screen 0: the HALL GUIDE (row 3), the GIFT MASTER (row 5)
npc(hall_id, '0', 2, 3, 0x0B, [{'ask': B(
    'THE ROGUE HALL. A new skill: Plunder steals one buff of a foe and puts it on your '
    'monster. The GIFT MASTER gives monsters, the two sparring bosses are east. Back to the '
    'city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Steal well.')}]}], 'hall_guide')
npc(hall_id, '0', 5, 5, 0x1D, [
    {'ask': B('I am the GIFT MASTER. Take PLUNDERER? It knows Plunder, Barrier, Upper and '
              'ChargeUP.', choice=True),
     'yes': [{'give_monster': {'enemy': gift_thief, 'to': 'party'}},
             {'say': B('Plunder takes one buff of a foe at random and gives it to the '
                       'user. Without a buff on the foe nothing happens.')}],
     'no': [{'ask': B('Then take SHIELDER? It knows Barrier, Increase, SpeedUp and '
                      'TailWind.', choice=True),
             'yes': [{'give_monster': {'enemy': gift_shield, 'to': 'party'}},
                     {'say': B('Buff it up, then fight the BANDIT: it steals buffs.')}],
             'no': [{'say': B('Come back any time.')}]}]}], 'gift_master_plunder')


def spar(x, y, sprite, monster, intro, enemies, name):
    return npc(hall_id, '1', x, y, sprite, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': enemies}},
                 {'say': B('A good fight!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=monster)


# screen 1: the sparring bosses (rows 2, 5)
spar(3, 2, 0xF0, 149, 'I am the BUFF KNIGHT. I raise my guard, my speed and my power. '
     'Plunder them if you can.', [boss_knight], 'spar_buffknight')
spar(6, 5, 0xF0, 120, 'I am the BANDIT. Your buffs are mine. With none, I just hit you.',
     [boss_bandit], 'spar_bandit')

# ---- the way in: the HALL GUIDE in Cities_FOUNT --------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the HALL GUIDE. To the ROGUE HALL, '
                                                 'where Plunder is?', choice=True),
                                       'yes': [go_to(hall_mid, 4, 4)],
                                       'no': [{'say': B('Another time.')}]}], 'hall_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'enemies', gift_thief, gift_shield, boss_knight,
      boss_bandit)
