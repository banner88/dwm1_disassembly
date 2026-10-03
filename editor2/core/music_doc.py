"""music_doc.py — the Music tab's document model (S116, ROADMAP P3.13b; EDITOR_DESIGN
§5.6 "As built S116"; compiler side: editor2/core/music.py, PROJECT_COMPILER §2.9).

Reads and writes custom.music:
  * songs — the project's songs: from the DWM2 catalog / the MIDI library
    (`source.library`) or imported MIDI files (`source.file` =
    assets/music/<id>.json, written here by midi_to_song's automatic
    conversion);
  * names — the author's names for any song (vanilla ids "0x09", library ids,
    project song ids); editor-only;
  * room_defaults / rooms[].music — a room's song (vanilla rooms by mapID,
    custom rooms by their own `music`);
  * gates — a gate's floors song and battle song;
  * battle — normal / boss / arena / Starry final battle songs, per-room and
    per-fight battle songs.
A song VALUE is a project song id (str), a sound id (int: any vanilla sound or
a raw custom id) or None (= the game's own choice).
"""
import copy
import json
import os

from editor2.core import music as M

LIBS = ["extracted/dwm2_song_library.json", "extracted/midi_song_library.json"]
REPO = M._OWN_REPO


def value_key(v):
    """The JSON form of a song value (int -> '0x09')."""
    if v is None or v == '':
        return None
    if isinstance(v, int):
        return f'0x{v:02X}'
    return v


def parse_value(v):
    if v is None:
        return None
    if isinstance(v, int):
        return v
    s = str(v)
    if s[:1].isdigit() or s.startswith(('$', '0x', '0X')):
        return int(s.replace('$', '0x'), 0)
    return s


def _slug(s):
    out = ''.join(c if c.isalnum() else '_' for c in s.lower()).strip('_')
    while '__' in out:
        out = out.replace('__', '_')
    return out or 'song'


