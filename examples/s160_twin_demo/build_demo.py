"""S160 demo (30 NEW skill ids; ROADMAP E13): THE TWIN HALL on the user's project.

Since S160 a project has 30 NEW skill slots: the 16 high ids 239-254 ($EF-$FE) as before,
then the 14 RECLAIMED ids — the battle skills of LifeAcorn, MysticNut, AtkSeed, DefSeed,
AglSeed, IntSeed (188-193, $BC-$C1) and of WarpWing, TinyMedal and the six books (204-211,
$CC-$D3). Those 14 items are FIELD-ONLY for good (they never worked in battle in the
original game either: their skill row said "not usable in battle"); a new skill on a
reclaimed id acts exactly like one on a high id.

This demo makes all 30, in TWINS: the first 14 high ids and the 14 reclaimed ids hold the
SAME 14 effects ("H…" = a high id, "R…" = its reclaimed twin), plus two more high ids:

  pair  base        high id   reclaimed id
  Fireb Firebal 3   239 $EF   188 $BC   (LifeAcorn's old id)  HFireb evolves from Blazemost, RFireb from Firebolt
  Bang  Bang 6      240 $F0   189 $BD   evolve from Blazemost AND Firebolt (never learned: see help 54)
  Infer Infernos 9  241       190
  Sleep Sleep 21    242       191
  Sap   Sap 28      243       192
  Antid Antidote 51 244       193 $C1
  Multi MultiCut 79 245       204 $CC   (WarpWing's old id)
  Beser Beserker    246       205
  Evil  EvilSlash   247       206
  Volt  BoltSlash   248       207
  Squal SquallHit   249       208
  Psych PsycheUp    250       209
  FAir  FireAir     251       210
  Whist Whistle     252       211 $D3
  + HSnow (SnowStorm, 253) and HHell (Hellblast, 254).
  HFireb / RFireb have their own announce lines (the reclaimed rows of the line table).

  * THE TWIN HALL (a new room, three screens west to east, gate look 9):
      screen 0: the TWIN GUIDE (what is where; YES = back to the city), the GIFT KEEPER
        (YES = HIGHTWIN and RECLTWIN, two KingSlimes: HFireb / HInfer / HAntid / HMulti and
        RFireb / RInfer / RAntid / RMulti), the LEARN TUTOR (YES = LEARNER, a Healer with
        Blazemost, Firebolt, HFAir and RFAir, INT 999: one level up teaches HFireb +
        RFireb).
      screen 1: the HIGH SLASHER (HEvil / HBeser / HSqual / HWhist, INT 200), the RECL
        SLASHER (the R twins), the TRAINING DUMMY (weak, a lot of EXP: level LEARNER up).
      screen 2: the HIGH CASTER (HSleep / HSap / HPsych / HVolt, INT 200), the RECL CASTER
        (the R twins), the ITEM KEEPER (YES = a LifeAcorn and a WarpWing: in battle "Can't
        use this item in battle!", in the field as always).

Way in: the TWIN GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s160_twin_demo/build_demo.py <base project.json> <out project.json>

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


def npc(room_id, key, x, y, sprite, steps, name, monster=None):
    rm = d.room(room_id)
    d.add_npc(rm, key, 0, x, y, sprite, 'down', **({'monster': monster} if monster else {}))
    k = len(d.npc_entries(rm, key, 0)) - 1
    sid = d.new_conversation(rm, {'steps': steps}, name=name)
    d.update_npc(rm, key, 0, k, script=sid)
    return sid


def go_to(mid, x=4, y=5):
    return {'move': {'dest': f'room:${mid:02X}', 'screen': 0, 'x': x, 'y': y}}


# ---- the 30 new skills ------------------------------------------------------------------
BLAZEMOST, FIREBOLT = 2, 5             # two skills nothing else evolves from (S160: see help 54)
PAIRS = [(3, 'Fireb'), (6, 'Bang'), (9, 'Infer'), (21, 'Sleep'), (28, 'Sap'), (51, 'Antid'),
         (79, 'Multi'), (61, 'Beser'), (64, 'Evil'), (69, 'Volt'), (85, 'Squal'),
         (86, 'Psych'), (92, 'FAir'), (126, 'Whist')]
EXTRA = [(13, 'Snow'), (100, 'Hell')]
H, R = {}, {}
for base, nm in PAIRS:
    H[nm] = d.new_custom_skill(base, 'H' + nm)
for base, nm in EXTRA:
    H[nm] = d.new_custom_skill(base, 'H' + nm)
for base, nm in PAIRS:
    R[nm] = d.new_custom_skill(base, 'R' + nm)
assert sorted(H.values()) == list(range(239, 255)), H
assert sorted(R.values()) == list(range(188, 194)) + list(range(204, 212)), R
for nm, sid in H.items():
    d.set_skill_description(sid, [f'Twin test, id {sid}', 'a HIGH new-skill', 'id.'])
for nm, sid in R.items():
    d.set_skill_description(sid, [f'Twin test, id {sid}', 'a RECLAIMED item', 'id.'])
d.set_skill_announce(H['Fireb'], lines=['{name} hurls a', 'HIGH fireball!'])
d.set_skill_announce(R['Fireb'], lines=['{name} hurls a', 'RECLAIMED fireball'])
ZERO = {'hp': 0, 'mp': 0, 'atk': 0, 'def': 0, 'agl': 0}
# one prerequisite each (learned; never two skills from ONE skill: the game freezes —
# the compiler warns, ROADMAP E13 note):
d.set_skill_learn(H['Fireb'], {'level': 1, **ZERO, 'int': 900, 'prereqs': [BLAZEMOST]})
d.set_skill_learn(R['Fireb'], {'level': 1, **ZERO, 'int': 900, 'prereqs': [FIREBOLT]})
for t in ('Bang',):                                    # two prerequisites: never learned
    for sid in (H[t], R[t]):
        d.set_skill_learn(sid, {'level': 1, **ZERO, 'int': 900, 'prereqs': [BLAZEMOST, FIREBOLT]})

KINGSLIME, HEALER, SWORDGON, EYEBALL, BABBLE = 15, 9, 27, 135, 6
hightwin = d.add_enemy(copy_eid=2, name='Hightwin', species=KINGSLIME, level=20, hp=300,
                       mp=300, atk=90, **{'def': 80}, agl=60, int=80, joinability=7,
                       skills=[H['Fireb'], H['Infer'], H['Antid'], H['Multi']])
recltwin = d.add_enemy(copy_eid=2, name='Recltwin', species=KINGSLIME, level=20, hp=300,
                       mp=300, atk=90, **{'def': 80}, agl=60, int=80, joinability=7,
                       skills=[R['Fireb'], R['Infer'], R['Antid'], R['Multi']])
learner = d.add_enemy(copy_eid=2, name='Learner', species=HEALER, level=1, hp=60, mp=80,
                      atk=20, **{'def': 20}, agl=20, int=999, joinability=7,
                      skills=[BLAZEMOST, FIREBOLT, H['FAir'], R['FAir']])


def sparrer(name, sp, skills):
    return d.add_enemy(copy_eid=2, name=name, species=sp, level=15, hp=400, mp=250,
                       atk=40, **{'def': 50}, agl=40, int=200, joinability=7,
                       ai_weights=[30, 250, 30, 0], skills=skills)


hslash = sparrer('High slasher', SWORDGON, [H[t] for t in ('Evil', 'Beser', 'Squal', 'Whist')])
rslash = sparrer('Recl slasher', SWORDGON, [R[t] for t in ('Evil', 'Beser', 'Squal', 'Whist')])
hcast = sparrer('High caster', EYEBALL, [H[t] for t in ('Sleep', 'Sap', 'Psych', 'Volt')])
rcast = sparrer('Recl caster', EYEBALL, [R[t] for t in ('Sleep', 'Sap', 'Psych', 'Volt')])
dummy = d.add_enemy(copy_eid=2, name='Dummy', species=BABBLE, level=1, hp=5, mp=0, atk=1,
                    **{'def': 1}, agl=1, int=1, exp=2000, joinability=7, skills=[])

# ---- THE TWIN HALL: three screens in a row (at most 3 NPCs a screen, one a row) --------
hall_id = d.new_room('TWIN HALL', 0, r, gate_theme=9)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lays = [lay0]
for k in (1, 2):
    lid = d.unique_layout_id(f'{hall_id}_s{k}')
    d.add_layout(lid, tiles=[list(row) for row in d.layout(lay0)['tiles']],
                 attr=[list(row) for row in d.layout(lay0)['attr']])
    d.add_screen(d.room(hall_id), k, {'id': lid})
    lays.append(lid)
for k, l_ in enumerate(lays):
    walls(l_)
    if k < 2:
        paint(l_, 9, 4, FLOOR)                         # the way east
    if k > 0:
        paint(l_, 0, 4, FLOOR)                         # the way west
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 3, 0x0B, [{'ask': B(
    'THE TWIN HALL. 30 new skills now: 16 on the high ids, 14 on the ids LifeAcorn, the '
    'seeds, WarpWing, TinyMedal and the books used. Every H skill has an R twin that '
    'works the same. Gifts here, sparring east. Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Twins, twins.')}]}], 'twin_guide')
npc(hall_id, '0', 5, 5, 0x1D, [
    {'ask': B('I am the GIFT KEEPER. Take HIGHTWIN and RECLTWIN? Fireb, Infer, Antid and '
              'Multi: one has the H skills, the other the R twins.', choice=True),
     'yes': [{'give_monster': {'enemy': hightwin, 'to': 'party'}},
             {'give_monster': {'enemy': recltwin, 'to': 'party'}},
             {'say': B('Cast the same skill from each one. Fireb has its own line.')}],
     'no': [{'say': B('Come back any time.')}]}], 'gift_keeper')
npc(hall_id, '0', 7, 2, 0x0B, [
    {'ask': B('I am the LEARN TUTOR. Take LEARNER? It knows Blazemost and Firebolt. One '
              'level up (the DUMMY, east) and it learns HFireb (from Blazemost) and RFireb '
              '(from Firebolt). HBang and RBang need BOTH: those it never learns.',
              choice=True),
     'yes': [{'give_monster': {'enemy': learner, 'to': 'party'}},
             {'say': B('Put LEARNER in your party and beat the DUMMY.')}],
     'no': [{'say': B('Another time.')}]}], 'learn_tutor')


def spar(key, x, y, monster, intro, enemies, name):
    return npc(hall_id, key, x, y, 0xF0, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': enemies}},
                 {'say': B('A good fight!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=monster)


spar('1', 2, 2, SWORDGON, 'I am the HIGH SLASHER: HEvil, HBeser, HSqual, HWhist.', [hslash],
     'spar_hslash')
spar('1', 5, 4, SWORDGON, 'I am the RECL SLASHER: the R twins of the HIGH SLASHER.', [rslash],
     'spar_rslash')
spar('1', 8, 5, BABBLE, 'I am the TRAINING DUMMY. Beat me for EXP.', [dummy], 'spar_dummy')
spar('2', 2, 2, EYEBALL, 'I am the HIGH CASTER: HSleep, HSap, HPsych, HVolt.', [hcast],
     'spar_hcast')
spar('2', 5, 4, EYEBALL, 'I am the RECL CASTER: the R twins of the HIGH CASTER.', [rcast],
     'spar_rcast')
LIFEACORN, WARPWING = 13, 29
npc(hall_id, '2', 8, 5, 0x1D, [
    {'ask': B('I am the ITEM KEEPER. A LifeAcorn and a WarpWing? Their battle ids hold new '
              'skills now, so in battle: "Can\'t use this item in battle!" In the field they '
              'work as always.', choice=True),
     'yes': [{'give_item': {'item': LIFEACORN, 'count': 1, 'got': B('You got a LifeAcorn!')}},
             {'give_item': {'item': WARPWING, 'count': 1, 'got': B('You got a WarpWing!')}}],
     'no': [{'say': B('Another time.')}]}], 'item_keeper')

# ---- the way in: the TWIN GUIDE in Cities_FOUNT --------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the TWIN GUIDE. To the TWIN HALL, '
                                                 'where the 30 new skills are?', choice=True),
                                       'yes': [go_to(hall_mid, 4, 4)],
                                       'no': [{'say': B('Another time.')}]}], 'hall_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'H', H, 'R', R, 'enemies', hightwin, recltwin, learner,
      hslash, rslash, hcast, rcast, dummy)
