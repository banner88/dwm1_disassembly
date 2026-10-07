"""S129 demo: two BRAND-NEW rooms on the user's project (the editor's own operations).

Kept as a reference for the editor's Document API (S129, ROADMAP P3.14b/c/d): story checks,
the story spine, a quest, says by progress, a lock, music by flag, a shop item set, gold
steps. It made examples/s129_story_demo/project.json from the user's my-dwm-hack_21:

    python3 examples/s129_story_demo/build_demo.py <base project.json> <out project.json>

(the base project's assets/ folder must sit beside the out project.json).

STORY HALL (teal crystal theme): Hall Guide, Sage of Checks, Medal Fairy, Medal Collector
(a quest), Chronicler (says by progress); sealed stairs (a lock) to the VAULT ANNEX.
VAULT ANNEX (crimson theme): Annex Guide, Banker (gold), Annex Merchant (an item set by
flag), Bard (a gate song by flag), stairs back.
Cities_FOUNT: the S129 DEMO NPC at (3, 4) -> the STORY HALL.
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from editor2.core.document import Document
from editor2.core.render_project import ProjectRenderer

src = sys.argv[1]
d = Document(src)
r = ProjectRenderer(REPO, os.path.dirname(os.path.abspath(src)), d.data)

WALL = [0x08, 0x09, 0x18, 0x19]
STAIRS = [0x3C, 0x3D, 0x3E, 0x3F]
MEDAL = 0x1E
HERB = 0x01


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


def B(*paras):
    """boxes: each argument = one paragraph, flowed into the game's boxes (the
    editor's own wrap: textenc.flow_boxes — 16 cells after "*:" on a first line)."""
    from editor2.core import textenc as T
    out = []
    for p in paras:
        out += T.flow_boxes(p.replace('|', ' '), first_box=not out)
    return {'boxes': out}


hall_id = d.new_room('STORY HALL', 0, r, gate_theme=10)
annex_id = d.new_room('VAULT ANNEX', 0, r, gate_theme=3)
hall, annex = d.room(hall_id), d.room(annex_id)
h_lid = hall['screens']['0']['layout']['id']
a_lid = annex['screens']['0']['layout']['id']
walls(h_lid)
walls(a_lid)
paint(h_lid, 8, 1, STAIRS)
paint(a_lid, 1, 1, STAIRS)
hall_mid = int(hall['mapID'], 16)
annex_mid = int(annex['mapID'], 16)

# ---- flags, checks, the story spine ---------------------------------------
d.add_flag('hall_visited', comment='S129 demo: the Hall Guide was met')
d.add_flag('bard_tune', comment='S129 demo: the Bard plays gate 0 a new song')
d.add_check('has_3_medals', {'kind': 'item', 'item': MEDAL, 'count': 3})
d.add_check('has_a_medal', {'kind': 'item', 'item': MEDAL, 'count': 1})
d.add_check('rich', {'kind': 'gold', 'amount': 5000})
d.add_check('strong_party', {'kind': 'level', 'level': 20, 'mode': 'any'})
d.add_check('big_farm', {'kind': 'monsters', 'count': 10})
d.add_check('bag_has_room', {'kind': 'bag_room', 'count': 1})

# ---- NPCs (STORY HALL) -----------------------------------------------------
S_GUIDE, S_SAGE, S_FAIRY, S_COLL, S_CHRON = 0x0B, 0x1D, 0x0C, 0x09, 0x0B
i_guide = d.add_npc(hall, '0', 0, 2, 2, S_GUIDE, 'down')
i_sage = d.add_npc(hall, '0', 0, 6, 3, S_SAGE, 'down')
i_fairy = d.add_npc(hall, '0', 0, 2, 4, S_FAIRY, 'down')
i_coll = d.add_npc(hall, '0', 0, 7, 5, S_COLL, 'down')
i_chron = d.add_npc(hall, '0', 0, 3, 6, S_CHRON, 'down')

cities = d.room('cities_fount')
cities_mid = int(cities['mapID'], 16)

