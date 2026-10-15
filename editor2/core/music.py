"""music.py — custom.music resolution (M3b S64; S116 P3.13b; owning doc PROJECT_COMPILER.md §2.9).

Schema (§2.9):
  "music": {
    "libraries": ["extracted/dwm2_song_library.json", ...],   # repo-relative catalogs
    "songs": [ {"id": "...",
                "source": {"library": "<lib song id>"}
                        | {"inline": {"channels": [...]}}
                        | {"file": "assets/music/x.json"},     # S116: project-relative
                "first_id": "0xA1" | "auto",
                "name": "..."} ],                              # S116: editor label
    "names": {"0x09": "...", "dwm2_bgm07": "..."},              # S116: editor-only labels
    "room_defaults": { "<mapID>": "<song id>" | <raw DWM1 BGM id> },
    "gates":  { "<gate 0-95>": {"floors": <song>, "battles": <song>} },   # S116
    "battle": { "normal": <song>, "boss": <song>, "arena": <song>,       # S116
                "starry": <song>,
                "rooms":  { "<mapID>": <song> },
                "fights": { "<enemy row EID>": <song> } }
  }
plus `custom.rooms[].music` sugar (merged into room_defaults).

A <song> value is a project song id (its sound id) or a raw sound id
(1-$FC: any vanilla sound, or a custom id). 0 / null = not set.

Resolution rules:
  * S147 (ROADMAP ARC CAP5 — songs at campaign scale): ONE sound id per song
    ($9E-$FC = 95 songs). An explicit "first_id" claims that one id (the key
    keeps its S64 name); "auto" takes the lowest free id, in song order. A song
    has 1-6 channels on any of the 6 state slots (each slot at most once) and is
    started by the rewritten InitBGM through bank $71 entry 6 -> bank $74 entry
    0 SongStart (templates/bank_074_head.asm): the song DIRECTORY in bank $74
    holds every song's record (channels, its bank, per channel a dummy id + slot
    + stream pointer). Until S147 a song took one id per channel (95 ids ~ 31
    songs, CustomBGMChanTable in bank $71).
  * Song banks (S147): every song's streams sit in ONE bank (never split), first
    fit in id order: bank $74 (after the head, the directory and every song's
    record), bank $75, then banks $80-$FF of the 4 MB ROM, taken after the
    stream / place / animation banks (Project._take_ext_bank('songs')). Until
    S147: $74 then $75 only (2 x 16,000 B) — AudioMasterTableExt had a 5th row
    for bank $75; now its custom row is always [$9E, SongRecords $4003, $74].
  * room_bgm (CustomRoomBGMTable, bank $71 entry 2): 0 = vanilla derivation;
    $FF (S116) = "a gate room with no song of its own — play the dive's gate
    song" (rooms served on gate floors + custom boss rooms, only when some gate
    has a floors song).
  * Gate tables (96 entries, wGateID 0-95): gate_bgm (maze floors, the special
    rooms, the gate rooms marked $FF), gate_battle.
  * Battle (bank $71 entry 7 BattleBGMResolve, from bank $51 LoadBattle):
    per fight (leader EID $DA03) > arena (Starry final / other matches) > the
    room's table (CustomRoomBattleBGMTable, $FF = follow the gate) > the gate >
    boss fights ($DA09 = 3) > normal; 0 everywhere = vanilla ($27, Starry final $2B).

The stream bytes come from tools/song_codec.py emit_tokens — one proven spec->bytes
path for DWM2, MIDI, and inline sources.
"""
import importlib.util
import json
import os

from . import formats as F

FIRST_ID = 0x9E
LAST_ID = 0xFC
SLOTS = (0x00, 0x1A, 0x34, 0x4E, 0x68, 0x82)
SLOT_HW = {0x00: 0, 0x1A: 1, 0x34: 0, 0x4E: 1, 0x68: 2, 0x82: 3}
SE_SLOTS = (0x00, 0x1A)
SONG_BANKS = (0x74, 0x75)                        # the song banks before the 4 MB ones
SONG_IDS = LAST_ID - FIRST_ID + 1                # 95 songs (S147: one id each)
BANK_BYTES = 0x4000
SONG_RECORDS_AT = 0x4003                         # bank $74 SongRecords (template ASSERT)
DIR_BYTES = 2 * SONG_IDS                         # SongDirectory: one dw per id
EXT_SONG_CAP = BANK_BYTES - 1                    # a song bank $75 / $80+: self-ID + streams
BANK_STREAM_CAP = EXT_SONG_CAP                   # (S116 name: one song bank's stream room)
GATE_TABLE_LEN = 96                              # gates 0-95 (S115 NG1)
MAX_FIGHTS = 255
FOLLOW_GATE = 0xFF                               # room tables: "the gate's song"
ROOM_MID_MAX = 0xEA                              # S138: the last custom map id (project.CUSTOM_MID_MAX)
# S140 (ROADMAP ARC CAP3a — regions): room / battle songs are indexed by the
# project mapID ($00-$6A vanilla, a place's mapID incl. its region byte — $176
# = region 1's $76); the bank $71 tables split into the 107 vanilla rows (by
# map id) and one row per PLACE (CustomPlaceBGMTable / CustomPlaceBattleBGMTable,
# place-number order — templates/bank_071_head.asm RoomSongByte71).
VANILLA_ROWS = 0x6B


