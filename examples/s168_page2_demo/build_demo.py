"""S168 demo (ROADMAP P3.3g — PAGE 2, the second 128 tiles of a tileset): THE NUMBERED
GALLERY on the user's project.

A new room of two screens drawn with 168 different tiles: every tile shows its own number in
two hex digits — PAGE 1 tiles (00-37) on a plain background, PAGE 2 tiles (00-7F) on a striped
background, so the eye tells the pages apart; the walls are numbered too. 168 different tiles
on the first screen alone (the game's limit was 128 a room). S168 r2: page-1 tiles 38-7F are
left empty — Grandpa's breeding screens draw into those slots while the room shows. Every window of the game opens
over page-2 cells here, so the letters and the art must stay clean:

  * screen 0 (west): the GALLERY CURATOR (what this is; a YES / NO question; YES = back to
    the city), the SHOPKEEPER (the Bazaar's list), GRANDPA (breeding);
  * screen 1 (east): the VAULT KEEPER, the LIBRARIAN (a full screen), the SPARRING SLIME (a
    battle); a strip of page-2 tiles BLINKS (an own animation on page 2).

Way in: the GALLERY CURATOR in Cities_FOUNT at (3, 4) (YES = to the gallery).

    python3 examples/s168_page2_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json).
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document                       # noqa: E402
from editor2.core.render_project import ProjectRenderer          # noqa: E402
from editor2.core import textenc as T                            # noqa: E402
from editor2.core import page2 as P2                             # noqa: E402

args = [a for a in sys.argv[1:] if not a.startswith('--')]
src, dst = args[0], args[1] if len(args) > 1 else args[0]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)
d.vanilla = r

# ---- the art: 256 numbered tiles -----------------------------------------------------------
FONT = {  # 3 x 5 hex digits, rows top to bottom, bit 2 = left
    '0': [7, 5, 5, 5, 7], '1': [2, 6, 2, 2, 7], '2': [7, 1, 7, 4, 7], '3': [7, 1, 3, 1, 7],
    '4': [5, 5, 7, 1, 1], '5': [7, 4, 7, 1, 7], '6': [7, 4, 7, 5, 7], '7': [7, 1, 1, 2, 2],
    '8': [7, 5, 7, 5, 7], '9': [7, 5, 7, 1, 7], 'A': [7, 5, 7, 5, 5], 'B': [6, 5, 6, 5, 6],
    'C': [7, 4, 4, 4, 7], 'D': [6, 5, 5, 5, 6], 'E': [7, 4, 6, 4, 7], 'F': [7, 4, 6, 4, 4]}


def tile(n, page):
    """8 x 8 colour indices: background (page 1 plain colour 0, page 2 stripes 0 / 2), the
    number in colour 3 (black) at rows 2-6, a colour-2 frame line on the top row."""
    px = [[0] * 8 for _ in range(8)]
    for y in range(8):
        for x in range(8):
            if page == 2 and (x + y) % 4 == 0:
                px[y][x] = 2
    for x in range(8):
        px[0][x] = 2 if page == 1 else 1
    s = f'{n:02X}'
    for k, ch in enumerate(s):
        for yy, bits in enumerate(FONT[ch]):
            for xx in range(3):
                if bits & (4 >> xx):
                    px[2 + yy][k * 4 + xx] = 3
    return px


def to2bpp(px):
    out = bytearray(16)
    for y in range(8):
        lo = hi = 0
        for x in range(8):
            c = px[y][x]
            lo |= (c & 1) << (7 - x)
            hi |= ((c >> 1) & 1) << (7 - x)
        out[2 * y], out[2 * y + 1] = lo, hi
    return bytes(out)


SHEET = b''.join(to2bpp(tile(n, 1)) if n < 0x38 else bytes(16) for n in range(128)) + \
    b''.join(to2bpp(tile(n, 2)) for n in range(128))
THR = 0x10                                    # slots 0-15 (and page-2 0-15) are walls


def B(*paras, choice=False):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out, **({'choice': True} if choice else {})}


def go_to(mid, x=4, y=5):
    return {'move': {'dest': f'room:${mid:02X}', 'screen': 0, 'x': x, 'y': y}}


# ---- the room ------------------------------------------------------------------------------
gid = d.new_room('NUMBERED GALLERY', 0x00, r, blank_tileset=True)
room = d.room(gid)
tid = room['record']['tileset']
room['record']['collision_threshold'] = f'0x{THR:02X}'
d.write_sheet(tid, SHEET)
words = [[0x7F7B, 0x6BFF, 0x4E73, 0x0000],    # 0: grey-blue
         [0x5FFF, 0x6BFF, 0x2B7F, 0x0000],    # 1: yellow
         [0x6BF7, 0x6BFF, 0x2EE9, 0x0000],    # 2: green
         [0x63DF, 0x6BFF, 0x315F, 0x0000],    # 3: red
         ] + [[0x6BFF, 0x6BFF, 0x0000, 0x0000]] * 4
pid = d.add_palette_from_words('pal_gallery', words, 'S168 demo: four colours for the numbers')
room['render']['palette'] = pid
lay0 = room['screens']['0']['layout']['id']


def V(slot):
    return P2.value_of(slot)


def cells(lid, rng):
    """Fill the room's inner cells (1-8 x 1-6) with metatiles of 4 consecutive slots from
    rng; returns the slots used."""
    g = d.layout(lid)['tiles']
    a = d.layout(lid)['attr']
    it = iter(rng)
    used = []
    for cy in range(1, 7):
        for cx in range(1, 9):
            try:
                q = [next(it) for _ in range(4)]
            except StopIteration:
                return used
            for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
                g[2 * cy + dr][2 * cx + dc] = V(q[j])
                a[2 * cy + dr][2 * cx + dc] = (cx + cy) % 4
            used += q
    return used


def walls(lid, offset):
    g = d.layout(lid)['tiles']
    a = d.layout(lid)['attr']
    ring = [(cx, 0) for cx in range(10)] + [(cx, 7) for cx in range(10)] + \
           [(0, cy) for cy in range(1, 7)] + [(9, cy) for cy in range(1, 7)]
    for i, (cx, cy) in enumerate(ring):
        page_base = 0 if i % 2 == 0 else 128
        q = [page_base + ((offset + i * 4 + k) % 16) for k in range(4)]
        for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
            g[2 * cy + dr][2 * cx + dc] = V(q[j])
            a[2 * cy + dr][2 * cx + dc] = 3


# S168 r2: page-1 slots $38-$7F stay EMPTY — Grandpa's breeding screens draw their words and
# icons there while the room shows (services.BORROWED_SLOTS; the user's report "Breed/hatch/
# exit menu ... creates visual glitches of words on the screen"); make_service_npc would move
# tiles placed there to page 2, and with 256 tiles in use there was no room left
P1 = list(range(0x10, 0x38))                       # page-1 floor tiles (40)
P2F = [128 + s for s in range(0x10, 0x80)]         # page-2 floor tiles (112)
# screen 0: page-1 / page-2 $10-$37 alternating cells, then page-2 $38-$7F
mix0 = []
for k in range(10):
    mix0 += P1[4 * k:4 * k + 4] + P2F[4 * k:4 * k + 4]
mix0 += P2F[40:] + P1                  # 48 cells (page 1 twice)
walls(lay0, 0)
cells(lay0, mix0)
# screen 1: every page-2 floor tile again, then page 1 (the blinking strip at row 3)
lay1 = d.unique_layout_id(f'{gid}_s1')
d.add_layout(lay1, tiles=[list(x) for x in d.layout(lay0)['tiles']],
             attr=[list(x) for x in d.layout(lay0)['attr']])
d.add_screen(d.room(gid), 1, {'id': lay1})
mix1 = P2F + P1 + P2F[:40]
walls(lay1, 8)
cells(lay1, mix1)
for lid, cx in ((lay0, 9), (lay1, 0)):                 # the passage between the screens
    g = d.layout(lid)['tiles']
    for j, (dr, dc) in enumerate(((0, 0), (0, 1), (1, 0), (1, 1))):
        g[2 * 4 + dr][2 * cx + dc] = V(128 + 64 + j)
room = d.room(gid)
room['record']['width_px'] = 320
room.setdefault('scripts', {})
if '0' not in room['scripts']:
    room['scripts']['0'] = f'{gid}_entry'
    d.custom['scripts'].append({'id': room['scripts']['0'], 'ops': [['end']]})

# the blinking strip: screen 1 row 3 cells 2-5 (page-2 slots), flip to page-1 art and back
g1 = d.layout(lay1)['tiles']
strip = [P2.slot_of(g1[6][c]) for c in range(4, 12)]
room['tile_anims'] = [{
    'id': 'p2blink', 'name': 'Page-2 blink', 'motion': 'flip', 'speed': 24,
    'rows': [strip],
    'frames': [[to2bpp(tile(s & 0x7F, 1)).hex() for s in strip]]}]

SLIME = 0
sparring = d.add_enemy(copy_eid=2, name='Number slime', species=SLIME, level=5, hp=60, mp=0,
                       atk=1, **{'def': 1}, agl=1, int=1, joinability=0, skills=[])


def npc(key, x, y, sprite, steps, name, monster=None):
    rm = d.room(gid)
    d.add_npc(rm, key, 0, x, y, sprite, 'down', **({'monster': monster} if monster else {}))
    k = len(d.npc_entries(rm, key, 0)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, key, 0, k, script=sid)


def service(key, x, y, sprite, kind):
    rm = d.room(gid)
    d.add_npc(rm, key, 0, x, y, sprite, 'down')
    k = len(d.npc_entries(rm, key, 0)) - 1
    if kind == 'shop':
        return d.make_shopkeeper(rm, key, 0, k, 'bazaar')
    return d.make_service_npc(rm, key, 0, k, kind)


cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)
npc('0', 2, 2, 0x0B, [{'ask': B(
    'THE NUMBERED GALLERY. Every tile here shows its number: plain ones are page 1, striped '
    'ones are page 2 - 168 tiles in one room. Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Look around. Every window should stay clean '
                                            'over the striped tiles.')}]}], 'gallery_curator')
service('0', 5, 6, 0x1D, 'shop')
service('0', 7, 3, 0x0B, 'grandpa')
gp_note = getattr(d, 'last_service_note', '')
service('1', 2, 2, 0x1D, 'vault')
service('1', 5, 6, 0x0B, 'library')
npc('1', 7, 3, 0x10, [
    {'ask': B('I am the SPARRING SLIME. A gentle fight on the numbered floor?', choice=True),
     'yes': [{'battle': {'enemies': [sparring]}}, {'say': B('The floor kept its numbers!')}],
     'no': [{'say': B('Another time.')}]}], 'gallery_spar', monster=SLIME)

g_mid = int(d.room(gid)['mapID'], 16)
rm = d.room('cities_fount')
d.add_npc(rm, '0', 0, 3, 4, 0x0B, 'down')
k = len(d.npc_entries(rm, '0', 0)) - 1
sid = d.new_conversation(rm, {'steps': [{'ask': B(
    'I am the GALLERY CURATOR. To the NUMBERED GALLERY, a room of 168 numbered tiles?',
    choice=True), 'yes': [go_to(g_mid, 4, 5)], 'no': [{'say': B('Another time.')}]}]},
    name='gallery_way_in')
d.update_npc(rm, '0', 0, k, script=sid)

d.save(dst)
print('gallery', gid, hex(g_mid), 'tileset', tid, 'spar row', sparring,
      'grandpa:', gp_note or 'no tile had to move')