sid = d.new_conversation(hall, {'steps': [
    {'say': B('This is the STORY|HALL (S129 demo).',
              'Everyone here|shows a story tool.',
              'The stairs open|when the Medal',
              'Collector is|happy.')},
    {'set': ['hall_visited']},
    {'ask': B('Back to Cities FOUNT?'),
     'yes': [{'move': {'dest': f'room:${cities_mid:02X}', 'screen': 0, 'x': 3, 'y': 5}}],
     'no': [{'say': B('Have fun!')}]}]}, name='guide')
d.update_npc(hall, '0', 0, i_guide, script=sid)

sid = d.new_conversation(hall, {'steps': [
    {'say': B('I am the Sage of|Checks. I read you.')},
    {'if': [{'flag': 'strong_party'}],
     'then': [{'say': B('A party monster is|level 20 or more.')}],
     'else': [{'say': B('No party monster|is level 20 yet.')}]},
    {'if': [{'flag': 'rich'}],
     'then': [{'say': B('You carry 5,000|gold or more!')}],
     'else': [{'say': B('Less than 5,000|gold. Ask the', 'Banker!')}]},
    {'if': [{'flag': 'big_farm'}],
     'then': [{'say': B('You own 10 or more|monsters.')}],
     'else': [{'say': B('You own fewer than|10 monsters.')}]},
    {'if': [{'flag': 'has_a_medal'}],
     'then': [{'say': B('I sense a TinyMedal|in your bag.')}],
     'else': [{'say': B('No TinyMedal in|your bag.')}]}]}, name='sage')
d.update_npc(hall, '0', 0, i_sage, script=sid)

sid = d.new_conversation(hall, {'steps': [
    {'say': B('I am the Medal|Fairy. Here!')},
    {'give_item': {'item': MEDAL, 'count': 1,
                   'got': B('You got a|TinyMedal!'),
                   'full': B('Your bag is full!|Make room first.')}}]}, name='fairy')
d.update_npc(hall, '0', 0, i_fairy, script=sid)

sid = d.new_conversation(hall, {'steps': [{'say': B('...')}]}, name='chronicler')
d.update_npc(hall, '0', 0, i_chron, script=sid)

# the quest (its giver = the Collector's own script)
sid_coll = d.new_conversation(hall, {'steps': [{'say': B('...')}]}, name='collector')
d.update_npc(hall, '0', 0, i_coll, script=sid_coll)
qid = d.add_quest('Medal quest', sid_coll)
q = d.quest(qid)
done = q['flags']['done']
d.update_quest(qid, {
    'name': 'Three TinyMedals',
    'offer': B('I collect|TinyMedals.', 'Will you bring me|three of them?'),
    'accept': B('Wonderful! Come|back with three.'),
    'decline': B('Oh well. Maybe|another time.'),
    'progress': B('Three TinyMedals,|please!',
                  'The Medal Fairy|may help you.'),
    'objective': [{'flag': 'has_3_medals'}],
    'take': [{'item': MEDAL, 'count': 3}],
    'complete': B('Three TinyMedals!|Thank you!',
                  'Take 300 gold and|two Herbs.', 'The stairs are|open now!'),
    'reward': {'gold': 300, 'items': [{'item': HERB, 'count': 2}], 'refresh': True},
    'done': B('Thanks again for|the medals!'),
})
d.set_milestones([('hall_visited', 'Chapter 1 — the Story Hall'),
                  (done, 'Chapter 2 — the medals')])
d.set_conversation(d.room(hall_id)['scripts'][[k for k, v in d.room(hall_id)['scripts'].items()
                                                 if v.endswith('chronicler')][0]],
                   {'steps': [
                       {'say': B('I am the|Chronicler.')},
                       {'by_progress': [
                           {'milestone': done,
                            'steps': [{'say': B('Chapter 2: the|medals came home!',
                                                'The stairs are|open.')}]},
                           {'milestone': 'hall_visited',
                            'steps': [{'say': B('Chapter 1: you|met the Guide.',
                                                'Now help the|Medal Collector.')}]}],
                        'else': [{'say': B('Your story has|not begun.',
                                           'Talk to the|Guide first.')}]}]})

