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

A <song> value is a project song id (its first sound id) or a raw sound id
(1-$FC: any vanilla sound, or a custom id). 0 / null = not set.

Resolution rules:
  * first_id "auto" allocates upward from $9E skipping explicit claims; a song
    reserves one consecutive id per channel (1-6 channels, any of the 6 state
    slots, each slot at most once). S116: a song keeps EXACTLY its channels —
    the rewritten InitBGM (patches/bank_000.asm) starts a project song through
    bank $71 entry 6 CustomBGMStart with the count from CustomBGMChanTable
    (the S64 trio padding / dropping is gone).
  * Two song banks (S116): songs in first-id order fill bank $74 (streams
    $4180-$7FFF, 16,000 B), the rest bank $75 from the first id that no longer
    fits (the split) — AudioMasterTableExt (ROM0 $3FE8, region
    rom0_audio_master) gets a 5th row [split, $4001, $75].
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

The byte emitter is tools/song_codec.py (emit_song_bank / song_bank_asm) — one
proven spec->bytes path for DWM2, MIDI, and inline sources.
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
SONG_BANKS = (0x74, 0x75)
STREAMS_AT = 0x4180
BANK_STREAM_CAP = 0x8000 - STREAMS_AT            # 16,000 B per song bank
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
        self.songs = []               # [{id, first_id, channels, bank}]
        self.song_ids = {}            # project song id -> first sound id
        self.banks = {}               # bank -> [songs]
        self.split = None             # first id resolved from bank $75 (None: one bank)
        self.room_bgm = [0] * 256          # S138: every map id (128 until S137)
        self.chan_table = [0] * (LAST_ID - FIRST_ID + 1)
        self.gate_bgm = [0] * GATE_TABLE_LEN
        self.gate_battle = [0] * GATE_TABLE_LEN
        self.room_battle = [0] * 256       # S138: every map id
        self.battle = {'normal': 0, 'boss': 0, 'arena': 0, 'starry': 0}
        self.fights = []              # [(eid, sound id)]
        self.rules = []               # S129: [(kind, id, [(flag, must_be_off)], sound id, what)]
        self.warnings = []
        self.stream_bytes = {}        # bank -> bytes used
        self.arena_alias = {}         # S138: {project arena copy mid: $5D / $06}

    def legacy(self):
        """(bank74_library, room_bgm, song_ids, warnings) — the S64 tuple."""
        return ({"_source": "project.json custom.music", "songs": self.banks.get(0x74, [])},
                self.room_bgm, self.song_ids, self.warnings)


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

    def claim(fid, n, sid):
        for i in range(fid, fid + n):
            if not (FIRST_ID <= i <= LAST_ID):
                raise MusicError(f"song {sid!r}: id ${i:02X} outside "
                                 f"${FIRST_ID:02X}-${LAST_ID:02X}")
            if i in used:
                raise MusicError(f"song {sid!r}: id ${i:02X} already claimed")
            used.add(i)

    for r in resolved:
        if r['_explicit'] is not None:
            r['first_id'] = r['_explicit']
            claim(r['first_id'], len(r['channels']), r['id'])
    nxt = FIRST_ID
    for r in resolved:
        if r['_explicit'] is None:
            while any(i in used for i in range(nxt, nxt + len(r['channels']))):
                nxt += 1
            r['first_id'] = nxt
            claim(nxt, len(r['channels']), r['id'])
        r.pop('_explicit')
    resolved.sort(key=lambda r: r['first_id'])
    P.song_ids = {r['id']: r['first_id'] for r in resolved}

    # ---- bank packing ($74 then $75) --------------------------------------
    bank, fill = 0x74, 0
    for r in resolved:
        n = sum(len(sc.emit_tokens(c['header'], c['tokens'])) for c in r['channels'])
        r['bytes'] = n
        if bank == 0x74 and fill + n > BANK_STREAM_CAP:
            bank, fill = 0x75, 0
            P.split = r['first_id']
        if fill + n > BANK_STREAM_CAP:
            raise MusicError(f"songs need more than the two song banks ($74/$75, "
                             f"{BANK_STREAM_CAP} B each) — remove or shorten songs "
                             f"(stopped at {r['id']!r})")
        fill += n
        r['bank'] = bank
        P.banks.setdefault(bank, []).append(r)
        P.stream_bytes[bank] = fill
        P.chan_table[r['first_id'] - FIRST_ID] = len(r['channels'])
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
def master_table_rows(P):
    rows = [(0x00, 0x4001, 0x1C), (0x21, 0x4001, 0x1D), (0x37, 0x4001, 0x1E),
            (FIRST_ID, 0x4001, 0x74)]
    if P.split is not None:
        rows.append((P.split, 0x4001, 0x75))
    return rows


def emit_region_master_table(prj, warnings):
    """region rom0_audio_master (patches/bank_000.asm, inside AudioMasterTableExt
    @ $3FE8, 24 B): the 3 vanilla rows, the bank $74 row, the bank $75 row when
    songs spill there, the $FF sentinel, $FF filler."""
    P = prj.music_plan()
    rows = master_table_rows(P)
    out = []
    what = {0x1C: 'vanilla row', 0x1D: 'vanilla row', 0x1E: 'vanilla row',
            0x74: 'project song bank 1', 0x75: 'project song bank 2 (S116)'}
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


def song_bank_asm(prj, bank):
    P = prj.music_plan()
    repo = _repo_root(getattr(prj, 'repo_root', None) or prj.root)
    sc = song_codec(repo)
    base = FIRST_ID if bank == 0x74 else (P.split or FIRST_ID)
    lib = {"_source": "project.json custom.music (music emitter, S116)",
           "songs": P.banks.get(bank, [])}
    return sc.song_bank_asm(lib, bank=bank, base_id=base)


def bank_images(prj):
    """{bank: 16 KB image} of the project's song banks (preview + census)."""
    P = prj.music_plan()
    repo = _repo_root(getattr(prj, 'repo_root', None) or prj.root)
    sc = song_codec(repo)
    out = {}
    for bank in SONG_BANKS:
        base = FIRST_ID if bank == 0x74 else (P.split or FIRST_ID)
        img, _, _ = sc.emit_song_bank({"songs": P.banks.get(bank, [])}, bank=bank,
                                      base_id=base)
        out[bank] = img
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

    lines = ["; " + "-" * 77,
             "; CustomBGMChanTable — channel count of the project song starting at",
             f"; each id ${FIRST_ID:02X}-${LAST_ID:02X} (0 = no song starts here: the old",
             "; 3-channel default). Read by entry 6 CustomBGMStart (S116). (generated)",
             "; " + "-" * 77]
    lines += _table_lines("CustomBGMChanTable", P.chan_table, start=FIRST_ID,
                          fmt=lambda i, row: f"ids ${i:02X}-${i + len(row) - 1:02X}"
                          + "".join(f" ${i + j:02X}:{by_id.get(i + j, '?')}={n}ch"
                                    for j, n in enumerate(row) if n))
    lines.append("")
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
