"""S137 demo (ROADMAP ARC CAP2c): the TINTED HALLS on the user's project.

Sixteen BRAND-NEW rooms, TINTED HALL 1-16, each in its own gate theme. Their colours
(render rows + palettes) no longer live in bank $17: they travel with each room into its
HOME BANK (bank $60 or a place bank $80+, editor2/core/places.py), and bank $17 reads
them through bank $60 entry 13 into WRAM. Every hall has:

  * screen 0, two STATES with two palettes: the gate theme's own colours (state 0) and a
    PAINTED tint (state 1, a colour of its own per hall — CRIMSON, AMBER, …). A GUIDE
    says which bank the hall's colours are copied from; a PAINTER paints the hall (YES:
    a flag ON, then the hall reloads -> the state rule picks state 1 -> new colours) or
    washes the paint off again (flag OFF -> state 0). Halls 3, 4, 11, 12 paint with a
    free colour 1 (the engine's cream replaced by a tinted one — the S96 marker);
  * screen 1 (walk east): even halls wear a DUSK palette of their own; odd halls BORROW
    an original room's colours from bank $17 (Castle, GreatTree, Bazaar, Farm, Starry
    Shrine, Library, Well, Monster School) — a KEEPER says which. A MONSTER to fight
    (the colours must come back after the battle) and a LIBRARIAN (the colours must
    come back after the library screen);
  * screen 2 (walk east again), the GALLERY: the other way round — even halls borrow,
    odd halls wear a DAWN palette of their own; a CURATOR says which. (Three screens
    also because the user's save stands on screen 2 of map $78, ECHO ROOM 3 of the S136
    demo: it continues in TINTED HALL 3's gallery.)
  * STAIRS both ways: screen 2 top right = up to the next hall, screen 0 top left = down.

Way in: the S137 DEMO NPC in Cities_FOUNT at (3, 4).

    python3 examples/s137_tint_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json).
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

N = 16
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
MONSTERS = [2, 6, 10, 14, 18, 24, 32, 43, 52, 65, 79, 90, 103, 117, 132, 152]
TINTS = [('CRIMSON', (31, 4, 6)), ('AMBER', (31, 18, 2)), ('GOLD', (30, 27, 4)),
         ('LIME', (18, 30, 4)), ('EMERALD', (3, 26, 10)), ('TEAL', (3, 24, 22)),
         ('AZURE', (6, 20, 31)), ('COBALT', (4, 8, 30)), ('VIOLET', (18, 6, 30)),
         ('ROSE', (31, 10, 20)), ('COPPER', (26, 12, 6)), ('JADE', (8, 22, 14)),
         ('SKY', (16, 26, 31)), ('PLUM', (20, 4, 16)), ('SILVER', (24, 24, 26)),
         ('SAND', (28, 24, 14))]
FREE1 = {2, 3, 10, 11}                     # halls 3, 4, 11, 12 (0-based)
BORROW = [(0x00, 'the CASTLE'), (0x01, 'the GREAT TREE'), (0x02, 'the BAZAAR'),
          (0x04, 'the FARM'), (0x09, 'the STARRY SHRINE'), (0x12, 'the LIBRARY'),
          (0x18, 'the WELL'), (0x1D, 'the MONSTER SCHOOL')]


def B(*paras):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out}


def rgb(c):
    return c & 31, (c >> 5) & 31, (c >> 10) & 31


def pack(r_, g, b):
    return (min(31, max(0, round(r_))) | min(31, max(0, round(g))) << 5
            | min(31, max(0, round(b))) << 10)


def mix(c, tint, k):
    r0, g0, b0 = rgb(c)
    return pack(r0 * (1 - k) + tint[0] * k, g0 * (1 - k) + tint[1] * k,
                b0 * (1 - k) + tint[2] * k)


def paint(lid, cx, cy, mt):
    g = d.layout(lid)['tiles']
    g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1] = mt[0], mt[1]
    g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1] = mt[2], mt[3]


def walls(lid, left, right):
    for cx in range(10):
        paint(lid, cx, 0, WALL)
        paint(lid, cx, 7, WALL)
    for cy in range(8):
        if left:
            paint(lid, 0, cy, WALL)
        if right:
            paint(lid, 9, cy, WALL)


halls = []
for n in range(N):
    rid = d.new_room(f'TINTED HALL {n + 1}', 0, r, gate_theme=n)
    room = d.room(rid)
    theme_pid = room['render']['palette']
    lid = room['screens']['0']['layout']['id']
    lay0 = d.layout(lid)
    lid1 = d.unique_layout_id(f'{rid}_s1')
    d.add_layout(lid1, tiles=copy.deepcopy(lay0['tiles']), attr=copy.deepcopy(lay0['attr']))
    d.add_screen(room, 1, {'id': lid1})
    lid2 = d.unique_layout_id(f'{rid}_s2')
    d.add_layout(lid2, tiles=copy.deepcopy(lay0['tiles']), attr=copy.deepcopy(lay0['attr']))
    d.add_screen(room, 2, {'id': lid2})
    walls(lid, True, False)                # screen 0 opens east into screen 1 …
    walls(lid1, False, False)
    walls(lid2, False, True)               # … and screen 1 into screen 2
    if n > 0:
        paint(lid, 1, 1, STAIRS)           # down (screen 0, top left)
    if n < N - 1:
        paint(lid2, 8, 1, STAIRS)          # up (screen 2, top right)
    words = [list(x) for x in d._theme_words(n)]
    name, tint = TINTS[n]
    pw = [list(x) for x in words]
    for s in range(4):
        pw[s][0] = mix(words[s][0], tint, 0.6)
        pw[s][2] = mix(words[s][2], tint, 0.6)
        if n in FREE1:
            pw[s][1] = mix(0x6BFF, tint, 0.45)
    paint_pid = d.add_palette_from_words(f'pal_{rid}_paint', pw,
                                         f'S137 demo: TINTED HALL {n + 1} painted {name}')
    if n in FREE1:
        d.set_palette_free1(paint_pid, True)
    own_pid = None                         # dusk (screen 1, even) / dawn (screen 2, odd)
    dw = [list(x) for x in words]
    for s in range(4):
        if n % 2 == 0:
            dw[s][0] = mix(words[s][0], (4, 2, 12), 0.55)
            dw[s][2] = mix(words[s][2], (10, 4, 20), 0.5)
        else:
            dw[s][0] = mix(words[s][0], (31, 20, 16), 0.5)
            dw[s][2] = mix(words[s][2], (31, 28, 20), 0.45)
    when = 'at dusk' if n % 2 == 0 else 'at dawn'
    own_pid = d.add_palette_from_words(f"pal_{rid}_{when.split()[1]}", dw,
                                       f'S137 demo: TINTED HALL {n + 1} {when}')
    # one NPC per row (the party fills a row's sprite budget — ROOM_DATA_FORMAT)
    g = d.add_npc(room, '0', 0, 3, 2, 0x0B, 'down')
    painter = d.add_npc(room, '0', 0, 7, 6, 0x0C, 'down')
    keeper = d.add_npc(room, '1', 0, 2, 2, 0x0B, 'down')
    mon = d.add_npc(room, '1', 0, 5, 4, 0xF0, 'down', monster=MONSTERS[n])
    libr = d.add_npc(room, '1', 0, 7, 6, 0x1D, 'down')
    curator = d.add_npc(room, '2', 0, 4, 3, 0x0C, 'down')
    d.make_service_npc(room, '1', 0, libr, 'library')
    enemy = d.add_enemy(copy_eid=2, name=f'Tint foe {n + 1}', species=MONSTERS[n],
                        level=1, hp=1, joinability=7)
    flag = f's137_tint_painted_{n + 1}'
    d.add_flag(flag, comment=f'S137 demo: TINTED HALL {n + 1} is painted {name}')
    halls.append({'id': rid, 'mid': int(room['mapID'], 16), 'guide': g, 'painter': painter,
                  'keeper': keeper, 'mon': mon, 'curator': curator, 'enemy': enemy, 'flag': flag, 'tint': name,
                  'theme_pid': theme_pid, 'paint_pid': paint_pid, 'own_pid': own_pid,
                  'sids': None})

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')


def write_texts(home):
    for i, h in enumerate(halls):
        room = d.room(h['id'])
        hb = home.get(h['mid'], 0)
        nxt = halls[i + 1] if i + 1 < N else None
        free = ' Its paint even changes the light colour (colour 1): a free colour.' \
            if i in FREE1 else ''
        guide = [{'say': B(f'TINTED HALL {i + 1}. I am its guide.',
                           f'The colours of this hall are copied from bank {hb:02X} into '
                           'memory every time the hall is drawn.',
                           'Talk to the painter to paint the hall, then walk east.')},
                 {'ask': B('Shall I send you on to the next hall?' if nxt else
                           'This is the last hall. Shall I send you home?'),
                  'yes': [{'move': {'dest': (f"room:${nxt['mid']:02X}" if nxt
                                             else f'room:${cities_mid:02X}'),
                                    'screen': 0, 'x': 5, 'y': 5}}],
                  'no': [{'say': B('Then look around. The stairs are always there.')}]}]
        here = f"room:${h['mid']:02X}"
        painter = [{'if': [{'flag': h['flag']}],
                    'then': [{'ask': B(f'This hall is painted {h["tint"]}. Shall I wash '
                                       'the paint off?'),
                              'yes': [{'clear': [h['flag']]},
                                      {'say': B('Splash! Back to the gate colours.')},
                                      {'move': {'dest': here, 'screen': 0, 'x': 6, 'y': 5}}],
                              'no': [{'say': B(f'{h["tint"]} suits it, I think.')}]}],
                    'else': [{'ask': B(f'I am the painter. Shall I paint this hall '
                                       f'{h["tint"]}?' + free),
                              'yes': [{'set': [h['flag']]},
                                      {'say': B('Swish! Look at the walls.')},
                                      {'move': {'dest': here, 'screen': 0, 'x': 6, 'y': 5}}],
                              'no': [{'say': B('The gate colours, then. Fine by me.')}]}]}]
        own = (f'a {"DUSK" if i % 2 == 0 else "DAWN"} palette of its own, stored in bank '
               f'{hb:02X} with the rest of the hall.')
        borrow = (f'the colours of {BORROW[(i // 2) % 8][1]}, BORROWED from the original '
                  'game (bank 17).')
        what = 'This screen wears ' + (own if i % 2 == 0 else borrow)
        what2 = 'This gallery wears ' + (borrow if i % 2 == 0 else own)
        keeper = [{'say': B(f'TINTED HALL {i + 1}, the east side. {what}',
                            'Fight the monster or read in the library, and see that the '
                            'colours come back.',
                            'The gallery is further east.')}]
        curator = [{'say': B(f'TINTED HALL {i + 1}, the GALLERY. {what2}',
                             'The stairs at the top right lead up to the next hall.' if nxt
                             else 'This is the last hall. The guide on the west side can '
                             'send you home.')}]
        mon = [{'ask': B(f'I am the monster of TINTED HALL {i + 1}. Fight me?'),
                'yes': [{'battle': {'enemies': [h['enemy']]}},
                        {'say': B('You won! Are the colours of the hall back?')}],
                'no': [{'say': B('Another time.')}]}]
        if h['sids'] is None:
            h['sids'] = {}
            for key, k, idx, steps in (('guide', '0', h['guide'], guide),
                                       ('painter', '0', h['painter'], painter),
                                       ('keeper', '1', h['keeper'], keeper),
                                       ('monster', '1', h['mon'], mon),
                                       ('curator', '2', h['curator'], curator)):
                sid = d.new_conversation(room, {'steps': steps}, name=key)
                d.update_npc(room, k, 0, idx, script=sid)
                h['sids'][key] = sid
        else:
            for key, steps in (('guide', guide), ('painter', painter), ('keeper', keeper),
                               ('monster', mon), ('curator', curator)):
                d.set_conversation(h['sids'][key], {'steps': steps})
    demo = [{'ask': B('S137 DEMO: the TINTED HALLS. Their colours now live with each hall '
                      'in its own bank. Go?'),
             # a fresh start: the hall flags take numbers a save from another build may
             # already have set (the user's S136 save sets $0159-$0167 — the S136 demo's)
             'yes': [{'clear': [h['flag'] for h in halls]},
                     {'move': {'dest': f"room:${halls[0]['mid']:02X}", 'screen': 0,
                               'x': 5, 'y': 5}}],
             'no': [{'say': B('Another time!')}]}]
    if not hasattr(write_texts, 'demo_sid'):
        write_texts.demo_sid = d.new_conversation(cities, {'steps': demo}, name='s137demo')
        d.update_npc(cities, '0', 0, k_demo, script=write_texts.demo_sid)
    else:
        d.set_conversation(write_texts.demo_sid, {'steps': demo})


write_texts({})
# the states, palettes, rules and doors (after the NPCs carry their scripts, so the
# painted state is a copy of state 0 with the same people in it)
for i, h in enumerate(halls):
    room = d.room(h['id'])
    d.add_state(room, '0', copy_from=0)
    d.set_state_palette(room, '0', 0, h['theme_pid'])
    d.set_state_palette(room, '0', 1, h['paint_pid'])
    # no room default: a screen without a palette of its own shows the vanilla source
    # room's colours (a borrow) — screen 1 of odd halls, screen 2 of even halls
    room['render'].pop('palette', None)
    room['source_mapID'] = f'0x{BORROW[(i // 2) % 8][0]:02X}'
    d.set_state_palette(room, '1' if i % 2 == 0 else '2', 0, h['own_pid'])
    d.set_state_rules(room, [{'state': 1, 'when': [{'flag': h['flag']}], 'screens': [0],
                              'comment': f'painted {h["tint"]}'},
                             {'state': 0, 'when': [], 'screens': [0],
                              'comment': 'the gate colours'}])
for n in range(N - 1):
    a = d.add_door(halls[n]['id'], '2', 8, 1, name=f'Tint stairs {n + 1} up')
    b = d.add_door(halls[n + 1]['id'], '0', 1, 1, name=f'Tint stairs {n + 2} down')
    d.link_doors(a, b)


def plan_now():
    prj = Project(copy.deepcopy(d.data), d.project_dir)
    prj.repo_root = REPO
    plan = prj.place_plan()
    return plan, {m: b for m, (b, _i) in plan['home'].items()}


p2, home2 = plan_now()
for _ in range(6):                         # the bank named in a text can move a place
    write_texts(home2)
    prev = home2
    p2, home2 = plan_now()
    if home2 == prev:
        break
else:
    raise SystemExit('the plan never settled')
d.save(dst)
print('tinted halls', ', '.join(f"{h['mid']:#04x}" for h in halls))
print('place banks', ', '.join(f'${b:02X}' for b in p2['overflow']),
      '| used', {f'${b:02X}': u for b, u in p2['used'].items()})
for i, h in enumerate(halls):
    print(f"  TINTED HALL {i + 1:2d} {h['mid']:#04x}: colours in ${home2[h['mid']]:02X}"
          + f", screen {1 if i % 2 else 2} borrows map ${BORROW[(i // 2) % 8][0]:02X}")
