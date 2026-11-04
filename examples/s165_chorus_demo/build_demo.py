"""S165 demo (ROADMAP E13 note "the 17 bases a copy still cannot run" + Phase F T-follow (a) "the
words drawn in the windows"): THE CHORUS HALL on the user's project.

E13 note — a NEW skill runs its base's effect under its own id; since S163 the effect code's
questions "which skill is this?" see the base (the act-time base view). 17 bases still answered
with the new id (the S163 census never ran them as a base — the compiler refused them): Sacrifice,
Bounce, Farewell, Massacre, QuadHits, Vacuum, PoisonAir, SandStorm, DeMagic, UltraDown, ThickFog,
TatsuCall, DiagoCall, SamsiCall, Guardian, StrongD, BladeD; S165 patched their 23 reads + the
turn order's defensive list (banks $52 / $53 / $58) and every base the game has is now one a new
skill may run (extracted/skill_clone_census.json: 155 same, 0 differ).

  * THE CHORUS HALL (a new room, two screens west to east, gate look 5):
      screen 0: the CHORUS GUIDE (what this is; YES = back to the city);
      screen 0: the SUMMON KEEPER (YES = ORIGINAL A + CHORUS A: TatsuCall, Guardian, Bounce, Farewell —
        and the four new twins CTatsu, CGuard, CBounce, CFarewl);
      screen 1: the STORM KEEPER (YES = ORIGINAL B + CHORUS B: QuadHits, Vacuum, PoisonAir, SandStorm and
        their twins);
      the HUSH KEEPER (YES = ORIGINAL C + CHORUS C: DeMagic, ThickFog, UltraDown, Sacrifice and
        their twins);
      screen 1: the SPARRING SLIME (YES = three sturdy, gentle slimes): cast each skill from ORIGINAL and
        from CHORUS and compare;
      screen 0: the WORDSMITH (the window words of this ROM: the field menu's INFO is STAT, the INFO
        page's ATK is POW, OPTN's JOURNAL is DIARY, the title menu says Continue).

Also in the project (for tools/walk_actbase.py --set s165, not given to the player): the twins of
Massacre, DiagoCall, SamsiCall, StrongD, BladeD (the 17th lands on the reclaimed id 188).

Way in: the CHORUS GUIDE in Cities_FOUNT at (3, 4) (YES = to the hall).

    python3 examples/s165_chorus_demo/build_demo.py <base project.json> <out project.json>

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


# ---- the new twins: every base S165 opened (walk_actbase --set s165 finds them by the C) -----
TWINS = [(132, 'Tatsu'), (137, 'Guard'), (40, 'Bounce'), (50, 'Farewl'),          # pair A
         (81, 'QuadHt'), (89, 'Vacuum'), (109, 'PoisAr'), (114, 'SandSt'),        # pair B
         (128, 'DeMagc'), (131, 'ThkFog'), (130, 'UltraD'), (20, 'Sacrif'),       # pair C
         (63, 'Massac'), (133, 'Diago'), (134, 'Samsi'), (142, 'StrngD'), (144, 'BladeD')]
C = {}
for base, nm in TWINS:
    C[base] = d.new_custom_skill(base, 'C' + nm)
    d.set_skill_description(C[base], [f'Chorus of {base}', 'a NEW skill on', 'that base.'])

HEALER, SLIME = 9, 0


def pair(tag, bases):
    stats = dict(copy_eid=2, species=HEALER, level=25, hp=400, mp=400, atk=60, **{'def': 60},
                 agl=60, int=150, joinability=7)
    o = d.add_enemy(name=f'Original{tag}', skills=list(bases), **stats)
    c = d.add_enemy(name=f'Chorus{tag}', skills=[C[b] for b in bases], **stats)
    return o, c


oa, ca = pair('A', [132, 137, 40, 50])
ob, cb = pair('B', [81, 89, 109, 114])
oc, cc = pair('C', [128, 131, 130, 20])
sparring = d.add_enemy(copy_eid=2, name='Spar slime', species=SLIME, level=10, hp=600, mp=0,
                       atk=12, **{'def': 30}, agl=10, int=1, joinability=7, skills=[])

# ---- the window words of this ROM (gamedata.window_words, editor2/core/window_words.py) ------
d.set_window_word('07:704D/1/2', 'STAT')          # the field menu: INFO -> STAT
d.set_window_word('07:70AD/1/2', 'STAT')          # the WHO list's header too
d.set_window_word('07:70F7/3/2', 'POW')           # the INFO page: ATK -> POW
d.set_window_word('07:7A61/9/2', 'DIARY')         # OPTN: JOURNAL -> DIARY
d.set_window_word('15:647D/1/2', 'Continue')      # the title menu

# ---- THE CHORUS HALL -------------------------------------------------------------------------
hall_id = d.new_room('CHORUS HALL', 0, r, gate_theme=5)
hall = d.room(hall_id)
lay0 = hall['screens']['0']['layout']['id']
walls(lay0)
FLOOR = d.layout(lay0)['tiles'][8][8:10] + d.layout(lay0)['tiles'][9][8:10]
lay1 = d.unique_layout_id(f'{hall_id}_s1')
d.add_layout(lay1, tiles=[list(row) for row in d.layout(lay0)['tiles']],
             attr=[list(row) for row in d.layout(lay0)['attr']])
d.add_screen(d.room(hall_id), 1, {'id': lay1})       # two screens in a row: at most 3 NPCs
walls(lay1)                                          # a screen (S151 r3: 5+ = half speed)
paint(lay0, 9, 4, FLOOR)                             # the way east
paint(lay1, 0, 4, FLOOR)                             # the way west
hall = d.room(hall_id)
entry_script(hall, hall_id)
cities = d.room('cities_fount')
c_mid = int(cities['mapID'], 16)

npc(hall_id, '0', 2, 2, 0x0B, [{'ask': B(
    'THE CHORUS HALL. A new skill runs the effect of its base. Seventeen bases still asked '
    '"which skill is this?" and heard the new one. Now all of them hear the base. Back to the '
    'city?', choice=True),
    'yes': [go_to(c_mid)], 'no': [{'say': B('Sing along.')}]}], 'chorus_guide')


def keeper(scr, x, y, title, o, c, what, after):
    return npc(hall_id, scr, x, y, 0x1D, [
        {'ask': B(f'I am the {title}. Take ORIGINAL and CHORUS? ORIGINAL knows {what}. CHORUS '
                  'knows their new twins.', choice=True),
         'yes': [{'give_monster': {'enemy': o, 'to': 'party'}},
                 {'give_monster': {'enemy': c, 'to': 'party'}},
                 {'say': B(after)}],
         'no': [{'say': B('Come back any time.')}]}], title.lower().replace(' ', '_'))


keeper('0', 5, 4, 'SUMMON KEEPER', oa, ca, 'TatsuCall, Guardian, Bounce and Farewell',
       'The twin of TatsuCall calls the same helper with the same HP and MP. The Guardian twin '
       'guards like Guardian. Bounce and Farewell say and do the same.')
keeper('1', 3, 2, 'STORM KEEPER', ob, cb, 'QuadHits, Vacuum, PoisonAir and SandStorm',
       'QuadHits and Vacuum hit as hard as the originals. PoisonAir and SandStorm show the same '
       'lines.')
keeper('1', 6, 5, 'HUSH KEEPER', oc, cc, 'DeMagic, ThickFog, UltraDown and Sacrifice',
       'DeMagic, ThickFog and UltraDown say the same lines. Careful: Sacrifice costs its caster.')
npc(hall_id, '1', 7, 4, 0x10, [
    {'ask': B('I am the SPARRING SLIME. Three of us, tough and gentle. Fight?', choice=True),
     'yes': [{'battle': {'enemies': [sparring, sparring, sparring]}},
             {'say': B('Again any time!')}],
     'no': [{'say': B('Another time.')}]}], 'chorus_spar', monster=SLIME)
npc(hall_id, '0', 7, 6, 0x0B, [{'say': B(
    'I am the WORDSMITH. The words of the windows are tiles, now editable. In this ROM the '
    'menu says STAT for INFO, the stats page says POW for ATK, OPTN says DIARY for JOURNAL, '
    'and the title says Continue.')}], 'chorus_wordsmith')

# ---- the way in: the CHORUS GUIDE in Cities_FOUNT ------------------------------------------
hall_mid = int(d.room(hall_id)['mapID'], 16)
npc('cities_fount', '0', 3, 4, 0x0B, [{'ask': B('I am the CHORUS GUIDE. To the CHORUS HALL, where '
                                                 'every new skill answers as its base?',
                                                 choice=True),
                                       'yes': [go_to(hall_mid, 4, 5)],
                                       'no': [{'say': B('Another time.')}]}], 'chorus_way_in')

d.save(dst)
print('hall', hall_id, hex(hall_mid), 'twins', C, 'rows', oa, ca, ob, cb, oc, cc, sparring)