class MusicMixin:
    # ------------------------------------------------------------ data
    def music(self):
        return (self.data.get('custom') or {}).get('music') or {}

    def _music_mut(self):
        m = self.data.setdefault('custom', {}).setdefault('music', {})
        m.setdefault('libraries', list(LIBS))
        for lib in LIBS:
            if lib not in m['libraries']:
                m['libraries'].append(lib)
        m.setdefault('songs', [])
        return m

    def music_project(self):
        prj = self._project()
        prj.repo_root = REPO
        return prj

    def music_plan(self):
        """The compiler's plan of the current data (raises MusicError)."""
        return self.music_project().music_plan()

    def library_songs(self):
        """{library id: entry} of the repo catalogs (DWM2 + MIDI)."""
        return M.load_libraries(REPO, LIBS)

    def vanilla_sounds(self):
        from editor2.core import music_preview as MP
        return MP.catalog(REPO)

    # ------------------------------------------------------------ names
    def song_name(self, key, default=None):
        return (self.music().get('names') or {}).get(key, default)

    def set_song_name(self, key, name):
        m = self._music_mut()
        names = m.setdefault('names', {})
        if name and name.strip():
            names[key] = name.strip()
        else:
            names.pop(key, None)
        if not names:
            m.pop('names')
        self.touch()

    # ------------------------------------------------------------ songs
    def project_songs(self):
        return list(self.music().get('songs') or [])

    def project_song(self, sid):
        for s in self.project_songs():
            if s.get('id') == sid:
                return s
        return None

    def song_channels(self, sid):
        """Channels of a project song or a library song (preview)."""
        s = self.project_song(sid)
        lib = self.library_songs()
        if s is None:
            if sid in lib:
                return lib[sid]['channels']
            raise KeyError(sid)
        return M.song_channels(s, lib, self.project_dir)

    def unique_song_id(self, base):
        ids = {s.get('id') for s in self.project_songs()}
        sid, n = _slug(base), 2
        while sid in ids:
            sid = f'{_slug(base)}_{n}'
            n += 1
        return sid

    def add_library_song(self, lib_id, name=None):
        """Put a catalog song (DWM2 / MIDI library) into the project -> song id."""
        lib = self.library_songs()
        if lib_id not in lib:
            raise KeyError(lib_id)
        m = self._music_mut()
        sid = self.unique_song_id(lib_id)
        song = {'id': sid, 'source': {'library': lib_id}, 'first_id': 'auto'}
        nm = name or self.song_name(lib_id) or lib[lib_id].get('name')
        if nm:
            song['name'] = nm
        m['songs'].append(song)
        self.touch()
        return sid

    def midi_asset(self, sid):
        return f'assets/music/{sid}.json'

    def import_midi(self, path, name=None):
        """Convert a MIDI file automatically (tools/midi_to_song.py) into the
        project: writes assets/music/<id>.json, adds the song -> (song id,
        warnings). Raises ValueError with the converter's message."""
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            '_midi_to_song', os.path.join(REPO, 'tools', 'midi_to_song.py'))
        ms = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(ms)
        base = name or os.path.splitext(os.path.basename(path))[0]
        sid = self.unique_song_id(base)
        entry, warnings = ms.convert_entry(ms.options(path, sid, base))
        rel = self.midi_asset(sid)
        full = os.path.join(self.project_dir, rel)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        with open(full, 'w') as f:
            json.dump(entry, f, indent=1)
        m = self._music_mut()
        m['songs'].append({'id': sid, 'source': {'file': rel}, 'first_id': 'auto',
                           'name': base})
        self.touch()
        return sid, sorted(set(warnings))

    def song_uses(self, sid):
        """Where a song value (project song id or sound id) is assigned."""
        out = []
        key = value_key(sid)
        m = self.music()
        for mid, v in (m.get('room_defaults') or {}).items():
            if value_key(parse_value(v)) == key:
                out.append(f'room {mid}')
        for r in self.custom.get('rooms', []):
            if value_key(parse_value(r.get('music'))) == key:
                out.append(f"room {r.get('id')}")
        for g, d in (m.get('gates') or {}).items():
            for k in M.GATE_MUSIC_KEYS:
                if value_key(parse_value(d.get(k))) == key:
                    out.append(f'gate {g} {k}')
        b = m.get('battle') or {}
        for k in ('normal', 'boss', 'arena', 'starry'):
            if value_key(parse_value(b.get(k))) == key:
                out.append(f'{k} battles')
        for mid, v in (b.get('rooms') or {}).items():
            if value_key(parse_value(v)) == key:
                out.append(f'battles in room {mid}')
        for eid, v in (b.get('fights') or {}).items():
            if value_key(parse_value(v)) == key:
                out.append(f'fight EID {eid}')
        return out

    def remove_song(self, sid):
        """Remove a project song and every assignment of it -> the cleared uses."""
        uses = self.song_uses(sid)
        m = self._music_mut()
        s = self.project_song(sid)
        m['songs'] = [x for x in m['songs'] if x.get('id') != sid]
        for mid in [k for k, v in (m.get('room_defaults') or {}).items() if v == sid]:
            del m['room_defaults'][mid]
        for r in self.custom.get('rooms', []):
            if r.get('music') == sid:
                r.pop('music')
        for g in list((m.get('gates') or {})):
            d = m['gates'][g]
            for k in list(d):
                if d[k] == sid:
                    del d[k]
            if not d:
                del m['gates'][g]
        b = m.get('battle') or {}
        for k in ('normal', 'boss', 'arena', 'starry'):
            if b.get(k) == sid:
                del b[k]
        for sect in ('rooms', 'fights'):
            for k in [k for k, v in (b.get(sect) or {}).items() if v == sid]:
                del b[sect][k]
        (m.get('names') or {}).pop(sid, None)
        self._tidy_music()
        self.touch()
        return uses, (s or {}).get('source', {}).get('file')

    def _tidy_music(self):
        m = self._music_mut()
        for k in ('room_defaults', 'gates', 'names'):
            if k in m and not m[k]:
                del m[k]
        b = m.get('battle')
        if b is not None:
            for k in ('rooms', 'fights'):
                if k in b and not b[k]:
                    del b[k]
            if not b:
                del m['battle']

    # ------------------------------------------------------------ rooms
    def room_music(self, mid):
        """The project's song for a room (custom: rooms[].music, vanilla:
        room_defaults) — a value or None."""
        for r in self.custom.get('rooms', []):
            if r.get('placeholder'):
                continue
            if int(str(r['mapID']), 0) == mid and r.get('music') is not None:
                return parse_value(r.get('music'))
        for k, v in (self.music().get('room_defaults') or {}).items():
            if int(str(k).replace('$', '0x'), 0) == mid:
                return parse_value(v)
        return None

    def set_room_music_id(self, mid, value):
        value = value_key(value)
        for r in self.custom.get('rooms', []):
            if not r.get('placeholder') and int(str(r['mapID']), 0) == mid:
                if value is None:
                    r.pop('music', None)
                else:
                    r['music'] = value
                m = self.music()
                if m.get('room_defaults'):
                    for k in [k for k in m['room_defaults']
                              if int(str(k).replace('$', '0x'), 0) == mid]:
                        del m['room_defaults'][k]
                self.touch()
                return
        m = self._music_mut()
        rd = m.setdefault('room_defaults', {})
        for k in [k for k in rd if int(str(k).replace('$', '0x'), 0) == mid]:
            del rd[k]
        if value is not None:
            rd[f'0x{mid:02X}'] = value
        self._tidy_music()
        self.touch()

    # ------------------------------------------------------------ gates
    def gate_music(self, gate):
        d = (self.music().get('gates') or {}).get(str(gate)) or {}
        return parse_value(d.get('floors')), parse_value(d.get('battles'))

    def set_gate_music(self, gate, floors='keep', battles='keep'):
        m = self._music_mut()
        g = m.setdefault('gates', {}).setdefault(str(gate), {})
        for k, v in (('floors', floors), ('battles', battles)):
            if v == 'keep':
                continue
            v = value_key(v)
            if v is None:
                g.pop(k, None)
            else:
                g[k] = v
        if not g:
            del m['gates'][str(gate)]
        self._tidy_music()
        self.touch()

    # ------------------------------------------------------------ battle
    def battle_music(self):
        b = self.music().get('battle') or {}
        return {k: parse_value(b.get(k)) for k in ('normal', 'boss', 'arena', 'starry')}

    def set_battle_music(self, kind, value):
        assert kind in ('normal', 'boss', 'arena', 'starry')
        m = self._music_mut()
        b = m.setdefault('battle', {})
        v = value_key(value)
        if v is None:
            b.pop(kind, None)
        else:
            b[kind] = v
        self._tidy_music()
        self.touch()

    def room_battle_music(self, mid):
        for k, v in ((self.music().get('battle') or {}).get('rooms') or {}).items():
            if int(str(k).replace('$', '0x'), 0) == mid:
                return parse_value(v)
        return None

    def set_room_battle_music(self, mid, value):
        m = self._music_mut()
        rooms = m.setdefault('battle', {}).setdefault('rooms', {})
        for k in [k for k in rooms if int(str(k).replace('$', '0x'), 0) == mid]:
            del rooms[k]
        if value_key(value) is not None:
            rooms[f'0x{mid:02X}'] = value_key(value)
        self._tidy_music()
        self.touch()

    def fight_music(self):
        """{EID: value}"""
        f = (self.music().get('battle') or {}).get('fights') or {}
        return {int(k): parse_value(v) for k, v in f.items()}

    def set_fight_music(self, eid, value):
        m = self._music_mut()
        f = m.setdefault('battle', {}).setdefault('fights', {})
        f.pop(str(eid), None)
        if value_key(value) is not None:
            f[str(eid)] = value_key(value)
        self._tidy_music()
        self.touch()

    # ------------------------------------------------------------ capacity
    def music_capacity(self):
        """{'ids': used, 'ids_max', 'banks': {bank: bytes}, 'bank_max', 'error'}."""
        try:
            P = self.music_plan()
        except Exception as e:
            return {'error': str(e)}
        used = sum(len(s['channels']) for s in P.songs)
        return {'ids': used, 'ids_max': M.LAST_ID - M.FIRST_ID + 1,
                'banks': dict(P.stream_bytes), 'bank_max': M.BANK_STREAM_CAP,
                'song_ids': dict(P.song_ids), 'error': None,
                'warnings': list(P.warnings)}

    def music_snapshot(self):
        return copy.deepcopy(self.music())
