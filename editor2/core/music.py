"""music.py — custom.music resolution (M3b, S64; owning doc PROJECT_COMPILER.md).

Schema (§2.9):
  "music": {
    "libraries": ["extracted/dwm2_song_library.json", ...],   # repo-relative
    "songs": [ {"id": "...", "source": {"library": "<lib song id>"}
                            | {"inline": {"channels": [...]}},
                "first_id": "0xA1" | "auto"} ],
    "room_defaults": { "<mapID>": "<song id>" | <raw DWM1 BGM id> }
  }
plus `custom.rooms[].music` sugar (merged into room_defaults).

Resolution rules:
  * first_id "auto" allocates upward from $9E skipping explicit claims;
    channel count reserves consecutive ids (SetBGM starts 3 consecutive ids
    for a normal BGM — SOUND_SYSTEM §1).
  * Every BGM song is normalized to EXACTLY the 3-channel trio (slots
    $34/$4E/$68): missing trio slots get a 6-byte silent stream (header +
    $FF) so InitBGM's third dispatch never runs into the NEXT song's
    channel; channels outside the trio (e.g. DWM2 noise 4th channels) are
    DROPPED with a warning (InitBGM channel-count extension is a boxed
    ROADMAP follow-up).
  * room_defaults values: a song id -> that song's first_id; a raw int/hex
    -> used verbatim (assign INBUILT vanilla music to any room).
  * The 128-entry CustomRoomBGMTable (bank $71, resolver entry 2) is
    indexed by wMapID; 0 = no assignment -> full vanilla derivation.

The byte emitter is tools/song_codec.py (emit_song_bank / song_bank_asm) —
one proven spec->bytes path for DWM2, MIDI, and inline sources.
"""
import importlib.util
import json
import os

from . import formats as F

TRIO = [(0x34, 0), (0x4E, 1), (0x68, 2)]      # (slot, hw): pulse1/pulse2/wave
SILENT_CHANNEL = {"header": [0, 0, 0, 0], "tokens": [{"op": "end"}]}
FIRST_ID = 0x9E
LAST_ID = 0xFC


def _repo_root(start):
    d = os.path.abspath(start)
    for _ in range(6):
        if os.path.exists(os.path.join(d, 'tools', 'verify_integrity.py')):
            return d
        d = os.path.dirname(d)
    raise RuntimeError("repo root not found from " + start)