# ---- NPCs (VAULT ANNEX) ----------------------------------------------------
S_AGUIDE, S_BANK, S_MERCH, S_BARD = 0x0B, 0x1D, 0x09, 0x0F
j_guide = d.add_npc(annex, '0', 0, 2, 2, S_AGUIDE, 'down')
j_bank = d.add_npc(annex, '0', 0, 7, 3, S_BANK, 'down')
j_merch = d.add_npc(annex, '0', 0, 2, 5, S_MERCH, 'down')
j_bard = d.add_npc(annex, '0', 0, 7, 6, S_BARD, 'down')
sid = d.new_conversation(annex, {'steps': [
    {'say': B('This is the VAULT|ANNEX (S129 demo).',
              'The Banker, the|Merchant and the',
              'Bard live here.|Stairs: back.')}]}, name='aguide')
d.update_npc(annex, '0', 0, j_guide, script=sid)
sid = d.new_conversation(annex, {'steps': [
    {'ask': B('I am the Banker.|Want 1,000 gold?'),
     'yes': [{'gold': {'give': 1000}}, {'say': B('Here you are:|1,000 gold!')}],
     'no': [{'ask': B('Then may I take|500 gold?'),
             'yes': [{'gold': {'take': 500}}, {'say': B('Thank you for|the 500 gold!')}],
             'no': [{'say': B('Suit yourself.')}]}]}]}, name='banker')
d.update_npc(annex, '0', 0, j_bank, script=sid)
shop = d.new_shop('Annex stall', [HERB, 0x07, 0x0D])
d.make_shopkeeper(annex, '0', 0, j_merch, shop,
                  greeting=B('Annex stall! After the medal quest: better goods!')['boxes'])
d.set_shop_sets(shop, [{'name': 'After the medals', 'when': [{'flag': done}],
                        'items': [0x05, 0x06, 0x03, 0x1D]}])
sid = d.new_conversation(annex, {'steps': [
    {'ask': B('I am the Bard.', 'Shall gate 0 sing|my song (YES)',
              'or its own (NO)?'),
     'yes': [{'set': ['bard_tune']}, {'say': B('Gate 0 floors now|play my song!')}],
     'no': [{'clear': ['bard_tune']}, {'say': B('Gate 0 sings its|own song again.')}]}]},
    name='bard')
d.update_npc(annex, '0', 0, j_bard, script=sid)

# ---- doors + the lock ------------------------------------------------------
h_door = d.add_door(hall_id, '0', 8, 1, name='Hall stairs')
a_door = d.add_door(annex_id, '0', 1, 1, name='Annex stairs')
d.link_doors(h_door, a_door)
locked = d.lock_exit(hall_id, '0', 8, 1, [{'flag': done}],
                     B('The stairs are sealed by magic.',
                       'The Medal Collector holds the key.')['boxes'])
# the locked look: a wall where the stairs are
st = d.screen(d.room(hall_id), '0')['states'][locked]
paint(st['layout']['id'], 8, 1, WALL)

# ---- music by flag ---------------------------------------------------------
d.set_room_music_rules(hall_id, [{'when': [{'flag': done}], 'song': '0x1E'}])
d.set_room_music_id(hall_mid, 0x31)
d.set_gate_music_rules(0, [{'when': [{'flag': 'bard_tune'}], 'song': '0x2E'}])

# ---- the way in: the S129 DEMO NPC in Cities_FOUNT ------------------------
k = d.add_npc(cities, '0', 0, 3, 4, 0x1D, 'down')
sid = d.new_conversation(cities, {'steps': [
    {'ask': B('S129 DEMO: story|checks, quests,', 'locks, music and|shop sets.',
              'Go to the STORY|HALL?'),
     'yes': [{'move': {'dest': f'room:${hall_mid:02X}', 'screen': 0, 'x': 5, 'y': 4}}],
     'no': [{'say': B('Another time!')}]}]}, name='s129demo')
d.update_npc(cities, '0', 0, k, script=sid)

d.save(sys.argv[2] if len(sys.argv) > 2 else src)
print('hall', hex(hall_mid), 'annex', hex(annex_mid), 'quest', qid, 'done flag', done,
      'locked state', locked)
