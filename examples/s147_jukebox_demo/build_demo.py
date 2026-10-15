"""S147 demo (ROADMAP ARC CAP5 — songs at campaign scale): the JUKEBOX HALLS on the user's project.

Before S147 a project song took one sound id PER CHANNEL (95 ids = about 31 songs) and
song data had only banks $74 / $75 (2 x 16,000 B): the user's project + the 11th DWM2-size
song stopped the build. Since S147 every song takes ONE id and songs past banks $74 / $75
go into the 4 MB ROM's banks $80+ (PROJECT_COMPILER §2.55).

This demo adds the WHOLE DWM2 catalog (31 songs) to the user's project (its own DQ6 town
song makes 32) and eleven BRAND-NEW rooms, JUKEBOX HALL 1-11, one screen each, each in its
own gate theme. Every hall:

  * has its OWN ROOM SONG (heard when you walk in, and after a CONTINUE there);
  * has two BARDS (A at the left, B at the right). Talking to a bard plays ITS song —
    a cutscene "Music" step naming the song (S147: the build finds its number). The
    bard says the song's name, its song number and the ROM bank it is played from
    ($74 / $75 = the two song banks, $80+ = the 4 MB ROM's banks);
  * STAIRS: top right = up to the next hall, top left = down to the one before.

JUKEBOX HALL 11 also has a MONSTER (middle): its battle plays a song from a bank $80+
(the hall's battle song), and the hall's Bard B plays the hall's own song again (the
"back to the room's song" step). 2 bards a hall (3 people in hall 11) — the user (S147):
"Dont put too many npcs in one room please, it lags hard."

Way in: the JUKEBOX GUIDE in Cities_FOUNT at (5, 4) (a new NPC; YES = to hall 1).

    python3 examples/s147_jukebox_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json). Prints the halls
and every song's id / bank as the build will place them.
"""
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document                       # noqa: E402
from editor2.core.render_project import ProjectRenderer          # noqa: E402
from editor2.core import textenc as T                            # noqa: E402
from editor2.core import cutscene_doc as CD                      # noqa: E402

src, dst = sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1]
d = Document(src)
d.project_dir = os.path.dirname(os.path.abspath(dst))
r = ProjectRenderer(REPO, d.project_dir, d.data)

N = 11
WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
MONSTER = 133

# every song: the user's own first, then the DWM2 catalog in its order
lib = json.load(open(os.path.join(REPO, 'extracted', 'dwm2_song_library.json')))['songs']
own = [s['id'] for s in (d.custom.get('music') or {}).get('songs') or []]
songs = list(own)
for s in lib:
    songs.append(d.add_library_song(s['id'], name=f"DWM2 {s['name']}"))
if len(songs) < 3 * N - 1:
    raise SystemExit(f'only {len(songs)} songs')


def B(*paras):
    out = []
    for p in paras:
        out += T.flow_boxes(p, first_box=not out)
    return {'boxes': out}


def paint(lid, cx, cy, mt):
    g = d.layout(lid)['tiles']
    g[2 * cy][2 * cx], g[2 * cy][2 * cx + 1] = mt[0], mt[1]
    g[2 * cy + 1][2 * cx], g[2 * cy + 1][2 * cx + 1] = mt[2], mt[3]


def word(sid):
    s = d.project_song(sid) or {}
    return (s.get('name') or sid).replace('#', 'no.')


halls = []
for n in range(N):
    rid = d.new_room(f'JUKEBOX HALL {n + 1}', 0, r, gate_theme=(n + 5) % 16)
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
    hall_song = songs[3 * n]
    a_song = songs[3 * n + 1]
    b_song = songs[3 * n + 2] if 3 * n + 2 < len(songs) else None   # hall 11: back
    d.set_room_music_id(mid, hall_song)
    d.add_npc(room, '0', 0, 3, 3, 0x0B, 'down')
    d.add_npc(room, '0', 0, 6, 3, 0x0C, 'down')
    CD.name_actor(d, rid, 0, 0, 1, 'Bard A')
    CD.name_actor(d, rid, 0, 0, 2, 'Bard B')
    h = {'id': rid, 'mid': mid, 'hall': hall_song, 'a': a_song, 'b': b_song, 'n': n + 1}
    if n == N - 1:
        d.add_npc(room, '0', 0, 5, 5, 0xF0, 'down', monster=MONSTER)
        h['enemy'] = d.add_enemy(copy_eid=2, name='Jukebox foe', species=MONSTER,
                                 level=1, hp=1, joinability=7)
    halls.append(h)

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)
k_demo = d.add_npc(cities, '0', 0, 5, 4, 0x1D, 'down')

