"""S136 demo (ROADMAP ARC CAP2b): the ECHO ROOMS on the user's project.

Sixteen BRAND-NEW rooms, ECHO ROOM 1-16, each in its own gate theme (16 looks), built
with the editor's own operations. There is more script and text than bank $60 holds
for the user's project, so the compiler's first fit (editor2/core/places.py) keeps the
user's rooms and the first echo rooms in bank $60 and puts the rest — and the text
sections — in PLACE BANKS $80+. Every room has:

  * a GUIDE (left) whose long story names the bank its own script lives in and the
    bank its words live in, then asks: next ECHO ROOM (YES) or stay (NO); the last
    room's YES goes home to Cities_FOUNT;
  * two screens: walk east into the second, where a MONSTER offers a fight (YES = a
    battle; the words after it play only when you win) and a SINGER remembers whether
    you beat it and whether the fairy greeted you (flags);
  * an ENTRY SCENE (the first visit): an echo fairy flickers in, walks up, speaks,
    makes a stone pillar appear on the floor (a script tile patch — ops $24 / $61) and
    flickers away;
  * a third screen with a CHOIR of three (each remembers both flags and asks YES / NO);
  * STAIRS both ways: third screen top right = up to the next room, first screen top
    left = back down.

Way in: the S136 DEMO NPC in Cities_FOUNT at (3, 4).

    python3 examples/s136_echo_demo/build_demo.py <base project.json> <out project.json>

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
from editor2.core import cutscene_doc as CD
from editor2.core import textenc as T

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

N = 16
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
MONSTERS = [0, 4, 8, 12, 16, 22, 30, 41, 50, 63, 77, 88, 101, 115, 130, 150]   # species shown

LORE = [
    'Long ago a choir sang in these halls, and the stones kept every note.',
    'When you speak here, the walls answer a moment later, a little softer.',
    'Travellers say the echoes remember their names long after they leave.',
    'The fairies of echo carry words from one room to the next on the wind.',
    'Each hall keeps a different song. Listen closely and you will hear it.',
    'The old builders cut these rooms from one great stone in a single night.',
    'A monster waits in every hall. It wants to see how strong you have become.',
    'If you climb all sixteen halls, the last stairs lead you home again.',
]


def B(*paras):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out}


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


rooms = []
for n in range(N):
    rid = d.new_room(f'ECHO ROOM {n + 1}', 0, r, gate_theme=n)
    room = d.room(rid)
    lid = room['screens']['0']['layout']['id']
    lid1 = d.unique_layout_id(f'{rid}_s1')
    lay0 = d.layout(lid)
    d.add_layout(lid1, tiles=copy.deepcopy(lay0['tiles']), attr=copy.deepcopy(lay0['attr']))
    d.add_screen(room, 1, {'id': lid1})
    lid2 = d.unique_layout_id(f'{rid}_s2')
    d.add_layout(lid2, tiles=copy.deepcopy(lay0['tiles']), attr=copy.deepcopy(lay0['attr']))
    d.add_screen(room, 2, {'id': lid2})
    walls(lid, True, False)                # screen 0 opens east into screen 1 …
    walls(lid1, False, False)
    walls(lid2, False, True)               # … and screen 1 into screen 2
    if n > 0:
        paint(lid, 1, 1, STAIRS)           # back down (screen 0, top left)
    if n < N - 1:
        paint(lid2, 8, 1, STAIRS)          # up to the next room (screen 2, top right)
    g = d.add_npc(room, '0', 0, 2, 4, 0x0B, 'down')
    sp = MONSTERS[n]
    mon = d.add_npc(room, '1', 0, 7, 4, 0xF0, 'down', monster=sp)
    singer = d.add_npc(room, '1', 0, 3, 3, 0x0C, 'down')
    choir = [d.add_npc(room, '2', 0, x, 3, 0x0C, 'down') for x in (3, 5, 7)]
    enemy = d.add_enemy(copy_eid=2, name=f'Echo foe {n + 1}', species=sp, level=1,
                        hp=1, joinability=7)
    rooms.append({'id': rid, 'mid': int(room['mapID'], 16), 'guide': g, 'mon': mon,
                  'singer': singer, 'choir': choir, 'csids': None, 'lid': lid, 'enemy': enemy, 'species': sp,
                  'sid': None, 'msid': None, 'ssid': None, 'scene': None})

# stairs both ways: room n top-right <-> room n+1 top-left
for n in range(N - 1):
    a = d.add_door(rooms[n]['id'], '2', 8, 1, name=f'Echo stairs {n + 1} up')
    b = d.add_door(rooms[n + 1]['id'], '0', 1, 1, name=f'Echo stairs {n + 2} down')
    d.link_doors(a, b)

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')
d.add_flag('s136_seen_echo', comment='S136 demo: unused marker')


def write_texts(home, text_bank):
    """home = {mapID: bank} of the places; text_bank(dialogue name) -> bank."""
    for i, h in enumerate(rooms):
        room = d.room(h['id'])
        hb = home.get(h['mid'], 0)
        tb = text_bank(i)
        nxt = rooms[i + 1] if i + 1 < N else None
        lore = [LORE[(i + j) % len(LORE)] for j in range(3)]
        dest = (f"room:${nxt['mid']:02X}" if nxt else f'room:${cities_mid:02X}')
        steps = [{'say': B(f'ECHO ROOM {i + 1}. I am its guide.', *lore,
                           f'My script lives in bank {hb:02X}. My words live in bank '
                           f'{tb:02X}.')},
                 {'ask': B('Shall the echo carry you on to the next room?' if nxt else
                           'This is the last room. Shall the echo carry you home?'),
                  'yes': [{'move': {'dest': dest, 'screen': 0, 'x': 5, 'y': 5}}],
                  'no': [{'say': B('Then rest a while. The stairs are always there.')}]}]
        mon_steps = [{'ask': B(f'I am the monster of ECHO ROOM {i + 1}. Will you fight me?'),
                      'yes': [{'battle': {'enemies': [h['enemy']]}},
                              {'say': B('You won! The echo of your victory will ring in '
                                        'these walls for a long time.')}],
                      'no': [{'say': B('Come back when you are ready.')}]}]
        flag = f's136_echo_scene_{i + 1}'
        won = f's136_echo_won_{i + 1}'
        mon_steps[0]['yes'].append({'set': [won]})
        sing = [{'say': B(f'I sing the song of ECHO ROOM {i + 1}. La la laa!')},
                {'if': [{'flag': won}],
                 'then': [{'say': B('You beat the monster of this room! The walls sing '
                                    'your name now.')}],
                 'else': [{'say': B('The monster over there is waiting for a brave '
                                    'challenger.')}]},
                {'if': [{'flag': flag}],
                 'then': [{'say': B('The echo fairy already greeted you. She raised the '
                                    'stone pillar on the first screen.')}],
                 'else': [{'say': B('Strange, the echo fairy has not met you yet.')}]},
                {'say': B('Climb the stairs at the top right to reach the next room.' if
                          nxt else 'This is the last room. The guide can send you home.')}]
        choir = []
        for voice, (part, line) in enumerate((
                ('ALTO', 'We are the choir of the third screen. Every room has one.'),
                ('TENOR', 'Our songs are written in the place bank of this room, far from '
                          'the old bank of the game.'),
                ('BASS', 'Sing with us! Or climb the stairs behind us to the next room.'))):
            choir.append([
                {'say': B(f'{part}: {line}')},
                {'if': [{'flag': won}, {'flag': flag}],
                 'then': [{'say': B(f'{part}: You met the fairy AND beat the monster of '
                                    f'ECHO ROOM {i + 1}. Bravo!')}],
                 'else': [{'if': [{'flag': won}],
                           'then': [{'say': B(f'{part}: You beat the monster. Have you met '
                                              'the fairy yet?')}],
                           'else': [{'say': B(f'{part}: The monster of this room is still '
                                              'unbeaten.')}]}]},
                {'ask': B(f'{part}: Shall I sing my note again?'),
                 'yes': [{'say': B(f'{part}: Laaaa!')}],
                 'no': [{'say': B(f'{part}: Farewell, traveller.')}]}])
        if h['sid'] is None:
            h['csids'] = []
            for v, steps_v in enumerate(choir):
                cs = d.new_conversation(room, {'steps': steps_v}, name=f'choir{v}')
                d.update_npc(room, '2', 0, h['choir'][v], script=cs)
                h['csids'].append(cs)
            d.add_flag(won, comment=f'S136 demo: the ECHO ROOM {i + 1} monster was beaten')
            h['ssid'] = d.new_conversation(room, {'steps': sing}, name='singer')
            d.update_npc(room, '1', 0, h['singer'], script=h['ssid'])
            h['sid'] = d.new_conversation(room, {'steps': steps}, name='guide')
            d.update_npc(room, '0', 0, h['guide'], script=h['sid'])
            h['msid'] = d.new_conversation(room, {'steps': mon_steps}, name='monster')
            d.update_npc(room, '1', 0, h['mon'], script=h['msid'])
        else:
            d.set_conversation(h['sid'], {'steps': steps})
            d.set_conversation(h['msid'], {'steps': mon_steps})
            d.set_conversation(h['ssid'], {'steps': sing})
            for cs, steps_v in zip(h['csids'], choir):
                d.set_conversation(cs, {'steps': steps_v})
        if h['scene'] is None:
            d.add_flag(flag, comment=f'S136 demo: ECHO ROOM {i + 1} entry scene played')
            CD.add_cast(d, h['id'], 0, 'Echo', 0x0C, 5, 6, 'up')
            h['scene'] = CD.new_cutscene(d, h['id'], f'Echo {i + 1} arrival', 0, 'entry')
        _r, sc = CD.find(d, h['scene'])
        sc = copy.deepcopy(sc)
        sc['trigger']['once'] = flag
        sc['player_start'] = {'x': 5, 'y': 5}
        sc['steps'] = [
            {'show': {'actor': 'Echo', 'how': 'flicker', 'at': [5, 6]}},
            {'walk': {'actor': 'Echo', 'to': [5, 3]}},
            {'say': B(f'Welcome to ECHO ROOM {i + 1}! I am an echo fairy. Watch the floor.')},
            {'tiles': {'x': 4, 'y': 6, 'rows': [[{'tiles': WALL, 'pal': 0}]]}},
            {'say': B('A pillar of stone, raised by an echo. Talk to the guide and the '
                      'monster!')},
            {'hide': {'actor': 'Echo', 'how': 'flicker'}}]
        CD.set_scene(d, h['scene'], sc)
    demo = [{'ask': B('S136 DEMO: the ECHO ROOMS. Their scripts and words live in the new '
                      'place banks. Go?'),
             'yes': [{'move': {'dest': f"room:${rooms[0]['mid']:02X}", 'screen': 0,
                               'x': 5, 'y': 5}}],
             'no': [{'say': B('Another time!')}]}]
    if not hasattr(write_texts, 'demo_sid'):
        write_texts.demo_sid = d.new_conversation(cities, {'steps': demo}, name='s136demo')
        d.update_npc(cities, '0', 0, k_demo, script=write_texts.demo_sid)
    else:
        d.set_conversation(write_texts.demo_sid, {'steps': demo})


def plan_now():
    prj = Project(copy.deepcopy(d.data), d.project_dir)
    prj.repo_root = REPO
    plan = prj.place_plan()
    # the guide's first text: the first dialogue entry its script shows
    guide_text = {}
    for i, h in enumerate(rooms):
        room = next(x for x in prj.rooms if x['id'] == h['id'])
        sid = h['sid']
        for it in prj.script(sid)['ops']:
            if isinstance(it, list) and it and it[0] == 'text':
                tid = it[1] if isinstance(it[1], int) else int(str(it[1]), 0)
                guide_text[i] = plan['text_home'][(tid >> 8) - 0x0A]
                break
    home = {m: b for m, (b, _i) in plan['home'].items()}
    return plan, home, guide_text


write_texts({}, lambda i: 0)
p2, home2, gt2 = plan_now()
for _ in range(6):                         # the banks written into the texts can move a
    write_texts(home2, lambda i: gt2.get(i, 0))     # place (a box wraps differently):
    prev = (home2, gt2)                    # repeat until the plan is a fixed point
    p2, home2, gt2 = plan_now()
    if (home2, gt2) == prev:
        break
else:
    raise SystemExit('the plan never settled')
d.save(dst)
print('echo rooms', ', '.join(f"{h['mid']:#04x}" for h in rooms))
print('place banks', ', '.join(f'${b:02X}' for b in p2['overflow']),
      '| used', {f'${b:02X}': u for b, u in p2['used'].items()})
print('text sections', ', '.join(f'{si}:${b:02X}' for si, b in enumerate(p2['text_home'])))
for i, h in enumerate(rooms):
    print(f"  ECHO ROOM {i + 1:2d} {h['mid']:#04x}: script ${home2[h['mid']]:02X}, "
          f"guide words ${gt2[i]:02X}")