def song_codec(repo_root):
    path = os.path.join(repo_root, 'tools', 'song_codec.py')
    spec = importlib.util.spec_from_file_location('_sc_music', path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class MusicError(ValueError):
    pass


def resolve(prj):
    """-> (bank74_library, room_bgm[128], song_ids{song_id: first_id},
    warnings). bank74_library feeds song_codec.song_bank_asm."""
    warnings = []
    music = prj.custom.get('music') or {}
    repo = _repo_root(getattr(prj, 'repo_root', prj.root))

    lib_index = {}
    for rel in music.get('libraries', []):
        path = os.path.join(repo, rel)
        if not os.path.exists(path):
            raise MusicError(f"music library {rel!r} not found (repo-relative)")
        lib = json.load(open(path))
        for s in lib.get('songs', []):
            if s['id'] in lib_index:
                raise MusicError(f"song id {s['id']!r} defined in two libraries")
            lib_index[s['id']] = s

    # ---- resolve song list + id allocation --------------------------------
    songs = music.get('songs', [])
    explicit = {}
    for s in songs:
        fid = s.get('first_id', 'auto')
        if str(fid) != 'auto':
            explicit[s['id']] = F.val(fid)
    resolved = []
    used = set()

    def claim(fid, n, sid):
        ids = list(range(fid, fid + n))
        for i in ids:
            if not (FIRST_ID <= i <= LAST_ID):
                raise MusicError(f"song {sid!r}: id ${i:02X} outside "
                                 f"${FIRST_ID:02X}-${LAST_ID:02X}")
            if i in used:
                raise MusicError(f"song {sid!r}: id ${i:02X} already claimed")
            used.add(i)

    for s in songs:
        src = s.get('source') or {}
        if 'library' in src:
            if src['library'] not in lib_index:
                raise MusicError(f"song {s['id']!r}: library ref "
                                 f"{src['library']!r} not found in "
                                 "music.libraries")
            entry = lib_index[src['library']]
            chans = [dict(c) for c in entry['channels']]
        elif 'inline' in src:
            chans = [dict(c) for c in src['inline']['channels']]
        else:
            raise MusicError(f"song {s['id']!r}: source needs 'library' or "
                             "'inline'")
        # normalize to the exact BGM trio
        by_slot = {}
        for c in chans:
            slot = F.val(c['slot'])
            if slot in dict(TRIO):
                if slot in by_slot:
                    raise MusicError(f"song {s['id']!r}: two channels on "
                                     f"slot ${slot:02X}")
                by_slot[slot] = c
            else:
                warnings.append(
                    f"song {s['id']}: channel on slot ${slot:02X} dropped — "
                    "BGM ids init exactly the 3-channel trio (InitBGM "
                    "channel-count extension is a ROADMAP box)")
        trio = []
        for slot, hw in TRIO:
            c = by_slot.get(slot)
            if c is None:
                c = {"slot": slot, "hw": hw, **SILENT_CHANNEL}
                warnings.append(f"song {s['id']}: slot ${slot:02X} padded "
                                "silent (source has fewer channels)")
            trio.append({"slot": F.val(c['slot']), "hw": F.val(c['hw']),
                         "header": c['header'], "tokens": c['tokens']})
        resolved.append({"id": s['id'], "channels": trio,
                         "_explicit": explicit.get(s['id'])})

    nxt = FIRST_ID
    for r in resolved:
        n = len(r['channels'])
        if r['_explicit'] is not None:
            r['first_id'] = r['_explicit']
            claim(r['first_id'], n, r['id'])
    for r in resolved:
        if '_explicit' in r and r['_explicit'] is None:
            while any(i in used for i in range(nxt, nxt + len(r['channels']))):
                nxt += 1
            r['first_id'] = nxt
            claim(nxt, len(r['channels']), r['id'])
        r.pop('_explicit')
    resolved.sort(key=lambda r: r['first_id'])
    song_ids = {r['id']: r['first_id'] for r in resolved}

    # ---- room defaults ----------------------------------------------------
    room_bgm = [0] * 128
    defaults = {}                      # mapID int -> assignment (normalized)
    for key, val in (music.get('room_defaults') or {}).items():
        mid = F.val(key)
        if mid in defaults:
            raise MusicError(f"room_defaults declares mapID {key!r} twice")
        defaults[mid] = val
    for r in prj.rooms:
        m = r.get('music')
        if m is not None:
            mid = F.val(r['mapID'])
            if mid in defaults and defaults[mid] != m:
                raise MusicError(f"room {r.get('id')}: rooms[].music and "
                                 f"music.room_defaults disagree for "
                                 f"{F.hexb(mid)}")
            defaults[mid] = m
    for mid, val in defaults.items():
        if not (0 <= mid < 128):
            raise MusicError(f"room_defaults mapID {F.hexb(mid)} outside "
                             "$00-$7F (CustomRoomBGMTable range)")
        if isinstance(val, str) and val in song_ids:
            bgm = song_ids[val]
        elif isinstance(val, str) and not val[:1].isdigit() \
                and not val.startswith(('$', '0x', '0X')):
            raise MusicError(f"room_defaults {F.hexb(mid)}: {val!r} is not a "
                             "defined song id (music.songs) nor a numeric "
                             "BGM id")
        else:
            bgm = F.val(val)
            if bgm >= FIRST_ID and bgm not in used:
                warnings.append(f"room_defaults {F.hexb(mid)}: raw id "
                                f"${bgm:02X} is in the custom range but no "
                                "song claims it")
        if bgm == 0:
            raise MusicError(f"room_defaults {F.hexb(mid)}: id 0 is the "
                             "no-assignment sentinel — it cannot be assigned")
        room_bgm[mid] = bgm

    library = {"_source": "project.json custom.music", "songs": resolved}
    return library, room_bgm, song_ids, warnings
