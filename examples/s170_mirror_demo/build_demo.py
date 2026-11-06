"""S170 demo (monster art past banks $7F / $7C / $7A — the 4 MB ROM's banks $80+, compressed):
EVERY ONE of the 215 original monsters re-arted, so the art no longer fits the three art banks
and spills into banks $80+.

What the eye sees, anywhere the game draws a monster:
  * the BATTLE POSE is the monster's own pose MIRRORED (it faces the other way) — battles, the
    party menu, INFO, the library, the breeding screens;
  * the WALKING sprite is the monster's own walking art with colours 1 and 2 SWAPPED (the light
    and the mid colour trade places) — followers, monster NPCs, the library's parent icons.
Colours (battle palette, OBJ palette) and walk styles stay the monster's own, so a monster
that looks wrong in any other way is a fault. Species are placed in id order: roughly the
first 80 land in banks $7F / $7C / $7A, the rest in banks $80+ (the build prints which).

    python3 examples/s170_mirror_demo/build_demo.py <base project dir> <out project dir>

The out dir gets project.json + assets/ (copied from the base) + assets/art/*.bin.
"""
import json
import os
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, REPO)
from dwm import sprite_codec as C                                 # noqa: E402
from editor2.core.sheet_import import literal_stream              # noqa: E402
from editor2.core.sprite_render import species_layout_id          # noqa: E402

ART_IDS = range(215)          # the original monsters (215-220 are not: Iron Rule 8)


def mirrored_pose(tiles):
    g = C.tiles_to_indices(tiles, 6, 6)
    return C.indices_to_tiles([row[::-1] for row in g], 6, 6)


def swapped_walk(tiles):
    g = C.tiles_to_indices(tiles, 16, 1)
    sw = {0: 0, 1: 2, 2: 1, 3: 3}
    return C.indices_to_tiles([[sw[v] for v in row] for row in g], 16, 1)


def main(src, dst):
    src = os.path.abspath(src)
    dst = os.path.abspath(dst)
    if src != dst:
        if os.path.exists(dst):
            shutil.rmtree(dst)
        shutil.copytree(src, dst, ignore=shutil.ignore_patterns('build', '.DS_Store'))
    data = json.load(open(os.path.join(dst, 'project.json')))
    ms = json.load(open(os.path.join(REPO, 'extracted', 'monster_sprites.json')))['monsters']
    os.makedirs(os.path.join(dst, 'assets', 'art'), exist_ok=True)
    art = data.setdefault('gamedata', {}).setdefault('art', {})
    for sid in ART_IDS:
        m = ms[str(sid)]
        b = mirrored_pose(bytes.fromhex(m['battle']['tile_bytes_hex']))
        f = swapped_walk(bytes.fromhex(m['follower']['tile_bytes_hex']))
        lid, _attr = species_layout_id(sid)
        bp = f'assets/art/{sid}_s170_battle.bin'
        fp = f'assets/art/{sid}_s170_follower.bin'
        open(os.path.join(dst, bp), 'wb').write(literal_stream(b))
        open(os.path.join(dst, fp), 'wb').write(literal_stream(f))
        art[str(sid)] = {'comment': 'S170 demo: own pose mirrored, own walk colours 1/2 swapped',
                         'battle': {'art': bp},
                         'follower': {'art': fp, 'layout': lid}}
    json.dump(data, open(os.path.join(dst, 'project.json'), 'w'), indent=1)
    print(f"{len(ART_IDS)} monsters re-arted -> {dst}")


if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2] if len(sys.argv) > 2 else sys.argv[1])
