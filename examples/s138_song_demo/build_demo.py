"""S138 demo (ROADMAP ARC CAP2e): the SONG GROTTOS on the user's project.

Sixteen BRAND-NEW rooms, SONG GROTTO 1-16 (map ids $76-$85 on the user's 11-room project),
each one screen in its own gate theme. Every grotto has its OWN ROOM SONG and its own
BATTLE SONG. Grottos 11-16 sit at map ids $80-$85: before S138 the room-song and
battle-song tables of bank $71 stopped at $7F (`cp $80`), so a project's 22nd room and
every room after it could not have a song of its own (the build refused it). Each grotto:

  * a BARD (top left) names the grotto, its map id, the song you hear and the battle song,
    and offers to send you to the next grotto (YES) — the last one sends you back;
  * a MONSTER (middle) to fight: the battle plays the grotto's battle song;
  * STAIRS: top right = up to the next grotto, top left = down to the one before;
  * SONG GROTTO 16 ($85) also has a SCRIBE (bottom right) who explains the stale-save test:
    record the JOURNAL in this grotto, then CONTINUE that save in a build of the plain
    project (11 rooms — it has no map $85): the game starts at home (the Castle's throne
    room, the party healed) instead of freezing.

Way in: the S138 DEMO NPC in Cities_FOUNT at (3, 4).

    python3 examples/s138_song_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json).
"""
import copy
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document
from editor2.core.render_project import ProjectRenderer
from editor2.core import textenc as T

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

N = 16
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
MONSTERS = [3, 7, 11, 15, 19, 25, 33, 44, 53, 66, 80, 91, 104, 118, 133, 153]

lib = {}
for k in ('dwm2_bgm01', 'dwm2_bgm02', 'dwm2_bgm03', 'dwm2_bgm06'):
    lib[k] = d.add_library_song(k, name=f'S138 demo: DWM2 {k[-5:].upper()}')
own = 'dq6_town1'                       # the user's own song (custom.music)

