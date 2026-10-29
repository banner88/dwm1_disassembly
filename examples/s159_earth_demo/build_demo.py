"""S159 demo (EARTH, the 27th resistance; ROADMAP E16): THE FAULT HALL on the user's project.

Resistance 26 — "Unused" (0 in every species) until S159 — is EARTH: species info +$29 ->
the monster record +$82 (bits 0-1; the memorial's tag in bits 3-7) -> battle position 27
(bank $51 SaveBtlS_4404, patched), read by every skill whose element is Earth
(BATTLE_SKILL_SYSTEM §15.3 "Earth (S159)"). This demo gives Earth to:

  * Quake (230): element Earth (the built-in hits all foes, flyers dodge);
  * ROCKFALL (a NEW skill, the first free id 239+): Bang's effect, element Earth;
  * Boom (7): moved from Explosion to Earth (the guide says so);
  * species: Golem (196) Earth 3 (immune), MudDoll (195) Earth 1, StoneMan (197) Earth 2
    (the gift — a monster made from the row gets its species' Earth);
    MadGopher (60) stays 0.

  * THE FAULT HALL (a new room, three screens west to east, gate look 9):
      screen 0: the FAULT GUIDE (what is where; YES = back to the city), the GIFT
        MASON (YES = TREMORER, a StoneMan: Quake, Rockfall, Boom, Blaze).
      screen 1: three sparring monsters — the STONE GOLEM (Earth 3: Quake / Rockfall /
        Boom do nothing), the MUD DOLL (Earth 1: a little less), the GOPHER (Earth 0:
        full damage);
      screen 2: the SEISMIC SAGE (a BombCrag with Boom + Rockfall, INT 200: the enemy AI
        leaves a party that is all Earth 3 alone) and the BLAST IMP (Bang, Explosion — the
        game's own element, for comparison).

Way in: the FAULT GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s159_earth_demo/build_demo.py <base project.json> <out project.json>

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


# ---- Earth: the skills and the species ------------------------------------------------
QUAKE, BOOM, BLAZE, BANG = 230, 7, 0, 6
GOLEM, MUDDOLL, STONEMAN, GOPHER, BOMBCRAG = 196, 195, 197, 60, 198
EARTH = 26
rockfall = d.new_custom_skill(BANG, 'Rockfall')
d.set_skill_element(rockfall, EARTH)
d.set_skill_description(rockfall, ['Rocks rain on all', 'foes. EARTH tests', 'it.'])
d.set_skill_element(QUAKE, EARTH)
d.set_skill_element(BOOM, EARTH)
d.set_species_resists({GOLEM: {'Earth': 3}, MUDDOLL: {'Earth': 1}, STONEMAN: {'Earth': 2}})

gift = d.add_enemy(copy_eid=2, name='Gift Tremorer', species=STONEMAN, level=25, hp=300,
                   mp=250, atk=90, **{'def': 80}, agl=60, int=80, joinability=7,
                   skills=[QUAKE, rockfall, BOOM, BLAZE])
golem = d.add_enemy(copy_eid=2, name='Stone golem', species=GOLEM, level=15, hp=400, mp=0,
                    atk=40, **{'def': 60}, agl=30, int=20, joinability=7, skills=[])
doll = d.add_enemy(copy_eid=2, name='Mud doll', species=MUDDOLL, level=15, hp=400, mp=0,
                   atk=40, **{'def': 60}, agl=30, int=20, joinability=7, skills=[])
gopher = d.add_enemy(copy_eid=2, name='Gopher', species=GOPHER, level=15, hp=400, mp=0,
                     atk=40, **{'def': 60}, agl=30, int=20, joinability=7, skills=[])
sage = d.add_enemy(copy_eid=2, name='Seismic sage', species=BOMBCRAG, level=15, hp=400,
                   mp=250, atk=40, **{'def': 50}, agl=40, int=200, joinability=7,
                   ai_weights=[30, 250, 30, 0], skills=[BOOM, rockfall])
imp = d.add_enemy(copy_eid=2, name='Blast imp', species=BOMBCRAG, level=15, hp=400,
                  mp=250, atk=40, **{'def': 50}, agl=40, int=200, joinability=7,
                  ai_weights=[30, 250, 30, 0], skills=[BANG])

# ---- THE FAULT HALL: three screens in a row (at most 3 NPCs a screen, one a row) -------
hall_id = d.new_room('FAULT HALL', 0, r, gate_theme=9)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lays = [lay0]
for k in (1, 2):
    lid = d.unique_layout_id(f'{hall_id}_s{k}')
    d.add_layout(lid, tiles=[list(row) for row in d.layout(lay0)['tiles']],
                 attr=[list(row) for row in d.layout(lay0)['attr']])
    d.add_screen(d.room(hall_id), k, {'id': lid})
    lays.append(lid)
for k, l_ in enumerate(lays):
    walls(l_)
    if k < 2:
        paint(l_, 9, 4, FLOOR)                         # the way east
    if k > 0:
        paint(l_, 0, 4, FLOOR)                         # the way west
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 3, 0x0B, [{'ask': B(
    'THE FAULT HALL. A new resistance: EARTH. Quake, the new skill Rockfall and (here) Boom '
    'test it. The GIFT MASON gives a monster with them; the sparring monsters are east. '
    'Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Shake the ground.')}]}], 'fault_guide')
npc(hall_id, '0', 5, 5, 0x1D, [
    {'ask': B('I am the GIFT MASON. Take TREMORER? It knows Quake, Rockfall, Boom and '
              'Blaze.', choice=True),
     'yes': [{'give_monster': {'enemy': gift, 'to': 'party'}},
             {'say': B('The GOLEM is immune to EARTH, the MUD DOLL resists a little, the '
                       'GOPHER not at all. Blaze is fire: try it on the GOLEM too.')}],
     'no': [{'say': B('Come back any time.')}]}], 'gift_mason')


def spar(x, y, sprite, monster, intro, enemies, name):
    return npc(hall_id, '1', x, y, sprite, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': enemies}},
                 {'say': B('A good fight!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=monster)


spar(2, 2, 0xF0, GOLEM, 'I am the STONE GOLEM. EARTH cannot touch me.', [golem], 'spar_golem')
spar(5, 4, 0xF0, MUDDOLL, 'I am the MUD DOLL. EARTH hurts me a little less.', [doll],
     'spar_doll')
spar(8, 5, 0xF0, GOPHER, 'I am the GOPHER. EARTH hurts me fully.', [gopher], 'spar_gopher')


def spar2(x, y, sprite, monster, intro, enemies, name):
    return npc(hall_id, '2', x, y, sprite, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': enemies}},
                 {'say': B('A good fight!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=monster)


spar2(3, 2, 0xF0, BOMBCRAG, 'I am the SEISMIC SAGE. Boom and Rockfall: EARTH. A '
      'monster immune to EARTH I leave alone.', [sage], 'spar_sage')
spar2(6, 5, 0xF0, BOMBCRAG, 'I am the BLAST IMP. I cast Bang: EXPLOSION, the game\'s own, '
      'for comparison.', [imp], 'spar_imp')

# ---- the way in: the FAULT GUIDE in Cities_FOUNT -----------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the FAULT GUIDE. To the FAULT HALL, '
                                                 'where EARTH is?', choice=True),
                                       'yes': [go_to(hall_mid, 4, 4)],
                                       'no': [{'say': B('Another time.')}]}], 'hall_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'rockfall', rockfall, 'enemies', gift, golem, doll,
      gopher, sage, imp)