for n in range(N - 1):
    a = d.add_door(halls[n]['id'], '0', 8, 1, name=f'Jukebox stairs {n + 1} up')
    b = d.add_door(halls[n + 1]['id'], '0', 1, 1, name=f'Jukebox stairs {n + 2} down')
    d.link_doors(a, b)

# the battle song of hall 11: the last DWM2 BGM the plan puts past bank $75 (set below
# once the plan is known; a placeholder keeps the room's battle row)
d.save(dst)

# ---- where the build puts every song (the music plan of this very project) -------
from editor2.core.project import Project                          # noqa: E402
from editor2.core import music as M                               # noqa: E402
prj = Project(json.load(open(dst)), d.project_dir)
prj.repo_root = REPO
P = prj.music_plan()
ext = M.song_ext_banks(prj)
where = {rr['id']: (rr['first_id'], M.real_bank(prj, rr['bank'])) for rr in P.songs}


def bank_words(b):
    return (f'bank {b:02X}, a song bank' if b in (0x74, 0x75)
            else f'bank {b:02X}, one of the 4 MB ROM\'s new banks')


big = [sid for sid in songs if where[sid][1] >= 0x80 and sid not in
       (halls[-1]['hall'], halls[-1]['a'])]
battle_song = big[-1]
d.set_room_battle_music(halls[-1]['mid'], battle_song)

for i, h in enumerate(halls):
    room = d.room(h['id'])
    nxt = halls[i + 1] if i + 1 < N else None
    hid, hb = where[h['hall']]
    for actor, sid in (('Bard A', h['a']), ('Bard B', h['b'])):
        sc_id = CD.new_cutscene(d, h['id'], f"{actor} plays", 0, on='talk', actor=actor)
        _rr, sc = CD.find(d, sc_id)
        if sid is not None:
            i_d, i_b = where[sid]
            steps = [{'say': B(f"JUKEBOX HALL {h['n']}. The hall plays {word(h['hall'])} "
                               f"(song {hid:02X}, {bank_words(hb)}).",
                               f"I am {actor.upper()}. Listen: {word(sid)}, song {i_d:02X}, "
                               f"played from {bank_words(i_b)}.")},
                     {'music': {'song': sid}}]
        else:
            steps = [{'say': B(f"JUKEBOX HALL {h['n']}, the last hall. I am BARD B.",
                               f"I bring the hall's own song back: {word(h['hall'])}.")},
                     {'music': 'back'}]
        if actor == 'Bard B' and nxt is None:
            steps.insert(1, {'say': B('The monster in the middle fights to '
                                      f"{word(battle_song)} (song {where[battle_song][0]:02X}, "
                                      f"{bank_words(where[battle_song][1])}).")})
        sc['steps'] = steps
        CD.set_scene(d, sc_id, sc)
    if 'enemy' in h:
        mon = [{'ask': B(f'I am the monster of JUKEBOX HALL {h["n"]}. Fight me?'),
                'yes': [{'battle': {'enemies': [h['enemy']]}},
                        {'say': B(f"You won! Did the battle play {word(battle_song)}?")}],
                'no': [{'say': B('Another time.')}]}]
        sid_m = d.new_conversation(room, {'steps': mon}, name='jukebox_monster')
        d.update_npc(room, '0', 0, 2, script=sid_m)

demo = [{'ask': B('S147 DEMO: the JUKEBOX HALLS. 32 songs, one song number each, '
                  'in the song banks AND the 4 MB ROM\'s new banks. Go?'),
         'yes': [{'move': {'dest': f"room:${halls[0]['mid']:02X}", 'screen': 0,
                           'x': 5, 'y': 6}}],
         'no': [{'say': B('Another time!')}]}]
sid = d.new_conversation(cities, {'steps': demo}, name='s147demo')
d.update_npc(cities, '0', 0, k_demo, script=sid)
d.save(dst)
print('halls', ', '.join(f"{h['mid']:#04x}" for h in halls))
print('songs', ' '.join(f"{s}=${where[s][0]:02X}@${where[s][1]:02X}" for s in songs))
print('battle song', battle_song, 'ext banks', {str(k): f'${b:02X}' for k, b in ext.items()})
