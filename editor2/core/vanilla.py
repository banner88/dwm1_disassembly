"""vanilla.py — PIL-free reader of the vanilla room table (S94b).

Shared by the compiler (entrance-redirect lowering, project.py) and the
live renderer (render_project.py) so both see the SAME notion of a
vanilla room's valid step entries. Source: extracted/map_table.json
(tools/dump_map_table.py), whose step lists are contaminated by phantom
rows past the real block (DOC_AUDIT S91) — `valid_steps` cuts the list at
the first entry whose tileset bank / pointers / coordinates are not sane,
which is the only rule the engine itself does not enforce (it checks only
tileset_bank in (0,$80)).
"""

import json
import os

VALID_TILESET_BANKS = set(range(0x23, 0x32)) | {0x37, 0x38}


class VanillaTable:
    def __init__(self, repo_root):
        path = os.path.join(repo_root, 'extracted', 'map_table.json')
        try:
            mt = json.load(open(path))
        except Exception:
            mt = []
        self.entries = {e['map_type']: e for e in mt if 'map_type' in e}

    def screen(self, mid, scr_idx):
        e = self.entries.get(mid)
        if e is None:
            raise KeyError(f"vanilla room ${mid:02X} has no room table entry")
        for sr in e.get('sub_rooms', []):
            if sr.get('c925') == scr_idx:
                return sr
        raise KeyError(f"vanilla room ${mid:02X} has no screen {scr_idx}")

    def counter(self, mid, scr_idx):
        return int(self.screen(mid, scr_idx)['ram_counter'], 16)

    def valid_steps(self, mid, scr_idx):
        """The screen's VALID step entries (room states), in order; the
        first invalid entry ends the list (never empty: falls back to
        step 0 alone)."""
        sr = self.screen(mid, scr_idx)
        out = []
        for st in sr['steps']:
            b = int(st['bytes_0_1'], 16) >> 8
            ip, ep = int(st['interact_ptr'], 16), int(st['exit_ptr'], 16)
            ok = (b in VALID_TILESET_BANKS and 0x4000 <= ip < 0x8000
                  and 0x4000 <= ep < 0x8000
                  and all(it['x'] < 16 and it['y'] < 16
                          for it in st.get('interact_data', [])))
            if not ok:
                break
            out.append(st)
        return out or sr['steps'][:1]

    def step_exits(self, mid, scr_idx, step):
        """The vanilla exit rows of one step as compiler-shaped dicts
        (x, y, dest 'vanilla:$xx', gate_flag, screen_byte, spawn_x,
        spawn_y) — EVERY 7-byte row up to the $FF terminator, exactly what
        the engine's SharedPtrChase reads. The dump tool labels x=0 / x=9
        rows 'arrival_point' / 'special_marker'; they are ordinary edge
        (boundary, Entry 9) exits and are kept verbatim."""
        st = self.valid_steps(mid, scr_idx)[step]
        rows = []
        for ex in st.get('exit_data', []):
            rows.append({
                'x': ex['trigger_x'], 'y': ex['trigger_y'],
                'dest': f"vanilla:${ex['dest_map_type']:02X}",
                'gate_flag': ex.get('gate_flag', 0),
                'screen_byte': ex['screen_byte'],
                'spawn_x': ex['spawn_x'], 'spawn_y': ex['spawn_y'],
                'comment': f"vanilla exit ({ex['trigger_x']},{ex['trigger_y']})"
                           f" -> ${ex['dest_map_type']:02X}",
            })
        return rows
