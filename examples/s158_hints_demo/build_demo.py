"""S158 demo (ROADMAP E15, the breeding hints): THE STONE GARDEN, THE GREAT ARCHIVE and
THE RUNE CRYPT on the user's project.

A MONUMENT shows a random breeding cross (a HINT) the player has not unlocked yet and
unlocks it; an ARCHIVE (one family) lists the family's unlocked crosses, a "(bred)"
mark on the ones the player has made; breeding exactly a hint's cross unlocks it too.

  * THE STONE GARDEN (a new room, the Room of Beginning's stone and pillars): three
    PILLARS are monuments — left: every family, plain words, skips monsters the
    player has owned; middle: the SLIME family, as a RIDDLE (two of its crosses have
    one); right: the DRAGON family, a few words first, then the riddle and the cross
    ("both"). The GARDEN GUIDE explains; the BREEDER (a breeding service: his MadCat
    is the mate — Healer x MadCat makes a FangSlime, one of the hints) and the EXIT
    GUIDE (to THE GREAT ARCHIVE or the city).
  * THE GREAT ARCHIVE (a new room, the Library's shelves): eleven BOOKCASES, one per
    family (Slime … Spirit, left to right, top row then bottom row) — examining one
    names its family. The ARCHIVIST explains; the EXIT GUIDE goes back.
  * THE RUNE CRYPT (a new room, a gate's maze look + a pillar) is served on gate 2's
    second floor (once a dive): one monument (every family), a sign, the stairs down.

The pool is a WHITELIST of 8 crosses (custom.hints.include) with 3 riddles.

Way in: the HINT GUIDE in Cities_FOUNT at (3, 4) (YES = to THE STONE GARDEN).

    python3 examples/s158_hints_demo/build_demo.py <base project.json> <out project.json>

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

# Room of Beginning ($23): pillar top / bottom, its wall, its floor
PILLAR_TOP, PILLAR_BOT = [0x06, 0x07, 0x08, 0x09], [0x0A, 0x0B, 0x0C, 0x0D]
STONE_WALL, STONE_FLOOR = [0x0E, 0x0E, 0x0E, 0x0E], [0x24, 0x25, 0x26, 0x27]
# Library ($12): a bookcase (top / bottom), its wall, its floor
SHELF_TOP, SHELF_BOT = [0x1A, 0x1B, 0x2A, 0x2B], [0x1C, 0x1D, 0x2C, 0x2D]
LIB_WALL, LIB_FLOOR = [0x08, 0x08, 0x09, 0x09], [0x40, 0x41, 0x42, 0x43]
FAMILIES = ['Slime', 'Dragon', 'Beast', 'Bird', 'Plant', 'Bug', 'Devil', 'Zombie',
            'Material', 'Boss', 'Spirit']


def B(*paras, choice=False):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out, **({'choice': True} if choice else {})}


def paint(lid, cx, cy, mt):
    g = d.layout(lid)['tiles']
    g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1] = mt[0], mt[1]
    g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1] = mt[2], mt[3]


def box_room(lid, wall, floor):
    for cy in range(8):
        for cx in range(10):
            edge = cx in (0, 9) or cy in (0, 7)
            paint(lid, cx, cy, wall if edge else floor)


def entry_script(rm, rid):
    t = rm.setdefault('scripts', {})
    if '0' not in t:
        t['0'] = f'{rid}_entry'
        d.custom['scripts'].append({'id': t['0'], 'ops': [['end']]})


def talker(room_id, x, y, sprite, steps, name, key='0', state=0):
    rm = d.room(room_id)
    d.add_npc(rm, key, state, x, y, sprite, 'down')
    k = len(d.npc_entries(rm, key, state)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, key, state, k, script=sid)
    return sid


# ---- the pool: a whitelist of 8 crosses, 3 riddles ---------------------------------
HINTS = ['Slimex68+0>10',     # any Slime x MadCat -> FangSlime  (the BREEDER's cross)
         'Slimex26+0>6',      # any Slime x Poisongon -> Babble
         'Slimex48+0>9',      # any Slime x PillowRat -> Healer   (Healer is owned)
         '8x8+5>15',          # Slime x Slime +5 -> KingSlime     (a plus)
         '130xSlime+0>138',   # Pixy x any Slime -> 1EyeClown
         ]
d.set_hints_mode('whitelist')
# + two Dragon crosses and one Beast cross from the table (the first that fire)
from editor2.core import hints as HT                             # noqa: E402
cands = HT.candidates(d.model_project())
for fam, n in ((1, 2), (2, 1)):
    HINTS += [c['key'] for c in cands if c['fam'] == fam and c['plus'] == 0][:n]
d.set_hints_in_pool(HINTS, True)
d.set_hint_riddle('Slimex68+0>10', [['A cat gone mad', 'and a slime beside'],
                                    ['it: a fanged one', 'is born of both.']])
d.set_hint_riddle('Slimex26+0>6', [['A poisoned drake', 'and a drop of goo'],
                                   ['make a slime that', 'wobbles and hops.']])
dragons = [k for k in HINTS if HT.parse_key(k)[3] in
           {c['child'] for c in cands if c['fam'] == 1}]
d.set_hint_riddle(dragons[0], [['Scales and a', 'second soul: a'], ['dragon wakes.',
                                                                    '({child})']])
d.pin_hint_numbers()

# ---- THE STONE GARDEN (one screen: 3 pillars, 3 NPCs one a row) ----------------------
gid = d.new_room('STONE GARDEN', 0x23, r)
garden = d.room(gid)
glay = garden['screens']['0']['layout']['id']
box_room(glay, STONE_WALL, STONE_FLOOR)
entry_script(garden, gid)
for x in (2, 5, 8):
    paint(glay, x, 1, PILLAR_TOP)
    paint(glay, x, 2, PILLAR_BOT)
garden = d.room(gid)
m1 = d.add_monument(garden, '0', 0, 2, 2, name='LEFT PILLAR')
m2 = d.add_monument(garden, '0', 0, 5, 2, families=['Slime'], skip_owned=False,
                    show='riddle', name='MIDDLE PILLAR')
m3 = d.add_monument(garden, '0', 0, 8, 2, families=['Dragon'], skip_owned=False,
                    show='both', name='RIGHT PILLAR')
d.set_hint_object_words(garden, 'monument', m3, 'intro',
                        [['An old pillar.', 'Its words are'], ['half lost...']])
talker(gid, 3, 4, 0x0B, [{'say': B(
    'THE STONE GARDEN. Each pillar is a MONUMENT: read one and it teaches you a breeding '
    'cross you have not found yet. Left: any family (it skips monsters you have owned). '
    'Middle: the Slime family, in riddles. Right: the Dragon family. Come back later and '
    'a pillar teaches another. The ARCHIVE keeps what you learn.')}], 'garden_guide')
rm = d.room(gid)
d.add_npc(rm, '0', 0, 7, 5, 0x1D, 'down')
bsid = d.make_service_npc(rm, '0', 0, len(d.npc_entries(rm, '0', 0)) - 1, 'breeder')
mate = d.mate_for(68, 10)                                  # a MadCat, level 10
for e in d.data.setdefault('progression', {}).setdefault('enemies', []):
    if e.get('id') == mate:
        e['gender'] = 'male'
d.set_breeder_options(bsid, mate=mate, intro=[['I am the BREEDER.', 'Breed with my'],
                                               ['MadCat? A Healer', 'makes a FangSlime.']])

# ---- THE GREAT ARCHIVE (eleven bookcases) ------------------------------------------
aid_room = d.new_room('GREAT ARCHIVE', 0x12, r)
arc = d.room(aid_room)
alay = arc['screens']['0']['layout']['id']
box_room(alay, LIB_WALL, LIB_FLOOR)
entry_script(arc, aid_room)
spots = [(x, 2) for x in range(1, 7)] + [(x, 5) for x in range(2, 7)]
for (x, y), fam in zip(spots, FAMILIES):
    paint(alay, x, y - 1, SHELF_TOP)
    paint(alay, x, y, SHELF_BOT)
arc = d.room(aid_room)
for (x, y), fam in zip(spots, FAMILIES):
    d.add_archive(arc, '0', 0, x, y, fam, name=f'{fam.upper()} SHELF')
talker(aid_room, 8, 3, 0x0B, [{'say': B(
    'THE GREAT ARCHIVE. Eleven bookcases, one per family: top row Slime, Dragon, Beast, '
    'Bird, Plant, Bug; bottom row Devil, Zombie, Material, Boss, Spirit. Each lists the '
    'crosses you have learned for its family; (bred) marks the ones you have made.')}],
    'archivist')

# ---- the EXIT GUIDEs + the way in --------------------------------------------------
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)
g_mid = int(d.room(gid)['mapID'], 16)
a_mid = int(d.room(aid_room)['mapID'], 16)
talker(gid, 4, 6, 0x1F, [
    {'ask': B('I am the EXIT GUIDE. To THE GREAT ARCHIVE?', choice=True),
     'yes': [{'move': {'dest': f'room:${a_mid:02X}', 'screen': 0, 'x': 7, 'y': 6}}],
     'no': [{'ask': B('Back to the city, then?', choice=True),
             'yes': [{'move': {'dest': f'room:${c_mid:02X}', 'screen': 0, 'x': 4, 'y': 5}}],
             'no': [{'say': B('Stay as long as you like.')}]}]}], 'garden_exit')
talker(aid_room, 8, 6, 0x1F, [
    {'ask': B('I am the EXIT GUIDE. Back to THE STONE GARDEN?', choice=True),
     'yes': [{'move': {'dest': f'room:${g_mid:02X}', 'screen': 0, 'x': 4, 'y': 5}}],
     'no': [{'say': B('Read as long as you like.')}]}], 'archive_exit')
talker('cities_fount', 3, 4, 0x0B, [{'ask': B('I am the HINT GUIDE. To THE STONE '
                                              'GARDEN?', choice=True),
                                     'yes': [{'move': {'dest': f'room:${g_mid:02X}',
                                                       'screen': 0, 'x': 4, 'y': 5}}],
                                     'no': [{'say': B('Another time.')}]}], 'hint_guide')

# ---- THE RUNE CRYPT: served on gate 2's second floor --------------------------------
crypt_id = d.new_room('RUNE CRYPT', 0, r, gate_theme=9)
crypt = d.room(crypt_id)
clay = crypt['screens']['0']['layout']['id']
WALL = [0x08, 0x09, 0x18, 0x19]
for cx in range(10):
    paint(clay, cx, 0, WALL)
    paint(clay, cx, 7, WALL)
for cy in range(8):
    paint(clay, 0, cy, WALL)
    paint(clay, 9, cy, WALL)
entry_script(crypt, crypt_id)
# the pillar, borrowed from the Room of Beginning's sheet (the editor's "borrow tiles")
rec23 = r.vanilla_record(0x23)
sheet23 = r.rom_sheet(int(rec23['gfx_bank'], 16), int(rec23['gfx_id'], 16))
from editor2.core.document import VocabReleaseWouldHelp       # noqa: E402
d._room_sheet(d.room(crypt_id), '0', 0, 1, 1)           # the theme sheet -> the room's own copy
mts = []
for tiles in (PILLAR_TOP, PILLAR_BOT):
    crypt = d.room(crypt_id)
    try:
        mt = d.import_metatile(crypt, {'tiles': tiles, 'pal': 0}, sheet23, 0x20, name='Pillar')
    except VocabReleaseWouldHelp:                       # a theme sheet is all vocabulary:
        d.set_released(d.room(crypt_id)['record']['tileset'], True)   # release it, as the
        crypt = d.room(crypt_id)                                       # editor offers
        mt = d.import_metatile(crypt, {'tiles': tiles, 'pal': 0}, sheet23, 0x20, name='Pillar')
    mts.append(mt['tiles'])
crypt = d.room(crypt_id)
clay = crypt['screens']['0']['layout']['id']
paint(clay, 5, 2, mts[0])
paint(clay, 5, 3, mts[1])
crypt = d.room(crypt_id)
d.add_monument(crypt, '0', 0, 5, 3, name='CRYPT PILLAR')
talker(crypt_id, 2, 5, 0x0B, [{'say': B(
    'THE RUNE CRYPT, deep in a gate: its PILLAR is a monument (any family). The STAIRS '
    '(right) go on down.')}], 'crypt_sign')
crypt = d.room(crypt_id)
d.add_stairs(crypt, '0', 0, 8, 6)
d.set_gate_arrival(crypt, 0, 4, 5)
rules = d.gate_inserts()
rules.insert(0, {'room': crypt_id, 'gate': 2, 'floors': [2], 'chance': 100,
                 'once_per_dive': True})
d.set_gate_inserts(rules)

d.save(dst)
print('garden', gid, hex(g_mid), 'archive', aid_room, hex(a_mid), 'crypt', crypt_id,
      d.room(crypt_id)['mapID'], 'monuments', m1, m2, m3, 'hints', HINTS)
