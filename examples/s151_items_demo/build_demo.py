"""S151 demo (ROADMAP E9 — items): THE CURIO HALL on the user's project.

Until S151 an item could change its price (S117) and its words (S150) — nothing else,
and there were exactly the game's 43. Now every field of an item is editable (how
likely it is used up, its power, whether it can be used from the field menu, its
lines, whether the shops buy it, whether it is kept after a lost battle, its battle
power) and a project can add NEW items (ids 44-127) that work like one of the game's.
This demo:

  * the game's WarpWing is PERMANENT (never used up — the user's S72 spec); the Herb
    heals 40-50 in the field and 45-55 in battle (was 30-40 both);
  * five NEW items, sold by the CURIO STALL (and one given):
      MegaHerb  (works like the Herb)   heals 80-90 HP; its own use line
      HeroSeed  (works like the ATKseed) ATK +10
      SparkRod  (works like the BoltStaff) — in battle the BoltStaff's lightning; the
                shops pay a tenth, as for a staff
      Feather   (works like the WarpWing) — leaves a gate; used up 1 time in 2
      OldKey    (an inert key item — works like the TinyMedal): the KEYKEEPER gives it,
                it cannot be used or sold, it is KEPT when the party loses a battle,
                and the DOOR WARDEN knows when you carry it (a story check "has an
                item")
  * THE CURIO HALL (a new room): the CURATOR explains; the CURIO STALL; the KEYKEEPER;
    the DOOR WARDEN; the VAULT keeper (store the new items); the STAIRS down to THE
    CURIO YARD — wild Slimes, to try the items in battle, and the BRUISER, who always
    wins (what the party keeps after a lost battle); the EXIT GUIDE goes back.

S151 r2 (the user's test: "Vault: text box starts at top then jumped when vault menu appears
… Make sure other services dont have this issue" / "Key: asked when inventory full. Then
wouldnt give because asked a second time"): THE SERVICE ROWS 1-4 (the stairs bottom left in
the hall) — the stall and the seven services, two a room, to talk to from below, and a plain
sign in each. The KEYKEEPER's Give now stops the conversation when the bag is full (the
editor's default since r2), so its flag is set only when the key was given.
S151 r3 (the user: "so many NPCs in that room some of them are invisible and the whole thing
lags"): at most 3 NPCs a screen, one per row — the hall 3 (the CURATOR's words are the CURIO
GUIDE's now), the yard 3 (the EXIT GUIDE moved there), each service row 3.

Way in: the CURIO GUIDE in Cities_FOUNT at (3, 4) (a new NPC; YES = to the hall).

    python3 examples/s151_items_demo/build_demo.py <base project.json> <out project.json>

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

# ---- the game's items --------------------------------------------------------------
d.set_item_field(29, 'consume', 0)                  # WarpWing: permanent (user, S72)
d.set_item_field(1, 'power', 40)                    # Herb: 40-50 HP in the field
d.set_item_description(1, 'Restores between\n40 to 50 HP')
d.set_item_battle(1, power=45)                      # … 45-55 in battle

# ---- the project's new items ---------------------------------------------------------
MEGA = d.new_item(1, 'MegaHerb')
d.set_item_field(MEGA, 'power', 80)
d.set_item_field(MEGA, 'price', 300)
d.set_item_description(MEGA, 'Restores between\n80 to 90 HP')
d.set_item_own_line(MEGA, 'use', '{ins 00} feeds\n{ins 10} a\n{ins 20}!')
SEED = d.new_item(15, 'HeroSeed')
d.set_item_field(SEED, 'power', 10)
d.set_item_field(SEED, 'price', 500)
d.set_item_description(SEED, 'Raises ATK by 10')
ROD = d.new_item(24, 'SparkRod')
d.set_item_field(ROD, 'price', 2000)
d.set_item_field(ROD, 'consume', 0)
d.set_item_description(ROD, 'Lightning in battle\nNever breaks')
FEATHER = d.new_item(29, 'Feather')
d.set_item_field(FEATHER, 'price', 60)
d.set_item_field(FEATHER, 'consume', 50)
d.set_item_description(FEATHER, 'Leaves a gate.\nBreaks half the time')
KEY = d.new_item(30, 'OldKey')
d.set_item_field(KEY, 'price', 0)
d.set_item_field(KEY, 'sellable', False)
d.set_item_field(KEY, 'keep_on_loss', True)
d.set_item_field(KEY, 'consume', 0)
d.set_item_description(KEY, 'A key from the\nCURIO HALL')


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


def npc(room_id, x, y, sprite):
    rm = d.room(room_id)
    d.add_npc(rm, '0', 0, x, y, sprite, 'down')
    return rm, len(d.npc_entries(rm, '0', 0)) - 1


def talker(room_id, x, y, sprite, steps, name):
    rm, k = npc(room_id, x, y, sprite)
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, '0', 0, k, script=sid)


# ---- THE CURIO HALL + THE CURIO YARD (new rooms) -------------------------------------
hall_id = d.new_room('CURIO HALL', 0, r, gate_theme=6)
yard_id = d.new_room('CURIO YARD', 0, r, gate_theme=13)
hall, yard = d.room(hall_id), d.room(yard_id)
hall_mid, yard_mid = int(hall['mapID'], 16), int(yard['mapID'], 16)
walls(hall['screens']['0']['layout']['id'])
walls(yard['screens']['0']['layout']['id'])
paint(hall['screens']['0']['layout']['id'], 8, 1, STAIRS)
paint(yard['screens']['0']['layout']['id'], 1, 1, STAIRS)
a = d.add_door(hall_id, '0', 8, 1, name='Curio stairs down')
b = d.add_door(yard_id, '0', 1, 1, name='Curio stairs up')
d.link_doors(a, b)
lists = d.custom.setdefault('encounter_lists', [])
lists.append({'id': 'curio_yard', 'name': 'The Curio Yard (Slimes)',
              'rate': 7, 'size_chance': [7, 0, 0], 'slot_chance': [7, 0, 0, 0, 0],
              'eids': [2, 0, 0, 0, 0], 'max_count': [3, 1, 1, 1, 1]})
d.touch()
d.set_room_battles(yard_id, 'own', list_ref='curio_yard', rate=7)
hall, yard = d.room(hall_id), d.room(yard_id)
entry_script(hall, hall_id)
entry_script(yard, yard_id)

# S151 r3 (user: "You put so many NPCs in that room some of them are invisible and the
# whole thing lags massively"): every screen of the demo holds at most 3 NPCs, one per row
# (no build warning for these rooms; PyBoy: 4 NPCs on a screen drop frames, 5+ halve the
# game's speed — PROJECT_COMPILER §2.59 r3)
# the CURATOR's words are the CURIO GUIDE's (Cities_FOUNT) since r3: the hall keeps 3 NPCs

# the CURIO STALL — a project shop
shop = d.new_shop('Curio stall', [MEGA, SEED, ROD, FEATHER, 29, 1])
rm, k = npc(hall_id, 2, 3, 0x0C)
d.make_shopkeeper(rm, '0', 0, k, shop, greeting=[['Curio stall! New', 'items, new prices.']])

# the KEYKEEPER gives the OldKey once
d.custom.setdefault('flags', []).append({'name': 'curio_key_given'})
talker(hall_id, 6, 4, 0x14, [
    {'if': [{'flag': 'curio_key_given', 'is': 'set'}],
     'then': [{'say': B('I gave you the OldKey already. Look at it in your bag: it is a '
                        'key - it cannot be used, and the shops will not buy it.')}],
     'else': [{'say': B('I am the KEYKEEPER. Take this OldKey - a NEW item of this '
                        'project.')},
              {'give_item': {'item': KEY, 'got': B('You got the OldKey!'),
                             'full': B('Your bag is full - come back with room.')}},
              {'set': ['curio_key_given']}]}], 'keykeeper')

# the DOOR WARDEN: a story check "the bag holds the OldKey"
d.add_check('has_oldkey', {'kind': 'item', 'item': KEY, 'count': 1})
talker(hall_id, 4, 5, 0x1D, [
    {'if': [{'flag': 'has_oldkey', 'is': 'set'}],
     'then': [{'say': B('DOOR WARDEN: you carry the OldKey - a story check reads your '
                        'bag for a NEW item. Well done!')}],
     'else': [{'say': B('DOOR WARDEN: bring me the OldKey. The KEYKEEPER (right) has '
                        'one.')}]}], 'warden')


# the BRUISER in the yard: lose to it to see what the party keeps (the OldKey)
bruiser = d.add_enemy(copy_eid=2, name='Curio bruiser', species=150, level=99,
                      hp=999, mp=0, atk=999, **{'def': 999}, agl=999, joinability=7)
yard = d.room(yard_id)
mon = d.add_npc(yard, '0', 0, 6, 5, 0xF0, 'down', monster=150)
sid = d.new_conversation(yard, {'steps': [
    {'ask': B('I am the BRUISER of the CURIO YARD. Lose to me and see what you keep: the '
              'OldKey stays in your bag, most other items are lost. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [bruiser]}},
             {'say': B('You won?! That was not the plan.')}],
     'no': [{'say': B('Wise.')}]}]}, name='bruiser')
d.update_npc(yard, '0', 0, len(d.npc_entries(yard, '0', 0)) - 1, script=sid)

# ---- S151 r2 (user: "Vault: text box starts at top then jumped when vault menu appears.
# Should always be on bottom. Make sure other services dont have this issue"); r3 (user:
# "You put so many NPCs in that room some of them are invisible and the whole thing lags
# massively"): THE SERVICE ROWS 1-4 — two service NPCs a room, on rows 4 and 5, to talk to
# from BELOW (rows 5 / 6: the LOWER half of the screen, where a plain talk's box opens at
# the TOP), and a plain SIGN at (8, 6) to talk to from (7, 6); stairs top left = back, top
# right = on. 3 NPCs a room, one per row: no sprite warning, full speed.
ROWS = [('SERVICE ROW 1', ('shop', None), ('vault', 0x1F)),
        ('SERVICE ROW 2', ('farm', 0x14), ('library', 0x0B)),
        ('SERVICE ROW 3', ('namer', 0x1D), ('medals', 0x0C)),
        ('SERVICE ROW 4', ('eggs', 0x14), ('gates', 0x1F))]
row_ids = []
for name, (k1, s1), (k2, s2) in ROWS:
    rid = d.new_room(name, 0, r, gate_theme=6)
    rm = d.room(rid)
    walls(rm['screens']['0']['layout']['id'])
    entry_script(rm, rid)
    for (kind, spr), (x, y) in (((k1, s1), (3, 4)), ((k2, s2), (6, 5))):
        if kind == 'shop':
            rm2, k = npc(rid, x, y, 0x0C)
            d.make_shopkeeper(rm2, '0', 0, k, shop,
                              greeting=[['Curio stall! New', 'items, new prices.']])
        else:
            rm2, k = npc(rid, x, y, spr)
            d.make_service_npc(rm2, '0', 0, k, kind)
    who = ' and '.join({'shop': 'the stall', 'vault': 'the Vault', 'farm': 'the farm keeper',
                        'library': 'the librarian', 'namer': 'the namer',
                        'medals': 'the Medal Man', 'eggs': 'the egg appraiser',
                        'gates': 'the gate guide'}[k] for k in (k1, k2))
    talker(rid, 8, 6, 0x0B, [{'say': B(
        f'{name}: {who}. Talk to each from BELOW - every box stays at the bottom. I am a '
        'plain sign: talked to from down here my box opens at the TOP, as the game does.')}],
        f'row{len(row_ids) + 1}_sign')
    row_ids.append(rid)
# the stairs: hall (1, 6) <-> row 1 (1, 1); row n (8, 1) <-> row n+1 (1, 1)
paint(hall['screens']['0']['layout']['id'], 1, 6, STAIRS)
prev = d.add_door(hall_id, '0', 1, 6, name='Curio stairs to the service rows')
for n, rid in enumerate(row_ids):
    lay = d.room(rid)['screens']['0']['layout']['id']
    paint(lay, 1, 1, STAIRS)
    back = d.add_door(rid, '0', 1, 1, name=f'Service row {n + 1} stairs back')
    d.link_doors(prev, back)
    if n + 1 < len(row_ids):
        paint(lay, 8, 1, STAIRS)
        prev = d.add_door(rid, '0', 8, 1, name=f'Service row {n + 1} stairs on')
row_mid = int(d.room(row_ids[0])['mapID'], 16)

cities = d.room('cities_fount')
talker(yard_id, 3, 4, 0x1D, [{'ask': B('I am the EXIT GUIDE. Back to the city with the '
                                       'fountain?', choice=True),
                              'yes': [{'move': {'dest': f"room:${int(cities['mapID'], 16):02X}",
                                                'screen': 0, 'x': 5, 'y': 5}}],
                              'no': [{'say': B('Take your time!')}]}], 'curio_exit')
talker(yard_id, 6, 2, 0x0B, [{'say': B(
    'THE CURIO YARD: wild Slimes. In battle choose ITEM: the MegaHerb heals like a Herb '
    '(45-55 now) and says its own name; the SparkRod calls lightning. The STAIRS (top '
    'left) go back up. The BRUISER (below) shows what a lost battle leaves you.')}],
    'curio_yard_sign')

talker('cities_fount', 3, 4, 0x1D, [{'say': B(
    'THE CURIO HALL (S151): every item can be edited - and a project can add NEW items that '
    'work like one of the game\'s.',
    'The CURIO STALL sells five: MegaHerb heals 80-90, HeroSeed gives ATK +10, SparkRod is a '
    'staff that never breaks, Feather leaves a gate but breaks half the time. The WarpWing '
    'is now PERMANENT, and the Herb heals 40-50.',
    'The KEYKEEPER gives an OldKey: you cannot use it or sell it, you keep it when you lose '
    'a battle, and the DOOR WARDEN knows you have it. The STAIRS top right go down to THE '
    'CURIO YARD (battles); the STAIRS bottom left to THE SERVICE ROWS.')},
    {'ask': B('S151 DEMO: THE CURIO HALL - items edited, and new items. Go?', choice=True),
    'yes': [{'move': {'dest': f'room:${hall_mid:02X}', 'screen': 0, 'x': 4, 'y': 6}}],
    'no': [{'say': B('Another time!')}]}], 's151demo')
d.save(dst)
# S151 r3 (the user: "so many NPCs in that room some of them are invisible and the whole
# thing lags massively. Did the editor not make a warning?" — it did, and this script's
# build was run with its warnings filtered out): the demo's rooms must build with NO warning
from editor2.core import compiler as _C                           # noqa: E402
_o, _p, _warns = _C.compile_project(d.project_dir, REPO)
_names = [d.room(rid)['name'] for rid in [hall_id, yard_id] + row_ids]
_mine = [x for x in _warns if any(f'room "{nm}"' in x or f'room {nm} ' in x for nm in _names)]
_city = d.room('cities_fount')['name']                     # the CURIO GUIDE's screen: its
_mine += [x for x in _warns if f'room "{_city}" screen 0' in x and any(   # NPC limits only
    k in x for k in ('row ', 'HALF SPEED', 'drops frames', 'NPCs on screen', 'NPC sprites'))]
if _mine:
    sys.exit('the demo rooms have build warnings:\n  ' + '\n  '.join(_mine))
print(f"hall ${hall_mid:02X}, yard ${yard_mid:02X}, rows from ${row_mid:02X}; new items {MEGA}-{KEY}")
