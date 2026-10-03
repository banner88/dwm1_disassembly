#!/usr/bin/env python3
"""dump_sound_catalog.py — S116 (ROADMAP P3.13b): every vanilla sound with what it
is and where the game uses it -> extracted/sound_catalog.json (the Music tab's
vanilla list; the user names the songs in the editor — music.names).

Per START id — every id the game starts a sound with: the 85 sound first ids of
extracted/songs.json, the sound-test lists, the room table, the scripts and the
code sites (a start may be a sound's later channel: the arena battle room's $61
starts sound $60's three BGM channels):
  * channels: how many the game's InitBGM / LoadSE starts (measured: the channel
    states alive after the start) + their state slots;
  * kind, from the game's own developer sound test (bank $55 `BGM_IDS` /
    `SE_IDS`, the menu's two id lists) + a measured play: "music" = a BGM-test id
    still sounding after 3 minutes (it loops), "jingle" = a BGM-test id that
    ends, "effect" = an SE-test id or no test at all; `length_frames` for the
    sounds that end (the editor's sound engine, editor2/core/sound_engine.py —
    census-proven == the game, tools/census_sound_engine.py);
  * uses: the rooms whose default it is (bank $01 `RoomBGMTable` $4373, 112
    entries, mapIDs $00-$6F; gate floors = $34 through the gate path,
    SOUND_SYSTEM §8), the vanilla scripts that start it (opcode $41 set_bgm,
    extracted/all_scripts.json), and the engine code that starts it (the
    SetBGM call sites, code-read S116 — listed in CODE_SITES with their
    instruction addresses, each checked against the ROM bytes here).

  python3 tools/dump_sound_catalog.py            # writes extracted/sound_catalog.json
  python3 tools/dump_sound_catalog.py --selftest # anchors only (verify check 5)
"""
import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, REPO)
OUT = os.path.join(REPO, 'extracted', 'sound_catalog.json')
ROM = os.path.join(REPO, 'data', 'DWM-original.gbc')

ROOM_BGM_TABLE = (0x01, 0x4373, 0x70)
SOUND_TEST_SIG = bytes([0x02, 0x06, 0x09, 0x0C, 0x0F, 0x12, 0x15, 0x18, 0x1B, 0x1E])

# SetBGM call sites in the engine (bank, address of the `ld a, n` / `ld b, n`
# that loads the id, the id, what the code is doing) — code-read S116; the
# bytes at each address are checked (3E nn = ld a,n / 06 nn = ld b,n).
CODE_SITES = [
    (0x51, 0x4073, 0x27, 'battle start (bank $51 LoadBattle) — every battle'),
    (0x51, 0x4089, 0x2B, 'battle start in the arena battle room when wArenaStarryBattle == 2 '
                         '(the Starry Night final)'),
    (0x13, 0x7370, 0x4B, 'bank $13 label13_7370 (state $C905 = 0): in a gate or below map $30'),
    (0x13, 0x737F, 0x4D, 'bank $13 label13_7370 (state $C905 = 0): maps $30+ outside gates '
                         '(the boss rooms)'),
    (0x15, None, 0x24, 'bank $15 — three screens set up after DrawWhiteScreen'),
    (0x5F, None, 0x21, 'bank $5F field-UI screen (after SetGBCPalette $FC)'),
    (0x5F, None, 0x31, 'bank $5F field-UI screen (after SetGBCPalette $FC)'),
    (0x5F, None, 0x06, 'bank $5F screen (two sites)'),
    (0x01, None, 0x4F, 'bank $01 after SetupPartyBattleData'),
    (0x51, None, 0x47, 'bank $51 after ExtractDigits (a party monster value drawn)'),
    (0x00, None, 0x02, 'many sites (map transitions, battle ends, ...): id $02 starts the silent '
                       'channels — music off'),
]


def rom_bytes():
    return open(ROM, 'rb').read()


def rd(rom, bank, addr, n=1):
    off = addr if addr < 0x4000 else bank * 0x4000 + addr - 0x4000
    return rom[off:off + n]


def find_sound_test(rom):
    bank = 0x55
    data = rom[bank * 0x4000:(bank + 1) * 0x4000]
    i = data.find(SOUND_TEST_SIG)
    if i < 0:
        raise SystemExit('sound-test BGM_IDS not found in bank $55')
    bgm = []
    j = i
    while data[j] != 0x00:
        bgm.append(data[j])
        j += 1
    while data[j] == 0x00:            # the BGM list's zero pad, then SE_IDS starts with $00
        j += 1
    se = [0]
    while data[j] != 0x00:
        se.append(data[j])
        j += 1
    return 0x4000 + i, bgm, se


