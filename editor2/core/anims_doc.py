"""anims_doc.py — the Animations tab's document model and a skill's own
presentation (ROADMAP P3.11e, S112; EDITOR_DESIGN §5.3 "As built S112";
compiler: editor2/core/battle_anims.py, PROJECT_COMPILER §2.28).

`custom.animations` = the project's NEW battle animations (numbers $2D..):
each a list of steps — a frame of one of the 45 stock animations with how long
it shows, a sound cue, or a blank. `gamedata.skills.<id>.presentation` = what
a skill shows instead of its look's own animation: an animation (stock or new)
with a motion, a screen effect, or nothing. Every setter validates with the
compiler's models (MonstersMixin._commit_data) before it is kept.
"""

import copy
import re

from editor2.core import battle_anims as BA


class AnimsMixin:
    # ------------------------------------------------------------ reading
    def animations(self):
        out = []
        for k, a in enumerate(BA.custom_list(self.data)):
            e = {'id': a['id'], 'name': a.get('name') or a['id'], 'number': BA.FIRST_CUSTOM + k,
                 'steps': copy.deepcopy(a.get('steps') or []), 'users': self.animation_users(a['id'])}
            try:
                c = BA.compose(a)
                e.update(duration=BA.duration(a), sources=c['sources'], tiles=c['tiles'],
                         frames=len(c['frames']), error=None, warnings=c['warnings'])
            except BA.AnimError as ex:
                e.update(duration=0, sources=[], tiles=0, frames=0, error=str(ex), warnings=[])
            out.append(e)
        return out

    def animation(self, aid):
        for e in self.animations():
            if e['id'] == aid:
                return e
        raise KeyError(aid)

    def animation_choices(self):
        """[(number, label)] — the 45 stock animations, then the project's."""
        out = [(c, f'${c:02X} {BA.stock_name(c)}') for c in range(BA.N_STOCK)]
        for e in self.animations():
            out.append((e['number'], f"${e['number']:02X} {e['name']} (new)"))
        return out

    def animation_users(self, aid):
        """Skill ids whose presentation shows animation `aid`."""
        sk = ((self.data.get('gamedata') or {}).get('skills')) or {}
        return sorted(int(k) for k, v in sk.items()
                      if isinstance(v, dict) and isinstance(v.get('presentation'), dict)
                      and v['presentation'].get('animation') == aid)

    def skill_presentation(self, sid):
        """{'own': the presentation dict or None, 'look': the id the tables see,
        'party' / 'enemy': the look's routine index per caster side, 'cmd_foe' /
        'cmd_own': the look's animation numbers}."""
        sid = int(sid)
        row = ((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {}
        look = self.skill_detail(sid).get('looks_like', sid)
        if look is None or look >= BA.SKILL_ROWS:
            look = sid if sid < BA.SKILL_ROWS else 0x09
        van = BA.vanilla()['skills'][look]
        return {'own': copy.deepcopy(row.get('presentation')), 'look': look,
                'party': van['party'], 'enemy': van['enemy'],
                'cmd_foe': van['cmd_foe'], 'cmd_own': van['cmd_own']}

    # ------------------------------------------------------------ writing
    def _battle_anim_write(self, mutate):
        data = copy.deepcopy(self.data)
        cu = data.setdefault('custom', {})
        lst = cu.setdefault('animations', [])
        mutate(lst, data)
        if not lst:
            cu.pop('animations')
        if not cu:
            data.pop('custom')
        self._commit_data(data)

    def _new_battle_anim_id(self, name):
        base = re.sub(r'[^a-z0-9]+', '_', (name or 'animation').lower()).strip('_') or 'animation'
        ids = {a['id'] for a in BA.custom_list(self.data)}
        aid, k = base, 2
        while aid in ids:
            aid, k = f'{base}_{k}', k + 1
        return aid

    def new_animation(self, name, source=None):
        """A new animation (all the steps of stock animation `source`, or Blaze's
        first frame) -> its id."""
        if len(BA.custom_list(self.data)) >= BA.MAX_CUSTOM:
            raise BA.AnimError(f'at most {BA.MAX_CUSTOM} new animations')
        aid = self._new_battle_anim_id(name)
        steps = BA.expand_source(int(source)) if source is not None else \
            [{'from': 0, 'frame': 0, 'hold': 4}, {'blank': True, 'hold': 2}]

        def mut(lst, _d):
            lst.append({'id': aid, 'name': name or aid, 'steps': steps})
        self._battle_anim_write(mut)
        return aid

    def duplicate_animation(self, aid):
        src = self.animation(aid)
        return self._battle_anim_dup(src)

    def _battle_anim_dup(self, src):
        if len(BA.custom_list(self.data)) >= BA.MAX_CUSTOM:
            raise BA.AnimError(f'at most {BA.MAX_CUSTOM} new animations')
        nid = self._new_battle_anim_id(src['name'] + ' copy')

        def mut(lst, _d):
            lst.append({'id': nid, 'name': src['name'] + ' copy', 'steps': src['steps']})
        self._battle_anim_write(mut)
        return nid

    def delete_animation(self, aid):
        users = self.animation_users(aid)
        if users:
            names = self.skill_names_effective()
            raise BA.AnimError('still shown by ' + ', '.join(f'{u} {names.get(u, "")}' for u in users)
                               + ' — give those skills another animation first')

        def mut(lst, _d):
            lst[:] = [a for a in lst if a.get('id') != aid]
        self._battle_anim_write(mut)

    def rename_animation(self, aid, name):
        def mut(lst, _d):
            for a in lst:
                if a.get('id') == aid:
                    a['name'] = name
        self._battle_anim_write(mut)

    def move_animation(self, aid, delta):
        """Up / down in the list (= its number)."""
        def mut(lst, _d):
            i = next(k for k, a in enumerate(lst) if a.get('id') == aid)
            j = max(0, min(len(lst) - 1, i + delta))
            lst.insert(j, lst.pop(i))
        self._battle_anim_write(mut)

    def set_animation_steps(self, aid, steps):
        def mut(lst, _d):
            for a in lst:
                if a.get('id') == aid:
                    a['steps'] = copy.deepcopy(steps)
        self._battle_anim_write(mut)

    def set_skill_presentation(self, sid, pres):
        """pres: None (what its look shows) or a presentation dict."""
        def mut(e):
            if pres is None:
                e.pop('presentation', None)
            else:
                e['presentation'] = copy.deepcopy(pres)
        self._skill_write(int(sid), mut)
