"""S148 demo (ROADMAP ARC CAP4 "$3E" box): THE REPLICA HALL on the user's project.

Make editable (a copy of a game room, tools/extract_room.py) stopped copying a script
at op $16 ("refresh sprites" — it only yields; the game goes on) until S148, and laid
the copy out in address order, so the copy FELL INTO THE NEXT BLOCK there:

  * the Castle's script 0 lost 186 steps: after the priest's GreatTree blessing (a
    return from a gate) the copy ran another scene instead of giving the HERB; the
    King's "How was it?" and his post-game greeting broke the same way;
  * the Priest gate floor's priest lost the music restore + the END after "HEAL!!!"
    and fell into his other line ("Every journey has its dangers…").

This demo makes the copies with the S148 copy tool and puts them behind a BRAND-NEW
room, THE REPLICA HALL (a gate theme of its own):

  * the CASTLE GUIDE (left): YES = into the REPLICA CASTLE (Make editable, "every state,
    following the original game") as if home from a gate ($D92B := 6, the King's speech
    code $D9E3 := 0) — the priest blesses the party ("Give the courageous master …
    the power of GreatTree!"), heals it, then says "For [HERO]'s safe journey, I'll give
    you an Herb!" and gives one;
  * the SPARRING SLIME (middle): a fight — the priest below heals only a party that is
    not at full HP and MP;
  * the STAIRS (top right) down to the REPLICA PRIEST FLOOR (Make editable, default:
    a copy of the Priest gate floor); its priest: "Let there be light! HEAL!!!", the
    flash, the music comes back — and nothing more; the hole in the floor = back up;
  * the EXIT GUIDE (right): back to Cities_FOUNT (the city with the fountain).

Way in: the REPLICA GUIDE in Cities_FOUNT at (3, 4) (a new NPC; YES = to the hall).

    python3 examples/s148_replica_demo/build_demo.py <base project.json> <out project.json>
        [--legacy-copies]

(the base project's assets/ folder must sit beside the out project.json).
--legacy-copies: make the two copies with the S92-S147 copy tool (extract_room
`decode_script(legacy_stop16=True)`) — the negative control of tools/walk_replicas.py.
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document                       # noqa: E402
from editor2.core.render_project import ProjectRenderer          # noqa: E402
from editor2.core import textenc as T                            # noqa: E402

LEGACY = '--legacy-copies' in sys.argv
argv = [a for a in sys.argv[1:] if a != '--legacy-copies']
src, dst = argv[0], argv[1] if len(argv) > 1 else argv[0]
if LEGACY:
    import importlib.util
    _spec = importlib.util.spec_from_file_location

    class _LegacyLoader:
        """Loads tools/extract_room.py, then makes decode_script the old tool's."""

        def __init__(self, inner):
            self.inner = inner

        def create_module(self, spec):
            return None

        def exec_module(self, mod):
            self.inner.exec_module(mod)
            dec = mod.decode_script

            def legacy(*a, **k):
                k['legacy_stop16'] = True
                return dec(*a, **k)
            mod.decode_script = legacy

    def _legacy_spec(name, path, *a, **k):
        sp = _spec(name, path, *a, **k)
        if str(path).endswith(os.path.join('tools', 'extract_room.py')):
            sp.loader = _LegacyLoader(sp.loader)
        return sp
    importlib.util.spec_from_file_location = _legacy_spec
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
SLIME = 0x00                     # species 0 = Slime (MONSTER_DATA)


def B(*paras, choice=False):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out, **({'choice': True} if choice else {})}


def paint(lid, cx, cy, mt):
    g = d.layout(lid)['tiles']
    g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1] = mt[0], mt[1]
    g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1] = mt[2], mt[3]


def text(tid, spec):
    """A dialogue entry of the project (raw scripts name it)."""
    dl = d.custom.setdefault('dialogue', [])
    e = {'id': tid, **spec, 'comment': 'S148 replica demo'}
    dl.append(e)
    return tid


# ---- the copies (the S148 copy tool) ---------------------------------------------
castle_id = d.clone_vanilla(0x00, 'REPLICA CASTLE', REPO, r, keep=None)
r.invalidate()
priest_id = d.clone_vanilla(0x51, 'REPLICA PRIEST FLOOR', REPO, r, keep='default')
r.invalidate()
castle = d.room(castle_id)
priest = d.room(priest_id)
castle_mid = int(castle['mapID'], 16)

# the priest floor's hole (8, 2) was the gate's way down (wWarpFlag $80, a floor kick):
# in a copy outside a gate it becomes the door back up to the hall
pscr = priest['screens']['0']
pscr['exits'] = [e for e in pscr.get('exits') or [] if (e.get('x'), e.get('y')) != (8, 2)]