def _room_key_ok(prj, mid):
    """A room / battle song key: a vanilla map id ($00-$6A) or a place's mapID
    shape (real id $6B-$EA, region 0-63 in the high byte). A key with no room
    of the project is accepted (S138: a song can be set before its room) and
    simply has no row (S140: the place rows exist only for places)."""
    if not isinstance(mid, int) or mid < 0:
        return False
    if mid < VANILLA_ROWS:
        return True
    return 0x6B <= (mid & 0xFF) <= ROOM_MID_MAX and (mid >> 8) <= 63


def _range_msg(what, mid):
    return (f"{what} {F.hexb(mid)} outside $00-$EA (a vanilla map, or a place's map id "
            "in its region: region r = $r6B-$rEA)")


MUSIC_KEYS = ('libraries', 'songs', 'room_defaults', 'names', 'gates', 'battle')
BATTLE_KEYS = ('normal', 'boss', 'arena', 'starry', 'rooms', 'fights')
GATE_MUSIC_KEYS = ('floors', 'battles', 'rules')
MUSIC_RULE_ROOM, MUSIC_RULE_GATE = 0, 1         # S129: MusicRuleTable kinds (bank $71)
MUSIC_RULE_MAX_TERMS = 8
# vanilla battle songs (bank $51 LoadBattle)
VANILLA_BATTLE = 0x27
VANILLA_STARRY_FINAL = 0x2B


_OWN_REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def _repo_root(start):
    """The repo the libraries are relative to: the one holding `start`, else the
    editor's own checkout (a user project usually lives outside the repo)."""
    d = os.path.abspath(start or _OWN_REPO)
    for _ in range(6):
        if os.path.exists(os.path.join(d, 'tools', 'verify_integrity.py')):
            return d
        d = os.path.dirname(d)
    if os.path.exists(os.path.join(_OWN_REPO, 'tools', 'verify_integrity.py')):
        return _OWN_REPO
    raise RuntimeError("repo root not found from " + str(start))


