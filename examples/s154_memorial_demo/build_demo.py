"""S154 demo (the memorial): THE MEMORIAL HALL and THE MEMORIAL CRYPT on the user's project.

A memorial statue shows a monster that WON a boss battle, an arena class or Starry
Night with the player and has since LEFT (bred away, released, traded) — every statue
of a room a different one, picked at random each time the player comes in; a statue
with nobody left to show keeps its empty plinth. Examining a statue: "In memory of
SLIB, a level 23 DrakSlime." (or "A blank statue, quiet and cold.").

  * THE MEMORIAL HALL (a new room): three statues on the back row (S154 r2: each a
    pedestal with the monster standing on it, grey on the floor behind); the HALL GUIDE explains; the MASON (YES) turns a flag ON and the hall's
    second room state has FIVE statues (the user: "Maybe I want to have more statues
    as game goes on so I change game state"); the CHAMPION is a boss to beat (a
    conversation battle = a boss battle: the party that wins it is remembered). East
    (screen 1): the FARM KEEPER (a farm service) to put monsters in the farm and part
    with them, the BREEDER (a breeding service: breed a winner away), the EXIT GUIDE
    back to the city.
  * THE MEMORIAL CRYPT (a new room) is served on gate 2's second floor (once a dive):
    two statues, a sign, the stairs on down.

Way in: the MEMORIAL GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s154_memorial_demo/build_demo.py <base project.json> <out project.json>

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
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]


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


def talker(room_id, x, y, sprite, steps, name, state=0):
    rm = d.room(room_id)
    d.add_npc(rm, '0', state, x, y, sprite, 'down')
    k = len(d.npc_entries(rm, '0', state)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', state, k, script=sid)
    return sid


def statue(room_id, state, x, y):
    """add_statue (S154 r2: its pedestal on (x, y), the monster on (x, y - 1), the statue
    palette set up by the editor: the floor's colours + grey); a theme room's sheet is
    all vocabulary (maze tiles the room never draws) — release it first, as the editor
    offers (VocabReleaseWouldHelp)."""
    from editor2.core.document import VocabReleaseWouldHelp
    try:
        return d.add_statue(d.room(room_id), '0', state, x, y)
    except VocabReleaseWouldHelp:
        rm = d.room(room_id)
        d.set_released(d._room_sheet(rm, '0', state, x, y)[0], True)
        return d.add_statue(d.room(room_id), '0', state, x, y)


# ---- THE MEMORIAL HALL (two screens, at most 3 NPCs a screen, one a row — S151 r3) ----
hall_id = d.new_room('MEMORIAL HALL', 0, r, gate_theme=6)
hall = d.room(hall_id)
lay = hall['screens']['0']['layout']['id']
walls(lay)
FLOOR = d.layout(lay)['tiles'][8][8:10] + d.layout(lay)['tiles'][9][8:10]
paint(lay, 9, 4, FLOOR)                                # the way to the east screen
lay1 = d.unique_layout_id(f'{hall_id}_s1')
d.add_layout(lay1, tiles=[list(row) for row in d.layout(lay)['tiles']],
             attr=[list(row) for row in d.layout(lay)['attr']])
d.add_screen(hall, 1, {'id': lay1})
walls(lay1)
paint(lay1, 0, 4, FLOOR)
hall = d.room(hall_id)
entry_script(hall, hall_id)
for x in (3, 5, 7):                                    # state 0: three statues (pedestal
    statue(hall_id, 0, x, 2)                           # row 2, the monsters on row 1)
# state 1 (the MASON's flag): five statues — the same three + two more
d.custom.setdefault('flags', []).append({'name': 'memorial_hall_grown'})
d.add_state(d.room(hall_id), '0', copy_from=0, own_layout=True)
statue(hall_id, 1, 2, 3)
statue(hall_id, 1, 8, 3)
d.set_state_rules(d.room(hall_id), [{'state': 1, 'screens': [0],
                                    'when': [{'flag': 'memorial_hall_grown'}]}])
d.set_memorial(cap=120)

# screen 0: the CHAMPION (row 4), the HALL GUIDE (row 5), the MASON (row 6)
champ = d.add_enemy(copy_eid=2, name='Hall champion', species=36, level=5,
                    hp=30, mp=0, atk=10, **{'def': 10}, agl=10, joinability=7)
for st in (0, 1):
    rm = d.room(hall_id)
    d.add_npc(rm, '0', st, 5, 4, 0xF0, 'down', monster=36)
    k = len(d.npc_entries(rm, '0', st)) - 1
    sid = d.new_conversation(rm, {'steps': [
        {'ask': B('I am the CHAMPION of the hall. Beat me and your party is remembered '
                  'here. Fight?', choice=True),
         'yes': [{'battle': {'enemies': [champ]}},
                 {'say': B("Well fought! Your party is in the hall's book now.")}],
         'no': [{'say': B('Another time.')}]}]}, name=f'champion{st}')
    d.update_npc(rm, '0', st, k, script=sid)
    talker(hall_id, 2, 5, 0x0B, [{'say': B(
        'THE MEMORIAL HALL. A statue remembers a monster that won a boss fight, an arena '
        'class or Starry Night with you and has since left you - bred, released or '
        'traded. Each visit the statues pick again, every one a different monster. '
        'Examine a statue to read it. The FARM is east.')}], f'hall_guide{st}', state=st)
    talker(hall_id, 7, 6, 0x1D, [
        {'if': [{'flag': 'memorial_hall_grown', 'is': 'set'}],
         'then': [{'say': B('I am the MASON. The hall has five statues now: the room '
                            'changed state.')}],
         'else': [{'ask': B('I am the MASON. Shall I carve two more statues? (A flag '
                            'turns the hall to its second state.)', choice=True),
                   'yes': [{'set': ['memorial_hall_grown']}, {'refresh': True}],
                   'no': [{'say': B('As you wish.')}]}]}], f'mason{st}', state=st)

# screen 1: the FARM KEEPER (row 3: drop a monster off, part with it), the EXIT GUIDE
# (row 5) and the BREEDER (row 6: breed a monster away — the memorial's main case; his
# mate is a male Dracky, the user's party being all female)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)
rm = d.room(hall_id)
d.add_npc(rm, '1', 0, 4, 3, 0x14, 'down')
d.make_service_npc(rm, '1', 0, len(d.npc_entries(rm, '1', 0)) - 1, 'farm')
rm = d.room(hall_id)
d.add_npc(rm, '1', 0, 6, 5, 0x1F, 'down')
k = len(d.npc_entries(rm, '1', 0)) - 1
sid = d.new_conversation(rm, {'steps': [
    {'ask': B('I am the EXIT GUIDE. Back to the city?', choice=True),
     'yes': [{'move': {'dest': f'room:${c_mid:02X}', 'screen': 0, 'x': 4, 'y': 5}}],
     'no': [{'say': B('Stay as long as you like.')}]}]}, name='hall_exit')
d.update_npc(rm, '1', 0, k, script=sid)
rm = d.room(hall_id)
d.add_npc(rm, '1', 0, 2, 6, 0x1D, 'down')
bsid = d.make_service_npc(rm, '1', 0, len(d.npc_entries(rm, '1', 0)) - 1, 'breeder')
mate = d.mate_for(3, 10)                                # a Dracky, level 10
for e in d.data.setdefault('progression', {}).setdefault('enemies', []):
    if e.get('id') == mate:
        e['gender'] = 'male'
d.set_breeder_options(bsid, mate=mate, intro=[['I am the BREEDER.', 'Breed with my'],
                                               ['Dracky? The parent', 'leaves you.']])

# ---- the way in: the MEMORIAL GUIDE in Cities_FOUNT --------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
talker('cities_fount', 3, 4, 0x0B, [{'ask': B('I am the MEMORIAL GUIDE. To the MEMORIAL '
                                              'HALL?', choice=True),
                                     'yes': [{'move': {'dest': f'room:${hall_mid:02X}',
                                                       'screen': 0, 'x': 4, 'y': 5}}],
                                     'no': [{'say': B('Another time.')}]}], 'memorial_guide')

# ---- THE MEMORIAL CRYPT: served on gate 2's second floor -----------------------------
crypt_id = d.new_room('MEMORIAL CRYPT', 0, r, gate_theme=13)
crypt = d.room(crypt_id)
clay = crypt['screens']['0']['layout']['id']
walls(clay)
entry_script(crypt, crypt_id)
statue(crypt_id, 0, 3, 2)
statue(crypt_id, 0, 6, 2)
talker(crypt_id, 2, 5, 0x0B, [{'say': B(
    'THE MEMORIAL CRYPT, deep in a gate: two more statues of the fallen. The STAIRS '
    '(right) go on down.')}], 'crypt_sign')
crypt = d.room(crypt_id)
d.add_stairs(crypt, '0', 0, 8, 6)
d.set_gate_arrival(crypt, 0, 4, 5)
rules = d.gate_inserts()
rules.insert(0, {'room': crypt_id, 'gate': 2, 'floors': [2], 'chance': 100,
                 'once_per_dive': True})
d.set_gate_inserts(rules)

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'crypt', crypt_id, d.room(crypt_id)['mapID'],
      'statues', [s['id'] for s in d.room(hall_id)['statues']],
      [s['tiles'] for s in d.room(hall_id)['statues']])
