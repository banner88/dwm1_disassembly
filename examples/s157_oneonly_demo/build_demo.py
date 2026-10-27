"""S157 demo (ROADMAP E9 — ONE-ONLY items): THE AVIARY on the user's project.

The user (S157): "If I set an item to permanent (doesnt break) user should not be allowed
to have more than 1 AND that item should NOT appear as a pickup in random gates" + "bag
or vault" + "Kept after lost battles yes" + (a give of one already held) "c ideally" =
a line of its own. Here the game's WarpWing is PERMANENT (never used up — the user's
"I basically want warpwing to be permanent as QOL"); the BeastTail and the ShinyHarp
were permanent already, so they are one-only too.

  * THE AVIARY (a new room, gate theme 3):
      the WING STALL sells the WarpWing, the BeastTail and the Herb — a one-only item
        the player holds (bag or Vault) is not on its list; the how-many window stops
        at 1 for one;
      the WINGKEEPER gives a WarpWing (a conversation's Give): with one already held it
        says the "already has one" line and gives nothing;
      the VAULT keeper: put the WarpWing in the Vault — the stall still hides it.
  * THE PERCH (a new room, gate theme 11; the STAIRS top right of the aviary):
      the NEST gives "2 BeastTails" (a Give of 2): a one-only item comes as one;
      the BRUISER always wins: the WarpWing stays after the lost battle (permanent ->
        kept on loss);
      the EXIT GUIDE goes back to the city.
  * The game's own Stable dresser (the WarpWing in the drawer, flag $0090): with a
    WarpWing held it says the "already has one" line and keeps its WarpWing for later.
  * The random gates: the WarpWing no longer lies on the floors or in the treasure
    chests (its 2-5 % went to the other items).

Way in: the AVIARY GUIDE in Cities_FOUNT at (3, 4) (a new NPC; YES = to the aviary).

    python3 examples/s157_oneonly_demo/build_demo.py <base project.json> <out project.json>

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
HERB, WARPWING, BEASTTAIL = 1, 29, 38

# ---- the game's WarpWing: permanent = one-only (S157) -------------------------------
d.set_item_field(WARPWING, 'consume', 0)


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


def npc(room_id, x, y, sprite, monster=None):
    rm = d.room(room_id)
    if monster is None:
        d.add_npc(rm, '0', 0, x, y, sprite, 'down')
    else:
        d.add_npc(rm, '0', 0, x, y, sprite, 'down', monster=monster)
    return rm, len(d.npc_entries(rm, '0', 0)) - 1


def talker(room_id, x, y, sprite, steps, name):
    rm, k = npc(room_id, x, y, sprite)
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', 0, k, script=sid)


# ---- THE AVIARY + THE PERCH (new rooms; at most 3 NPCs a screen, one per row) --------
hall_id = d.new_room('AVIARY', 0, r, gate_theme=3)
perch_id = d.new_room('PERCH', 0, r, gate_theme=11)
hall, perch = d.room(hall_id), d.room(perch_id)
hall_mid, perch_mid = int(hall['mapID'], 16), int(perch['mapID'], 16)
walls(hall['screens']['0']['layout']['id'])
walls(perch['screens']['0']['layout']['id'])
paint(hall['screens']['0']['layout']['id'], 8, 1, STAIRS)
paint(perch['screens']['0']['layout']['id'], 1, 1, STAIRS)
a = d.add_door(hall_id, '0', 8, 1, name='Aviary stairs to the perch')
b = d.add_door(perch_id, '0', 1, 1, name='Perch stairs back')
d.link_doors(a, b)
entry_script(hall, hall_id)
entry_script(perch, perch_id)

# the WING STALL — a project shop (row 3)
shop = d.new_shop('Wing stall', [WARPWING, BEASTTAIL, HERB])
rm, k = npc(hall_id, 2, 3, 0x0C)
d.make_shopkeeper(rm, '0', 0, k, shop, greeting=[['Wing stall!', 'Wings and tails.']])

# the WINGKEEPER (row 4) gives a WarpWing — every time it is asked
talker(hall_id, 6, 4, 0x14, [
    {'say': B('I am the WINGKEEPER. A WarpWing never breaks now - so you may carry only '
              'one. Here, take one!')},
    {'give_item': {'item': WARPWING, 'got': B('You got a WarpWing!'),
                   'full': B('Your bag is full - come back with room.')}}], 'wingkeeper')

# the VAULT keeper (row 5)
rm, k = npc(hall_id, 3, 5, 0x1F)
d.make_service_npc(rm, '0', 0, k, 'vault')

# the NEST (perch, row 3): a Give of 2 BeastTails — a one-only item comes as one
talker(perch_id, 3, 3, 0x0B, [
    {'say': B('THE NEST holds BeastTails. Take two!')},
    {'give_item': {'item': BEASTTAIL, 'count': 2, 'got': B('You got BeastTails!'),
                   'full': B('No room - or you have one already.')}}], 'nest')

# the BRUISER (perch, row 4): lose to it — the WarpWing stays
bruiser = d.add_enemy(copy_eid=2, name='Aviary bruiser', species=150, level=99,
                      hp=999, mp=0, atk=999, **{'def': 999}, agl=999, joinability=7)
perch = d.room(perch_id)
d.add_npc(perch, '0', 0, 6, 4, 0xF0, 'down', monster=150)
sid = d.new_conversation(perch, {'steps': [
    {'ask': B('I am the BRUISER of THE PERCH. Lose to me and look in your bag: the WarpWing '
              'is permanent, so it stays. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [bruiser]}},
             {'say': B('You won?! That was not the plan.')}],
     'no': [{'say': B('Wise.')}]}]}, name='bruiser')
d.update_npc(perch, '0', 0, len(d.npc_entries(perch, '0', 0)) - 1, script=sid)

cities = d.room('cities_fount')
talker(perch_id, 3, 5, 0x1D, [{'ask': B('I am the EXIT GUIDE. Back to the city with the '
                                        'fountain?', choice=True),
                               'yes': [{'move': {'dest': f"room:${int(cities['mapID'], 16):02X}",
                                                 'screen': 0, 'x': 5, 'y': 5}}],
                               'no': [{'say': B('Take your time!')}]}], 'aviary_exit')

talker('cities_fount', 3, 4, 0x1D, [{'say': B(
    'THE AVIARY (S157): the WarpWing is PERMANENT now - it never breaks - so you may carry '
    'only ONE, in the bag or the Vault. The BeastTail and the ShinyHarp were permanent '
    'already: one each too.',
    'The WING STALL hides a WarpWing you hold and sells only one at a time. The '
    'WINGKEEPER gives one - unless you have it. The VAULT keeper keeps it for you.',
    'The STAIRS top right go to THE PERCH: the NEST gives "two" BeastTails, the BRUISER '
    'shows the WarpWing stays after a lost battle. The random gates never lay a WarpWing '
    'on their floors or in their chests any more.')},
    {'ask': B('S157 DEMO: THE AVIARY - one-only items. Go?', choice=True),
     'yes': [{'move': {'dest': f'room:${hall_mid:02X}', 'screen': 0, 'x': 4, 'y': 6}}],
     'no': [{'say': B('Another time!')}]}], 's157demo')
d.save(dst)
# S151 r3 rule: the demo's rooms must build with NO warning
from editor2.core import compiler as _C                           # noqa: E402
_o, _p, _warns = _C.compile_project(d.project_dir, REPO)
_names = [d.room(rid)['name'] for rid in (hall_id, perch_id)]
_mine = [x for x in _warns if any(f'room "{nm}"' in x or f'room {nm} ' in x for nm in _names)]
_city = d.room('cities_fount')['name']
_mine += [x for x in _warns if f'room "{_city}" screen 0' in x and any(
    k in x for k in ('row ', 'HALF SPEED', 'drops frames', 'NPCs on screen', 'NPC sprites'))]
if _mine:
    sys.exit('the demo rooms have build warnings:\n  ' + '\n  '.join(_mine))
print(f"aviary ${hall_mid:02X}, perch ${perch_mid:02X}")