def song_codec(repo_root):
    path = os.path.join(repo_root, 'tools', 'song_codec.py')
    spec = importlib.util.spec_from_file_location('_sc_music', path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class MusicError(ValueError):
    pass


def load_libraries(repo, rels):
    lib_index = {}
    for rel in rels:
        path = os.path.join(repo, rel)
        if not os.path.exists(path):
            raise MusicError(f"music library {rel!r} not found (repo-relative)")
        lib = json.load(open(path))
        for s in lib.get('songs', []):
            if s['id'] in lib_index:
                raise MusicError(f"song id {s['id']!r} defined in two libraries")
            lib_index[s['id']] = dict(s, _library=rel)
    return lib_index


def song_channels(song, lib_index, project_root):
    """A project song's channels [{slot, hw, header, tokens}] from its source."""
    src = song.get('source') or {}
    sid = song.get('id')
    if 'library' in src:
        if src['library'] not in lib_index:
            raise MusicError(f"song {sid!r}: library ref {src['library']!r} not found "
                             "in music.libraries")
        chans = lib_index[src['library']]['channels']
    elif 'inline' in src:
        chans = src['inline']['channels']
    elif 'file' in src:
        path = os.path.join(project_root, src['file'])
        if not os.path.exists(path):
            raise MusicError(f"song {sid!r}: file {src['file']!r} not found in the project")
        data = json.load(open(path))
        chans = data['channels'] if 'channels' in data else data['songs'][0]['channels']
    else:
        raise MusicError(f"song {sid!r}: source needs 'library', 'inline' or 'file'")
    out = []
    seen = set()
    for c in chans:
        slot = F.val(c['slot'])
        if slot not in SLOTS:
            raise MusicError(f"song {sid!r}: channel slot ${slot:02X} is not one of the "
                             "six state slots $00/$1A/$34/$4E/$68/$82")
        if slot in seen:
            raise MusicError(f"song {sid!r}: two channels on slot ${slot:02X}")
        seen.add(slot)
        out.append({"slot": slot, "hw": F.val(c['hw']),
                    "header": list(c['header']), "tokens": c['tokens']})
    if not 1 <= len(out) <= 6:
        raise MusicError(f"song {sid!r}: {len(out)} channels (1-6 allowed)")
    return out


class Plan:
    """Everything the music emitters need, resolved once per compile."""

    def __init__(self):
        self.songs = []               # [{id, first_id, channels, bank, bytes}] in id order
        self.song_ids = {}            # project song id -> its sound id (S147: one per song)
        self.banks = {}               # bank key -> [songs]: $74, $75, ('ext', k) (S147)
        self.split = None             # S116 field, always None since S147 (no row 5)
        self.room_bgm = [0] * 256          # S138: every map id (128 until S137)
        self.gate_bgm = [0] * GATE_TABLE_LEN
        self.gate_battle = [0] * GATE_TABLE_LEN
        self.room_battle = [0] * 256       # S138: every map id
        self.battle = {'normal': 0, 'boss': 0, 'arena': 0, 'starry': 0}
        self.fights = []              # [(eid, sound id)]
        self.rules = []               # S129: [(kind, id, [(flag, must_be_off)], sound id, what)]
        self.warnings = []
        self.stream_bytes = {}        # bank key -> stream bytes used
        self.records_bytes = 0        # S147: the songs' records in bank $74
        self.arena_alias = {}         # S138: {project arena copy mid: $5D / $06}

    def legacy(self):
        """(bank74 songs, room_bgm, song_ids, warnings) — the S64 tuple."""
        return ({"_source": "project.json custom.music", "songs": self.banks.get(0x74, [])},
                self.room_bgm, self.song_ids, self.warnings)

    def song_bytes(self):
        """S147: every song's stream bytes (wherever they are)."""
        return sum(self.stream_bytes.values())


def dummy_id(slot, hw):
    """S147: the id of bank $74's dummy record for a channel on state slot `slot`
    with hw channel `hw` (SongRecords: id $9E + 4 x slot index + hw)."""
    return FIRST_ID + 4 * SLOTS.index(slot) + (hw & 3)


def dummy_records(silent_ptr):
    """S147: the 95 dummy records of bank $74 (SongRecords, $74:$4003) as bytes —
    == the template's (test_compiler checks it against the built ROM)."""
    out = bytearray()
    for k in range(SONG_IDS):
        slot, hw = (SLOTS[k // 4], k % 4) if k < 4 * len(SLOTS) else (0x00, 0)
        out += bytes((slot, hw, silent_ptr & 0xFF, silent_ptr >> 8))
    return bytes(out)


SILENT_STREAM = bytes((0, 0, 0, 0, 0xFF, 0x00))      # bank $74 SongSilent


def record_bytes(song):
    """S147: a song's record in bank $74: channels, bank, 4 B per channel."""
    return 2 + 4 * len(song['channels'])


def _value(v, song_ids, used, ctx, warnings):
    """A <song> value -> sound id (0 = not set)."""
    if v is None or v == '' or v == 0:
        return 0
    if isinstance(v, str) and v in song_ids:
        return song_ids[v]
    if isinstance(v, str) and not v[:1].isdigit() and not v.startswith(('$', '0x', '0X')):
        raise MusicError(f"{ctx}: {v!r} is not a defined song id (music.songs) nor a "
                         "numeric sound id")
    n = F.val(v)
    if not 1 <= n <= LAST_ID:
        raise MusicError(f"{ctx}: sound id {F.hexb(n)} outside $01-$FC")
    if n >= FIRST_ID and n not in used:
        warnings.append(f"{ctx}: raw id ${n:02X} is in the project range but no song "
                        "claims it")
    return n


def plan(prj):
    P = Plan()
    music = prj.custom.get('music') or {}
    for k in music:
        if k not in MUSIC_KEYS and not k.startswith('_'):
            raise MusicError(f"unknown key {k!r}")
    repo = _repo_root(getattr(prj, 'repo_root', None) or prj.root)
    lib_index = load_libraries(repo, music.get('libraries', []))
    sc = song_codec(repo)

    # ---- songs + id allocation --------------------------------------------
    songs = music.get('songs', [])
    names = set()
    resolved = []
    for s in songs:
        if not s.get('id'):
            raise MusicError("a song without an id")
        if s['id'] in names:
            raise MusicError(f"song id {s['id']!r} defined twice")
        names.add(s['id'])
        chans = song_channels(s, lib_index, prj.root)
        if any(c['slot'] in SE_SLOTS for c in chans):
            P.warnings.append(f"song {s['id']}: plays on a sound-effect slot "
                              "($00/$1A) — a sound effect cuts that channel until the "
                              "song restarts")
        fid = s.get('first_id', 'auto')
        resolved.append({"id": s['id'], "channels": chans,
                         "_explicit": None if str(fid) == 'auto' else F.val(fid)})
    used = set()
    if len(resolved) > SONG_IDS:
        raise MusicError(f"{len(resolved)} songs — at most {SONG_IDS} (one sound id each, "
                         f"${FIRST_ID:02X}-${LAST_ID:02X})")

    def claim(fid, sid):
        if not (FIRST_ID <= fid <= LAST_ID):
            raise MusicError(f"song {sid!r}: id ${fid:02X} outside "
                             f"${FIRST_ID:02X}-${LAST_ID:02X}")
        if fid in used:
            raise MusicError(f"song {sid!r}: id ${fid:02X} already claimed")
        used.add(fid)

    # S147: one id per song (a channel no longer takes an id of its own)
    for r in resolved:
        if r['_explicit'] is not None:
            r['first_id'] = r['_explicit']
            claim(r['first_id'], r['id'])
    nxt = FIRST_ID
    for r in resolved:
        if r['_explicit'] is None:
            while nxt in used:
                nxt += 1
            r['first_id'] = nxt
            claim(nxt, r['id'])
        r.pop('_explicit')
        for c in r['channels']:
            if not 0 <= c['hw'] <= 3:
                raise MusicError(f"song {r['id']!r}: hw channel {c['hw']} (0-3 allowed)")
    resolved.sort(key=lambda r: r['first_id'])
    P.song_ids = {r['id']: r['first_id'] for r in resolved}

    # ---- song banks (S147): one bank a song, first fit in id order --------
    # bank $74 holds the head, the directory and EVERY song's record first
    from . import validators as V
    P.records_bytes = sum(record_bytes(r) for r in resolved)
    tmpl = V.TEMPLATE_SIZE.get(0x74) or 0
    cap = {0x74: BANK_BYTES - tmpl - DIR_BYTES - P.records_bytes, 0x75: EXT_SONG_CAP}
    if cap[0x74] < 0:
        raise MusicError("the song records do not fit bank $74")
    order = [0x74, 0x75]
    fill = {0x74: 0, 0x75: 0}
    for r in resolved:
        n = sum(len(sc.emit_tokens(c['header'], c['tokens'])) for c in r['channels'])
        r['bytes'] = n
        if n > EXT_SONG_CAP:
            raise MusicError(f"song {r['id']!r}: {n:,} bytes — a song must fit one bank "
                             f"({EXT_SONG_CAP:,} B)")
        for b in order:
            if fill[b] + n <= cap[b]:
                break
        else:
            b = ('ext', len(order) - 2)
            order.append(b)
            cap[b], fill[b] = EXT_SONG_CAP, 0
        fill[b] += n
        r['bank'] = b
        P.banks.setdefault(b, []).append(r)
        P.stream_bytes[b] = fill[b]
    P.songs = resolved

    def val(v, ctx):
        return _value(v, P.song_ids, used, ctx, P.warnings)

    # ---- room defaults ----------------------------------------------------
    defaults = {}
    for key, v in (music.get('room_defaults') or {}).items():
        mid = F.val(key)
        if mid in defaults:
            raise MusicError(f"room_defaults declares mapID {key!r} twice")
        defaults[mid] = v
    for r in prj.rooms:
        m = r.get('music')
        if m is not None:
            mid = F.val(r['mapID'])
            if mid in defaults and defaults[mid] != m:
                raise MusicError(f"room {r.get('id')}: rooms[].music and "
                                 f"music.room_defaults disagree for {F.hexb(mid)}")
            defaults[mid] = m
    size = max([256] + [F.val(r['mapID']) + 1 for r in prj.rooms]
               + [F.val(k) + 1 for k in defaults if isinstance(F.val(k), int)]
               + [F.val(k) + 1 for k in ((music.get('battle') or {}).get('rooms') or {})
                  if isinstance(F.val(k), int)])
    P.room_bgm = [0] * size            # S140: index = the project mapID (regions: up to $3FEA)
    P.room_battle = [0] * size
    for mid, v in defaults.items():
        if not _room_key_ok(prj, mid):
            raise MusicError(_range_msg("room_defaults mapID", mid))
        if v in (0, '0', '0x00', '$00'):
            raise MusicError(f"room_defaults {F.hexb(mid)}: id 0 is the no-assignment "
                             "sentinel — it cannot be assigned")
        P.room_bgm[mid] = val(v, f"room_defaults {F.hexb(mid)}")

    # ---- gates ------------------------------------------------------------
    for key, g in (music.get('gates') or {}).items():
        gid = F.val(key)
        if not 0 <= gid < GATE_TABLE_LEN:
            raise MusicError(f"music.gates: gate {key!r} outside 0-{GATE_TABLE_LEN - 1}")
        if not isinstance(g, dict):
            raise MusicError(f"music.gates {key}: an object {{floors, battles}}")
        bad = [k for k in g if k not in GATE_MUSIC_KEYS and not k.startswith('_')]
        if bad:
            raise MusicError(f"music.gates {key}: unknown key(s) {bad}")
        P.gate_bgm[gid] = val(g.get('floors'), f"music.gates {key} floors")
        P.gate_battle[gid] = val(g.get('battles'), f"music.gates {key} battles")
        for i, ru in enumerate(g.get('rules') or []):
            P.rules.append(_rule(prj, ru, MUSIC_RULE_GATE, gid, val,
                                 f"music.gates {key} rules[{i}]"))

    # ---- S129: music by flag — a room's rules (custom.rooms[].music_rules) ----
    for r in prj.rooms:
        for i, ru in enumerate(r.get('music_rules') or []):
            mid = F.val(r['mapID'])
            ctx = f"room {r.get('id')} music_rules[{i}]"
            P.rules.append(_rule(prj, ru, MUSIC_RULE_ROOM, mid, val, ctx))

    # gate rooms with no song of their own follow the gate (only matters when a
    # gate has a song: otherwise the vanilla path is byte-for-byte what it was)
    try:
        served = set(prj.gate_rooms())
    except Exception:
        served = set()
    try:
        bosses = set(prj.boss_room_ids())
    except Exception:
        bosses = set()
    if any(P.gate_bgm):
        for r in prj.rooms:
            mid = F.val(r['mapID'])
            if P.room_bgm[mid] == 0 and (r.get('id') in served
                                         or r.get('id') in bosses):
                P.room_bgm[mid] = FOLLOW_GATE

    # ---- battle -----------------------------------------------------------
    b = music.get('battle') or {}
    bad = [k for k in b if k not in BATTLE_KEYS and not k.startswith('_')]
    if bad:
        raise MusicError(f"music.battle: unknown key(s) {bad}")
    for k in ('normal', 'boss', 'arena', 'starry'):
        P.battle[k] = val(b.get(k), f"music.battle.{k}")
    for key, v in (b.get('rooms') or {}).items():
        mid = F.val(key)
        if not _room_key_ok(prj, mid):
            raise MusicError(_range_msg("music.battle.rooms: mapID", mid))
        P.room_battle[mid] = val(v, f"music.battle.rooms {F.hexb(mid)}")
    if any(P.gate_battle):
        for r in prj.rooms:
            mid = F.val(r['mapID'])
            if P.room_battle[mid] == 0 and r.get('id') in served:
                P.room_battle[mid] = FOLLOW_GATE
    for key, v in (b.get('fights') or {}).items():
        eid = F.val(key)
        if not 0 <= eid < 0xFFFF:
            raise MusicError(f"music.battle.fights: EID {key!r} out of range")
        sid = val(v, f"music.battle.fights {eid}")
        if sid:
            P.fights.append((eid, sid))
    P.fights.sort()
    if len(P.fights) > MAX_FIGHTS:
        raise MusicError(f"music.battle.fights: {len(P.fights)} fights (at most {MAX_FIGHTS})")
    # S138: the project's arena copies (ROM0 ArenaAlias, S128) for model_battle_bgm
    P.arena_alias = {}
    try:
        from editor2.core import your_arena as YA
        ar = YA.resolve(prj)
        if ar is not None:
            P.arena_alias = {ar['battle_mid']: 0x5D, ar['lobby_mid']: 0x06}
    except Exception:
        pass
    return P


def _rule(prj, ru, kind, ident, val, ctx):
    """S129 (ROADMAP P3.14d — music by flag): {"when": [terms], "song": <song>,
    "comment": …} -> (kind, id, [(flag, must_be_off)], sound id, ctx). First rule
    whose terms all hold wins (bank $71 MusicRulePick); a rule with no terms
    always holds (rules after it never play)."""
    if not isinstance(ru, dict):
        raise MusicError(f"{ctx}: a rule is an object {{when, song}}")
    bad = [k for k in ru if k not in ('when', 'song', 'comment') and not k.startswith('_')]
    if bad:
        raise MusicError(f"{ctx}: unknown key(s) {bad} (when, song)")
    sid = val(ru.get('song'), ctx + '.song')
    if not sid:
        raise MusicError(f"{ctx}: a rule needs a song")
    terms = []
    for t in ru.get('when') or []:
        is_ = t.get('is', 'set')
        if is_ not in ('set', 'clear'):
            raise MusicError(f"{ctx}: term 'is' must be set/clear")
        try:
            idx = prj.resolve_flag_ref(t.get('flag'), ctx)
        except Exception as ex:
            raise MusicError(str(ex))
        terms.append((idx, is_ == 'clear'))
    if len(terms) > MUSIC_RULE_MAX_TERMS:
        raise MusicError(f"{ctx}: {len(terms)} terms (max {MUSIC_RULE_MAX_TERMS})")
    return (kind, ident, terms, sid, ctx)


def resolve(prj):
    """S64 interface: (bank74_library, room_bgm[256], song_ids, warnings)."""
    return prj.music_plan().legacy()


# ---------------------------------------------------------------- emitters
def master_table_rows(P=None):
    """AudioMasterTableExt (ROM0 $3FE8): the 3 vanilla rows + ids $9E-$FC -> bank
    $74's dummy records (S147: always these 4 rows — no bank $75 row)."""
    return [(0x00, 0x4001, 0x1C), (0x21, 0x4001, 0x1D), (0x37, 0x4001, 0x1E),
            (FIRST_ID, SONG_RECORDS_AT, 0x74)]


def emit_region_master_table(prj, warnings):
    """region rom0_audio_master (patches/bank_000.asm, inside AudioMasterTableExt
    @ $3FE8, 24 B): the 3 vanilla rows, the bank $74 row (S147: its dummy records
    SongRecords $74:$4003 — templates/bank_074_head.asm ASSERTs the address), the
    $FF sentinel, $FF filler."""
    rows = master_table_rows()
    out = []
    what = {0x1C: 'vanilla row', 0x1D: 'vanilla row', 0x1E: 'vanilla row',
            0x74: 'project songs: bank $74 SongRecords (S147)'}
    ends = [r[0] for r in rows[1:]] + [0xFD]
    for (base, ptr, bank), end in zip(rows, ends):
        out.append(f"    db ${base:02X}, ${ptr & 0xFF:02X}, ${ptr >> 8:02X}, ${bank:02X}"
                   f"       ; ids ${base:02X}-${end - 1:02X} -> ${bank:02X}:${ptr:04X} ({what[bank]})")
    n = 4 * len(rows)
    out.append("    db $FF                      ; sentinel")
    n += 1
    pad = 24 - n
    out.append("    db " + ", ".join(["$FF"] * pad) + f"   ; filler ({pad} B; slot $3FE8-$3FFF)")
    return "\n".join(out) + "\n"


def song_ext_banks(prj):
    """S147: {('ext', k): bank $80-$FF} — the song banks past $75, taken from the 4
    MB ROM after the stream, place and animation banks (cached on the Project;
    Project.stream_plan drops it with the other plans)."""
    got = getattr(prj, '_song_ext', None)
    if got is not None:
        return got
    P = prj.music_plan()
    keys = sorted((b for b in P.banks if isinstance(b, tuple)), key=lambda b: b[1])
    out = {}
    if keys:
        from . import tileanim as TA
        TA.plan(prj)                       # streams, places, animations number first
        taken0 = list(getattr(prj, '_ext_taken', None) or [])
        try:
            for k in keys:
                out[k] = prj._take_ext_bank('songs')
        except Exception:
            prj._ext_taken = taken0
            raise
    prj._song_ext = out
    return out


def real_bank(prj, key):
    return key if isinstance(key, int) else song_ext_banks(prj)[key]


def ch_label(r, k):
    return f"SongCh_{r['first_id']:02X}_{k}"


def song_streams(prj, r):
    """[(label, bytes)] of a song's channels (song_codec.emit_tokens)."""
    repo = _repo_root(getattr(prj, 'repo_root', None) or prj.root)
    sc = song_codec(repo)
    return [(ch_label(r, k), sc.emit_tokens(c['header'], c['tokens']))
            for k, c in enumerate(r['channels'])]


def _stream_lines(prj, songs):
    out = []
    for r in songs:
        for k, (label, blob) in enumerate(song_streams(prj, r)):
            c = r['channels'][k]
            out.append(f"{label}:   ; {r['id']} channel {k} (slot ${c['slot']:02X}, hw "
                       f"{c['hw']}): {len(blob)} B")
            for i in range(0, len(blob), 16):
                out.append(F.db_line(list(blob[i:i + 16])))
    return out


def emit_bank_074(prj):
    """S147: bank $74 = the pinned head (SongStart + the dummy records) + the song
    directory + every song's record + the streams the plan keeps here."""
    from .emitters import template
    P = prj.music_plan()
    by_id = {r['first_id']: r for r in P.songs}
    lines = [template('bank_074_head.asm').rstrip('\n'), "",
             "; SongDirectory — one dw per id $9E-$FC: the song's record, 0 = no song.",
             "SongDirectory:"]
    for i in range(FIRST_ID, LAST_ID + 1, 8):
        ids = range(i, min(i + 8, LAST_ID + 1))
        lines.append("    dw " + ", ".join(f"SongRec_{j:02X}" if j in by_id else "$0000"
                                           for j in ids)
                     + f"   ; ids ${i:02X}-${ids[-1]:02X}")
    lines.append("")
    lines.append("; The song records: db channels, db the song's bank; per channel db dummy id,")
    lines.append("; db state slot, dw stream (S147).")
    for r in P.songs:
        b = real_bank(prj, r['bank'])
        lines.append(f"SongRec_{r['first_id']:02X}:   ; {r['id']}: {len(r['channels'])} "
                     f"channels, {r['bytes']:,} B in bank ${b:02X}")
        lines.append(F.db_line([len(r['channels']), b]))
        for k, c in enumerate(r['channels']):
            lines.append(f"    db ${dummy_id(c['slot'], c['hw']):02X}, ${c['slot']:02X}   "
                         f"; channel {k}: slot ${c['slot']:02X}, hw {c['hw']}")
            lines.append(f"    dw {ch_label(r, k)}")
    lines.append("")
    lines.append(f"; streams in bank $74 ({P.stream_bytes.get(0x74, 0):,} B)")
    lines += _stream_lines(prj, P.banks.get(0x74, []))
    return "\n".join(lines) + "\n"


def emit_song_bank(prj, key):
    """S147: bank $75 or a song bank $80+: the self-ID byte + its songs' streams."""
    P = prj.music_plan()
    b = real_bank(prj, key)
    songs = P.banks.get(key, [])
    lines = ["; " + "=" * 77,
             f"; BANK ${b:02X} — project song streams (S147, ROADMAP ARC CAP5; GENERATED by",
             "; editor2/core/music.py — do not hand-edit). The songs' records and the",
             "; directory are in bank $74 (SongStart, templates/bank_074_head.asm).",
             "; Songs: " + (", ".join(f"{r['id']} (${r['first_id']:02X})" for r in songs)
                           or "none"),
             "; " + "=" * 77, "",
             f'SECTION "ROM Bank ${b:03X}", ROMX[$4000], BANK[${b:02X}]', "",
             f"    db ${b:02X}                          ; bank self-ID at $4000", ""]
    lines += _stream_lines(prj, songs)
    return "\n".join(lines) + "\n"


def song_bank_files(prj):
    """S147: {bank $80+: 'bank_0xx.asm'} of the song banks past $75."""
    return {b: f"bank_{b:03x}.asm" for b in song_ext_banks(prj).values()}


def emit_song_ext_banks(prj, warnings):
    """multi:song_banks — one whole file per song bank $80+ (none when $74 / $75 hold
    every song)."""
    return {f"file:patches/{fn}": emit_song_bank(prj, k)
            for k, b in song_ext_banks(prj).items()
            for fn in [f"bank_{b:03x}.asm"]}


def song_layout(prj):
    """S147: [{id, sid, bank, channels: [(slot, hw, dummy id, label, bytes)]}] — where
    every song is (the census and the tests read the ROM through game.sym)."""
    P = prj.music_plan()
    out = []
    for r in P.songs:
        st = song_streams(prj, r)
        out.append({'id': r['id'], 'sid': r['first_id'], 'bank': real_bank(prj, r['bank']),
                    'channels': [(c['slot'], c['hw'], dummy_id(c['slot'], c['hw']), lab, blob)
                                 for c, (lab, blob) in zip(r['channels'], st)]})
    return out


def _table_lines(label, values, width=16, start=0, fmt=None):
    out = [f"{label}:"]
    for i in range(0, len(values), width):
        row = values[i:i + width]
        out.append(F.db_line(row, comment=fmt(start + i, row) if fmt else None))
    return out


def emit_bank_071_tables(prj, warnings):
    """The S116 tables of bank $71 (after the S64 CustomRoomBGMTable)."""
    P = prj.music_plan()
    for w in P.warnings:
        if w not in warnings:
            warnings.append(w)
    by_id = {v: k for k, v in P.song_ids.items()}

    def tag(v):
        if v == FOLLOW_GATE:
            return 'follow the gate'
        return by_id.get(v, F.hexb(v))

    lines = []                       # S147: CustomBGMChanTable is gone (bank $74 directory)
    lines += ["; " + "-" * 77,
              "; CustomGateBGMTable / CustomGateBattleBGMTable — per gate 0-95 (wGateID):",
              "; the song of its floors / of its battles, 0 = vanilla. Read by entries",
              "; 2 and 7 (S116). (generated)",
              "; " + "-" * 77,
              f"GATE_BGM_LEN EQU {GATE_TABLE_LEN}"]
    for label, vals in (("CustomGateBGMTable", P.gate_bgm),
                        ("CustomGateBattleBGMTable", P.gate_battle)):
        lines += _table_lines(label, vals, fmt=lambda i, row: f"gates {i}-{i + len(row) - 1}"
                              + (": " + ", ".join(f"{i + j}={tag(v)}" for j, v in enumerate(row) if v)
                                 if any(row) else ""))
    lines.append("")
    lines += ["; " + "-" * 77,
              "; CustomRoomBattleBGMTable — the 107 vanilla map ids ($00-$6A) /",
              "; CustomPlaceBattleBGMTable — one row per PLACE, place-number order (S140",
              "; ARC CAP3a; S138-S139: 256 rows by wMapID): the song of battles in that",
              "; room (0 = not set, $FF = follow the gate being dived). Read by entry 7",
              "; BattleBGMResolve through RoomSongByte71 (S116). (generated)",
              "; " + "-" * 77]
    lines += _table_lines("CustomRoomBattleBGMTable", P.room_battle[:VANILLA_ROWS],
                          fmt=lambda i, row: f"mapIDs ${i:02X}-${i + len(row) - 1:02X}"
                          + (": " + ", ".join(f"${i + j:02X}={tag(v)}"
                                              for j, v in enumerate(row) if v)
                             if any(row) else ""))
    lines += place_song_lines(prj, "CustomPlaceBattleBGMTable", P.room_battle, tag)
    lines.append("")
    lines += ["; " + "-" * 77,
              "; BattleBGMSettings — [normal, boss, arena, Starry final] (0 = vanilla:",
              "; $27 / $27 / $27 / $2B). BattleFightBGMTable — [EID lo, EID hi, song]",
              "; per fight (the first enemy's row, $DA03), $FF $FF ends. (generated)",
              "; " + "-" * 77,
              "BattleBGMSettings:",
              F.db_line([P.battle['normal'], P.battle['boss'], P.battle['arena'],
                         P.battle['starry']],
                        comment="normal, boss, arena, Starry final: "
                        + ", ".join(f"{k}={tag(v)}" for k, v in P.battle.items() if v)),
              "BattleFightBGMTable:"]
    for eid, sid in P.fights:
        lines.append(F.db_line([eid & 0xFF, eid >> 8, sid], comment=f"EID {eid} -> {tag(sid)}"))
    lines.append("    db $FF, $FF")
    lines.append("")
    lines += ["; " + "-" * 77,
              "; MusicRuleTable (S129, ROADMAP P3.14d — music by flag): rows [kind (0 a",
              "; room / 1 a gate by wGateID), key (dw; S140: a room's key = its vanilla",
              "; map id, or $100 + its place number — bank $71 RoomKey71), n, n x dw flag",
              "; (bit 15 = must be OFF), song]; the FIRST row of the room / gate whose",
              "; terms all hold plays. Read by MusicRulePick (entry 2). (generated)",
              "; " + "-" * 77,
              f"MUSIC_RULE_ROOM EQU {MUSIC_RULE_ROOM}",
              f"MUSIC_RULE_GATE EQU {MUSIC_RULE_GATE}",
              "MusicRuleTable:"]
    for kind, ident, terms, sid, what in P.rules:
        key = rule_key(prj, kind, ident)
        b = [kind, key & 0xFF, key >> 8, len(terms)]
        for idx, off in terms:
            w = idx | (0x8000 if off else 0)
            b += [w & 0xFF, w >> 8]
        b.append(sid)
        lines.append(F.db_line(b, comment=f"{what} -> {tag(sid)}"))
    lines.append("    db $FF")
    lines.append("")
    return lines


def rule_key(prj, kind, ident):
    """S140: a MusicRuleTable row's 16-bit key (bank $71 RoomKey71): a gate =
    its number; a room = its vanilla map id, or $100 + its place number."""
    if kind == MUSIC_RULE_GATE or ident < VANILLA_ROWS:
        return ident
    return 0x100 + prj.place_number(ident)


def place_song_lines(prj, label, table, tag):
    """S140: one row per place (P order), PLACE_SONG_LEN rows (the bank $71
    RoomSongByte71 bound) — `table` is indexed by the project mapID."""
    out = ["", f"{label}:   ; per place (place-number order)"]
    rows = prj.rooms
    for i in range(0, len(rows), 16):
        part = rows[i:i + 16]
        vals = [table[F.val(r['mapID'])] if F.val(r['mapID']) < len(table) else 0
                for r in part]
        tags = [f"{F.hexb(F.val(r['mapID']))}={tag(v)}" for r, v in zip(part, vals) if v]
        out.append(F.db_line(vals, comment=f"places {i}-{i + len(part) - 1}"
                             + (": " + ", ".join(tags) if tags else "")))
    return out


def rule_holds(terms, flags_on):
    """A rule's terms against a set of flags ON (the models; a story check
    counts as its own flag number)."""
    return all((idx in flags_on) != off for idx, off in terms)


# ---------------------------------------------------------------- models
# Python twins of the bank $71 resolvers (the template head, S116), used by the
# editor to say what plays where and by tools/census_music_resolve.py, which
# stub-calls the built ROM's entries 2 / 7 over a grid of game states and
# requires the same answers.
def model_room_bgm(P, ctx):
    """CustomRoomBGMResolve: ctx = {in_gate, map, gate, floor, last, boss_map}
    -> E (0 = the vanilla derivation decides)."""
    room = P.room_bgm

    def floor_song(d):
        if not d:
            return 0
        for k, i, terms, sid, _w in P.rules:        # S129: the gate's rules first
            if k == MUSIC_RULE_GATE and i == ctx['gate'] and \
                    rule_holds(terms, ctx.get('flags') or set()):
                return sid
        if ctx['gate'] >= GATE_TABLE_LEN:
            return 0
        return P.gate_bgm[ctx['gate']]

    def dive(d):
        if ctx['floor'] != (ctx['last'] - 2) & 0xFF:
            return floor_song(d)
        bm = ctx['boss_map']
        if bm < 0x6B:
            return 0
        e = room[bm]                       # S138: every id (was < $80 only)
        if e not in (0, FOLLOW_GATE):
            return e
        e = floor_song(d)
        return e if e else 0x34

    flags_on = ctx.get('flags') or set()

    def rule(kind, ident):
        for k, i, terms, sid, _w in P.rules:
            if k == kind and i == ident and rule_holds(terms, flags_on):
                return sid
        return 0

    if ctx['in_gate']:
        return dive(True)
    m = ctx['map']                         # S138: no `cp $80` — 256 rows
    e = rule(MUSIC_RULE_ROOM, m)
    if e:
        return e
    e = room[m]
    if e == FOLLOW_GATE:
        return dive(True)
    if e:
        return e
    if m >= 0x61:
        return dive(False)
    if m < 0x50 or m == 0x52 or m >= 0x5D:
        return 0
    return dive(True)


def model_battle_bgm(P, ctx):
    """BattleBGMResolve: ctx = {link, map, starry, eid, in_gate, gate, mode}
    -> E (the song the battle starts with)."""
    # S138 (census fix): bank $71 reads the arena tests through ROM0 ArenaMapID
    # (S128): the project's arena copy counts as $5D, its lobby as $06 — the room
    # table and the special-room tests below read the raw map id
    amap = getattr(P, 'arena_alias', {}).get(ctx['map'], ctx['map'])
    e = 0x27
    if amap == 0x5D and ctx['starry'] == 2:
        e = 0x2B
    if ctx['link']:
        return e
    for eid, sid in P.fights:
        if eid == ctx['eid']:
            return sid
    b = P.battle
    if amap == 0x5D:
        if e == 0x2B and b['starry']:
            return b['starry']
        if b['arena']:
            return b['arena']

    def gate():
        if ctx['gate'] < GATE_TABLE_LEN and P.gate_battle[ctx['gate']]:
            return P.gate_battle[ctx['gate']]
        return None

    def typ():
        if ctx['mode'] == 3 and b['boss']:
            return b['boss']
        if e != 0x27:
            return e
        return b['normal'] or e

    if ctx['in_gate']:
        return gate() or typ()
    m = ctx['map']                         # S138: no `cp $80` — 256 rows
    v = P.room_battle[m]
    if v == FOLLOW_GATE:
        return gate() or typ()
    if v:
        return v
    if m < 0x50 or m == 0x52 or m >= 0x5D:
        return typ()
    return gate() or typ()
