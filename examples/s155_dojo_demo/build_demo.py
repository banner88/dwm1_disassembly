"""S155 demo (the new custom skills): THE WOLF DOJO and THE WOLF DEN on the user's project.

The S155 built-in custom skills — LoneWolf, Punish, Finish, Rupture, Blunt (battle; was Rust until S155 r3) and
Repel (field) — given to the player on two gift monsters, and used against the player by
three sparring bosses with a high INT (the AI's rule chains run from INT 21 up; a low-INT
enemy picks at random).

  * THE WOLF DOJO (a new room, three screens west to east):
      screen 0: the DOJO GUIDE (what is where; YES = back to the city), the GIFT MASTER
        (YES = a gift monster: LONEWOLF with LoneWolf / Punish / Finish / Rupture, or —
        the second question — BLUNTER with Blunt / Repel / PoisonHit / Surge), the FARM
        KEEPER (a farm service: leave monsters there to fight in a party of two or alone
        for LoneWolf's x2 / x4).
      screen 1: three sparring bosses — the LONE WOLF (alone: LoneWolf x4, Finish when
        the party is hurt), the VIPER + the BURSTER (the viper poisons, the burster's
        Rupture bursts the poison for x3), the BLUNT KNIGHT (Blunt on the strongest
        monster, Upper on itself — a buff for Punish).
      screen 2: the DEN GUIDE (YES = to the WOLF DEN).
  * THE WOLF DEN (a new room): random battles on every step (gate 1's first-floor
    monsters); the DEN KEEPER explains and takes the party back to the dojo. Cast Repel
    here (field menu, SKILL): no more battles until the party leaves the room; come back
    and they return. In a gate Repel lasts one floor.

Way in: the DOJO GUIDE in Cities_FOUNT at (3, 4) (YES = to the dojo).

    python3 examples/s155_dojo_demo/build_demo.py <base project.json> <out project.json>

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
REPEL, LONEWOLF, PUNISH, FINISH, RUPTURE, BLUNT = 222, 223, 235, 236, 237, 238
POISONHIT, UPPER, SURGE = 103, 30, 129


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


# ---- the monsters: two gifts, four sparring enemies -----------------------------------
gift_wolf = d.add_enemy(copy_eid=2, name='Gift LoneWolf', species=141, level=20, hp=180,
                        mp=120, atk=90, **{'def': 60}, agl=60, int=60, joinability=7,
                        skills=[LONEWOLF, PUNISH, FINISH, RUPTURE])
gift_blunt = d.add_enemy(copy_eid=2, name='Gift Blunter', species=196, level=20, hp=200,
                        mp=120, atk=80, **{'def': 70}, agl=40, int=60, joinability=7,
                        skills=[BLUNT, REPEL, POISONHIT, SURGE])
boss_wolf = d.add_enemy(copy_eid=2, name='Lone wolf', species=137, level=15, hp=320, mp=200,
                        atk=55, **{'def': 40}, agl=45, int=200, joinability=7,
                        ai_weights=[250, 50, 0, 100], skills=[LONEWOLF, FINISH])
boss_viper = d.add_enemy(copy_eid=2, name='Viper', species=39, level=12, hp=200, mp=200,
                         atk=40, **{'def': 30}, agl=50, int=200, joinability=7,
                         ai_weights=[250, 50, 0, 100], skills=[POISONHIT])
boss_burst = d.add_enemy(copy_eid=2, name='Burster', species=198, level=12, hp=220, mp=200,
                         atk=45, **{'def': 40}, agl=30, int=200, joinability=7,
                         ai_weights=[250, 50, 0, 100], skills=[RUPTURE])
boss_blunt = d.add_enemy(copy_eid=2, name='Blunt knight', species=149, level=15, hp=320,
                        mp=200, atk=50, **{'def': 50}, agl=35, int=200, joinability=7,
                        ai_weights=[50, 0, 250, 0], skills=[BLUNT, UPPER])

# ---- THE WOLF DOJO: three screens in a row ----------------------------------------------
dojo_id = d.new_room('WOLF DOJO', 0, r, gate_theme=4)
dojo = d.room(dojo_id)
lay0 = dojo['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lays = [lay0]
for k in (1, 2):
    lid = d.unique_layout_id(f'{dojo_id}_s{k}')
    d.add_layout(lid, tiles=[list(row) for row in d.layout(lay0)['tiles']],
                 attr=[list(row) for row in d.layout(lay0)['attr']])
    d.add_screen(d.room(dojo_id), k, {'id': lid})
    lays.append(lid)
for k, lid in enumerate(lays):
    walls(lid)
    if k < 2:
        paint(lid, 9, 4, FLOOR)                        # the way east
    if k > 0:
        paint(lid, 0, 4, FLOOR)                        # the way west
dojo = d.room(dojo_id)
entry_script(dojo, dojo_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

# screen 0: the DOJO GUIDE (row 3), the GIFT MASTER (row 5), the FARM KEEPER (row 6)
npc(dojo_id, '0', 2, 3, 0x0B, [{'ask': B(
    'THE WOLF DOJO. New skills: LoneWolf, Punish, Finish, Rupture, Blunt and Repel. The '
    'GIFT MASTER gives monsters that know them, the FARM KEEPER holds the rest of your '
    'party (fight alone for LoneWolf). East: three sparring bosses, then the way to the '
    'WOLF DEN. Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Train well.')}]}], 'dojo_guide')
npc(dojo_id, '0', 5, 5, 0x1D, [
    {'ask': B('I am the GIFT MASTER. Take LONEWOLF? It knows LoneWolf, Punish, Finish '
              'and Rupture.', choice=True),
     'yes': [{'give_monster': {'enemy': gift_wolf, 'to': 'party'}},
             {'say': B('LoneWolf hits x2 in a party of two, x4 alone. Punish hits harder '
                       'per buff on the foe. Finish hits harder the more HP the foe has '
                       'lost. Rupture bursts a foe\'s ailments for x3.')}],
     'no': [{'ask': B('Then take BLUNTER? It knows Blunt, Repel, PoisonHit and Surge.',
                      choice=True),
             'yes': [{'give_monster': {'enemy': gift_blunt, 'to': 'party'}},
                     {'say': B('Blunt lowers a foe\'s attack. Repel (field menu) keeps '
                               'monsters away for one gate floor or until you leave a '
                               'room. PoisonHit sets up a Rupture; Surge undoes a Blunt.')}],
             'no': [{'say': B('Come back any time.')}]}]}], 'gift_master')
rm = d.room(dojo_id)
d.add_npc(rm, '0', 0, 7, 6, 0x14, 'down')
d.make_service_npc(rm, '0', 0, len(d.npc_entries(rm, '0', 0)) - 1, 'farm')


def spar(x, y, sprite, monster, intro, enemies, name):
    return npc(dojo_id, '1', x, y, sprite, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': enemies}},
                 {'say': B('A good fight!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=monster)


# screen 1: the sparring bosses (rows 2, 4, 6)
spar(3, 2, 0xF0, 137, 'I am the LONE WOLF. Alone I hit four times as hard, and I finish '
     'the hurt.', [boss_wolf], 'spar_lonewolf')
spar(6, 4, 0xF0, 39, 'We are the VIPER and the BURSTER. I poison, my friend bursts the '
     'poison with Rupture.', [boss_viper, boss_burst], 'spar_rupture')
spar(3, 6, 0xF0, 149, 'I am the BLUNT KNIGHT. I blunt your strongest monster and raise my '
     'guard (a buff your Punish loves).', [boss_blunt], 'spar_blunt')

# ---- THE WOLF DEN: random battles; Repel's room ----------------------------------------
den_id = d.new_room('WOLF DEN', 0, r, gate_theme=9)
den = d.room(den_id)
dlay = den['screens']['0']['layout']['id']
walls(dlay)
entry_script(den, den_id)
dojo_mid = int(d.room(dojo_id)['mapID'], 16)
den_mid = int(d.room(den_id)['mapID'], 16)
npc(den_id, '0', 2, 2, 0x1F, [{'ask': B(
    'THE WOLF DEN. Monsters attack on every few steps here. Cast Repel from the field '
    'menu (SKILL) and they stay away until you leave this room. Back to the dojo?',
    choice=True), 'yes': [go_to(dojo_mid, 4, 4)], 'no': [{'say': B('Walk around!')}]}],
    'den_keeper')
d.set_room_battles(den_id, 'gate', gate_id=1, floor=0)

# screen 2 of the dojo: the DEN GUIDE (row 4)
npc(dojo_id, '2', 5, 4, 0x0B, [{'ask': B('I am the DEN GUIDE. To the WOLF DEN, where '
                                          'monsters attack? (Try Repel there.)',
                                          choice=True),
                                 'yes': [go_to(den_mid, 5, 5)],
                                 'no': [{'say': B('Another time.')}]}], 'den_guide')

# ---- the way in: the DOJO GUIDE in Cities_FOUNT ------------------------------------------
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the DOJO GUIDE. To the WOLF DOJO, '
                                                 'where the new skills are?', choice=True),
                                       'yes': [go_to(dojo_mid, 4, 4)],
                                       'no': [{'say': B('Another time.')}]}], 'dojo_way_in')

d.save(dst)
print('dojo', dojo_id, hex(dojo_mid), 'den', den_id, hex(den_mid),
      'enemies', gift_wolf, gift_blunt, boss_wolf, boss_viper, boss_burst, boss_blunt)
