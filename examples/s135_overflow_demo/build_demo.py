"""S135 demo (ROADMAP ARC CAP2a): the OVERFLOW HALLS on the user's project.

Sixteen BRAND-NEW rooms, OVERFLOW HALL 1-16, one per gate theme (each its own
project tileset — a copy of that theme's sheet — and colours), three screens each,
all real maze screens of the gates (their own layout + palette grid).
There is more art than banks $64 / $67 still hold for the user's project, so the
compiler's first fit puts the first halls' streams in $64 / $67 and the rest in
the 4 MB ROM's overflow banks ($80, $81, …). Every hall's guide NPC SAYS which
bank its tiles and each of its three screens come from, then offers the next
hall (YES) or Cities_FOUNT (NO). (Short texts: the user's bank $60 has ~3.5 KB
left — scripts and text spill only with ARC CAP2b.) Way in: the S135 DEMO NPC in Cities_FOUNT at (3, 4).

    python3 examples/s135_overflow_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json; the
script writes the new tileset copies into it).
"""
import copy
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document
from editor2.core.project import Project
from editor2.core.render_project import ProjectRenderer
from editor2.core import textenc as T

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

FLOOR = [0x33, 0x33, 0x33, 0x33]          # the themes' plain floor (walkable, >= $30)
N = 16


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
    """The palette slot the maze screen itself uses for its floor tiles."""
    lay = d.layout(lid)
    for rr in range(16):
        for cc in range(20):
            if 0x30 <= lay['tiles'][rr][cc] <= 0x33:
                return lay['attr'][rr][cc]
    return 0


def corridor(lid):
    p = floor_pal(lid)
    for cx in range(10):                   # row 4: the way across both screens
        paint(lid, cx, 4, FLOOR, p)
    for cy in range(2, 7):                 # column 2: around the NPCs
        paint(lid, 2, cy, FLOOR, p)


SCREENS = 3
halls = []
for n in range(N):
    t = n                                  # gate theme n (bank $28 sheet n)
    rid = d.new_room(f'OVERFLOW HALL {n + 1}', 0, r, gate_theme=t)
    room = d.room(rid)
    d.localize_tileset(room, r.theme_gfx(t).sheet, name=f'ts_overflow_hall_{n + 1}')
    for k in range(1, SCREENS):
        d.add_screen(room, k, {'id': room['screens']['0']['layout']['id']})
    lids = []
    for k in range(SCREENS):
        lid = d.stamp_maze_screen(rid, str(k), 0, (((n + 5 * k) % 15) << 4), renderer=r)
        corridor(lid)
        lids.append(lid)
    g = d.add_npc(room, '0', 0, 2, 3, 0x0B, 'down')
    halls.append({'id': rid, 'mid': int(room['mapID'], 16), 'guide': g,
                  'tileset': room['record']['tileset'], 'lids': lids, 'sid': None})

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')


def where(plan, key):
    return plan['where'][key][0]


def write_texts(plan):
    for i, h in enumerate(halls):
        room = d.room(h['id'])
        ts = where(plan, ('tileset', h['tileset']))
        sb = [where(plan, ('tiles', lid)) for lid in h['lids']]
        nxt = halls[(i + 1) % N]
        banks = ' '.join(f'{b:02X}' for b in sb)
        steps = [{'ask': B(f'OVERFLOW HALL {i + 1}. Tiles: bank {ts:02X}. Screens (walk east): '
                           f'{banks}. Next hall?'),
                  'yes': [{'move': {'dest': f"room:${nxt['mid']:02X}", 'screen': 0,
                                    'x': 2, 'y': 4}}],
                  'no': [{'move': {'dest': f'room:${cities_mid:02X}', 'screen': 0,
                                   'x': 3, 'y': 5}}]}]
        if h['sid'] is None:
            h['sid'] = d.new_conversation(room, {'steps': steps}, name='guide')
            d.update_npc(room, '0', 0, h['guide'], script=h['sid'])
        else:
            d.set_conversation(h['sid'], {'steps': steps})
    demo = [{'ask': B('S135 DEMO: OVERFLOW HALLS, art in the new banks (hex). Go?'),
             'yes': [{'move': {'dest': f"room:${halls[0]['mid']:02X}", 'screen': 0,
                               'x': 2, 'y': 4}}],
             'no': [{'say': B('Another time!')}]}]
    if not hasattr(write_texts, 'demo_sid'):
        write_texts.demo_sid = d.new_conversation(cities, {'steps': demo}, name='s135demo')
        d.update_npc(cities, '0', 0, k_demo, script=write_texts.demo_sid)
    else:
        d.set_conversation(write_texts.demo_sid, {'steps': demo})


def plan_now():
    prj = Project(copy.deepcopy(d.data), d.project_dir)
    prj.repo_root = REPO
    return prj.stream_plan()


write_texts({'where': {k: (0, 0) for k in plan_now()['where']}})
p1 = plan_now()
write_texts(p1)                            # the banks the compiler really uses
assert plan_now()['where'] == p1['where'], 'texts moved a stream (they live in bank $60)'
d.save(dst)
print('halls', ', '.join(f"{h['mid']:#04x}" for h in halls))
print('overflow banks', ', '.join(f'${b:02X}' for b in p1['overflow']))
for i, h in enumerate(halls):
    print(f"  HALL {i + 1:2d} {h['mid']:#04x}: tiles ${where(p1, ('tileset', h['tileset'])):02X}, screens "
          + ' '.join(f"${where(p1, ('tiles', l)):02X}/${where(p1, ('attr', l)):02X}" for l in h['lids']))
