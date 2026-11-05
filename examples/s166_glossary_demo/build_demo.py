"""S166 demo (ROADMAP Phase F T-follow (a) the other screens' windows, (b) the packed menu words,
(c) the text window widths): THE GLOSSARY HALL on the user's project.

Every service screen of the game in one hall, so the window words of the shop, the Vault, the farm,
the library, the Monster Namer, the Medal Man, the egg appraiser, the gate list, Grandpa's breeding
menus and the battle can be seen with the words this ROM changed (GLOSSARY_EDITS below; the
WORDSMITH says them):

  * THE GLOSSARY HALL (a new room, four screens west to east, gate look 7):
      screen 0: the GLOSSARY GUIDE (what this is; YES = back to the city), the SHOPKEEPER (the
        Bazaar's list), the VAULT KEEPER (one NPC a row; row 4 = the passage east / west);
      screen 1: the FARM KEEPER, the LIBRARIAN, the MONSTER NAMER;
      screen 2: the MEDAL MAN, the EGG APPRAISER, the GATE GUIDE;
      screen 3: GRANDPA (breeding), the SPARRING SLIME (a battle), the WORDSMITH.

Way in: the GLOSSARY GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s166_glossary_demo/build_demo.py <base project.json> <out project.json> [--plain]

(--plain: no window-word / text edits — the build the census tours; the base project's assets/
folder must sit beside the out project.json).
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document                       # noqa: E402
from editor2.core.render_project import ProjectRenderer          # noqa: E402
from editor2.core import textenc as T                            # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith('--')]
PLAIN = '--plain' in sys.argv
src, dst = args[0], args[1] if len(args) > 1 else args[0]
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


def service(room_id, key, x, y, sprite, kind):
    rm = d.room(room_id)
    d.add_npc(rm, key, 0, x, y, sprite, 'down')
    k = len(d.npc_entries(rm, key, 0)) - 1
    if kind == 'shop':
        return d.make_shopkeeper(rm, key, 0, k, 'bazaar')
    return d.make_service_npc(rm, key, 0, k, kind)


def go_to(mid, x=4, y=5):
    return {'move': {'dest': f'room:${mid:02X}', 'screen': 0, 'x': x, 'y': y}}


SLIME = 0
sparring = d.add_enemy(copy_eid=2, name='Gloss slime', species=SLIME, level=5, hp=60, mp=0,
                       atk=1, **{'def': 1}, agl=1, int=1, joinability=0, skills=[])

# ---- THE GLOSSARY HALL ------------------------------------------------------------------------
hall_id = d.new_room('GLOSSARY HALL', 0, r, gate_theme=7)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lays = [lay0]
for s in (1, 2, 3):
    ls = d.unique_layout_id(f'{hall_id}_s{s}')
    d.add_layout(ls, tiles=[list(row) for row in d.layout(lay0)['tiles']],
                 attr=[list(row) for row in d.layout(lay0)['attr']])
    d.add_screen(d.room(hall_id), s, {'id': ls})     # four screens in a row: at most 3 NPCs a
    walls(ls)                                         # screen (S151 r3)
    lays.append(ls)
for s, ls in enumerate(lays):
    if s < 3:
        paint(ls, 9, 4, FLOOR)                        # the way east
    if s > 0:
        paint(ls, 0, 4, FLOOR)                        # the way west
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 2, 0x0B, [{'ask': B(
    'THE GLOSSARY HALL. Every service screen of the game, in one place, so its window words can '
    'be read. Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Read on.')}]}], 'glossary_guide')
# one NPC a row (S117b: the party + 2 NPCs on a row = one vanishes); row 4 is the passage
SERVICES = [('0', 5, 6, 0x1D, 'shop'), ('0', 7, 3, 0x0B, 'vault'),
            ('1', 2, 2, 0x1D, 'farm'), ('1', 5, 6, 0x0B, 'library'), ('1', 7, 3, 0x1D, 'namer'),
            ('2', 2, 2, 0x0B, 'medals'), ('2', 5, 6, 0x1D, 'eggs'), ('2', 7, 3, 0x0B, 'gates'),
            ('3', 2, 2, 0x1D, 'grandpa')]
for key, x, y, spr, kind in SERVICES:
    service(hall_id, key, x, y, spr, kind)
npc(hall_id, '3', 5, 6, 0x10, [
    {'ask': B('I am the SPARRING SLIME. A gentle fight, to see the battle windows? I like to '
              'join a winner: say YES with a full party to see the farm windows.', choice=True),
     'yes': [{'battle': {'enemies': [sparring]}}, {'say': B('Again any time!')}],
     'no': [{'say': B('Another time.')}]}], 'gloss_spar', monster=SLIME)

# ---- the edits of this ROM (Text → Window words; editor2/core/window_words.py) ---------------
# tile words: only the letters the screen holds (the measured `letters`); text words (T:…): any
GLOSSARY_EDITS = {
    '09:6F3C/1/2': 'GET',            # the shop: BUY -> GET
    '09:6F3C/5/2': 'OUT',            # the shop: EXIT -> OUT
    'T:field_message:11/0': 'STOW',  # the Vault: PUT -> STOW   (a word of the text PUT TAKEEXIT)
    'T:field_message:11/4': 'GET',   # the Vault: TAKE -> GET
    '12:710C/9/2': 'REST',           # the farm: SLEEP -> REST
    '0A:75AB/1/2': 'MATE',           # Grandpa: BREED -> MATE
    'T:field_message:16/0': 'BACK',  # Grandpa: EXIT -> BACK    (a word of the text EXIT INFO)
    '0A:77D7/1/2': 'RATE',           # the egg appraiser: EVAL -> RATE
    '50:6ED2/1/2': 'HIT',            # the battle: FIGHT -> HIT
    '50:6ED2/3/8': 'FLY',            # the battle: RUN -> FLY
    '50:6F60/5/2': 'CAREFUL',        # the tactics: CAUTIOUS -> CAREFUL
}
WORDSMITH = ('I am the WORDSMITH. In this ROM the shop says GET and OUT, the Vault STOW and GET, '
             'the farm REST, Grandpa MATE and BACK, the egg appraiser RATE; in a battle HIT, FLY '
             'and CAREFUL.')
if PLAIN:
    WORDSMITH = 'I am the WORDSMITH. This ROM leaves every window word as the game has it.'
else:
    for k, v in GLOSSARY_EDITS.items():
        d.set_window_word(k, v)
npc(hall_id, '3', 7, 3, 0x0B, [{'say': B(WORDSMITH)}], 'gloss_wordsmith')

# ---- the way in: the GLOSSARY GUIDE in Cities_FOUNT ------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the GLOSSARY GUIDE. To the GLOSSARY HALL, '
                                                 'where every service screen stands?', choice=True),
                                       'yes': [go_to(hall_mid, 4, 5)],
                                       'no': [{'say': B('Another time.')}]}], 'glossary_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'spar row', sparring)
