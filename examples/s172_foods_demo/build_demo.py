"""S172 demo (gamedata.foods — "Foods instead of meats"): THE PANTRY on the user's project.

The user (S172): "I want to replace the meats and meat icons in the game with different
items … Toast, Apple, Biscuit, Honey … Make this a TICK on the editor"; BadMeat ->
"BadApple is good"; the field sprite: "YES, and disambiguate so not everything is meat.
Apple becomes an apple icon, honey becomes a honey icon".

The tick is ON here (Items tab → "Foods instead of meats"):

  * THE PANTRY (a new room, gate theme 6):
      the PANTRY STALL sells all five — Toast 20 G, Apple 80 G, Biscuit 300 G, Honey
        1000 G (the game's prices) and BadApple (the game never sells BadMeat; here for
        a look);
      TOAST and APPLE stand on the floor — each its own picture; talk to them.
  * THE LARDER (a new room, gate theme 9; the STAIRS top right of the pantry):
      BISCUIT, BADAPPLE and HONEY — talk to each.
  * THE CELLAR (a new room, gate theme 13; the STAIRS top right of the larder):
      the game's own MEAT PROP (sprite $5F — the spring scene, the ending bedroom) now
        shows the Apple;
      the HUNGRY SLIME — fight it and throw a Toast (ITEM): the battle says "Toast";
      the EXIT GUIDE goes back to the city.

Way in: the PANTRY GUIDE in Cities_FOUNT (a new NPC; YES = to the pantry).

  * GATE FLOORS (r2): a meat lying on a gate floor shows its food's own pickup icon (the
    game draws all five with the red meat). Meats are about a third of the floor items in
    every gate AFTER the Gate of Beginning (none in it). The pictures are the editor's
    defaults unless the project drew its own (Items tab → click a picture).

    python3 examples/s172_foods_demo/build_demo.py <base project.json> <out project.json>

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
GUIDE_AT = (3, 4)                       # Cities_FOUNT screen 0 (the walk stands at (3, 5) facing up)
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)
d.vanilla = r

WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
TOAST, APPLE, BISCUIT, BADAPPLE, HONEY = 19, 20, 21, 22, 23

# ---- the tick ---------------------------------------------------------------------------
d.set_foods(True)


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


def talker(room_id, x, y, sprite, steps, name, monster=None):
    rm = d.room(room_id)
    if monster is None:
        d.add_npc(rm, '0', 0, x, y, sprite, 'down')
    else:
        d.add_npc(rm, '0', 0, x, y, sprite, 'down', monster=monster)
    k = len(d.npc_entries(rm, '0', 0)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', 0, k, script=sid)


def prop(room_id, x, y, sprite, words, name):
    talker(room_id, x, y, sprite, [{'say': B(words)}], name)


# ---- THE PANTRY / THE LARDER / THE CELLAR (new rooms; at most 3 NPCs a screen, one per row)
ids = {}
for key, nm, theme in (('pantry', 'PANTRY', 6), ('larder', 'LARDER', 9), ('cellar', 'CELLAR', 13)):
    ids[key] = d.new_room(nm, 0, r, gate_theme=theme)
    rm = d.room(ids[key])
    walls(rm['screens']['0']['layout']['id'])
    entry_script(rm, ids[key])
mid = {k: int(d.room(v)['mapID'], 16) for k, v in ids.items()}
for a_key, b_key in (('pantry', 'larder'), ('larder', 'cellar')):
    a_lid = d.room(ids[a_key])['screens']['0']['layout']['id']
    b_lid = d.room(ids[b_key])['screens']['0']['layout']['id']
    paint(a_lid, 8, 1, STAIRS)
    paint(b_lid, 1, 1, STAIRS)
    da = d.add_door(ids[a_key], '0', 8, 1, name=f'{a_key} stairs to the {b_key}')
    db = d.add_door(ids[b_key], '0', 1, 1, name=f'{b_key} stairs back to the {a_key}')
    d.link_doors(da, db)

# the PANTRY STALL — a project shop (row 2)
shop = d.new_shop('Pantry stall', [TOAST, APPLE, BISCUIT, HONEY, BADAPPLE])
rm = d.room(ids['pantry'])
d.add_npc(rm, '0', 0, 2, 2, 0x0C, 'down')
d.make_shopkeeper(rm, '0', 0, len(d.npc_entries(rm, '0', 0)) - 1, shop,
                  greeting=[['PANTRY STALL!', 'Foods, not meats.']])
prop(ids['pantry'], 4, 4, 0x58, 'TOAST (NPC sprite 58). It was the BeefJerky: +10 in battle, '
     '20 G at the Bazaar.', 'toast_prop')
prop(ids['pantry'], 6, 6, 0x59, 'APPLE (NPC sprite 59). It was the PorkChop: +30 in battle, '
     '80 G at the Bazaar.', 'apple_prop')
prop(ids['larder'], 3, 2, 0x5A, 'BISCUIT (NPC sprite 5A). It was the Rib: +100 in battle, '
     '300 G at Starry Night.', 'biscuit_prop')
prop(ids['larder'], 5, 4, 0x5B, 'BADAPPLE (NPC sprite 5B). It was the BadMeat: it poisons. '
     'Warubou still eats it.', 'badapple_prop')
prop(ids['larder'], 3, 6, 0x5C, 'HONEY (NPC sprite 5C). It was the Sirloin: +400 in battle, '
     '1000 G at the rare-item shop.', 'honey_prop')
prop(ids['cellar'], 3, 2, 0x5F, 'The game\'s own MEAT PROP (NPC sprite 5F: the spring and the '
     'ending bedroom). With Foods on it is an APPLE.', 'meat_prop')

# the HUNGRY SLIME (cellar, row 4): fight it and throw a Toast
slime = d.add_enemy(copy_eid=2, name='Hungry slime', species=8, level=1,
                    hp=999, mp=0, atk=1, **{'def': 1}, agl=1, joinability=7)
talker(ids['cellar'], 6, 4, 0xF0, [
    {'ask': B('I am the HUNGRY SLIME. Fight me and throw a TOAST (ITEM) - the battle says '
              'Toast, not BeefJerky. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [slime]}}, {'say': B('Yum. Toast!')}],
     'no': [{'say': B('Bring Toast!')}]}], 'hungry_slime', monster=8)

cities = d.room('cities_fount')
talker(ids['cellar'], 3, 6, 0x1D, [
    {'ask': B('I am the EXIT GUIDE. Back to the city with the fountain?', choice=True),
     'yes': [{'move': {'dest': f"room:${int(cities['mapID'], 16):02X}", 'screen': 0,
                       'x': 3, 'y': 5}}],
     'no': [{'say': B('Take your time!')}]}], 'pantry_exit')

talker('cities_fount', GUIDE_AT[0], GUIDE_AT[1], 0x1D, [{'say': B(
    'THE PANTRY (S172): Foods instead of meats is ON - BeefJerky is TOAST, PorkChop is '
    'APPLE, Rib is BISCUIT, BadMeat is BADAPPLE and Sirloin is HONEY. Same prices, same '
    'shops, same power.',
    'Each food has its own picture: the PANTRY STALL sells them, the pantry, the LARDER '
    'and the CELLAR show them. In the CELLAR the game\'s own meat prop is an Apple, and the '
    'HUNGRY SLIME eats your Toast.')},
    {'ask': B('S172 DEMO: THE PANTRY - foods instead of meats. Go?', choice=True),
     'yes': [{'move': {'dest': f"room:${mid['pantry']:02X}", 'screen': 0, 'x': 4, 'y': 6}}],
     'no': [{'say': B('Another time!')}]}], 's172demo')
d.save(dst)
# S151 r3 rule: the demo's rooms must build with NO warning
from editor2.core import compiler as _C                           # noqa: E402
_o, _p, _warns = _C.compile_project(d.project_dir, REPO)
_names = [d.room(rid)['name'] for rid in ids.values()]
_mine = [x for x in _warns if any(f'room "{nm}"' in x or f'room {nm} ' in x for nm in _names)]
_city = d.room('cities_fount')['name']
_mine += [x for x in _warns if f'room "{_city}" screen 0' in x and any(
    k in x for k in ('row ', 'HALF SPEED', 'drops frames', 'NPCs on screen', 'NPC sprites'))]
_mine += [x for x in _warns if 'FOOD sprite' in x]
if _mine:
    sys.exit('the demo rooms have build warnings:\n  ' + '\n  '.join(_mine))
print(' '.join(f'{k} ${v:02X}' for k, v in mid.items()))
