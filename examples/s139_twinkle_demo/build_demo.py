"""S139 demo (ROADMAP ARC CAP2d): the TWINKLE CAVES on the user's project.

Twelve BRAND-NEW rooms, TWINKLE CAVE 1-12, each one screen in its own gate theme
(its own project tileset — a copy of the theme's sheet with new art drawn into the
theme's empty slots $40+) and HEAVY animated tiles of its own:

  * a RIVER — a strip 2 cells wide drifting right (odd caves) or left (even caves),
    32 frames of 8 tiles = 4 KB of frames; caves 1, 4, 7, 10 have a SECOND river
    drifting the other way;
  * two LANTERNS that flip through 4 frames (pingpong in even caves);
  * a BANNER that sways back and forth.

That is more frame data than bank $6C holds next to the user's own animations, so
the compiler's first fit (editor2/core/tileanim.py plan) puts the first caves in
bank $6C and the rest in new ANIMATION BANKS of the 4 MB ROM ($8x). Each cave:

  * a LAMPLIGHTER (top left) names the cave, its map id and THE BANK ITS TILES PLAY
    FROM, and offers to send you on to the next cave (YES) — the last one sends you
    back to the fountain;
  * a MONSTER (top right) to fight — after the battle the river must still flow;
  * STAIRS: top right corner = up to the next cave, top left corner = down to the one
    before.

Way in: the S139 DEMO NPC in Cities_FOUNT at (3, 4).

    python3 examples/s139_twinkle_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json; the script
writes the caves' tileset copies into it).
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
from editor2.core import tileanim as TA

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

N = 12
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
MONSTERS = [3, 7, 11, 15, 19, 25, 33, 44, 53, 66, 80, 91]
RIVER_A, RIVER_B, LANTERN, BANNER = 0x40, 0x48, 0x50, 0x58      # free theme slots


def B(*paras):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out}


def tile(pix):
    """8 rows of 8 colour indices (0-3) -> 16-byte 2bpp tile."""
    out = bytearray()
    for row in pix:
        lo = hi = 0
        for c in row:
            lo = (lo << 1) | (c & 1)
            hi = (hi << 1) | (c >> 1)
        out += bytes((lo, hi))
    return bytes(out)


def wave(n, k, y0):
    """River art: tile k of a 4-tile row — a band of waves, unique per cave."""
    pix = []
    for y in range(8):
        row = []
        for x in range(8):
            gx = 8 * k + x
            h = (gx * (2 + n % 3) // 3 + y0 + y + n) % 8
            row.append(3 if h == 0 else 2 if h in (1, 7) else 0 if h in (3, 4, 5) else 1)
        pix.append(row)
    return tile(pix)


def lantern(f, k, n):
    """Lantern frame f (0-3), quarter k of the cell: a glow that grows."""
    pix = []
    for y in range(8):
        row = []
        for x in range(8):
            gx, gy = 8 * (k & 1) + x, 8 * (k >> 1) + y
            dd = abs(gx - 7.5) + abs(gy - 7.5)
            rad = 3 + 2 * f + (n % 2)
            row.append(3 if dd < 2 else 1 if dd < rad else 2 if dd < rad + 1.5 else 0)
        pix.append(row)
    return tile(pix)


def banner(k, n):
    pix = []
    for y in range(8):
        row = []
        for x in range(8):
            gx, gy = 8 * (k & 1) + x, 8 * (k >> 1) + y
            row.append(0 if gx in (0, 15) else 3 if (gx + gy + n) % 6 == 0 else
                       2 if gy < 4 else 1)
        pix.append(row)
    return tile(pix)


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


def river(n, slot0, motion, speed):
    return {'id': f'river_{slot0:02x}', 'name': 'River', 'motion': motion,
            'speed': speed, 'strip': True,
            'rows': [[slot0 + i for i in range(4)], [slot0 + 4 + i for i in range(4)]]}


caves = []
for n in range(N):
    rid = d.new_room(f'TWINKLE CAVE {n + 1}', 0, r, gate_theme=n)
    room = d.room(rid)
    tid = d.localize_tileset(room, r.theme_gfx(n).sheet, name=f'ts_twinkle_cave_{n + 1}')
    sheet = d.read_sheet(tid)
    put = lambda s, b: sheet.__setitem__(slice(s * 16, s * 16 + 16), b)
    for k in range(4):
        put(RIVER_A + k, wave(n, k, 0))
        put(RIVER_A + 4 + k, wave(n, k, 4))
        put(RIVER_B + k, wave(n + 5, k, 2))
        put(RIVER_B + 4 + k, wave(n + 5, k, 6))
    for c in range(2):                         # two lanterns, frame 0 = the sheet
        for k in range(4):
            put(LANTERN + 4 * c + k, lantern(c, k, n))
    for k in range(4):
        put(BANNER + k, banner(k, n))
    d.write_sheet(tid, sheet)
    lid = room['screens']['0']['layout']['id']
    pal = floor_pal(lid)
    for cx in range(10):
        paint(lid, cx, 0, WALL, pal)
        paint(lid, cx, 7, WALL, pal)
    for cy in range(8):
        paint(lid, 0, cy, WALL, pal)
        paint(lid, 9, cy, WALL, pal)
    if n > 0:
        paint(lid, 1, 1, STAIRS, pal)           # down
    if n < N - 1:
        paint(lid, 8, 1, STAIRS, pal)           # up
    paint(lid, 3, 4, [RIVER_A, RIVER_A + 1, RIVER_A + 4, RIVER_A + 5], pal)
    paint(lid, 4, 4, [RIVER_A + 2, RIVER_A + 3, RIVER_A + 6, RIVER_A + 7], pal)
    two = n % 3 == 0
    if two:
        paint(lid, 5, 5, [RIVER_B, RIVER_B + 1, RIVER_B + 4, RIVER_B + 5], pal)
        paint(lid, 6, 5, [RIVER_B + 2, RIVER_B + 3, RIVER_B + 6, RIVER_B + 7], pal)
    paint(lid, 2, 6, [LANTERN + i for i in range(4)], pal)
    paint(lid, 7, 6, [LANTERN + 4 + i for i in range(4)], pal)
    paint(lid, 8, 4, [BANNER + i for i in range(4)], pal)
    left_first = n % 2 == 1
    anims = [river(n, RIVER_A, 'drift_left' if left_first else 'drift_right', 6 + 2 * (n % 3))]
    if two:
        anims.append(river(n, RIVER_B, 'drift_right' if left_first else 'drift_left', 8))
    lf = [[lantern((c + f) % 4, k, n).hex() for c in range(2) for k in range(4)]
          for f in (1, 2, 3)]
    anims.append({'id': 'lanterns', 'name': 'Lanterns', 'motion': 'flip', 'speed': 20,
                  'order': 'pingpong' if n % 2 else 'loop',
                  'rows': [[LANTERN + i for i in range(8)]], 'frames': lf})
    anims.append({'id': 'banner', 'name': 'Banner', 'motion': 'sway', 'speed': 12,
                  'amplitude': 2, 'strip': True,
                  'rows': [[BANNER, BANNER + 1], [BANNER + 2, BANNER + 3]]})
    room['tile_anims'] = anims
    lamp = d.add_npc(room, '0', 0, 3, 2, 0x0B, 'down')
    mon = d.add_npc(room, '0', 0, 6, 2, 0xF0, 'down', monster=MONSTERS[n])
    enemy = d.add_enemy(copy_eid=2, name=f'Cave foe {n + 1}', species=MONSTERS[n],
                        level=1, hp=1, joinability=7)
    caves.append({'id': rid, 'mid': int(room['mapID'], 16), 'lamp': lamp, 'mon': mon,
                  'enemy': enemy, 'sid': None, 'two': two})

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')

for n in range(N - 1):
    a = d.add_door(caves[n]['id'], '0', 8, 1, name=f'Cave stairs {n + 1} up')
    b = d.add_door(caves[n + 1]['id'], '0', 1, 1, name=f'Cave stairs {n + 2} down')
    d.link_doors(a, b)


def write_texts(home):
    for i, c in enumerate(caves):
        room = d.room(c['id'])
        nxt = caves[i + 1] if i + 1 < N else None
        bank = home.get(c['mid'], (0, 0))[0]
        what = 'two rivers, lanterns and banner' if c['two'] else 'river, lanterns and banner'
        lamp = [{'say': B(f"TWINKLE CAVE {i + 1}, map {c['mid']:02X}. Its {what} play "
                          f"from bank {bank:02X}.",
                          'Fight the monster, then look: the water must still flow.')},
                {'ask': B('Shall I send you on to the next cave?' if nxt else
                          'This is the last cave. Shall I send you back to the fountain?'),
                 'yes': [{'move': {'dest': (f"room:${nxt['mid']:02X}" if nxt
                                            else f'room:${cities_mid:02X}'),
                                   'screen': 0, 'x': 5, 'y': 3}}],
                 'no': [{'say': B('Then stay and watch the water.')}]}]
        if c['sid'] is None:
            c['sid'] = d.new_conversation(room, {'steps': lamp}, name='lamplighter')
            d.update_npc(room, '0', 0, c['lamp'], script=c['sid'])
            mon = [{'ask': B(f'I am the monster of TWINKLE CAVE {i + 1}. Fight me?'),
                    'yes': [{'battle': {'enemies': [c['enemy']]}},
                            {'say': B('You won! Is the river still flowing?')}],
                    'no': [{'say': B('Another time.')}]}]
            sid = d.new_conversation(room, {'steps': mon}, name='monster')
            d.update_npc(room, '0', 0, c['mon'], script=sid)
        else:
            d.set_conversation(c['sid'], {'steps': lamp})
    demo = [{'ask': B('S139 DEMO: the TWINKLE CAVES. Their animated tiles fill bank 6C and '
                      'new banks. Go?'),
             'yes': [{'move': {'dest': f"room:${caves[0]['mid']:02X}", 'screen': 0,
                               'x': 5, 'y': 3}}],
             'no': [{'say': B('Another time!')}]}]
    if not hasattr(write_texts, 'sid'):
        write_texts.sid = d.new_conversation(cities, {'steps': demo}, name='s139demo')
        d.update_npc(cities, '0', 0, k_demo, script=write_texts.sid)
    else:
        d.set_conversation(write_texts.sid, {'steps': demo})


def plan_now():
    prj = Project(copy.deepcopy(d.data), d.project_dir)
    prj.repo_root = REPO
    return TA.plan(prj)


write_texts({})
for _ in range(3):                             # the texts may move a place bank
    p = plan_now()
    write_texts(p['home'])
assert plan_now()['home'] == p['home'], 'the texts keep moving the animation banks'
d.save(dst)
print('caves', ', '.join(f"{c['mid']:#04x}" for c in caves))
print('animation banks', ', '.join(f'${b:02X}' for b in p['overflow']))
for i, c in enumerate(caves):
    b, k = p['home'][c['mid']]
    print(f"  CAVE {i + 1:2d} {c['mid']:#04x}: bank ${b:02X} index {k}, "
          f"{p['room_bytes'][c['mid']]} B")
print('used', {f'${b:02X}': u for b, u in p['used'].items()})
