"""S149 demo (ROADMAP ARC CAP5, battles at campaign scale): THE MUSTER HALL on the user's
project.

Until S149 a monster made from one of the project's OWN enemy rows (EID 519+: it joins
after a battle, a script gives it) went through two original lookups that only know the
original rows (bank $14 label14_40b4): its GENDER came from past the end of the game's
gender table (rows 1-14 always male, later rows a junk gender byte), and rows whose
number shares its low byte with a rival tamer's row took that tamer's NAME as master
(the 43rd row) or arrived as an EGG (the 88th). And a project had at most 640 enemy
rows and 128 battle lists of its own. This demo builds a project past both old limits
(1,100 enemy rows, 600 battle lists — fillers nobody meets) and puts the rows that
used to break behind a BRAND-NEW room, THE MUSTER HALL (a gate theme of its own):

  * the DRACKY (left): row 43 — "always male"; before S149 it joined with a rival
    tamer's name as its master;
  * the HEALER (middle): row 88 — "rolled by the species"; before S149 it arrived as
    an EGG;
  * the PIXY (right): row 900, far past the old 640 limit (it lives in a new bank of
    the 4 MB ROM) — "always female";
    (each: YES = a short fight; it always joins — name it, and see it in your party or
    at the farm keeper);
  * the FARM KEEPER (bottom left): the game's farm screen, to look at who joined;
  * the STAIRS (top right) down to THE MUSTER FIELD: its wild battles come from YOUR
    battle list 700 (in a new bank too) — only GOLEMs (row 1,000) live there; the FIELD
    GUIDE says so; the stairs back up;
  * the EXIT GUIDE (bottom right): back to Cities_FOUNT.

Way in: the MUSTER GUIDE in Cities_FOUNT at (3, 4) (a new NPC; YES = to the hall).

    python3 examples/s149_muster_demo/build_demo.py <base project.json> <out project.json>

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
d.vanilla = r                    # as the editor's Session does (paint_swirl reads vanilla art)

WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
DRACKY, HEALER, PIXY, GOLEM = 78, 9, 130, 196     # species (MONSTER_DATA)
ROWS, LISTS = 1100, 600                           # past the old 640 / 128
ROW_DRACKY, ROW_HEALER, ROW_PIXY, ROW_GOLEM = 43, 88, 900, 1000   # 1-based row numbers
LIST_FIELD = 700                                   # a list number past the old 255


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


# ---- the enemy rows: fillers up to row 1,100, the demo's rows at their places ----------
ens = d.data.setdefault('progression', {}).setdefault('enemies', [])
special = {ROW_DRACKY: ('Muster Dracky', DRACKY, 'male'),
           ROW_HEALER: ('Muster Healer', HEALER, None),
           ROW_PIXY: ('Muster Pixy', PIXY, 'female'),
           ROW_GOLEM: ('Field Golem', GOLEM, None)}
ids = {}
while len(ens) < ROWS:
    n = len(ens) + 1                               # this row's number (1-based)
    if n in special:
        name, sp, g = special[n]
        # level-5 stats (S149 r2, the user: "they FAINT AFTER JOINING" — S149 r1 gave
        # them HP 1 / MP 0 for short fights, and the creation roll x0.80-1.00 rounded
        # down makes HP 1 a 0-HP monster 51 times in 52; the game's own rows are HP 2+)
        rid = d.add_enemy(copy_eid=2, name=name, species=sp, level=5, hp=30, mp=15, atk=14,
                          agl=12, joinability=0 if n != ROW_GOLEM else 7)
        if g:
            d.update_enemy(rid, gender=g)
        ids[n] = rid
    else:
        d.add_enemy(copy_eid=2, name=f'Muster filler {n}', species=8, level=1,
                    joinability=7)
for n, rid in ids.items():
    assert d.project_eid(d.project_enemy(rid)) == 519 + n - 1, (n, rid)

# ---- the battle lists: fillers up to number 700, the field's list there ----------------
lists = d.custom.setdefault('encounter_lists', [])
while 128 + len(lists) < LIST_FIELD:
    lists.append({'id': f'muster_filler_{len(lists)}', 'name': 'Muster filler',
                  'rate': 3, 'size_chance': [7, 0, 0], 'slot_chance': [7, 0, 0, 0, 0],
                  'eids': [2, 0, 0, 0, 0], 'max_count': [1, 1, 1, 1, 1]})
lists.append({'id': 'muster_field', 'name': 'The Muster Field (only GOLEMs)',
              'rate': 7, 'size_chance': [7, 0, 0], 'slot_chance': [7, 0, 0, 0, 0],
              'eids': [ids[ROW_GOLEM], 0, 0, 0, 0], 'max_count': [1, 1, 1, 1, 1]})
while len(lists) < LISTS:
    lists.append({'id': f'muster_filler_{len(lists)}', 'name': 'Muster filler',
                  'rate': 3, 'size_chance': [7, 0, 0], 'slot_chance': [7, 0, 0, 0, 0],
                  'eids': [2, 0, 0, 0, 0], 'max_count': [1, 1, 1, 1, 1]})
assert 128 + [x['id'] for x in lists].index('muster_field') == LIST_FIELD
d.touch()

# ---- the hall ----------------------------------------------------------------------
hall_id = d.new_room('MUSTER HALL', 0, r, gate_theme=6)
hall = d.room(hall_id)
hall_mid = int(hall['mapID'], 16)
lid = hall['screens']['0']['layout']['id']
walls(lid)
paint(lid, 8, 1, STAIRS)
field_id = d.new_room('MUSTER FIELD', 0, r, gate_theme=2)
field = d.room(field_id)
field_mid = int(field['mapID'], 16)
flid = field['screens']['0']['layout']['id']
walls(flid)
paint(flid, 1, 1, STAIRS)
a = d.add_door(hall_id, '0', 8, 1, name='Muster stairs down')
b = d.add_door(field_id, '0', 1, 1, name='Muster stairs up')
d.link_doors(a, b)
d.set_room_battles(field_id, 'own', list_ref='muster_field', rate=7)
hall, field = d.room(hall_id), d.room(field_id)    # (that write commits a fresh copy)

tbl = hall.setdefault('scripts', {})
if '0' not in tbl:
    tbl['0'] = f'{hall_id}_entry'
    d.custom['scripts'].append({'id': tbl['0'], 'ops': [['end']]})


def monster(x, species, rid, words):
    d.add_npc(hall, '0', 0, x, 3, 0xF0, 'down', monster=species)
    k = len(d.npc_entries(hall, '0', 0)) - 1
    steps = [{'ask': B(*words, choice=True),
              'yes': [{'battle': {'enemies': [rid]}},
                      {'say': B('Look at it in your party (or at the FARM KEEPER): its '
                                'master is YOU, and its gender is as I said.')}],
              'no': [{'say': B('Another time!')}]}]
    sid = d.new_conversation(hall, {'steps': steps}, name=f'muster_{x}')
    d.update_npc(hall, '0', 0, k, script=sid)


monster(2, DRACKY, ids[ROW_DRACKY], (
    'THE MUSTER HALL. I am your enemy row 43, a DRACKY, ALWAYS MALE.',
    "Before S149 I joined carrying a rival tamer's name as my master. Fight me? I always "
    'join.'))
monster(5, HEALER, ids[ROW_HEALER], (
    'I am your enemy row 88, a HEALER; my gender is ROLLED by my species, like most of '
    "the game's monsters.",
    'Before S149 I arrived as an EGG. Fight me? I always join.'))
monster(8, PIXY, ids[ROW_PIXY], (
    'I am your enemy row 900, a PIXY, ALWAYS FEMALE. Projects stopped at 640 rows '
    'before S149; I live in a new bank of the 4 MB ROM.',
    'Fight me? I always join.'))

d.add_npc(hall, '0', 0, 2, 6, 0x07, 'down')
k_farm = len(d.npc_entries(hall, '0', 0)) - 1
d.make_service_npc(hall, '0', 0, k_farm, 'farm')
k_exit = d.add_npc(hall, '0', 0, 7, 6, 0x1D, 'down')
cities = d.room('cities_fount')
back = [{'ask': B('I am the EXIT GUIDE. The FARM KEEPER (left) shows the monsters at '
                  'your farm. The STAIRS (top right) go down to THE MUSTER FIELD. Back to '
                  'the city with the fountain?', choice=True),
         'yes': [{'move': {'dest': f"room:${int(cities['mapID'], 16):02X}", 'screen': 0,
                           'x': 5, 'y': 5}}],
         'no': [{'say': B('Take your time!')}]}]
sid_x = d.new_conversation(hall, {'steps': back}, name='muster_exit')
d.update_npc(hall, '0', 0, k_exit, script=sid_x)

ftbl = field.setdefault('scripts', {})
if '0' not in ftbl:
    ftbl['0'] = f'{field_id}_entry'
    d.custom['scripts'].append({'id': ftbl['0'], 'ops': [['end']]})
k_fg = d.add_npc(field, '0', 0, 4, 2, 0x0B, 'down')
fg = [{'say': B('THE MUSTER FIELD. The wild monsters here come from YOUR battle list 700 '
                '(projects stopped at list 255 before S149; this one lives in a new bank).',
                'Only GOLEMs live here: enemy row 1,000. Walk around! The STAIRS (top '
                'left) go back up.')}]
sid_fg = d.new_conversation(field, {'steps': fg}, name='muster_field_guide')
d.update_npc(field, '0', 0, k_fg, script=sid_fg)

# ---- THE FAR WING: region 1 (the S141 acceptance not walked then: the arena from a
# later region, a world in a later region, a JOURNAL save in a dive in a later region) --
FAR = 0x16B                                         # region 1 is empty in the user's project


def region1(room_id, n):
    rm = d.room(room_id)
    rm['mapID'] = f'0x{FAR + n:03X}'
    return rm


land_id = d.new_room('FAR LANDING', 0, r, gate_theme=9)
grove_id = d.new_room('FAR GROVE', 0, r, gate_theme=3)
den_id = d.new_room('FAR DEN', 0, r, gate_theme=12)
rest_id = d.new_room('FAR REST', 0, r, gate_theme=14)
for n, rid in enumerate((land_id, grove_id, den_id, rest_id)):
    region1(rid, n)
    walls(d.room(rid)['screens']['0']['layout']['id'])
for rid in (land_id, grove_id, den_id, rest_id):
    t = d.room(rid).setdefault('scripts', {})
    if '0' not in t:
        t['0'] = f'{rid}_entry'
        d.custom['scripts'].append({'id': t['0'], 'ops': [['end']]})


def talker(room_id, x, y, sprite, steps, name):
    rm = d.room(room_id)
    d.add_npc(rm, '0', 0, x, y, sprite, 'down')
    k = len(d.npc_entries(rm, '0', 0)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', 0, k, script=sid)


def go(room_id, screen, x, y):
    rm = d.room(room_id)
    return {'move': {'dest': f"room:${int(rm['mapID'], 16):02X}" if int(rm['mapID'], 16) < 0x100
                     else f"room:${int(rm['mapID'], 16):03X}", 'screen': screen, 'x': x, 'y': y}}


# the world: FAR GROVE (start) + FAR DEN (battles), both region 1. Gate numbers of their
# own (44 / 45): the user's save has cleared 33 (the S141 demo's DIAL GATE) and the Gate
# of Villager — a cleared gate's portal swirl is hidden, and the portals must SHOW
_new_gate = d.new_gate
d.new_gate = lambda copy_of, name, floors=None, gate_id=None: _new_gate(
    copy_of, name, floors, gate_id=44)
far_world = d.new_world('Far World', grove_id, screen=0, x=4, y=5)
d.new_gate = _new_gate
far_gate = d.new_gate(1, 'Far Gate', gate_id=45)        # a copy of the Gate of Villager
d.add_world_room(far_world, den_id)
ga = d.add_door(grove_id, '0', 8, 1, name='Far grove door')
gb = d.add_door(den_id, '0', 1, 6, name='Far den door')
paint(d.room(grove_id)['screens']['0']['layout']['id'], 8, 1, STAIRS)
paint(d.room(den_id)['screens']['0']['layout']['id'], 1, 6, STAIRS)
d.link_doors(ga, gb)
d.set_room_battles(den_id, 'own', list_ref='muster_field', rate=7)
# the dive: the FAR GATE (gate 45, the Gate of Villager's 5 floors) floor 2 = FAR REST,
# saving allowed
VILLAGER = far_gate
rest = d.room(rest_id)
rest['gate_arrival'] = {'screen': 0, 'x': 4, 'y': 5}
rest['can_save'] = True
rest['screens']['0']['exits'].append({'x': 8, 'y': 1, 'stairs': 'down'})
paint(rest['screens']['0']['layout']['id'], 8, 1, STAIRS)
d.set_gate_inserts(list(d.gate_inserts()) + [
    {'room': rest_id, 'gate': VILLAGER, 'floors': [2, 2], 'chance': 100,
     'comment': 'S149 demo: a region-1 room served on a gate floor (saving allowed)'}])
# FAR LANDING: two portals (a world, a gate) + the arena guide + the way back
for cx, gid in ((2, far_world), (7, VILLAGER)):      # what Rooms → "Gate entrance here…"
    d.add_gate_entrance(d.room(land_id), '0', 0, cx, 2, gid)   # does: the exit + the
    d.paint_swirl(d.room(land_id), '0', 0, cx, 2)              # spinning object + the art
lobby = d.room('arena_lobby')
talker(land_id, 2, 5, 0x0B, [{'ask': B(
    'FAR LANDING (region 1). Left portal: the FAR WORLD (a world in region 1). Right '
    'portal: the FAR GATE (like the Gate of Villager) - its floor 2 is FAR REST (region '
    '1), where you may save.',
    'I can take you to the ARENA LOBBY: a match there from region 1, then its own door '
    'out goes to GreatTree as always. Go?', choice=True),
    'yes': [go('arena_lobby', 1, 4, 7)], 'no': [{'say': B('Another time!')}]}], 'far_arena')
talker(land_id, 7, 5, 0x1D, [{'ask': B('Back to THE MUSTER FIELD?', choice=True),
                              'yes': [go(field_id, 0, 4, 4)],
                              'no': [{'say': B('Take your time!')}]}], 'far_back')
talker(grove_id, 4, 3, 0x0B, [{'ask': B(
    'FAR GROVE: the start of the FAR WORLD, region 1. The STAIRS (top right) go to the '
    'FAR DEN, where wild GOLEMs live. Leave the world, back to FAR LANDING?', choice=True),
    'yes': [go(land_id, 0, 4, 4)], 'no': [{'say': B('Explore!')}]}], 'far_grove_guide')
talker(den_id, 5, 3, 0x0B, [{'say': B(
    'FAR DEN, the FAR WORLD, region 1: wild GOLEMs. The STAIRS (bottom left) go back to '
    'the FAR GROVE.')}], 'far_den_sign')
talker(rest_id, 4, 3, 0x0B, [{'say': B(
    'FAR REST: floor 2 of the FAR GATE, a room of region 1. You may SAVE here '
    '(JOURNAL). CONTINUE that save: you are here again. The STAIRS go on down.')}],
    'far_rest_sign')
field = d.room(field_id)
talker(field_id, 7, 2, 0x1D, [{'ask': B(
    'I am the FAR GUIDE: THE FAR WING lies in region 1 (the next group of 128 rooms): '
    'the arena from there, a world, a room inside a gate where you may save. Go?',
    choice=True), 'yes': [go(land_id, 0, 4, 4)], 'no': [{'say': B('Another time!')}]}],
    'far_guide')
cities = d.room('cities_fount')

k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')
demo = [{'ask': B('S149 DEMO: THE MUSTER HALL - enemy rows and battle lists past the old '
                  'limits, and monsters that join with the right gender. Go?',
                  choice=True),
         'yes': [{'move': {'dest': f'room:${hall_mid:02X}', 'screen': 0, 'x': 4, 'y': 6}}],
         'no': [{'say': B('Another time!')}]}]
sid = d.new_conversation(cities, {'steps': demo}, name='s149demo')
d.update_npc(cities, '0', 0, k_demo, script=sid)
d.save(dst)
print(f'hall ${hall_mid:02X}, field ${field_mid:02X}, far world gate {far_world}; '
      f'rows {len(ens)}, lists {len(lists)}; '
      + ', '.join(f'row {n} = EID {519 + n - 1} {ids[n]}' for n in sorted(ids)))
