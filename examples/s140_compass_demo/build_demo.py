"""S140 demo (ROADMAP ARC CAP3a — regions): the COMPASS LODGES on the user's project.

Thirty-six BRAND-NEW rooms in FOUR REGIONS — COMPASS LODGE 0-1 .. 0-9 in region 0,
1-1 .. 1-9 in region 1, 2-1 .. 2-9 in region 2, 3-1 .. 3-9 in region 3. A region's
lodges have the map ids $76-$7E, so EVERY map id is used four times: lodge r-k is
project mapID (r << 8) | ($75 + k) — the game tells them apart by the region
(wMapRegion), not by the map id. Each lodge is one screen in its own gate theme,
plays its REGION's song (region 0 $09, 1 $1E, 2 $31, 3 $61), and the lodges with
an odd number have two LANTERNS that flip (their own animated tiles — two lodges
with the same map id in different regions animate differently).

  * a GUIDE (top left) names the lodge, its region and map id and offers to send
    you to the lodge with the SAME map id in the NEXT region (YES; region 3 sends
    you back to region 0) — a script warp across regions;
  * a MONSTER (top right) to fight — after the battle you must be in the same lodge;
  * STAIRS: top right = up to the next lodge, top left = down to the one before;
    the stairs between lodge r-9 and lodge (r+1)-1 cross from one region into
    the next (an exit row with a region: a LINK id); lodge 3-9's "up" stairs lead
    into the game's GreatTree (a vanilla room — you are still in region 3 there):
    the GreatTree door to Cities_FOUNT (a redirect of a vanilla door) brings you
    back to region 0, and the GreatTree door to the Arena Lobby (a GLOBAL place)
    works from any region;
  * lodge 3-5 has a SCRIBE: save with the JOURNAL there, reset and CONTINUE —
    you must wake up in COMPASS LODGE 3-5 (the region is saved).

Way in: the S140 DEMO NPC in Cities_FOUNT at (3, 4).

    python3 examples/s140_compass_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json; the script
writes the lanterns' tileset copies into it).
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document
from editor2.core.render_project import ProjectRenderer
from editor2.core import textenc as T

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

REGIONS, PER = 4, 9
FIRST = 0x76
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
LANTERN = 0x50                                   # free theme slots
SONGS = ['0x09', '0x1E', '0x31', '0x61']
MONSTERS = [3, 7, 11, 15, 19, 25, 33, 44, 53]
GREATTREE = {'dest': 'vanilla:$01', 'screen_byte': '0x04', 'spawn_x': 4, 'spawn_y': 3}


def B(*paras):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out}


def tile(pix):
    out = bytearray()
    for row in pix:
        lo = hi = 0
        for c in row:
            lo = (lo << 1) | (c & 1)
            hi = (hi << 1) | (c >> 1)
        out += bytes((lo, hi))
    return bytes(out)


def lantern(f, k, n):
    """Lantern frame f (0-3), quarter k of the cell — a glow, its size by lodge."""
    pix = []
    for y in range(8):
        row = []
        for x in range(8):
            gx, gy = 8 * (k & 1) + x, 8 * (k >> 1) + y
            dd = abs(gx - 7.5) + abs(gy - 7.5)
            rad = 2 + 2 * f + (n % 3)
            row.append(3 if dd < 2 else 1 if dd < rad else 2 if dd < rad + 1.5 else 0)
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


lodges = []                                      # in walking order: 0-1 .. 3-9
for reg in range(REGIONS):
    for k in range(PER):
        n = reg * PER + k
        rid = d.new_room(f'COMPASS LODGE {reg}-{k + 1}', 0, r, gate_theme=(5 * reg + k) % 16)
        room = d.room(rid)
        mid = (reg << 8) | (FIRST + k)
        room['mapID'] = f'0x{mid:02X}' if reg == 0 else f'0x{mid:03X}'
        room['music'] = SONGS[reg]
        lid = room['screens']['0']['layout']['id']
        anim = k % 2 == 0                            # lodges 1, 3, 5, 7, 9
        if anim:
            tid = d.localize_tileset(room, r.theme_gfx((5 * reg + k) % 16).sheet,
                                     name=f'ts_compass_lodge_{reg}_{k + 1}')
            sheet = d.read_sheet(tid)
            for c in range(2):
                for q in range(4):
                    s = LANTERN + 4 * c + q
                    sheet[s * 16:s * 16 + 16] = lantern(c, q, n)
            d.write_sheet(tid, sheet)
        pal = floor_pal(lid)
        for cx in range(10):
            paint(lid, cx, 0, WALL, pal)
            paint(lid, cx, 7, WALL, pal)
        for cy in range(8):
            paint(lid, 0, cy, WALL, pal)
            paint(lid, 9, cy, WALL, pal)
        if n > 0:
            paint(lid, 1, 1, STAIRS, pal)            # down
        paint(lid, 8, 1, STAIRS, pal)                # up (3-9: to the GreatTree)
        if anim:
            paint(lid, 2, 6, [LANTERN + i for i in range(4)], pal)
            paint(lid, 7, 6, [LANTERN + 4 + i for i in range(4)], pal)
            lf = [[lantern((c + f) % 4, q, n).hex() for c in range(2) for q in range(4)]
                  for f in (1, 2, 3)]
            room['tile_anims'] = [{'id': 'lanterns', 'name': 'Lanterns', 'motion': 'flip',
                                   'speed': 12 + 4 * reg, 'order': 'loop',
                                   'rows': [[LANTERN + i for i in range(8)]], 'frames': lf}]
        guide = d.add_npc(room, '0', 0, 3, 2, 0x0B, 'down')
        mon = d.add_npc(room, '0', 0, 6, 2, 0xF0, 'down', monster=MONSTERS[k])
        enemy = d.add_enemy(copy_eid=2, name=f'Lodge foe {reg}-{k + 1}', species=MONSTERS[k],
                            level=1, hp=1, joinability=7)
        scribe = d.add_npc(room, '0', 0, 4, 5, 0x0C, 'down') if (reg, k) == (3, 4) else None
        lodges.append({'id': rid, 'mid': mid, 'reg': reg, 'k': k, 'guide': guide,
                       'mon': mon, 'enemy': enemy, 'scribe': scribe, 'anim': anim})

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')

for n in range(len(lodges) - 1):
    a = d.add_door(lodges[n]['id'], '0', 8, 1, name=f'Lodge stairs {n + 1} up')
    b = d.add_door(lodges[n + 1]['id'], '0', 1, 1, name=f'Lodge stairs {n + 2} down')
    d.link_doors(a, b)
last = d.room(lodges[-1]['id'])
last['screens']['0']['exits'].append(dict(GREATTREE, x=8, y=1, gate_flag=0,
                                          comment='S140: up the stairs into the GreatTree '
                                                  '(a vanilla room; still region 3)'))


def dest(lo):
    return f"room:${lo['mid']:X}"


for i, lo in enumerate(lodges):
    room = d.room(lo['id'])
    reg, k = lo['reg'], lo['k']
    nxt = next(x for x in lodges if x['reg'] == (reg + 1) % REGIONS and x['k'] == k)
    what = 'Its lanterns flicker on their own. ' if lo['anim'] else ''
    steps = [{'say': B(f"COMPASS LODGE {reg}-{k + 1}: region {reg}, map {lo['mid'] & 0xFF:02X}. "
                       + what + f"Lodge {nxt['reg']}-{k + 1} next door has the same map "
                       f"{lo['mid'] & 0xFF:02X} in region {nxt['reg']}.")},
             {'ask': B(f"Shall I send you to lodge {nxt['reg']}-{k + 1}?"),
              'yes': [{'move': {'dest': dest(nxt), 'screen': 0, 'x': 5, 'y': 3}}],
              'no': [{'say': B('Then take the stairs: up is the next lodge.')}]}]
    sid = d.new_conversation(room, {'steps': steps}, name='guide')
    d.update_npc(room, '0', 0, lo['guide'], script=sid)
    mon = [{'ask': B(f'I am the monster of lodge {reg}-{k + 1}. Fight me?'),
            'yes': [{'battle': {'enemies': [lo['enemy']]}},
                    {'say': B(f'You won! This is still lodge {reg}-{k + 1}.')}],
            'no': [{'say': B('Another time.')}]}]
    sid = d.new_conversation(room, {'steps': mon}, name='monster')
    d.update_npc(room, '0', 0, lo['mon'], script=sid)
    if lo['scribe'] is not None:
        sc = [{'say': B('I am the SCRIBE of lodge 3-5. Save with the JOURNAL here, '
                        'turn the game off and CONTINUE.',
                        'You must wake up here, in region 3, not in lodge 0-5 or the castle.')}]
        sid = d.new_conversation(room, {'steps': sc}, name='scribe')
        d.update_npc(room, '0', 0, lo['scribe'], script=sid)

demo = [{'ask': B('S140 DEMO: the COMPASS LODGES, 36 rooms in 4 regions. Every map id is '
                  'used four times. Go?'),
         'yes': [{'move': {'dest': dest(lodges[0]), 'screen': 0, 'x': 5, 'y': 3}}],
         'no': [{'say': B('Another time!')}]}]
sid = d.new_conversation(cities, {'steps': demo}, name='s140demo')
d.update_npc(cities, '0', 0, k_demo, script=sid)
d.save(dst)
print('lodges', ' '.join(f"{lo['mid']:#05x}" for lo in lodges))
