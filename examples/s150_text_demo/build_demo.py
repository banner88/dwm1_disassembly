"""S150 demo (ROADMAP P3.6 / Phase F T-author — editing the game's own texts): THE
SCRIBE'S HALL on the user's project.

Until S150 the game's own 2,560 dialogue lines and every text table (battle messages,
item names / descriptions / use lines, menu words, the credits …) were read-only: a
project could only rename monsters and skills. Now any of them can be rewritten, any
length (an edited text lives in a new bank of the 4 MB ROM). This demo edits a few the
user meets at once and adds a BRAND-NEW room to show them:

  * the Castle's throne room: the LADY by the throne (the one in the long dress)
    has a new, longer speech (text $0489); the soldiers beside the throne say their
    original lines (unedited — the comparison);
  * the bag: ElfWater is now "FairyDew", Laurel is "BayLeaf", with new descriptions;
    using FairyDew on a monster (the field menu) says "<you> pours 1 FairyDew on
    <monster>." (an edited use line — "uses" before — + an edited name the game COPIES
    into the line);
  * THE SCRIBE'S HALL (a new room): the SCRIBE explains; the QUOTER shows the lady's
    edited line ($0489) from a room of the project; the STAIRS go down to THE SCRIBE'S
    FIELD — wild Slimes; a battle now opens with "Here they come! … (edited)" and the
    win says "… earns … Exp" — the SIGN there says so; the EXIT GUIDE goes back.

Way in: the SCRIBE GUIDE in Cities_FOUNT at (3, 4) (a new NPC; YES = to the hall).

    python3 examples/s150_text_demo/build_demo.py <base project.json> <out project.json>

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

WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]

# ---- the edits of the game's own texts (gamedata.text — editor2/core/textmark.py) ------
EDITS = {
    ('dialogue', '$0489'): '{low}*:This speech was\nrewritten in the▼\n*:new TEXT tab of\nthe editor!▼\n'
                           '*:Edited lines can\nbe any length.▼\n*:Now, head to\nthe arena, Master\n'
                           '{hero}!',
    ('item_name', '6'): 'FairyDew',
    ('item_description', '6'): 'Restores MP to\nmax. (edited)',
    ('item_name', '10'): 'BayLeaf',
    ('item_description', '10'): 'Breaks a curse.\n(edited)',
    ('item_use_message', '3'): '{ins 00} pours\n1 {ins 20} on{clear}{F2}{ins 10}.\n{clear}',
    ('battle_message', '0'): '{ED}Here they come!\n{ins 00} (edited){FC 10}{EC}',
    ('battle_message', '1'): '{ED}A gang of\n{ins 00} (edited){FC 10}{EC}',
}
for (src_, key), m in EDITS.items():
    d.set_game_text(src_, key, m)


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


def talker(room_id, x, y, sprite, steps, name):
    rm = d.room(room_id)
    d.add_npc(rm, '0', 0, x, y, sprite, 'down')
    k = len(d.npc_entries(rm, '0', 0)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', 0, k, script=sid)


# ---- THE SCRIBE'S HALL + THE SCRIBE'S FIELD (new rooms, gate themes of their own) -------
hall_id = d.new_room("SCRIBE'S HALL", 0, r, gate_theme=11)
field_id = d.new_room("SCRIBE'S FIELD", 0, r, gate_theme=5)
hall, field = d.room(hall_id), d.room(field_id)
hall_mid, field_mid = int(hall['mapID'], 16), int(field['mapID'], 16)
walls(hall['screens']['0']['layout']['id'])
walls(field['screens']['0']['layout']['id'])
paint(hall['screens']['0']['layout']['id'], 8, 1, STAIRS)
paint(field['screens']['0']['layout']['id'], 1, 1, STAIRS)
a = d.add_door(hall_id, '0', 8, 1, name='Scribe stairs down')
b = d.add_door(field_id, '0', 1, 1, name='Scribe stairs up')
d.link_doors(a, b)
lists = d.custom.setdefault('encounter_lists', [])
lists.append({'id': 'scribe_field', 'name': "The Scribe's Field (Slimes)",
              'rate': 7, 'size_chance': [7, 0, 0], 'slot_chance': [7, 0, 0, 0, 0],
              'eids': [1, 0, 0, 0, 0], 'max_count': [3, 1, 1, 1, 1]})
d.touch()
d.set_room_battles(field_id, 'own', list_ref='scribe_field', rate=7)
hall, field = d.room(hall_id), d.room(field_id)
entry_script(hall, hall_id)
entry_script(field, field_id)

talker(hall_id, 4, 3, 0x1D, [{'say': B(
    "THE SCRIBE'S HALL. Since S150 the game's OWN texts can be rewritten: dialogue, "
    'battle messages, item names, menus, even the credits - any length.',
    "Try it: in the Castle's throne room the LADY by the throne has a new speech. In "
    'your bag ElfWater is now FairyDew and Laurel is BayLeaf - read their pages, and '
    'use FairyDew on a monster: you POUR it now.',
    'The QUOTER (left) says the lady\'s new line from here. The STAIRS go down to THE '
    "SCRIBE'S FIELD: its battles open with an edited line.")}], 'scribe')

# the QUOTER: a script that shows the game's own text id $0489 (the edited one)
hall = d.room(hall_id)
d.add_npc(hall, '0', 0, 2, 5, 0x11, 'down')
d.custom['scripts'].append({'id': 'scribe_quoter', 'ops': [['text', '0x0489'], ['end']]})
tbl = hall.setdefault('scripts', {})
idx = 1
while str(idx) in tbl:
    idx += 1
tbl[str(idx)] = 'scribe_quoter'
d.update_npc(hall, '0', 0, len(d.npc_entries(hall, '0', 0)) - 1, script='scribe_quoter')

cities = d.room('cities_fount')
talker(hall_id, 7, 6, 0x1D, [{'ask': B('I am the EXIT GUIDE. Back to the city with the '
                                       'fountain?', choice=True),
                              'yes': [{'move': {'dest': f"room:${int(cities['mapID'], 16):02X}",
                                                'screen': 0, 'x': 5, 'y': 5}}],
                              'no': [{'say': B('Take your time!')}]}], 'scribe_exit')
talker(field_id, 6, 2, 0x0B, [{'say': B(
    "THE SCRIBE'S FIELD: wild Slimes. Walk around - each battle now opens with an "
    "edited line: \"Here they come!\" ... \"(edited)\". The STAIRS (top left) go back up.")}],
    'scribe_field_sign')

talker('cities_fount', 3, 4, 0x1D, [{'ask': B(
    "S150 DEMO: THE SCRIBE'S HALL - the game's own texts, edited. Go?", choice=True),
    'yes': [{'move': {'dest': f'room:${hall_mid:02X}', 'screen': 0, 'x': 4, 'y': 6}}],
    'no': [{'say': B('Another time!')}]}], 's150demo')
d.save(dst)
print(f"hall ${hall_mid:02X}, field ${field_mid:02X}; {len(EDITS)} texts edited")
