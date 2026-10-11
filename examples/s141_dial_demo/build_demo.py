"""S141 demo (ROADMAP ARC CAP3b — regions, the rest of the acceptance): the DIAL HALLS on
the user's project.

S140 walked doors and script warps between regions. This demo walks the moments where the
GAME moves the player by itself, with no door: a lost battle (home = the hub), the WarpWing
(home), the breeding ceremony (back to the room you came from), a gate that serves one of
your rooms on a floor, and a gate's boss floor. Each must land in the right REGION.

Eight BRAND-NEW rooms, four map ids used twice: the TEST rooms are in region 2 (MOONDIAL
HALL, MOON HEARTH, MOON CELLAR, MOON DAIS = project mapIDs $276-$279), and region 0 has a
DECOY with the same map id each (SUNDIAL HALL, SUN HEARTH, SUN CELLAR, SUN DAIS = $76-$79).
A move that forgot the region would land in the decoy, which says so. (Region 1 is empty.)

  * MOONDIAL HALL (region 2; the way in: the S141 DEMO NPC in Cities_FOUNT (3, 4), which
    also turns the hub on): a GRANDPA (BREED — the ceremony must bring you back here), a
    BRUISER monster that always wins (you must wake up in MOON HEARTH), a WING KEEPER (a
    WarpWing for the gate), a SIGN and a GUIDE to SUNDIAL HALL;
  * SUNDIAL HALL (region 0): the PORTAL into the DIAL GATE (a new gate, a copy of the Gate of
    Beginning, 4 floors), another BRUISER (lose here: you must still wake up in MOON HEARTH,
    region 2), a SIGN and a GUIDE back to MOONDIAL HALL;
  * the DIAL GATE: floor 2 is always MOON CELLAR (region 2, served from a region-0 portal),
    floor 3 is the gate's own (throw the WarpWing there: MOON HEARTH), floor 4 = the boss
    floor MOON DAIS (region 2): the DIAL WARDEN — beat it, the gate is cleared (the portal's
    swirl stops) and it sends you home;
  * MOON HEARTH (region 2) = the HUB while the flag `s141_hub` is ON: it greets you with the
    reason you came (lost / WarpWing / sent home); its KEEPER turns the hub off (then the
    Castle is home, as in the game) and on again.

    python3 examples/s141_dial_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json).
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document               # noqa: E402
from editor2.core.render_project import ProjectRenderer  # noqa: E402
from editor2.core import textenc as T                    # noqa: E402
from editor2.core import cutscene_doc as CD              # noqa: E402

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

WALL = [0x08, 0x09, 0x18, 0x19]
GATE = 33                                        # the DIAL GATE (a new gate)
BRUISER_SPECIES, WARDEN_SPECIES = 150, 26        # a big one to lose to; a small boss
WARPWING = 29
HUB_FLAG = 's141_hub'


def B(*paras):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out}


def paint(lid, cx, cy, mt, pal):
    lay = d.layout(lid)
    g, a = lay['tiles'], lay['attr']
    for i, (dy, dx) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
        g[2 * cy + dy][2 * cx + dx] = mt[i]
        a[2 * cy + dy][2 * cx + dx] = pal


def floor_pal(lid):
    lay = d.layout(lid)
    for rr in range(16):
        for cc in range(20):
            if 0x30 <= lay['tiles'][rr][cc] <= 0x33:
                return lay['attr'][rr][cc]
    return 0


def room(name, mid, theme, song):
    rid = d.new_room(name, 0, r, gate_theme=theme)
    rm = d.room(rid)
    rm['mapID'] = f'0x{mid:02X}' if mid < 0x100 else f'0x{mid:03X}'
    rm['music'] = song
    lid = rm['screens']['0']['layout']['id']
    pal = floor_pal(lid)
    for cx in range(10):
        paint(lid, cx, 0, WALL, pal)
        paint(lid, cx, 7, WALL, pal)
    for cy in range(8):
        paint(lid, 0, cy, WALL, pal)
        paint(lid, 9, cy, WALL, pal)
    return rid, rm


def dest(mid):
    return f'room:${mid:X}'


def talk(rm, npc, steps, name):
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', 0, npc, script=sid)
    return sid


if not any(f.get('name') == HUB_FLAG for f in d.flags()):
    d.add_flag(HUB_FLAG, 'S141 demo: MOON HEARTH is home (the hub) while ON')

# ---------------------------------------------------------------- the rooms
TEST = {'hall': 0x276, 'hearth': 0x277, 'cellar': 0x278, 'dais': 0x279}
DECOY = {'hall': 0x76, 'hearth': 0x77, 'cellar': 0x78, 'dais': 0x79}
NAMES = {'hall': ('MOONDIAL HALL', 'SUNDIAL HALL'), 'hearth': ('MOON HEARTH', 'SUN HEARTH'),
         'cellar': ('MOON CELLAR', 'SUN CELLAR'), 'dais': ('MOON DAIS', 'SUN DAIS')}
THEMES = {'hall': (9, 1), 'hearth': (13, 4), 'cellar': (10, 2), 'dais': (14, 6)}
rooms = {}
for k in TEST:
    rooms[('t', k)] = room(NAMES[k][0], TEST[k], THEMES[k][0], '0x31')
    rooms[('d', k)] = room(NAMES[k][1], DECOY[k], THEMES[k][1], '0x09')

hall_id, hall = rooms[('t', 'hall')]
hearth_id, hearth = rooms[('t', 'hearth')]
cellar_id, cellar = rooms[('t', 'cellar')]
dais_id, dais = rooms[('t', 'dais')]
sun_id, sun = rooms[('d', 'hall')]

bruiser = d.add_enemy(copy_eid=2, name='Dial bruiser', species=BRUISER_SPECIES, level=99,
                      hp=999, mp=0, atk=999, **{'def': 999}, agl=999, joinability=7)
warden = d.add_enemy(copy_eid=2, name='Dial warden', species=WARDEN_SPECIES, level=1,
                     hp=1, joinability=7)

# the decoys: only a sign that says "wrong place" and a guide out (SUNDIAL HALL is
# the portal room as well — below)
for k in ('hearth', 'cellar', 'dais'):
    _rid, rm = rooms[('d', k)]
    sign = d.add_npc(rm, '0', 0, 3, 1, 0x0B, 'down')
    guide = d.add_npc(rm, '0', 0, 6, 2, 0x0C, 'down')
    talk(rm, sign, [{'say': B(f'{NAMES[k][1]}: region 0, map {DECOY[k]:02X}.',
                              f'If the game just SENT you here, that is a BUG: you should be in '
                              f'{NAMES[k][0]}, region 2, the same map {DECOY[k]:02X}.')}],
         'sign')
    talk(rm, guide, [{'ask': B('Back to MOONDIAL HALL?'),
                      'yes': [{'move': {'dest': dest(TEST['hall']), 'screen': 0,
                                        'x': 5, 'y': 5}}],
                      'no': [{'say': B('Another time.')}]}], 'guide')

# MOONDIAL HALL (region 2)
# one NPC per row (a row shared with the walking party loses sprites —
# ROOM_DATA_FORMAT "Sprite limits"); the arrival cell (5, 5) is on a free row
sign = d.add_npc(hall, '0', 0, 2, 1, 0x0B, 'down')
gp = d.add_npc(hall, '0', 0, 5, 2, 0x0C, 'down')
mon = d.add_npc(hall, '0', 0, 8, 3, 0xF0, 'down', monster=BRUISER_SPECIES)
wing = d.add_npc(hall, '0', 0, 1, 4, 0x10, 'down')
guide = d.add_npc(hall, '0', 0, 8, 6, 0x00, 'left')
talk(hall, sign, [{'say': B('MOONDIAL HALL: region 2, map 76. SUNDIAL HALL in region 0 has '
                            'the same map 76.',
                            'Breed with GRANDPA: you must come back HERE. Lose to the BRUISER: '
                            'you must wake up in MOON HEARTH.')}], 'sign')
d.make_service_npc(hall, '0', 0, gp, 'grandpa',
                   first_time={'boxes': B('I am the GRANDPA of MOONDIAL HALL, region 2. After '
                                          'the ceremony you come back here.')['boxes'],
                               'flag': 's141_grandpa_met'})
talk(hall, mon, [{'ask': B('I am the BRUISER of MOONDIAL HALL. Nobody beats me. Fight?'),
                  'yes': [{'battle': {'enemies': [bruiser]}},
                          {'say': B('You won?! That was not the plan.')}],
                  'no': [{'say': B('Wise.')}]}], 'bruiser')
talk(hall, wing, [{'say': B('I am the WING KEEPER. Throw a WarpWing on a floor of the '
                            'DIAL GATE: it must fly you to MOON HEARTH.')},
                  {'give_item': {'item': WARPWING, 'count': 1,
                                 'got': B('Here is a WarpWing.'),
                                 'full': B('Your bag is full.')}}], 'wing')
talk(hall, guide, [{'ask': B('Go to SUNDIAL HALL (region 0), where the portal to the DIAL '
                             'GATE is?'),
                    'yes': [{'move': {'dest': dest(DECOY['hall']), 'screen': 0, 'x': 5,
                                      'y': 3}}],
                    'no': [{'say': B('Another time.')}]}], 'guide')

# SUNDIAL HALL (region 0): the decoy of MOONDIAL HALL and the portal room
sign = d.add_npc(sun, '0', 0, 2, 1, 0x0B, 'down')
mon = d.add_npc(sun, '0', 0, 2, 4, 0xF0, 'right', monster=BRUISER_SPECIES)
guide = d.add_npc(sun, '0', 0, 8, 2, 0x00, 'down')
talk(sun, sign, [{'say': B('SUNDIAL HALL: region 0, map 76. The swirl is the DIAL GATE.',
                           'On floor 2 you must meet MOON CELLAR (region 2) and on the last '
                           'floor MOON DAIS (region 2) - never a SUN room.',
                           'Lose to the BRUISER here: you must still wake up in MOON HEARTH, '
                           'region 2.')}], 'sign')
talk(sun, mon, [{'ask': B('I am the BRUISER of SUNDIAL HALL. Fight?'),
                 'yes': [{'battle': {'enemies': [bruiser]}},
                         {'say': B('You won?! That was not the plan.')}],
                 'no': [{'say': B('Wise.')}]}], 'bruiser')
talk(sun, guide, [{'ask': B('Back to MOONDIAL HALL?'),
                   'yes': [{'move': {'dest': dest(TEST['hall']), 'screen': 0, 'x': 5,
                                     'y': 5}}],
                   'no': [{'say': B('Another time.')}]}], 'guide')

# the DIAL GATE
d.new_gate(0, 'Dial Gate', floors=4, gate_id=GATE)
d.add_gate_entrance(sun, '0', 0, 5, 5, GATE)
d.set_gate_arrival(cellar, 0, 4, 5)
d.add_stairs(cellar, '0', 0, 7, 5)
d.set_encounter_mode(cellar, 'follow')
d.set_gate_arrival(dais, 0, 4, 5)
d.set_gate_setting(GATE, boss=dais_id)
rules = d.gate_inserts()
rules.append({'room': cellar_id, 'gate': GATE, 'floors': [2], 'chance': 100,
              'comment': 'S141 demo: a region-2 room served from a region-0 portal'})
d.set_gate_inserts(rules)
sign = d.add_npc(cellar, '0', 0, 3, 2, 0x0B, 'down')
talk(cellar, sign, [{'say': B('MOON CELLAR: region 2, map 78, floor 2 of the DIAL GATE. You '
                              'came from a region-0 portal.',
                              'The hole leads on. On floor 3 throw the WarpWing: you must '
                              'land in MOON HEARTH.')}], 'sign')
boss = d.add_npc(dais, '0', 0, 4, 2, 0xF0, 'down', monster=WARDEN_SPECIES)
talk(dais, boss, [{'say': B('MOON DAIS: region 2, map 79, the boss floor of the DIAL GATE.')},
                  {'ask': B('I am the DIAL WARDEN. Beat me and the gate is cleared. Fight?'),
                   'yes': [{'battle': {'enemies': [warden]}},
                           {'say': B('Cleared! The swirl in SUNDIAL HALL stops. Now home: '
                                     'MOON HEARTH (or the Castle if the hub is off).')},
                           {'move': {'dest': 'hub'}}],
                   'no': [{'say': B('Then the hole is the only way on... there is none. '
                                    'Talk to me again.')}]}], 'warden')

# MOON HEARTH (region 2) = the hub while s141_hub is ON
d.add_hub_rule({'when': [{'flag': HUB_FLAG}], 'room': hearth_id, 'screen': 0, 'x': 4, 'y': 4,
                'comment': 'S141 demo'})
WHY = {'lost': 'You LOST a battle.', 'warpwing': 'Your WarpWing flew you here.',
       'home': 'A script sent you home.'}
for reason, heal in (('lost', True), ('warpwing', True), ('home', False)):
    sid = CD.new_cutscene(d, hearth_id, f'Arrival {reason}', 0, 'entry')
    _r, sc = CD.find(d, sid)
    sc['trigger']['arrival'] = [reason] + (['wiped'] if reason == 'lost' else [])
    sc['player_start'] = {'x': 4, 'y': 4, 'face': 'down'}
    sc['steps'] = [{'say': B(f'MOON HEARTH: region 2, map 77. {WHY[reason]}')}] + (
        [{'heal': {}}] if heal else [])
keeper = d.add_npc(hearth, '0', 0, 2, 1, 0x0B, 'down')
guide = d.add_npc(hearth, '0', 0, 7, 2, 0x00, 'down')
talk(hearth, keeper, [{'if': [{'flag': HUB_FLAG}],
                       'then': [{'ask': B('I am the KEEPER of MOON HEARTH. This is home now. '
                                          'Make the Castle home again?'),
                                 'yes': [{'clear': HUB_FLAG},
                                         {'say': B('The Castle is home again.')}],
                                 'no': [{'say': B('Then home stays here.')}]}],
                       'else': [{'ask': B('I am the KEEPER of MOON HEARTH. The Castle is '
                                          'home. Make this hearth home?'),
                                 'yes': [{'set': HUB_FLAG},
                                         {'say': B('This hearth is home now.')}],
                                 'no': [{'say': B('Then the Castle stays home.')}]}]}],
     'keeper')
talk(hearth, guide, [{'ask': B('Back to MOONDIAL HALL?'),
                      'yes': [{'move': {'dest': dest(TEST['hall']), 'screen': 0, 'x': 5,
                                        'y': 5}}],
                      'no': [{'say': B('Rest a while.')}]}], 'guide')

# the way in
cities = d.room('cities_fount')
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')
talk(cities, k_demo, [{'ask': B('S141 DEMO: the DIAL HALLS. Rooms of region 2 with the same map '
                                'ids as rooms of region 0. Go? (MOON HEARTH becomes home.)'),
                       'yes': [{'set': HUB_FLAG},
                               {'move': {'dest': dest(TEST['hall']), 'screen': 0, 'x': 5,
                                         'y': 5}}],
                       'no': [{'say': B('Another time!')}]}], 's141demo')
d.save(dst)
print('rooms', ' '.join(f"{rm['name']}={rm['mapID']}" for _rid, rm in rooms.values()))