def anchors(rom):
    bank, addr, n = ROOM_BGM_TABLE
    tbl = rd(rom, bank, addr, n)
    assert tbl[0x00] == 0x09 and tbl[0x06] == 0x1E and tbl[0x5D] == 0x61, \
        'RoomBGMTable anchor (Castle $09, Arena Lobby $1E, arena battle room $61)'
    for b, a, sid, _ in CODE_SITES:
        if a is None:
            continue
        op = rd(rom, b, a, 2)
        assert op[0] in (0x3E, 0x06) and op[1] == sid, \
            f'code site ${b:02X}:${a:04X} is not ld a/b,${sid:02X} ({op.hex()})'
    at, bgm, se = find_sound_test(rom)
    assert bgm[:3] == [0x02, 0x06, 0x09] and 0x27 in bgm
    return tbl, (at, bgm, se)


def measure(rom, sid, path, limit=10800):
    from editor2.core import sound_engine as SE
    m = SE.Machine(rom)
    m._call(SE.INIT_AUDIO)            # every channel dead ($FF) before the start
    if path == 'bgm':
        m.start_bgm(sid)
    else:
        m.start_se(sid)
    w = m.wram
    slots = (0x00, 0x1A, 0x34, 0x4E, 0x68, 0x82)

    def alive(s):
        return not (w[0xDD80 - 0xC000 + s] == 0xFF and w[0xDD80 - 0xC000 + s + 0x19] == 0xFF)
    started = [s for s in slots if alive(s)]
    for f in range(limit):
        m.frame()
        if not any(alive(s) for s in slots):
            return f + 1, started
    return None, started


def main():
    rom = rom_bytes()
    tbl, (test_at, bgm_ids, se_ids) = anchors(rom)
    if '--selftest' in sys.argv:
        print(f'OK: RoomBGMTable, {len([c for c in CODE_SITES if c[1]])} code sites, '
              f'sound test @ $55:${test_at:04X} ({len(bgm_ids)} BGM / {len(se_ids)} SE ids)')
        return 0
    from dwm.map_names import get_name
    songs = json.load(open(os.path.join(REPO, 'extracted', 'songs.json')))['sounds']
    scripts = json.load(open(os.path.join(REPO, 'extracted', 'all_scripts.json')))['scripts']
    script_uses = {}
    for s in scripts:
        cm = s['commands']
        for i, c in enumerate(cm):
            if c.get('name') == 'set_bgm' and i + 1 < len(cm) and cm[i + 1].get('type') == 'param':
                v = cm[i + 1]['value']
                script_uses.setdefault(v, set()).add(f"{s['map_name']} (script {s['script_id']})")
    starts = sorted({snd['first_id'] for snd in songs} | set(bgm_ids) | set(se_ids)
                    | {v for v in tbl} | set(script_uses) | {c[2] for c in CODE_SITES})
    starts = [x for x in starts if x]
    out = []
    for sid in starts:
        rooms = [f'${m:02X} {get_name(m)}' for m in range(len(tbl)) if tbl[m] == sid]
        if sid == 0x34:
            rooms.append('every gate floor (the gate path)')
        in_bgm, in_se = sid in bgm_ids, sid in se_ids
        as_bgm = in_bgm or sid in tbl or sid in script_uses or \
            any(c[2] == sid for c in CODE_SITES)
        path = 'bgm' if as_bgm or not in_se else 'se'
        n, slots = measure(rom, sid, path)
        kind = ('music' if n is None else 'jingle') if path == 'bgm' else 'effect'
        out.append({
            'id': f'${sid:02X}', 'id_int': sid,
            'kind': kind,
            'channels': len(slots),
            'slots': [f'${x:02X}' for x in slots],
            'sound_test': 'BGM' if in_bgm else 'SE' if in_se else None,
            'starts_as': path,
            'length_frames': n,
            'rooms': rooms,
            'scripts': sorted(script_uses.get(sid, [])),
            'code': [f"${b:02X}" + (f":${a:04X}" if a else '') + f" — {what}"
                     for b, a, i, what in CODE_SITES if i == sid],
        })
    json.dump({'_generator': 'tools/dump_sound_catalog.py (S116): vanilla sounds — kind from the '
                             'bank $55 sound test + a measured play (editor2/core/sound_engine.py), '
                             'uses from RoomBGMTable $01:$4373, set_bgm scripts, SetBGM code sites',
               '_rom': 'DWM-original.gbc 1ca6579359f21d8e27b446f865bf6b83',
               'sound_test': {'addr': f'$55:${test_at:04X}',
                              'bgm_ids': [f'${x:02X}' for x in bgm_ids],
                              'se_ids': [f'${x:02X}' for x in se_ids]},
               'sounds': out}, open(OUT, 'w'), indent=1)
    kinds = {}
    for s in out:
        kinds[s['kind']] = kinds.get(s['kind'], 0) + 1
    print(f'wrote {OUT}: {len(out)} sounds {kinds}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