# ---- the hall --------------------------------------------------------------------
hall_id = d.new_room('REPLICA HALL', 0, r, gate_theme=11)
hall = d.room(hall_id)
hall_mid = int(hall['mapID'], 16)
lid = hall['screens']['0']['layout']['id']
for cx in range(10):
    paint(lid, cx, 0, WALL)
    paint(lid, cx, 7, WALL)
for cy in range(8):
    paint(lid, 0, cy, WALL)
    paint(lid, 9, cy, WALL)
paint(lid, 8, 1, STAIRS)

a = d.add_door(hall_id, '0', 8, 1, name='Replica stairs down')
b = d.add_door(priest_id, '0', 8, 2, name='Replica hole up')
d.link_doors(a, b)

k_castle = d.add_npc(hall, '0', 0, 2, 3, 0x0B, 'down')
k_exit = d.add_npc(hall, '0', 0, 7, 5, 0x1D, 'down')
d.add_npc(hall, '0', 0, 5, 4, 0xF0, 'down', monster=SLIME)
k_slime = len(d.npc_entries(hall, '0', 0)) - 1

# the CASTLE GUIDE: a raw script (the arrival code needs RAM writes; story steps do
# not write RAM): YES -> $D92B := 6 (the Castle's "home from a gate" code, written by
# every vanilla boss room's entry script), $D9E3 := 0 (no King's speech pending), the
# warp onto the throne room cell the game's own boss tails use ($E8, $58 = screen 1)
q = text('s148_castle_q', B(
    'THE REPLICA HALL. Behind me: the REPLICA CASTLE, a copy of the Castle made with '
    'Make editable (every state, following the original game).',
    'Go in as if you came home from a gate? The priest blesses you, heals you, and then '
    "gives you an HERB. (A copy made before S148 broke right after the healing.)",
    choice=True))
no = text('s148_castle_no', B('Another time!'))
sid_c = 's148_castle_guide'
d.custom['scripts'].append({'id': sid_c, 'ops': [
    ['text', q],
    ['op', 'check_and_branch', '0xC83C', '0x0001', '@no'],
    ['op', 'write_ram', '0xD92B', '0x0006'],
    ['op', 'write_ram', '0xD9E3', '0x0000'],
    ['op', 'map_transition', f'0x{castle_mid:04X}', '0x00E8', '0x0058'],
    ['end'],
    'label:no',
    ['text', no],
    ['end']]})
tbl = hall.setdefault('scripts', {})
if '0' not in tbl:
    tbl['0'] = f'{hall_id}_entry'
    d.custom['scripts'].append({'id': tbl['0'], 'ops': [['end']]})
tbl['1'] = sid_c
d.update_npc(hall, '0', 0, k_castle, script=sid_c)

# the SPARRING SLIME: a fight that leaves marks (fast, hits hard, falls at once)
foe = d.add_enemy(copy_eid=2, name='Sparring Slime', species=SLIME, level=1, hp=2,
                  agl=511, atk=80, joinability=7)
spar = [{'ask': B('I am the SPARRING SLIME. I hit first and hard, so the priest '
                  'downstairs has something to heal. Fight?'),
         'yes': [{'battle': {'enemies': [foe]}},
                 {'say': B('Ouch. Now take the STAIRS (top right) down to the '
                           'REPLICA PRIEST FLOOR and talk to the priest.')}],
         'no': [{'say': B('The priest heals only a party that lost HP or MP.')}]}]
sid_s = d.new_conversation(hall, {'steps': spar}, name='sparring')
d.update_npc(hall, '0', 0, k_slime, script=sid_s)

cities = d.room('cities_fount')
back = [{'ask': B('Back to the city with the fountain?'),
         'yes': [{'move': {'dest': f"room:${int(cities['mapID'], 16):02X}", 'screen': 0,
                           'x': 5, 'y': 5}}],
         'no': [{'say': B('The REPLICA PRIEST FLOOR is down the STAIRS.')}]}]
sid_x = d.new_conversation(hall, {'steps': back}, name='exit')
d.update_npc(hall, '0', 0, k_exit, script=sid_x)

k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')
demo = [{'ask': B('S148 DEMO: the REPLICA HALL - copies of the Castle and the Priest '
                  'floor made with Make editable. Go?'),
         'yes': [{'move': {'dest': f'room:${hall_mid:02X}', 'screen': 0, 'x': 4, 'y': 6}}],
         'no': [{'say': B('Another time!')}]}]
sid = d.new_conversation(cities, {'steps': demo}, name='s148demo')
d.update_npc(cities, '0', 0, k_demo, script=sid)
d.save(dst)
print(f'hall ${hall_mid:02X}, castle copy ${castle_mid:02X}, priest copy '
      f"${int(priest['mapID'], 16):02X}")
