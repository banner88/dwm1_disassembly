"""S161 demo (ROADMAP E17 + the E13 note): THE MIRROR HALL on the user's project.

E17 — the enemy AI and NEW skills. The AI scores a skill by its record's AI weight, a roll and
the bonuses / vetoes of the bank $57 rule chains, which pick skills BY ID; a new id matched
none of them, so an enemy (almost) never cast a new skill. Since S161 the AI judges a new
skill AS ITS BASE (the rules see the base's id; every record read still gives the new skill's
own data). This demo puts sparring partners side by side: a STOCK row with four original
skills and its NEW twin with four new skills on the same bases (the same data), on the high
ids and on the reclaimed ids.

E13 note — two skills evolving from ONE skill. Blazemore (original) and FLARE (new) both
evolve from Blaze at level 13; GLOW (new) evolves from Blaze at level 40. Until S161 the
level up that taught both Blazemore and Flare never ended ("… becomes …!" forever); since
S161 the first replaces Blaze and the second is learned as a new skill. Glow can never be
learned once Blaze has become Blazemore.

  new skills  base         id
  NFireb      Firebal 3    239 (high)   NEW MAGE
  NBang       Bang 6       240
  NInfer      Infernos 9   241
  NSnow       SnowStorm 13 242
  NSleep      Sleep 21     243          NEW CASTER
  NSap        Sap 28       244
  NPsych      PsycheUp 86  245
  NVolt       BoltSlash 69 246
  Flare       Blaze 0      247          from Blaze, level 13 (beside Blazemore)
  Glow        Blaze 0      248          from Blaze, level 40
  PFireb      Firebal 3    249          PICKY MAGE: AI preference 0
  PBang       Bang 6       250            -60 (avoids it: never cast)
  PInfer      Infernos 9   251            0
  PSnow       SnowStorm 13 252            +60 (favours it)
  (253, 254 spare)
  RFireb … RSnow           188-191 (reclaimed: LifeAcorn, MysticNut, AtkSeed, DefSeed)
                                        RECL MAGE

  * THE MIRROR HALL (a new room, three screens west to east, gate look 4):
      screen 0: the MIRROR GUIDE (what is where; YES = back to the city), the SIBLING
        KEEPER (YES = TWINFLAME, a Healer, level 12, Blaze only: its next level up teaches
        Blazemore AND Flare; with eight skills already it asks which one to forget —
        tools/walk_mirror.py checks that case), the PICKY MAGE (the mage's four as new
        skills with AI preferences: SnowStorm's twin +60, Bang's twin -60).
      screen 1: the STOCK MAGE (Firebal, Bang, Infernos, SnowStorm; INT 200), the NEW MAGE
        (the N twins), the TRAINING DUMMY (weak, a lot of EXP).
      screen 2: the STOCK CASTER (Sleep, Sap, PsycheUp, BoltSlash), the NEW CASTER (the N
        twins), the RECL MAGE (the R twins of the mage, on reclaimed ids).

Way in: the MIRROR GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s161_mirror_demo/build_demo.py <base project.json> <out project.json>

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


# ---- the new skills ------------------------------------------------------------------------
BLAZE = 0
MAGE = [(3, 'Fireb'), (6, 'Bang'), (9, 'Infer'), (13, 'Snow')]
CASTER = [(21, 'Sleep'), (28, 'Sap'), (86, 'Psych'), (69, 'Volt')]
N, R = {}, {}
for base, nm in MAGE + CASTER:
    N[nm] = d.new_custom_skill(base, 'N' + nm)
FLARE = d.new_custom_skill(BLAZE, 'Flare')
GLOW = d.new_custom_skill(BLAZE, 'Glow')
# Document.new_custom_skill takes the next free id, the 16 high ids first: the mage's R twins
# need reclaimed ids, so the remaining high ids go to SPARE skills nobody uses or learns, then
# the four R twins land on 188-191.
P = {}
for base, nm in MAGE:
    P[nm] = d.new_custom_skill(base, 'P' + nm)
d.set_skill_ai_pref(P['Bang'], -60)
d.set_skill_ai_pref(P['Snow'], 60)
SPARE = []
for k in range(16 - len(N) - len(P) - 2):
    SPARE.append(d.new_custom_skill(3, f'Spare{k}'))
for base, nm in MAGE:
    R[nm] = d.new_custom_skill(base, 'R' + nm)
assert sorted(list(N.values()) + [FLARE, GLOW] + list(P.values()) + SPARE) == list(range(239, 255))
assert sorted(R.values()) == [188, 189, 190, 191], R
for nm, sid in list(N.items()) + list(R.items()) + list(P.items()):
    d.set_skill_description(sid, [f'Mirror test {sid}', 'a NEW skill on a', 'stock base.'])
d.set_skill_description(FLARE, ['Mirror test, from', 'Blaze, beside', 'Blazemore, lv 13'])
d.set_skill_description(GLOW, ['Mirror test, from', 'Blaze, level 40;', 'never after it.'])
ZERO = {'hp': 0, 'atk': 0, 'def': 0, 'agl': 0}
# Blazemore (original row): level 13, MP 46, INT 64, from Blaze. Flare: the same level.
d.set_skill_learn(FLARE, {'level': 13, **ZERO, 'mp': 46, 'int': 64, 'prereqs': [BLAZE]})
d.set_skill_learn(GLOW, {'level': 40, **ZERO, 'mp': 46, 'int': 64, 'prereqs': [BLAZE]})
for sid in list(N.values()) + list(R.values()) + list(P.values()) + SPARE:
    d.set_skill_learn(sid, {'learnable': False})

HEALER, EYEBALL, BABBLE, SWORDGON = 9, 135, 6, 27
twinflame = d.add_enemy(copy_eid=2, name='Twinflame', species=HEALER, level=12, hp=120, mp=99,
                        atk=40, **{'def': 40}, agl=40, int=99, joinability=7, skills=[BLAZE])
dummy = d.add_enemy(copy_eid=2, name='Dummy', species=BABBLE, level=1, hp=5, mp=0, atk=1,
                    **{'def': 1}, agl=1, int=1, exp=2000, joinability=7, skills=[])


def sparrer(name, sp, skills, **kw):
    return d.add_enemy(copy_eid=2, name=name, species=sp, level=15, hp=400, mp=250,
                       atk=40, **{'def': 50}, agl=40, int=200, joinability=7,
                       ai_weights=[30, 250, 30, 0], skills=skills, **kw)


# S163: the STOCK / NEW MAGE rows hold back group spells (S162: a project row's own
# `holds_group_spells`, absent = casts) — the walk's `dupcast` pair counts the conversions
# (until S162 these rows read the flag table past its end: "holding" by accident)
smage = sparrer('Stock mage', EYEBALL, [b for b, _ in MAGE], holds_group_spells=True)
nmage = sparrer('New mage', EYEBALL, [N[t] for _, t in MAGE], holds_group_spells=True)
rmage = sparrer('Recl mage', EYEBALL, [R[t] for _, t in MAGE])
pmage = sparrer('Picky mage', EYEBALL, [P[t] for _, t in MAGE])
scast = sparrer('Stock caster', SWORDGON, [b for b, _ in CASTER])
ncast = sparrer('New caster', SWORDGON, [N[t] for _, t in CASTER])

# ---- THE MIRROR HALL: three screens in a row (at most 3 NPCs a screen, one a row) ---------
hall_id = d.new_room('MIRROR HALL', 0, r, gate_theme=4)
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
    'THE MIRROR HALL. Enemies now use a new skill as often as the skill it is built on. '
    'East: a STOCK row and its NEW twin side by side. Here: two skills from one skill. '
    'Back to the city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Look in the mirror.')}]}], 'mirror_guide')
npc(hall_id, '0', 5, 5, 0x1D, [
    {'ask': B('I am the SIBLING KEEPER. Take TWINFLAME? It knows Blaze. At level 13 it '
              'learns Blazemore AND Flare, both from Blaze. Glow (from Blaze, level 40) it '
              'can never learn after that.', choice=True),
     'yes': [{'give_monster': {'enemy': twinflame, 'to': 'party'}},
             {'say': B('Beat the DUMMY, east, for its level up.')}],
     'no': [{'say': B('Come back any time.')}]}], 'sibling_keeper')
npc(hall_id, '0', 7, 2, 0xF0, [
    {'ask': B('I am the PICKY MAGE: the mage\'s four as new skills. AI preference: my '
              'SnowStorm twin +60, my Bang twin -60. So: lots of PSnow, never PBang. '
              'Fight?', choice=True),
     'yes': [{'battle': {'enemies': [pmage]}}, {'say': B('Picky, picky.')}],
     'no': [{'say': B('Another time.')}]}], 'spar_pmage', monster=EYEBALL)


def spar(key, x, y, monster, intro, enemies, name):
    return npc(hall_id, key, x, y, 0xF0, [
        {'ask': B(intro + ' Fight?', choice=True),
         'yes': [{'battle': {'enemies': enemies}},
                 {'say': B('A good fight!')}],
         'no': [{'say': B('Another time.')}]}], name, monster=monster)


spar('1', 2, 2, EYEBALL, 'I am the STOCK MAGE: Firebal, Bang, Infernos, SnowStorm.', [smage],
     'spar_smage')
spar('1', 5, 4, EYEBALL, 'I am the NEW MAGE: NFireb, NBang, NInfer, NSnow, new skills on '
     'the same four.', [nmage], 'spar_nmage')
spar('1', 8, 5, BABBLE, 'I am the TRAINING DUMMY. Beat me for EXP.', [dummy], 'spar_dummy')
spar('2', 2, 2, SWORDGON, 'I am the STOCK CASTER: Sleep, Sap, PsycheUp, BoltSlash.', [scast],
     'spar_scast')
spar('2', 5, 4, SWORDGON, 'I am the NEW CASTER: their new twins.', [ncast], 'spar_ncast')
spar('2', 8, 5, EYEBALL, 'I am the RECL MAGE: the mage\'s four on the ids of LifeAcorn and '
     'the seeds.', [rmage], 'spar_rmage')

# ---- the way in: the MIRROR GUIDE in Cities_FOUNT --------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the MIRROR GUIDE. To the MIRROR HALL, '
                                                 'where enemies learned new skills?',
                                                 choice=True),
                                       'yes': [go_to(hall_mid, 4, 4)],
                                       'no': [{'say': B('Another time.')}]}], 'hall_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'N', N, 'R', R, 'P', P, 'FLARE', FLARE, 'GLOW', GLOW, 'SPARE', SPARE,
      'enemies', twinflame, dummy, smage, nmage, rmage, pmage, scast, ncast)