# (room song, its words, battle song, its words) per grotto
SONGS = [
    (0x09, "the CASTLE's song", 0x0F, "a boss song (GIGANTES')"),
    (0x34, "the gate ITEM SHOP's song", 0x2B, 'the STARRY NIGHT final battle'),
    (0x12, "a boss song (SKYDRAGON's)", 0x1B, "a boss song (BATTLEREX's)"),
    (0x1E, "the ARENA LOBBY's song", 0x0C, "a boss song (GOLEM's)"),
    (lib['dwm2_bgm06'], 'DWM2 song 6', 0x2E, "a boss song (FANGSLIME's)"),
    (0x31, "the STARRY SHRINE's song", 0x18, "a boss song (MADCAT's)"),
    (0x61, "the COLISEUM's song", 0x15, "a boss song (FACETREE's)"),
    (own, 'your own DQ6 town song', 0x12, "a boss song (SKYDRAGON's)"),
    (0x18, "a boss song (MADCAT's)", 0x34, "the gate ITEM SHOP's song"),
    (0x2E, "a boss song (FANGSLIME's)", 0x09, "the CASTLE's song"),
    (lib['dwm2_bgm01'], 'DWM2 song 1', 0x2B, 'the STARRY NIGHT final battle'),
    (0x1E, "the ARENA LOBBY's song", 0x1B, "a boss song (BATTLEREX's)"),
    (0x31, "the STARRY SHRINE's song", lib['dwm2_bgm02'], 'DWM2 song 2'),
    (own, 'your own DQ6 town song', 0x0C, "a boss song (GOLEM's)"),
    (0x61, "the COLISEUM's song", 0x2E, "a boss song (FANGSLIME's)"),
    (lib['dwm2_bgm03'], 'DWM2 song 3', 0x15, "a boss song (FACETREE's)"),
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


grottos = []
for n in range(N):
    rid = d.new_room(f'SONG GROTTO {n + 1}', 0, r, gate_theme=n)
    room = d.room(rid)
    lid = room['screens']['0']['layout']['id']
    for cx in range(10):
        paint(lid, cx, 0, WALL)
        paint(lid, cx, 7, WALL)
    for cy in range(8):
        paint(lid, 0, cy, WALL)
        paint(lid, 9, cy, WALL)
    if n > 0:
        paint(lid, 1, 1, STAIRS)           # down
    if n < N - 1:
        paint(lid, 8, 1, STAIRS)           # up
    mid = int(room['mapID'], 16)
    song, sw, bsong, bw = SONGS[n]
    d.set_room_music_id(mid, song)
    d.set_room_battle_music(mid, bsong)
    bard = d.add_npc(room, '0', 0, 3, 2, 0x0B, 'down')
    mon = d.add_npc(room, '0', 0, 5, 4, 0xF0, 'down', monster=MONSTERS[n])
    scribe = d.add_npc(room, '0', 0, 7, 6, 0x0C, 'down') if n == N - 1 else None
    enemy = d.add_enemy(copy_eid=2, name=f'Song foe {n + 1}', species=MONSTERS[n],
                        level=1, hp=1, joinability=7)
    grottos.append({'id': rid, 'mid': mid, 'bard': bard, 'mon': mon, 'scribe': scribe,
                    'enemy': enemy, 'sw': sw, 'bw': bw})

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')

for i, g in enumerate(grottos):
    room = d.room(g['id'])
    nxt = grottos[i + 1] if i + 1 < N else None
    old = (' Before S138 a room from map 80 up could not have a song of its own.'
           if g['mid'] >= 0x80 else '')
    bard = [{'say': B(f"SONG GROTTO {i + 1}, map {g['mid']:02X}. You hear {g['sw']}.{old}",
                      f"Fight the monster: its battle plays {g['bw']}.")},
            {'ask': B('Shall I send you on to the next grotto?' if nxt else
                      'This is the last grotto. Shall I send you back to the fountain?'),
             'yes': [{'move': {'dest': (f"room:${nxt['mid']:02X}" if nxt
                                        else f'room:${cities_mid:02X}'),
                               'screen': 0, 'x': 5, 'y': 6}}],
             'no': [{'say': B('Then listen a while. The stairs are always there.')}]}]
    mon = [{'ask': B(f'I am the monster of SONG GROTTO {i + 1}. Fight me?'),
            'yes': [{'battle': {'enemies': [g['enemy']]}},
                    {'say': B(f"You won! Did the battle play {g['bw']}?")}],
            'no': [{'say': B('Another time.')}]}]
    for key, idx, steps in (('bard', g['bard'], bard), ('monster', g['mon'], mon)):
        sid = d.new_conversation(room, {'steps': steps}, name=key)
        d.update_npc(room, '0', 0, idx, script=sid)
    if g['scribe'] is not None:
        scribe = [{'say': B('I am the SCRIBE. The STALE SAVE test:',
                            'Record the JOURNAL here, in map 85. Then CONTINUE that save in '
                            'the build of your plain project, which has no map 85.',
                            'Before S138 the game froze. Now it starts at home: the Castle '
                            'throne room, your party healed.')}]
        sid = d.new_conversation(room, {'steps': scribe}, name='scribe')
        d.update_npc(room, '0', 0, g['scribe'], script=sid)

for n in range(N - 1):
    a = d.add_door(grottos[n]['id'], '0', 8, 1, name=f'Song stairs {n + 1} up')
    b = d.add_door(grottos[n + 1]['id'], '0', 1, 1, name=f'Song stairs {n + 2} down')
    d.link_doors(a, b)

demo = [{'ask': B('S138 DEMO: the SONG GROTTOS. Every grotto has its own song, even past '
                  'map 80. Go?'),
         'yes': [{'move': {'dest': f"room:${grottos[0]['mid']:02X}", 'screen': 0,
                           'x': 5, 'y': 6}}],
         'no': [{'say': B('Another time!')}]}]
sid = d.new_conversation(cities, {'steps': demo}, name='s138demo')
d.update_npc(cities, '0', 0, k_demo, script=sid)
d.save(dst)
print('song grottos', ', '.join(f"{g['mid']:#04x}" for g in grottos))
